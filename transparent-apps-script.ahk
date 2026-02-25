; Initialize the auto-check flag and start the timer
isAutoCheckEnabled := true
transparencyLevels := Map()  ; Store transparency level per app

SetTimer CheckApps, 1000  ; Check every 1 second

; Function to check and make apps transparent
CheckApps()
{
    global isAutoCheckEnabled, transparencyLevels
    
    ; Only run if auto-check is enabled
    if (isAutoCheckEnabled)
    {
        ; Apply transparency to all apps in the map
        for procName, transparency in transparencyLevels
        {
            if WinExist("ahk_exe " procName)
                WinSetTransparent(transparency, "ahk_exe " procName)
        }
    }
}

; Hotkey: Ctrl+Shift+Right Click to toggle transparency for current app
^+RButton::
{
    global isAutoCheckEnabled, transparencyLevels
    
    procName := WinGetProcessName("A")
    
    ; Add app to map if not already there
    if (!transparencyLevels.Has(procName))
        transparencyLevels[procName] := 220
    
    ; Toggle the auto-check on/off for this app
    isAutoCheckEnabled := !isAutoCheckEnabled
    
    ; If disabling, make the window fully opaque
    if (!isAutoCheckEnabled)
    {
        WinSetTransparent(255, "A")
    }
}

; Hotkey: Ctrl+Shift+Plus to increase transparency
^+NumpadAdd::
{
    global transparencyLevels
    
    procName := WinGetProcessName("A")
    
    ; Add app to map if not already there
    if (!transparencyLevels.Has(procName))
        transparencyLevels[procName] := 220
    
    ; Increase transparency by 10
    if (transparencyLevels[procName] < 255)
    {
        transparencyLevels[procName] += 10
        if (transparencyLevels[procName] > 255)
            transparencyLevels[procName] := 255
        
        WinSetTransparent(transparencyLevels[procName], "A")
    }
}

; Hotkey: Ctrl+Shift+Minus to decrease transparency
^+NumpadSub::
{
    global transparencyLevels
    
    procName := WinGetProcessName("A")
    
    ; Add app to map if not already there
    if (!transparencyLevels.Has(procName))
        transparencyLevels[procName] := 220
    
    ; Decrease transparency by 10
    if (transparencyLevels[procName] > 0)
    {
        transparencyLevels[procName] -= 10
        if (transparencyLevels[procName] < 0)
            transparencyLevels[procName] := 0
        
        WinSetTransparent(transparencyLevels[procName], "A")
    }
}

alwaysOnTopWindows := Map()

^+Space::
{
    global alwaysOnTopWindows
 
    winHandle := WinExist("A")
    
    if (winHandle = 0)
        return
    
    if (alwaysOnTopWindows.Has(winHandle))
    {
        WinSetAlwaysOnTop(0, winHandle)
        alwaysOnTopWindows.Delete(winHandle)
        ToolTip("Always-on-top: OFF")
    }
    else
    {
        WinSetAlwaysOnTop(1, winHandle)
        alwaysOnTopWindows[winHandle] := true
        ToolTip("Always-on-top: ON")
    }   
    
    SetTimer(() => ToolTip(), 1500)
}
