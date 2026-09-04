# SaveReminderSSE (Skyrim SE 1.5.97 / AE 1.6.x / Steam 1.7.104)

A Skyrim SE mod that reminds the player to save after a set time since their last load or save.

**Download:** https://www.nexusmods.com/skyrimspecialedition/mods/176475

The same DLL supports Skyrim SE 1.5.97, AE 1.6.x, and Steam 1.7.104. Skyrim VR is not supported.

## Features
- Reminder intervals from 5 to 90 minutes
- Optional timer pause while game menus are open
- Optional reminder suppression during combat and NPC dialogue
- Notification and pop-up display modes
- Automatic reminder-message translation for all nine Skyrim SE PC languages
- Optional custom reminder text with a `{minutes}` placeholder
- MCM Helper settings persistence and modlist defaults
- Optional diagnostic logging

## Dependencies
- SKSE64
- Address Library for SKSE Plugins matching your Skyrim runtime
- SkyUI
- MCM Helper

Skyrim 1.7.104 requires SKSE 2.3.1 and Address Library v13 or later.

## Build
Run `tools/setup.ps1` once after cloning, then see `docs/build.md`.

The native plugin uses CommonLibSSE-NG 6.7.1 pinned to commit `70c1acd5261210982bd52f6d4468a082fe04d798`.

## Structure
- `cpp/`: native SKSE plugin
- `papyrus/`: Papyrus scripts and compiler support
- `plugin/`: ESP
- `mcm/`: MCM Helper settings files
- `tools/`: build and release scripts
- `docs/`: build and CK setup notes

## Modlist authors
Copy `mcm/SaveReminderSSE_defaults.ini` to `MCM/Settings/SaveReminderSSE.ini` in your own settings mod to ship custom defaults.

Set `sCustomReminderMessage` under `[Display]` to ship custom reminder text. The `{minutes}` placeholder is optional. Leave the value empty to use the translated default selected from Skyrim's current language.

## License
GPL-3.0-or-later. See `LICENSE`.
