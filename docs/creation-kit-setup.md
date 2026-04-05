# Creation Kit Setup

## 1. Create Plugin
1. Open Creation Kit.
2. Load `Skyrim.esm` (and required masters in your load order).
3. Save a new plugin as `SaveReminderSSE.esp`.

## 2. Create Controller Quest
1. In Object Window, create a new Quest: `SRSSE_ControllerQuest`.
2. Check `Start Game Enabled`.
3. Attach script `SRSSE_ReminderController`.
4. Set script properties to match shipped defaults:
   - `ModEnabled = true`
   - `ThresholdMinutes = 15`
   - `PauseInMenus = true`
   - `PauseInCombat = true`
   - `MessageStyle = 0` (Notification)
   - `PlayerRef = PlayerRef` (optional; script auto-fills if unset)

> These property values are overridden at runtime by MCM Helper from `mcm/settings.ini`.
> The values set here are only used if MCM Helper is not installed.

## 3. Create MCM Quest
1. Create a second quest: `SRSSE_MCMQuest`.
2. Check `Start Game Enabled`.
3. Check `Run Once`.
4. Attach script `SRSSE_MCM`.
5. Fill `Controller` property by selecting `SRSSE_ControllerQuest`.
6. Open `Quest Aliases` and create a new alias named `PlayerAlias`.
7. Set the alias fill type to `Unique Actor` and choose `Player`.
8. Attach `SKI_PlayerLoadGameAlias` to that alias.

## 4. Script Deployment
1. Compile and place `SRSSE_Native.pex`, `SRSSE_ReminderController.pex`, and `SRSSE_MCM.pex` in `Data/Scripts/`.
2. Place native plugin DLL in `Data/SKSE/Plugins/`.

## 5. In-Game Validation
1. Start a new game (existing saves may not register the MCM quest correctly).
2. Open MCM and confirm options appear:
   - `Enable Reminders`
   - `Remind Every`
   - `Pause in Menus`
   - `Suppress During Combat`
   - `Use Pop-up Dialog`
3. Load an existing save and verify the timer begins from load time.
4. Set `Remind Every` to 5 minutes and verify a reminder fires after 5 minutes.
5. Save and verify the timer resets.

## Notes
- Treat `plugin/SaveReminderSSE.esp` as the canonical plugin. If Creation Kit saves into the live Skyrim `Data` folder, sync it back with:
  `powershell -ExecutionPolicy Bypass -File tools/build/sync-plugin-from-game.ps1`
- SkyUI MCM registration requires the MCM quest to have a player alias with `SKI_PlayerLoadGameAlias` attached.
- Always validate MCM registration on a new game when testing quest setup changes.
