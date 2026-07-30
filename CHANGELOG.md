# Changelog

## [Unreleased]

## [0.2.2] - 2026-07-30
- Added a universal DLL for Skyrim SE 1.5.97 and AE 1.6.x. Skyrim VR remains unsupported.
- Updated to CommonLibSSE-NG 5.4.2, pinned to commit `274b463677936660797b6ada518258fe5e235f3a`.
- Reworked menu-pause tracking to use the engine's pause state, preventing mismatched menu events from leaving the timer stuck.
- Added an enabled-by-default option to suppress reminders during NPC dialogue.
- Fixed dialogue suppression by checking the engine's actual Dialogue Menu state instead of relying on the player's dialogue target.
- Added a short dialogue-close debounce so transient menu closures between conversation states cannot release a reminder.
- Fixed suppression release near an interval boundary so it cannot produce two reminders only seconds apart.
- Hardened reminder polling so a failed update cannot permanently stop future reminders.
- Added optional detailed diagnostic logging to the MCM Maintenance page.

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
