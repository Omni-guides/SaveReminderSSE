# Changelog

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
