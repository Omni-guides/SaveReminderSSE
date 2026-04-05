Scriptname SRSSE_MCM extends SKI_ConfigBase

Import MCM

SRSSE_ReminderController Property Controller Auto

String _settingsModName = "SaveReminderSSE"
String _version = "0.1.3"

int _oidEnabled = -1
int _oidThreshold = -1
int _oidPauseMenus = -1
int _oidPauseCombat = -1
int _oidMessageStyle = -1
int _oidTimeSinceLastSave = -1
int _oidResetDefaults = -1

int Function GetVersion()
    return 3
EndFunction

Event OnConfigInit()
    ModName = _settingsModName

    Pages = new String[2]
    Pages[0] = "General"
    Pages[1] = "Maintenance"

    LoadSettings()
EndEvent

Event OnVersionUpdate(int aVersion)
    Parent.OnVersionUpdate(aVersion)
    LoadSettings()
EndEvent

Event OnGameReload()
    Parent.OnGameReload()
    LoadSettings()
EndEvent

Event OnPageReset(String aPage)
    if (aPage == "")
        LoadCustomContent("skyui/res/mcm_logo.dds", 258, 95)
        return
    endif

    UnloadCustomContent()
    SetCursorFillMode(TOP_TO_BOTTOM)

    if (aPage == "General")
        AddHeaderOption("Current Status")
        _oidTimeSinceLastSave = AddTextOption("Time Since Last Save", FormatElapsedTime())

        AddHeaderOption("Reminder Timing")
        _oidEnabled = AddToggleOption("Enable Reminders", Controller.ModEnabled)
        _oidThreshold = AddSliderOption("Remind Every", Controller.ThresholdMinutes, "{0} MINUTES")

        AddHeaderOption("Reminder Behavior")
        _oidPauseMenus = AddToggleOption("Pause in Menus", Controller.PauseInMenus)
        _oidPauseCombat = AddToggleOption("Suppress During Combat", Controller.PauseInCombat)

        AddHeaderOption("Reminder Display")
        _oidMessageStyle = AddToggleOption("Use Pop-up Dialog", Controller.MessageStyle == 1)
        return
    endif

    if (aPage == "Maintenance")
        AddHeaderOption("Settings")
        _oidResetDefaults = AddTextOption("Reset To Defaults", "")
        AddTextOption("Version", _version, OPTION_FLAG_DISABLED)
    endif
EndEvent

Event OnOptionHighlight(int aOption)
    if (aOption == _oidTimeSinceLastSave)
        SetInfoText("Shows the current effective reminder timer, including menu pause behavior.")
        return
    endif

    if (aOption == _oidEnabled)
        SetInfoText("Turn save reminders on or off.")
        return
    endif

    if (aOption == _oidThreshold)
        SetInfoText("Show a reminder after this many minutes have passed since your last load or save. The timer resets every time you load or save.")
        return
    endif

    if (aOption == _oidPauseMenus)
        SetInfoText("Pause the reminder timer while menu screens are open.")
        return
    endif

    if (aOption == _oidPauseCombat)
        SetInfoText("Do not show reminders while the player is in combat. The timer keeps running and a reminder can appear after combat ends if you are overdue.")
        return
    endif

    if (aOption == _oidMessageStyle)
        SetInfoText("Turn this on to use a pop-up dialog that must be dismissed. Turn it off to use a lighter top-left notification.")
        return
    endif

    if (aOption == _oidResetDefaults)
        SetInfoText("Restore the shipped defaults from this mod's MCM Helper settings store.")
        return
    endif
EndEvent

Event OnOptionSelect(int aOption)
    if (aOption == _oidEnabled)
        bool newEnabled = !Controller.ModEnabled
        MCM.SetModSettingBool(_settingsModName, "bModEnabled:General", newEnabled)
        LoadSettings(true)
        SetToggleOptionValue(aOption, newEnabled)
        return
    endif

    if (aOption == _oidPauseMenus)
        bool newPauseMenus = !Controller.PauseInMenus
        MCM.SetModSettingBool(_settingsModName, "bPauseInMenus:Behavior", newPauseMenus)
        LoadSettings(false)
        SetToggleOptionValue(aOption, newPauseMenus)
        SetTextOptionValue(_oidTimeSinceLastSave, FormatElapsedTime())
        return
    endif

    if (aOption == _oidPauseCombat)
        bool newPauseCombat = !Controller.PauseInCombat
        MCM.SetModSettingBool(_settingsModName, "bSuppressDuringCombat:Behavior", newPauseCombat)
        LoadSettings(false)
        SetToggleOptionValue(aOption, newPauseCombat)
        return
    endif

    if (aOption == _oidMessageStyle)
        bool useDialog = (Controller.MessageStyle != 1)
        MCM.SetModSettingBool(_settingsModName, "bUsePopupDialog:Display", useDialog)
        LoadSettings(false)
        SetToggleOptionValue(aOption, useDialog)
        return
    endif

    if (aOption == _oidResetDefaults)
        Default()
        ForcePageReset()
        return
    endif
EndEvent

Event OnOptionSliderOpen(int aOption)
    if (aOption == _oidThreshold)
        SetSliderDialogStartValue(Controller.ThresholdMinutes)
        SetSliderDialogDefaultValue(15.0)
        SetSliderDialogRange(5.0, 90.0)
        SetSliderDialogInterval(5.0)
        return
    endif
EndEvent

Event OnOptionSliderAccept(int aOption, float aValue)
    if (aOption == _oidThreshold)
        int newValue = SnapReminderInterval(aValue as int)
        MCM.SetModSettingInt(_settingsModName, "iThresholdMinutes:General", newValue)
        LoadSettings(true)
        SetSliderOptionValue(aOption, newValue, "{0} MINUTES")
        return
    endif
EndEvent

Function Default()
    MCM.SetModSettingBool(_settingsModName, "bModEnabled:General", true)
    MCM.SetModSettingInt(_settingsModName, "iThresholdMinutes:General", 15)
    MCM.SetModSettingBool(_settingsModName, "bPauseInMenus:Behavior", true)
    MCM.SetModSettingBool(_settingsModName, "bSuppressDuringCombat:Behavior", true)
    MCM.SetModSettingBool(_settingsModName, "bUsePopupDialog:Display", false)
    LoadSettings(true)
EndFunction

Function LoadSettings(bool resetReminderState = false)
    if (Controller == None)
        return
    endif

    Controller.ApplySettingsFromStore(resetReminderState)
EndFunction

String Function FormatElapsedTime()
    if (Controller == None)
        return "Unavailable"
    endif

    float elapsedSeconds = Controller.GetEffectiveElapsedSeconds()
    if (elapsedSeconds < 0.0)
        return "No save loaded"
    endif

    int totalSeconds = Math.Floor(elapsedSeconds)
    int minutes = totalSeconds / 60
    int seconds = totalSeconds - (minutes * 60)
    String secondsText = seconds as String
    if (seconds < 10)
        secondsText = "0" + secondsText
    endif

    return minutes + "m " + secondsText + "s"
EndFunction

int Function SnapReminderInterval(int aMinutes)
    if (aMinutes <= 5)
        return 5
    endif

    if (aMinutes >= 90)
        return 90
    endif

    return ((aMinutes + 2) / 5) * 5
EndFunction
