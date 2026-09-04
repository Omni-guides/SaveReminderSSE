# Changelog

## Unreleased

## [0.2.3] - 2026-09-04
- Added Skyrim 1.7.104 support while retaining the same DLL for Skyrim SE 1.5.97 and AE 1.6.x.
- Updated to CommonLibSSE-NG 6.7.1, pinned to commit `70c1acd5261210982bd52f6d4468a082fe04d798`.
- Added automatic reminder-message translation for all nine languages supported by Skyrim SE on PC.
- Added an optional custom reminder message with an optional `{minutes}` placeholder.
- Added MCM actions to preview the current reminder and restore the translated default without changing other settings.

## [0.2.2] - 2026-07-31
- Added a universal DLL for Skyrim SE 1.5.97 and AE 1.6.x.
- Updated to CommonLibSSE-NG 5.4.2, pinned to commit `274b463677936660797b6ada518258fe5e235f3a`.
- Reworked menu-pause tracking to use the engine's pause state, preventing mismatched menu events from leaving the timer stuck.
- Added an option to suppress reminders during NPC dialogue (enabled by default).
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
