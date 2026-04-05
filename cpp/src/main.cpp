#include <SKSE/Impl/PCH.h>
#include <SKSE/SKSE.h>
#include <RE/M/MenuOpenCloseEvent.h>
#include <RE/N/NativeFunction.h>
#include <RE/U/UI.h>
#include <spdlog/sinks/basic_file_sink.h>

#include <atomic>
#include <chrono>

using namespace std::literals;

namespace logger = SKSE::log;

namespace
{
    std::atomic<bool> g_seenSaveThisSession{ false };
    std::atomic<long long> g_lastSaveEpochMs{ 0 };
    std::atomic<int> g_openMenuCount{ 0 };
    std::atomic<bool> g_menuPauseActive{ false };
    std::atomic<long long> g_menuPauseStartedEpochMs{ 0 };
    std::atomic<long long> g_accumulatedMenuPauseMs{ 0 };

    long long GetEpochMsNow()
    {
        const auto now = std::chrono::system_clock::now();
        const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch());
        return ms.count();
    }

    float GetSecondsSinceLastSave(RE::StaticFunctionTag*)
    {
        if (!g_seenSaveThisSession.load()) {
            return -1.0F;
        }

        const auto last = g_lastSaveEpochMs.load();
        const auto now = GetEpochMsNow();

        if (last <= 0) {
            return 0.0F;
        }

        return static_cast<float>(now - last) / 1000.0F;
    }

    bool HasSeenSaveThisSession(RE::StaticFunctionTag*)
    {
        return g_seenSaveThisSession.load();
    }

    float GetMenuPausedSeconds(RE::StaticFunctionTag*)
    {
        long long pausedMs = g_accumulatedMenuPauseMs.load();

        if (g_menuPauseActive.load()) {
            const auto pauseStarted = g_menuPauseStartedEpochMs.load();
            if (pauseStarted > 0) {
                pausedMs += GetEpochMsNow() - pauseStarted;
            }
        }

        if (pausedMs < 0) {
            pausedMs = 0;
        }

        return static_cast<float>(pausedMs) / 1000.0F;
    }

    void BeginMenuPause()
    {
        if (g_menuPauseActive.exchange(true)) {
            return;
        }

        g_menuPauseStartedEpochMs.store(GetEpochMsNow());
        logger::info("Menu pause started.");
    }

    void EndMenuPause()
    {
        if (!g_menuPauseActive.exchange(false)) {
            return;
        }

        const auto pauseStarted = g_menuPauseStartedEpochMs.exchange(0);
        if (pauseStarted > 0) {
            const auto pauseDuration = GetEpochMsNow() - pauseStarted;
            if (pauseDuration > 0) {
                g_accumulatedMenuPauseMs.fetch_add(pauseDuration);
            }
        }

        logger::info("Menu pause ended.");
    }

    bool RegisterPapyrus(RE::BSScript::IVirtualMachine* vm)
    {
        vm->RegisterFunction("GetSecondsSinceLastSave", "SRSSE_Native", GetSecondsSinceLastSave);
        vm->RegisterFunction("HasSeenSaveThisSession", "SRSSE_Native", HasSeenSaveThisSession);
        vm->RegisterFunction("GetMenuPausedSeconds", "SRSSE_Native", GetMenuPausedSeconds);
        logger::info("Papyrus functions registered.");
        return true;
    }

    void OnSKSEMessage(SKSE::MessagingInterface::Message* message)
    {
        if (!message) {
            return;
        }

        switch (message->type) {
        case SKSE::MessagingInterface::kPostLoadGame:
            g_seenSaveThisSession.store(true);
            g_lastSaveEpochMs.store(GetEpochMsNow());
            g_accumulatedMenuPauseMs.store(0);
            g_menuPauseStartedEpochMs.store(0);
            g_menuPauseActive.store(false);
            logger::info("Load game detected; timer started from load time.");
            break;
        case SKSE::MessagingInterface::kSaveGame:
            g_seenSaveThisSession.store(true);
            g_lastSaveEpochMs.store(GetEpochMsNow());
            g_accumulatedMenuPauseMs.store(0);
            g_menuPauseStartedEpochMs.store(0);
            g_menuPauseActive.store(false);
            logger::info("Save event captured.");
            break;
        default:
            break;
        }
    }

    class MenuEventSink final : public RE::BSTEventSink<RE::MenuOpenCloseEvent>
    {
    public:
        RE::BSEventNotifyControl ProcessEvent(
            const RE::MenuOpenCloseEvent* event,
            RE::BSTEventSource<RE::MenuOpenCloseEvent>*)
            override
        {
            if (!event) {
                return RE::BSEventNotifyControl::kContinue;
            }

            if (event->opening) {
                const auto previousCount = g_openMenuCount.fetch_add(1);
                if (previousCount <= 0) {
                    g_openMenuCount.store(1);
                    BeginMenuPause();
                }
            } else {
                int expectedCount = g_openMenuCount.load();
                int nextCount = expectedCount;
                do {
                    nextCount = (expectedCount > 0) ? (expectedCount - 1) : 0;
                } while (!g_openMenuCount.compare_exchange_weak(expectedCount, nextCount));

                if (nextCount == 0) {
                    EndMenuPause();
                }
            }

            return RE::BSEventNotifyControl::kContinue;
        }
    };

    MenuEventSink g_menuEventSink;

    void InitializeLogging()
    {
        auto path = logger::log_directory();
        if (!path) {
            SKSE::stl::report_and_fail("Unable to find SKSE log directory.");
        }

        *path /= "SaveReminderSSE.log";

        auto sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(path->string(), true);
        auto log = std::make_shared<spdlog::logger>("global", std::move(sink));

        log->set_level(spdlog::level::info);
        log->flush_on(spdlog::level::info);

        spdlog::set_default_logger(std::move(log));
        spdlog::set_pattern("[%H:%M:%S.%e] [%^%l%$] %v");
    }
}

SKSEPluginInfo(
    .Version = REL::Version{ 0, 1, 3, 0 },
    .Name = "SaveReminderSSE"sv,
    .Author = "Omni"sv,
    .StructCompatibility = SKSE::StructCompatibility::Independent,
    .RuntimeCompatibility = SKSE::VersionIndependence::AddressLibrary
)

SKSEPluginLoad(const SKSE::LoadInterface* skse)
{
    InitializeLogging();
    SKSE::Init(skse);

    logger::info("SaveReminderSSE plugin loading...");

    auto* messaging = SKSE::GetMessagingInterface();
    if (!messaging || !messaging->RegisterListener(OnSKSEMessage)) {
        logger::critical("Failed to register SKSE messaging listener.");
        return false;
    }

    auto* papyrus = SKSE::GetPapyrusInterface();
    if (!papyrus || !papyrus->Register(RegisterPapyrus)) {
        logger::critical("Failed to register Papyrus interface.");
        return false;
    }

    auto* ui = RE::UI::GetSingleton();
    if (!ui) {
        logger::critical("Failed to acquire UI singleton.");
        return false;
    }

    ui->AddEventSink<RE::MenuOpenCloseEvent>(&g_menuEventSink);

    logger::info("SaveReminderSSE plugin loaded.");
    return true;
}
