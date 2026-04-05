# SaveReminderSSE (Skyrim SE 1.6.1170)

A Skyrim SE mod that reminds the player to save after a set time since their last load or save.

**Download:** https://www.nexusmods.com/skyrimspecialedition/mods/176475

## Dependencies
- SKSE64
- Address Library for SKSE Plugins
- SkyUI
- MCM Helper

## Build
Run `tools/setup.ps1` once after cloning, then see `docs/build.md`.

## Structure
- `cpp/` — native SKSE plugin
- `papyrus/` — Papyrus scripts and compiler support
- `plugin/` — ESP
- `mcm/` — MCM Helper settings files
- `tools/` — build and release scripts
- `docs/` — build and CK setup notes

## Modlist authors
Copy `mcm/SaveReminderSSE_defaults.ini` to `MCM/Settings/SaveReminderSSE.ini` in your own settings mod to ship custom defaults.
