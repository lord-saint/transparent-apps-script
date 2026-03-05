; ============================================================
;  TransparencyManager.ahk  —  AHK v2
;  Per-app window transparency + Always On Top
;  with persistent INI storage — GlazeWM compatible
;
;  HOTKEYS:
;    Ctrl+Shift+LClick     → Open GUI to manage current app
;    Ctrl+Shift+RClick     → Toggle transparency ON/OFF for current app
;    Ctrl+Shift+Space      → Toggle Always On Top for current window
;    Ctrl+Shift+Numpad+    → Increase opacity  (+10)
;    Ctrl+Shift+Numpad-    → Decrease opacity  (-10)
;    Ctrl+Shift+Numpad*    → Reset to fully opaque (255)
;    Ctrl+Shift+Numpad/    → Toggle transparency ON/OFF for current app
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir

; ─── Constants ───────────────────────────────────────────────
CONFIG_FILE   := A_ScriptDir . "\TransparencySettings.ini"
INI_SECTION   := "Transparency"
PIN_SECTION   := "PinnedApps"
STEP          := 10
MIN_TRANS     := 20
MAX_TRANS     := 255
DEFAULT_TRANS := 220

; ─── State ───────────────────────────────────────────────────
global transparencyLevels := Map()   ; proc  → opacity value
global disabledApps       := Map()   ; proc  → true  (transparency off)
global pinnedWindows      := Map()   ; winID → proc  (always-on-top enforced)

; ─── Boot ────────────────────────────────────────────────────
LoadSettings()
SetTimer(ApplyTransparency, 600)
SetTimer(EnforcePinnedWindows, 300)   ; <-- fights GlazeWM re-focus resets
A_IconTip := "Transparency Manager"

; ============================================================
;  HOTKEYS
; ============================================================

; Ctrl+Shift+Left Click → Open GUI
^+LButton:: ShowAppGui()

; Ctrl+Shift+Right Click → Toggle transparency ON/OFF
^+RButton::
{
    proc := SafeGetProc()
    if (proc = "")
        return
    EnsureEntry(proc)
    ToggleApp(proc)
}

