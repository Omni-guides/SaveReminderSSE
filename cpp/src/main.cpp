#include <SKSE/Impl/PCH.h>
#include <SKSE/SKSE.h>
#include <RE/D/DialogueMenu.h>
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
    std::atomic<bool> g_menuPauseActive{ false };
    std::atomic<long long> g_menuPauseStartedEpochMs{ 0 };
    std::atomic<long long> g_accumulatedMenuPauseMs{ 0 };

    long long GetEpochMsNow()
    {
        const auto now = std::chrono::system_clock::now();
        const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch());
        return ms.count();
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

    // Resyncs against the engine's own pause state instead of counting per-menu open/close
    // events, so a missed or mismatched event (nested menus, HUD/Loading Menu churn on area
    // transitions, third-party UI mods) can't leave the timer stuck paused.
    void SyncMenuPauseState()
    {
        auto* ui = RE::UI::GetSingleton();
        if (!ui) {
            return;
        }

        if (ui->GameIsPaused()) {
            BeginMenuPause();
        } else {
            EndMenuPause();
        }
    }

    float GetSecondsSinceLastSave(RE::StaticFunctionTag*)
    {
        SyncMenuPauseState();

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

    bool IsDialogueMenuOpen(RE::StaticFunctionTag*)
    {
        auto* ui = RE::UI::GetSingleton();
        return ui && ui->IsMenuOpen(RE::DialogueMenu::MENU_NAME);
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

    void WriteDebugLog(RE::StaticFunctionTag*, std::string message)
    {
        logger::info("[Debug] {}", message);
    }

    bool RegisterPapyrus(RE::BSScript::IVirtualMachine* vm)
    {
        vm->RegisterFunction("GetSecondsSinceLastSave", "SRSSE_Native", GetSecondsSinceLastSave);
        vm->RegisterFunction("HasSeenSaveThisSession", "SRSSE_Native", HasSeenSaveThisSession);
        vm->RegisterFunction("IsDialogueMenuOpen", "SRSSE_Native", IsDialogueMenuOpen);
        vm->RegisterFunction("GetMenuPausedSeconds", "SRSSE_Native", GetMenuPausedSeconds);
        vm->RegisterFunction("WriteDebugLog", "SRSSE_Native", WriteDebugLog);
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
            const RE::MenuOpenCloseEvent*,
            RE::BSTEventSource<RE::MenuOpenCloseEvent>*)
            override
        {
            SyncMenuPauseState();
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
    .Version = REL::Version{ 0, 2, 2, 0 },
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
