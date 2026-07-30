Scriptname SRSSE_ReminderController extends Quest

Import MCM

bool Property ModEnabled = true Auto
int Property ThresholdMinutes = 15 Auto
bool Property PauseInMenus = true Auto
bool Property PauseInCombat = true Auto
bool Property SuppressDuringDialogue = true Auto
bool Property DebugLogging = false Auto

; 0 = notification, 1 = message box
int Property MessageStyle = 0 Auto

Actor Property PlayerRef Auto

String _settingsModName = "SaveReminderSSE"

int _lastAnnouncedMultiple = 0
float _pollIntervalSeconds = 5.0
float _lastObservedElapsedSeconds = -1.0
bool _reminderSuppressedActive = false
bool _dialogueSuppressedActive = false
int _dialogueClearPolls = 0

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
    ; Arm the next poll first so a runtime error below cannot stop reminders forever.
    StartPolling()
    LogDebug("Poll started")

    if (!ModEnabled)
        LogDebug("Reminders disabled; resetting reminder state")
        ResetReminderState()
        return
    endif

    if (ThresholdMinutes < 1)
        ThresholdMinutes = 1
    endif

    if (SRSSE_Native.HasSeenSaveThisSession())
        float elapsedSeconds = SRSSE_Native.GetSecondsSinceLastSave()
        if (elapsedSeconds < 0.0)
            LogDebug("Native timer returned no active save")
            return
        endif

        LogDebug("Timer raw=" + elapsedSeconds + "s, menuPaused=" + GetPausedSecondsForDisplay() + "s")
        UpdateReminderTimer(elapsedSeconds)
    else
        LogDebug("No save has been seen this session; resetting reminder state")
        ResetReminderState()
    endif
EndEvent

Function UpdateReminderTimer(float elapsedSeconds)
    if (_lastObservedElapsedSeconds >= 0.0 && elapsedSeconds < _lastObservedElapsedSeconds)
        LogDebug("Timer moved backwards; treating this as a reset")
        ResetReminderState()
    endif

    float effectiveElapsedSeconds = elapsedSeconds - GetPausedSecondsForDisplay()
    if (effectiveElapsedSeconds < 0.0)
        effectiveElapsedSeconds = 0.0
    endif

    if (ShouldSuppressReminder())
        LogDebug("Reminder display suppressed; leaving overdue interval pending")
        _reminderSuppressedActive = true
        _lastObservedElapsedSeconds = elapsedSeconds
        return
    endif

    if (_reminderSuppressedActive)
        LogDebug("Suppression ended; checking for an overdue reminder")
        HandleSuppressionReleaseReminder(effectiveElapsedSeconds, ThresholdMinutes)
        _reminderSuppressedActive = false
        _lastObservedElapsedSeconds = elapsedSeconds
        return
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

    float effectiveElapsedSeconds = elapsedSeconds - GetPausedSecondsForDisplay()
    if (effectiveElapsedSeconds < 0.0)
        return 0.0
    endif

    return effectiveElapsedSeconds
EndFunction

float Function GetPausedSecondsForDisplay()
    if (PauseInMenus)
        return SRSSE_Native.GetMenuPausedSeconds()
    endif

    return 0.0
EndFunction

Function HandleReminderInterval(float elapsedSeconds, int thresholdMinutes)
    int currentMultiple = Math.Floor(elapsedSeconds / (thresholdMinutes * 60.0))
    LogDebug("Interval check effective=" + elapsedSeconds + "s, multiple=" + currentMultiple + ", lastAnnounced=" + _lastAnnouncedMultiple)

    if (currentMultiple <= 0)
        _lastAnnouncedMultiple = 0
    elseif (currentMultiple > _lastAnnouncedMultiple)
        int elapsedMinutes = currentMultiple * thresholdMinutes
        ShowReminder(elapsedMinutes)
        _lastAnnouncedMultiple = currentMultiple
    endif
EndFunction

