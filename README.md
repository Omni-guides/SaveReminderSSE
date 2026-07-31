# SaveReminderSSE (Skyrim SE 1.5.97 / AE 1.6.x)

A Skyrim SE mod that reminds the player to save after a set time since their last load or save.

**Download:** https://www.nexusmods.com/skyrimspecialedition/mods/176475

The same DLL supports Skyrim SE 1.5.97 and AE 1.6.x. Skyrim VR is not supported.

## Features
- Reminder intervals from 5 to 90 minutes
- Optional timer pause while game menus are open
- Optional reminder suppression during combat and NPC dialogue
- Notification and pop-up display modes
- MCM Helper settings persistence and modlist defaults
- Optional diagnostic logging

## Dependencies
- SKSE64
- Address Library for SKSE Plugins matching your Skyrim runtime
- SkyUI
- MCM Helper

## Build
Run `tools/setup.ps1` once after cloning, then see `docs/build.md`.

The native plugin uses CommonLibSSE-NG 5.4.2 pinned to commit `274b463677936660797b6ada518258fe5e235f3a`.

## Structure
- `cpp/`: native SKSE plugin
- `papyrus/`: Papyrus scripts and compiler support
- `plugin/`: ESP
- `mcm/`: MCM Helper settings files
- `tools/`: build and release scripts
- `docs/`: build and CK setup notes

## Modlist authors
Copy `mcm/SaveReminderSSE_defaults.ini` to `MCM/Settings/SaveReminderSSE.ini` in your own settings mod to ship custom defaults.

## License
GPL-3.0-or-later. See `LICENSE`.
