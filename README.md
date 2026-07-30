# SaveReminderSSE Universal (Skyrim SE 1.5.97 / AE 1.6.x)

A Skyrim SE mod that reminds the player to save after a set time since their last load or save.

**Download:** https://www.nexusmods.com/skyrimspecialedition/mods/176475

This universal build targets Skyrim SE 1.5.97 and AE 1.6.x from one DLL. It uses alandtse CommonLibSSE-NG 5.4.2 pinned at commit `274b463677936660797b6ada518258fe5e235f3a`. VR support is intentionally disabled until it receives a dedicated compatibility test pass.

The universal source and native plugin are licensed under GPL-3.0-or-later; see `LICENSE`.

## Dependencies
- SKSE64
- Address Library for SKSE Plugins matching your Skyrim runtime
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
