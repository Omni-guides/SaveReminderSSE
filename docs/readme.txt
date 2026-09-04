Save Reminder SSE
Skyrim SE 1.5.97 / AE 1.6.x / Steam 1.7.104

Version 0.2.3

The native plugin uses alandtse CommonLibSSE-NG 6.7.1. Skyrim VR is not
supported by this release.

License: GPL-3.0-or-later. See LICENSE.txt included with this package.

Reminds you to save after a set amount of time since your last save. The timer
resets whenever you load or save.

The MCM lets you adjust the interval, pause the timer while menus are open,
suppress reminders during combat or NPC dialogue, and choose between a
top-left notification or a pop-up dialog. Optional diagnostic logging is on
the Maintenance page.

The default reminder message follows Skyrim's configured language. English,
French, German, Italian, Spanish, Polish, Russian, Japanese, and Traditional
Chinese are included. The Reminder Display section lets you enter custom text,
preview it, or restore the translated default. Use {minutes} in custom text to
include the elapsed number, or omit it for a static message.

Requirements
- SKSE64
- Address Library for SKSE Plugins matching your Skyrim runtime
- SkyUI
- MCM Helper

Skyrim 1.7.104 requires SKSE 2.3.1 and Address Library v13 or later.

Install
- Install the contents of the Data folder with a mod manager.
- Activate SaveReminderSSE.esp.

Modlist authors
- Defaults ship in Data\MCM\Config\SaveReminderSSE\settings.ini.
- To ship custom defaults, copy SaveReminderSSE_defaults.ini (included) to MCM\Settings\SaveReminderSSE.ini in your own settings mod.
- Set sCustomReminderMessage under [Display] to ship custom text. Leave it empty to use the translated default.
