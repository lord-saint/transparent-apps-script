; Initialize the auto-check flag and start the timer
isAutoCheckEnabled := true
currentTransparency := 220  ; Store current transparency level
SetTimer CheckApps, 1000  ; Check every 1 second

; Function to check and make apps transparent
CheckApps()
{
    global isAutoCheckEnabled, currentTransparency
    
    ; Only run if auto-check is enabled
    if (isAutoCheckEnabled)
    {
        ; Check if Brave is open and make it transparent
        if WinExist("ahk_exe brave.exe")
            WinSetTransparent(currentTransparency, "ahk_exe brave.exe")
        
        ; Check if VLC is open and make it transparent
        if WinExist("ahk_exe vlc.exe")
            WinSetTransparent(currentTransparency, "ahk_exe vlc.exe")
        
        ; Check if Notepad is open and make it transparent
        if WinExist("ahk_exe notepad.exe")
            WinSetTransparent(currentTransparency, "ahk_exe notepad.exe")
    }
}

; Hotkey: Ctrl+Shift+Right Click to toggle transparency
^+RButton::
{
    global isAutoCheckEnabled, currentTransparency
    
    ; Get the process name of the active window
    procName := WinGetProcessName("A")
    
    ; Check if active window is one of our target apps
    if (procName = "brave.exe" or procName = "vlc.exe" or procName = "notepad.exe") 
    {
        ; Toggle the auto-check on/off
        isAutoCheckEnabled := !isAutoCheckEnabled
        
        ; If disabling, make the window fully opaque
        if (!isAutoCheckEnabled)
        {
            WinSetTransparent(255, "A")
        }
    }
}

; Hotkey: Ctrl+Shift+Plus to increase transparency
^+NumpadAdd::
{
    global currentTransparency
    
    ; Increase transparency by 10 (max is 255 = fully opaque)
    if (currentTransparency < 255)
    {
        currentTransparency += 10
        if (currentTransparency > 255)
            currentTransparency := 255
        
        ; Apply to active window
        WinSetTransparent(currentTransparency, "A")
    }
}

; Hotkey: Ctrl+Shift+Minus to decrease transparency
^+NumpadSub::
{
    global currentTransparency
    
    ; Decrease transparency by 10 (min is 0 = fully transparent)
    if (currentTransparency > 0)
    {
        currentTransparency -= 10
        if (currentTransparency < 0)
            currentTransparency := 0
        
        ; Apply to active window
        WinSetTransparent(currentTransparency, "A")
    }
}