; Ctrl+Shift+Space → Toggle Always On Top
^+Space::
{
    try
    {
        if (!WinExist("A"))
            return
        cls := WinGetClass("A")
        if (cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd")
        {
            ShowTip("⛔ Cannot pin desktop / taskbar", 1600)
            return
        }
        wid  := WinGetID("A")
        proc := WinGetProcessName("A")
        TogglePin(wid, proc)
    }
    catch Error as e
        ShowTip("⛔ Could not pin this window", 1600)
}

; Ctrl+Shift+Numpad+ → More opaque
^+NumpadAdd::
{
    proc := SafeGetProc()
    if (proc = "")
        return
    EnsureEntry(proc)
    if (disabledApps.Has(proc))
        disabledApps.Delete(proc)
    newVal := Min(transparencyLevels[proc] + STEP, MAX_TRANS)
    SetAppTransparency(proc, newVal)
    ShowTip("🔆 Opacity: " . Round((newVal / 255) * 100) . "% (" . newVal . ")", 900)
}

; Ctrl+Shift+Numpad- → More transparent
^+NumpadSub::
{
    proc := SafeGetProc()
    if (proc = "")
        return
    EnsureEntry(proc)
    if (disabledApps.Has(proc))
        disabledApps.Delete(proc)
    newVal := Max(transparencyLevels[proc] - STEP, MIN_TRANS)
    SetAppTransparency(proc, newVal)
    ShowTip("🔅 Opacity: " . Round((newVal / 255) * 100) . "% (" . newVal . ")", 900)
}

; Ctrl+Shift+Numpad* → Reset fully opaque
^+NumpadMult::
{
    proc := SafeGetProc()
    if (proc = "")
        return
    SetAppTransparency(proc, MAX_TRANS)
    if (disabledApps.Has(proc))
        disabledApps.Delete(proc)
    ShowTip("✅ Reset: fully opaque", 1200)
}

; Ctrl+Shift+Numpad/ → Toggle transparency ON/OFF
^+NumpadDiv::
{
    proc := SafeGetProc()
    if (proc = "")
        return
    EnsureEntry(proc)
    ToggleApp(proc)
}

; ============================================================
;  ALWAYS ON TOP — CORE
; ============================================================

; Toggle pin for a specific window ID
TogglePin(wid, proc)
{
    global pinnedWindows

    if (pinnedWindows.Has(wid))
    {
        ; Unpin
        pinnedWindows.Delete(wid)
        try WinSetAlwaysOnTop(0, "ahk_id " . wid)
        SavePinnedApps()
        ShowTip("📌 Unpinned  —  " . proc, 1600)
    }
    else
    {
        ; Pin and track by window ID
        pinnedWindows[wid] := proc
        try WinSetAlwaysOnTop(1, "ahk_id " . wid)
        SavePinnedApps()
        ShowTip("📌 Pinned On Top  —  " . proc, 1600)
    }
}

; Timer: re-enforce topmost on all pinned windows every 300ms
; This is what defeats GlazeWM stripping the flag on focus
EnforcePinnedWindows()
{
    global pinnedWindows
    deadIDs := []

    for wid, proc in pinnedWindows
    {
        if (!WinExist("ahk_id " . wid))
        {
            ; Window was closed — clean up
            deadIDs.Push(wid)
            continue
        }

        ; Re-apply topmost if GlazeWM stripped it
        try
        {
            exStyle := WinGetExStyle("ahk_id " . wid)
            if (!(exStyle & 0x8))
                WinSetAlwaysOnTop(1, "ahk_id " . wid)
        }
    }

    ; Remove closed windows from map
    for , wid in deadIDs
        pinnedWindows.Delete(wid)
}

; Check if a given window ID is currently pinned
IsWinPinned(wid)
{
    global pinnedWindows
    return pinnedWindows.Has(wid)
}

; ============================================================
;  TRANSPARENCY — CORE
; ============================================================

ApplyTransparency()
{
    global transparencyLevels, disabledApps
    for proc, level in transparencyLevels
    {
        effectiveLevel := disabledApps.Has(proc) ? MAX_TRANS : level
        wins := WinGetList("ahk_exe " . proc)
        for , wid in wins
            SafeSetTrans(wid, effectiveLevel)
    }
}

SetAppTransparency(proc, value)
{
    global transparencyLevels
    transparencyLevels[proc] := value
    SaveSetting(proc, value)
    wins := WinGetList("ahk_exe " . proc)
    for , wid in wins
        SafeSetTrans(wid, value)
}

ToggleApp(proc)
{
    global disabledApps, transparencyLevels
    if (disabledApps.Has(proc))
    {
        disabledApps.Delete(proc)
        wins := WinGetList("ahk_exe " . proc)
        for , wid in wins
            SafeSetTrans(wid, transparencyLevels[proc])
        ShowTip("✅ Transparency ON`n" . proc . "`nOpacity: " . Round((transparencyLevels[proc] / 255) * 100) . "%", 1600)
    }
    else
    {
        disabledApps[proc] := true
        wins := WinGetList("ahk_exe " . proc)
        for , wid in wins
            SafeSetTrans(wid, MAX_TRANS)
        ShowTip("❌ Transparency OFF`n" . proc, 1600)
    }
}

SafeSetTrans(wid, level)
{
    try
    {
        if (!WinExist("ahk_id " . wid))
            return
        cls := WinGetClass("ahk_id " . wid)
        if (cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd"
         || cls = "DV2ControlHost" || cls = "MsgrIMEWindowClass")
            return
        WinSetTransparent(level, "ahk_id " . wid)
    }
}

; ============================================================
;  HELPERS
; ============================================================

SafeGetProc()
{
    try
    {
        if (!WinExist("A"))
            return ""
        cls := WinGetClass("A")
        if (cls = "Progman" || cls = "WorkerW" || cls = "Shell_TrayWnd")
        {
            ShowTip("⛔ Cannot apply to desktop / taskbar", 1800)
            return ""
        }
        return WinGetProcessName("A")
    }
    catch
        return ""
}

EnsureEntry(proc)
{
    global transparencyLevels
    if (!transparencyLevels.Has(proc))
    {
        transparencyLevels[proc] := DEFAULT_TRANS
        SaveSetting(proc, DEFAULT_TRANS)
    }
}

ShowTip(text, ms := 1200)
{
    ToolTip(text)
    SetTimer(() => ToolTip(), -ms)
}

; ============================================================
;  INI PERSISTENCE
; ============================================================

LoadSettings()
{
    global transparencyLevels, CONFIG_FILE, INI_SECTION, MIN_TRANS, MAX_TRANS, DEFAULT_TRANS
    if (!FileExist(CONFIG_FILE))
    {
        FileAppend("[" . INI_SECTION . "]`n", CONFIG_FILE)
        return
    }
    content   := FileRead(CONFIG_FILE)
    inSection := false
    for , line in StrSplit(content, "`n")
    {
        line := Trim(line)
        if (line = "")
            continue
        if (line = "[" . INI_SECTION . "]")
        {
            inSection := true
            continue
        }
        if (SubStr(line, 1, 1) = "[")
        {
            inSection := false
            continue
        }
        if (!inSection)
            continue
        pos := InStr(line, "=")
        if (pos < 2)
            continue
        appName := Trim(SubStr(line, 1, pos - 1))
        rawVal  := Trim(SubStr(line, pos + 1))
        if (!IsInteger(rawVal))
            continue
        val := Integer(rawVal)
        if (val < MIN_TRANS || val > MAX_TRANS)
            val := DEFAULT_TRANS
        transparencyLevels[appName] := val
    }
}

SaveSetting(appName, value)
{
    global CONFIG_FILE, INI_SECTION
    IniWrite(value, CONFIG_FILE, INI_SECTION, appName)
}

; Save pinned window process names to INI so user knows what was pinned
; (Window IDs change every session so we just log proc names as reference)
SavePinnedApps()
{
    global pinnedWindows, CONFIG_FILE, PIN_SECTION
    try IniDelete(CONFIG_FILE, PIN_SECTION)
    for wid, proc in pinnedWindows
        IniWrite(proc, CONFIG_FILE, PIN_SECTION, wid)
}

DeleteSetting(appName)
{
    global CONFIG_FILE, INI_SECTION
    try IniDelete(CONFIG_FILE, INI_SECTION, appName)
    global transparencyLevels, disabledApps
    if (transparencyLevels.Has(appName))
        transparencyLevels.Delete(appName)
    if (disabledApps.Has(appName))
        disabledApps.Delete(appName)
}

; ============================================================
;  GUI  (Ctrl+Shift+Left Click)
; ============================================================

ShowAppGui()
{
    global transparencyLevels, disabledApps, pinnedWindows

    proc := SafeGetProc()
    if (proc = "")
        return
    EnsureEntry(proc)

    isOff    := disabledApps.Has(proc)
    curLevel := transparencyLevels[proc]
    curPct   := Round((curLevel / 255) * 100)

    ; Get current window ID for pin status
    wid      := WinGetID("A")
    isPinned := IsWinPinned(wid)

    g := Gui("+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox", "  🪟 Transparency Manager")
    g.BackColor := "1E1E2E"
    g.SetFont("s9 cF0F0F0", "Segoe UI")
    g.MarginX := 20
    g.MarginY := 16

    ; ── Header ───────────────────────────────────────────────
    g.SetFont("s8 cA0A0C0", "Segoe UI")
    g.AddText("w300", "ACTIVE APPLICATION")

    g.SetFont("s11 Bold cFFFFFF", "Segoe UI")
    g.AddText("w300 y+4", proc)

    ; Status badges
    g.SetFont("s9 c" . (isOff ? "FF6B6B" : "69FF94"), "Segoe UI")
    g.AddText("w144 y+4", isOff ? "⬤  Transparency OFF" : "⬤  Transparency ON")

    g.SetFont("s9 c" . (isPinned ? "FFD700" : "606080"), "Segoe UI")
    g.AddText("w144 yp Right", isPinned ? "📌 Pinned ON TOP" : "📌 Not Pinned")

    ; ── Divider ──────────────────────────────────────────────
    g.SetFont("s8 c404060", "Segoe UI")
    g.AddText("w300 y+12", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    ; ── Slider ───────────────────────────────────────────────
    g.SetFont("s9 cA0A0C0", "Segoe UI")
    g.AddText("w150 y+10", "OPACITY LEVEL")

    g.SetFont("s11 Bold cFFFFFF", "Segoe UI")
    lblPct := g.AddText("w140 yp Right", curPct . "%")

    g.SetFont("s9 cF0F0F0", "Segoe UI")
    slider := g.AddSlider("w300 y+6 Range20-255 TickInterval10 Page10 AltSubmit Background1E1E2E", curLevel)

    g.SetFont("s8 c606080", "Segoe UI")
    g.AddText("w150 y+4", "More Transparent")
    g.AddText("w140 yp Right", "Fully Opaque")

    slider.OnEvent("Change", (*) => UpdateLabel())
    UpdateLabel()
    {
        v   := slider.Value
        pct := Round((v / 255) * 100)
        lblPct.Value := pct . "%"
    }

    ; ── Quick presets ────────────────────────────────────────
    g.SetFont("s8 cA0A0C0", "Segoe UI")
    g.AddText("w300 y+14", "QUICK PRESETS")

    g.SetFont("s9 cFFFFFF", "Segoe UI")
    btn25  := g.AddButton("w66 y+6 Background2A2A3E", "25%")
    btn50  := g.AddButton("w66 x+6 yp Background2A2A3E", "50%")
    btn75  := g.AddButton("w66 x+6 yp Background2A2A3E", "75%")
    btn100 := g.AddButton("w66 x+6 yp Background2A2A3E", "100%")

    btn25.OnEvent("Click",  (*) => (slider.Value := 64,  UpdateLabel()))
    btn50.OnEvent("Click",  (*) => (slider.Value := 128, UpdateLabel()))
    btn75.OnEvent("Click",  (*) => (slider.Value := 191, UpdateLabel()))
    btn100.OnEvent("Click", (*) => (slider.Value := 255, UpdateLabel()))

    ; ── Divider ──────────────────────────────────────────────
    g.SetFont("s8 c404060", "Segoe UI")
    g.AddText("w300 y+14", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    ; ── Action buttons ───────────────────────────────────────
    g.SetFont("s10 Bold cFFFFFF", "Segoe UI")
    btnApply  := g.AddButton("w300 y+10 h34 Background0078D4", "✔  Apply Opacity")

    g.SetFont("s9 cFFFFFF", "Segoe UI")
    btnToggle := g.AddButton("w144 y+8 h30 Background" . (isOff ? "1A6B3A" : "6B1A1A"), isOff ? "✅  Enable Trans." : "❌  Disable Trans.")
    btnPin    := g.AddButton("w144 x+12 yp h30 Background" . (isPinned ? "5A4A00" : "1A3A2A"), isPinned ? "📌 Unpin Top" : "📌 Pin On Top")
    btnRemove := g.AddButton("w300 y+8 h28 Background3A2A1A", "🗑  Remove App from Tracking")

    ; ── Hotkey hint ──────────────────────────────────────────
    g.SetFont("s8 c505070", "Segoe UI")
    g.AddText("w300 y+14 Center", "Numpad +/−  adjust  |  *  reset  |  RClick  toggle  |  Space  pin")

    ; ── GlazeWM notice ───────────────────────────────────────
    g.SetFont("s8 cFFD700", "Segoe UI")
    g.AddText("w300 y+6 Center", "⚡ GlazeWM mode: pin is actively re-enforced every 300ms")

    ; ── Events ───────────────────────────────────────────────
    btnApply.OnEvent("Click", ApplyClick)
    btnToggle.OnEvent("Click", ToggleClick)
    btnPin.OnEvent("Click", PinClick)
    btnRemove.OnEvent("Click", RemoveClick)
    g.OnEvent("Close", (*) => g.Destroy())

    ApplyClick(*)
    {
        newVal := slider.Value
        if (disabledApps.Has(proc))
            disabledApps.Delete(proc)
        SetAppTransparency(proc, newVal)
        ShowTip("✅ Applied: " . proc . "  →  " . Round((newVal / 255) * 100) . "%", 1400)
        g.Destroy()
    }

    ToggleClick(*)
    {
        ToggleApp(proc)
        g.Destroy()
    }

    PinClick(*)
    {
        TogglePin(wid, proc)
        g.Destroy()
    }

    RemoveClick(*)
    {
        DeleteSetting(proc)
        wins := WinGetList("ahk_exe " . proc)
        for , deadWid in wins
        {
            SafeSetTrans(deadWid, MAX_TRANS)
            if (pinnedWindows.Has(deadWid))
                pinnedWindows.Delete(deadWid)
        }
        ShowTip("🗑 Removed: " . proc . "  →  fully opaque", 1500)
        g.Destroy()
    }

    g.Show("AutoSize Center")
}