Function HandleSuppressionReleaseReminder(float elapsedSeconds, int thresholdMinutes)
    int thresholdSeconds = thresholdMinutes * 60
    int currentMultiple = Math.Floor(elapsedSeconds / thresholdSeconds)

    if (currentMultiple <= _lastAnnouncedMultiple)
        LogDebug("Suppression release: no overdue interval")
        return
    endif

    float nextReminderSeconds = ((currentMultiple + 1) * thresholdSeconds) - elapsedSeconds
    float skipWindowSeconds = thresholdSeconds * 0.25
    if (skipWindowSeconds > 120.0)
        skipWindowSeconds = 120.0
    endif

    if (nextReminderSeconds <= skipWindowSeconds)
        LogDebug("Suppression release: close to next boundary; waiting for normal interval reminder")
        _lastAnnouncedMultiple = currentMultiple
        return
    endif

    int elapsedMinutes = Math.Floor((elapsedSeconds + 30.0) / 60.0)
    if (elapsedMinutes < 1)
        elapsedMinutes = 1
    endif

    ShowReminder(elapsedMinutes)
    _lastAnnouncedMultiple = currentMultiple
EndFunction

bool Function ShouldSuppressReminder()
    ; Evaluate both so dialogue state remains accurate when combat overlaps dialogue.
    bool suppressForCombat = ShouldSuppressForCombat()
    bool suppressForDialogue = ShouldSuppressForDialogue()
    if (suppressForCombat || suppressForDialogue)
        return true
    endif

    return false
EndFunction

bool Function ShouldSuppressForCombat()
    if (PauseInCombat)
        if (PlayerRef == None)
            PlayerRef = Game.GetPlayer()
        endif

        if (PlayerRef != None && PlayerRef.IsInCombat())
            LogDebug("Suppression reason: combat")
            return true
        endif
    endif

    return false
EndFunction

bool Function ShouldSuppressForDialogue()
    if (!SuppressDuringDialogue)
        _dialogueSuppressedActive = false
        _dialogueClearPolls = 0
        return false
    endif

    if (SRSSE_Native.IsDialogueMenuOpen())
        _dialogueSuppressedActive = true
        _dialogueClearPolls = 0
        LogDebug("Suppression reason: Dialogue Menu is open")
        return true
    endif

    ; Dialogue Menu can briefly close between response states. Require it to
    ; remain closed for a full poll before releasing a pending reminder.
    if (_dialogueSuppressedActive && _dialogueClearPolls < 1)
        _dialogueClearPolls += 1
        LogDebug("Suppression reason: waiting for Dialogue Menu close debounce")
        return true
    endif

    _dialogueSuppressedActive = false
    _dialogueClearPolls = 0

    return false
EndFunction

Function ShowReminder(int elapsedMinutes)
    string unit = "minutes"
    if (elapsedMinutes == 1)
        unit = "minute"
    endif

    string msg = "It has been " + elapsedMinutes + " " + unit + " since your last save."
    LogDebug("Showing reminder: " + msg + " style=" + MessageStyle)
    if (MessageStyle == 1)
        Debug.MessageBox(msg)
    else
        Debug.Notification(msg)
    endif
EndFunction

Function ResetReminderState()
    _lastAnnouncedMultiple = 0
    _lastObservedElapsedSeconds = -1.0
    _reminderSuppressedActive = false
    _dialogueSuppressedActive = false
    _dialogueClearPolls = 0
EndFunction

Function ApplySettingsFromStore(bool resetReminderState)
    if (MCM.IsInstalled())
        ModEnabled = MCM.GetModSettingBool(_settingsModName, "bModEnabled:General")
        ThresholdMinutes = SnapReminderInterval(MCM.GetModSettingInt(_settingsModName, "iThresholdMinutes:General"))
        PauseInMenus = MCM.GetModSettingBool(_settingsModName, "bPauseInMenus:Behavior")
        PauseInCombat = MCM.GetModSettingBool(_settingsModName, "bSuppressDuringCombat:Behavior")
        SuppressDuringDialogue = MCM.GetModSettingBool(_settingsModName, "bSuppressDuringDialogue:Behavior")
        DebugLogging = MCM.GetModSettingBool(_settingsModName, "bDebugLogging:Diagnostics")

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

Function LogDebug(String aMessage)
    if (DebugLogging)
        SRSSE_Native.WriteDebugLog(aMessage)
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
