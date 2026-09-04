Scriptname SRSSE_MCM extends SKI_ConfigBase

Import MCM

SRSSE_ReminderController Property Controller Auto

String _settingsModName = "SaveReminderSSE"

int _oidEnabled = -1
int _oidThreshold = -1
int _oidPauseMenus = -1
int _oidPauseCombat = -1
int _oidSuppressDialogue = -1
int _oidMessageStyle = -1
int _oidCustomMessage = -1
int _oidPreviewMessage = -1
int _oidRestoreMessage = -1
int _oidTimeSinceLastSave = -1
int _oidDebugLogging = -1

int Function GetVersion()
    return 6
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
    Controller.StartPolling()
EndEvent

Event OnGameReload()
    Parent.OnGameReload()
    LoadSettings()
    Controller.StartPolling()
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
        _oidSuppressDialogue = AddToggleOption("Suppress During Dialogue", Controller.SuppressDuringDialogue)

        AddHeaderOption("Reminder Display")
        _oidMessageStyle = AddToggleOption("Use Pop-up Dialog", Controller.MessageStyle == 1)
        _oidCustomMessage = AddInputOption("Custom Reminder Message", FormatCustomMessageSetting())
        _oidPreviewMessage = AddTextOption("Preview Reminder", "")
        _oidRestoreMessage = AddTextOption("Restore Default Message", "")
        return
    endif

    if (aPage == "Maintenance")
        AddHeaderOption("Diagnostics")
        _oidDebugLogging = AddToggleOption("Enable Debug Logging", Controller.DebugLogging)
        AddHeaderOption("Settings")
        ; Keep this as a literal. Ordinary script variables are persisted in saves,
        ; so an upgraded save would otherwise continue displaying its old version.
        AddTextOption("Version", "0.2.3", OPTION_FLAG_DISABLED)
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

    if (aOption == _oidSuppressDialogue)
        SetInfoText("Do not show reminders during conversations. The timer keeps running and a reminder can appear after dialogue ends if you are overdue.")
        return
    endif

    if (aOption == _oidMessageStyle)
        SetInfoText("Turn this on to use a pop-up dialog that must be dismissed. Turn it off to use a lighter top-left notification.")
        return
    endif

    if (aOption == _oidCustomMessage)
        SetInfoText("Enter any reminder text. Use {minutes} where the elapsed number should appear. The placeholder is optional.")
        return
    endif

    if (aOption == _oidPreviewMessage)
        SetInfoText("Show the current reminder message without changing the timer.")
        return
    endif

    if (aOption == _oidRestoreMessage)
        SetInfoText("Clear the custom message and use the translated default for the current game language.")
        return
    endif

    if (aOption == _oidDebugLogging)
        SetInfoText("Write detailed polling, suppression, and reminder decisions to the SaveReminderSSE SKSE log. Leave off during normal play.")
        return
    endif
EndEvent

Event OnOptionSelect(int aOption)
    if (aOption == _oidDebugLogging)
        bool newDebugLogging = !Controller.DebugLogging
        MCM.SetModSettingBool(_settingsModName, "bDebugLogging:Diagnostics", newDebugLogging)
        LoadSettings(false)
        SetToggleOptionValue(aOption, newDebugLogging)
        Controller.LogDebug("Debug logging enabled from MCM")
        return
    endif

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

    if (aOption == _oidSuppressDialogue)
        bool newSuppressDialogue = !Controller.SuppressDuringDialogue
        MCM.SetModSettingBool(_settingsModName, "bSuppressDuringDialogue:Behavior", newSuppressDialogue)
        LoadSettings(false)
        SetToggleOptionValue(aOption, newSuppressDialogue)
        return
    endif

    if (aOption == _oidMessageStyle)
        bool useDialog = (Controller.MessageStyle != 1)
        MCM.SetModSettingBool(_settingsModName, "bUsePopupDialog:Display", useDialog)
        LoadSettings(false)
        SetToggleOptionValue(aOption, useDialog)
        return
    endif

    if (aOption == _oidPreviewMessage)
        Controller.PreviewReminder(Controller.ThresholdMinutes)
        return
    endif

    if (aOption == _oidRestoreMessage)
        MCM.SetModSettingString(_settingsModName, "sCustomReminderMessage:Display", "")
        LoadSettings(false)
        SetInputOptionValue(_oidCustomMessage, "Default")
        return
    endif
EndEvent

Event OnOptionInputOpen(int aOption)
    if (aOption == _oidCustomMessage)
        SetInputDialogStartText(Controller.CustomReminderMessage)
    endif
EndEvent

Event OnOptionInputAccept(int aOption, String aInput)
    if (aOption == _oidCustomMessage)
        MCM.SetModSettingString(_settingsModName, "sCustomReminderMessage:Display", aInput)
        LoadSettings(false)
        SetInputOptionValue(aOption, FormatCustomMessageSetting())
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

Function LoadSettings(bool resetReminderState = false)
    if (Controller == None)
        return
    endif

    Controller.ApplySettingsFromStore(resetReminderState)
EndFunction

String Function FormatCustomMessageSetting()
    if (Controller == None || Controller.CustomReminderMessage == "")
        return "Default"
    endif

    return Controller.CustomReminderMessage
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
