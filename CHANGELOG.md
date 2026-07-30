# Changelog

## [0.2.2] - 2026-07-30
- Fixed dialogue suppression by checking the engine's actual Dialogue Menu state instead of relying on the player's dialogue target.
- Added a short dialogue-close debounce so transient menu closures between conversation states cannot release a reminder.
- Fixed suppression release near an interval boundary so it cannot produce two reminders only seconds apart.
- Hardened reminder polling so a failed update cannot permanently stop future reminders.
- Added optional detailed diagnostic logging to the MCM Maintenance page.

## [0.2.1] - 2026-07-29
- Migrated the native plugin from the unmaintained CharmedBaryon CommonLibSSE-NG 3.7.0 vcpkg port to alandtse CommonLibSSE-NG 5.4.2, pinned at commit `274b463677936660797b6ada518258fe5e235f3a`.
- Universal build supports Skyrim SE 1.5.97 and AE 1.6.x from one DLL. VR support remains disabled until it receives a dedicated compatibility test pass.
- Corrected CommonLib runtime-aware logging behavior, including the standard SKSE log locations for Steam, GOG, and VR builds.
- Fixed a bug where the reminder timer could get stuck paused indefinitely. The menu-pause tracking previously counted per-menu open/close events, which could desync (nested/stacked menus, HUD or Loading Menu churn on area transitions, third-party UI mods) and leave the pause flag stuck on with no reminder ever firing. It now reads the engine's own pause state (`RE::UI::GameIsPaused()`) directly and resyncs on every menu event and every timer poll, so it can't get stuck regardless of which menu misbehaves.
- Added an enabled-by-default MCM option to suppress reminders during NPC dialogue. The timer continues running and an overdue reminder can appear after the conversation ends.

## [0.1.4] - 2026-04-05
- Corrected ESL flag in packaged release (0.1.3 archive contained unflagged ESP).

## [0.1.3] - 2026-04-05
- ESL-flagged plugin (compacted FormIDs, light plugin flag set).
- Version number now shown on the MCM Maintenance page.

## [0.1.2] - 2026-04-04
Initial public release.
- ESL-flagged plugin (compacted FormIDs for light module compatibility).
- Packaging and tooling improvements.

## [0.1.1] - 2026-04-02
- Integrated MCM Helper: settings now persist across sessions via MCM Helper's settings store.
- Added menu pause tracking to native plugin; timer no longer advances while menus are open (if enabled).
- Shipped `mcm/settings.ini` and `mcm/SaveReminderSSE_defaults.ini` for modlist author overrides.

## [0.1.0] - 2026-03-31
Initial release.
- Native SKSE plugin tracks time since last load or save.
- Papyrus quest script polls native API and triggers reminders at a configurable interval.
- SkyUI MCM exposes enable toggle, reminder interval, menu pause, combat suppress, and display style.
