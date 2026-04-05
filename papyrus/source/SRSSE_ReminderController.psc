Scriptname SRSSE_ReminderController extends Quest

Import MCM

bool Property ModEnabled = true Auto
int Property ThresholdMinutes = 15 Auto
bool Property PauseInMenus = true Auto
bool Property PauseInCombat = true Auto

; 0 = notification, 1 = message box
int Property MessageStyle = 0 Auto

Actor Property PlayerRef Auto

String _settingsModName = "SaveReminderSSE"

int _lastAnnouncedMultiple = 0
float _pollIntervalSeconds = 5.0
float _lastObservedElapsedSeconds = -1.0
bool _combatSuppressedActive = false

Event OnInit()
    if (PlayerRef == None)
        PlayerRef = Game.GetPlayer()
    endif
    ApplySettingsFromStore(false)
    StartPolling()
EndEvent

Event OnPlayerLoadGame()
    if (PlayerRef == None)
        PlayerRef = Game.GetPlayer()
    endif
    ApplySettingsFromStore(true)
    StartPolling()
EndEvent

Function StartPolling()
    UnregisterForUpdate()
    RegisterForSingleUpdate(_pollIntervalSeconds)
EndFunction

Event OnUpdate()
    if (!ModEnabled)
        ResetReminderState()
        StartPolling()
        return
    endif

    if (ThresholdMinutes < 1)
        ThresholdMinutes = 1
    endif

    if (SRSSE_Native.HasSeenSaveThisSession())
        float elapsedSeconds = SRSSE_Native.GetSecondsSinceLastSave()
        if (elapsedSeconds < 0.0)
            StartPolling()
            return
        endif

        UpdateReminderTimer(elapsedSeconds)
    else
        ResetReminderState()
    endif

    StartPolling()
EndEvent

Function UpdateReminderTimer(float elapsedSeconds)
    if (_lastObservedElapsedSeconds >= 0.0 && elapsedSeconds < _lastObservedElapsedSeconds)
        ResetReminderState()
    endif

    float effectiveElapsedSeconds = elapsedSeconds - GetPausedSecondsForDisplay(elapsedSeconds)
    if (effectiveElapsedSeconds < 0.0)
        effectiveElapsedSeconds = 0.0
    endif

    if (ShouldSuppressForCombat())
        _combatSuppressedActive = true
        _lastObservedElapsedSeconds = elapsedSeconds
        return
    endif

    if (_combatSuppressedActive)
        HandleCombatReleaseReminder(effectiveElapsedSeconds, ThresholdMinutes)
        _combatSuppressedActive = false
    endif

    HandleReminderInterval(effectiveElapsedSeconds, ThresholdMinutes)
    _lastObservedElapsedSeconds = elapsedSeconds
EndFunction

float Function GetEffectiveElapsedSeconds()
    if (!SRSSE_Native.HasSeenSaveThisSession())
        return -1.0
    endif

    float elapsedSeconds = SRSSE_Native.GetSecondsSinceLastSave()
    if (elapsedSeconds < 0.0)
        return -1.0
    endif

    if (_lastObservedElapsedSeconds >= 0.0 && elapsedSeconds < _lastObservedElapsedSeconds)
        return 0.0
    endif

    float effectiveElapsedSeconds = elapsedSeconds - GetPausedSecondsForDisplay(elapsedSeconds)
    if (effectiveElapsedSeconds < 0.0)
        return 0.0
    endif

    return effectiveElapsedSeconds
EndFunction

float Function GetPausedSecondsForDisplay(float elapsedSeconds)
    if (PauseInMenus)
        return SRSSE_Native.GetMenuPausedSeconds()
    endif

    return 0.0
EndFunction

Function HandleReminderInterval(float elapsedSeconds, int thresholdMinutes)
    int currentMultiple = Math.Floor(elapsedSeconds / (thresholdMinutes * 60.0))

    if (currentMultiple <= 0)
        _lastAnnouncedMultiple = 0
    elseif (currentMultiple > _lastAnnouncedMultiple)
        int elapsedMinutes = currentMultiple * thresholdMinutes
        ShowReminder(elapsedMinutes)
        _lastAnnouncedMultiple = currentMultiple
    endif
EndFunction

Function HandleCombatReleaseReminder(float elapsedSeconds, int thresholdMinutes)
    int thresholdSeconds = thresholdMinutes * 60
    int currentMultiple = Math.Floor(elapsedSeconds / thresholdSeconds)

    if (currentMultiple <= _lastAnnouncedMultiple)
        return
    endif

    float nextReminderSeconds = ((currentMultiple + 1) * thresholdSeconds) - elapsedSeconds
    float skipWindowSeconds = thresholdSeconds * 0.25
    if (skipWindowSeconds > 120.0)
        skipWindowSeconds = 120.0
    endif

    if (nextReminderSeconds <= skipWindowSeconds)
        return
    endif

    int elapsedMinutes = Math.Floor((elapsedSeconds + 30.0) / 60.0)
    if (elapsedMinutes < 1)
        elapsedMinutes = 1
    endif

    ShowReminder(elapsedMinutes)
    _lastAnnouncedMultiple = currentMultiple
EndFunction

bool Function ShouldSuppressForCombat()
    if (PauseInCombat)
        if (PlayerRef == None)
            PlayerRef = Game.GetPlayer()
        endif

        if (PlayerRef != None && PlayerRef.IsInCombat())
            return true
        endif
    endif

    return false
EndFunction

Function ShowReminder(int elapsedMinutes)
    string unit = "minutes"
    if (elapsedMinutes == 1)
        unit = "minute"
    endif

    string msg = "It has been " + elapsedMinutes + " " + unit + " since your last save."
    if (MessageStyle == 1)
        Debug.MessageBox(msg)
    else
        Debug.Notification(msg)
    endif
EndFunction

Function ResetReminderState()
    _lastAnnouncedMultiple = 0
    _lastObservedElapsedSeconds = -1.0
    _combatSuppressedActive = false
EndFunction

Function ApplySettingsFromStore(bool resetReminderState)
    if (MCM.IsInstalled())
        ModEnabled = MCM.GetModSettingBool(_settingsModName, "bModEnabled:General")
        ThresholdMinutes = SnapReminderInterval(MCM.GetModSettingInt(_settingsModName, "iThresholdMinutes:General"))
        PauseInMenus = MCM.GetModSettingBool(_settingsModName, "bPauseInMenus:Behavior")
        PauseInCombat = MCM.GetModSettingBool(_settingsModName, "bSuppressDuringCombat:Behavior")

        if (MCM.GetModSettingBool(_settingsModName, "bUsePopupDialog:Display"))
            MessageStyle = 1
        else
            MessageStyle = 0
        endif
    else
        ThresholdMinutes = SnapReminderInterval(ThresholdMinutes)
    endif

    if (resetReminderState)
        ResetReminderState()
    endif
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
