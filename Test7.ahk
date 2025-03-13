; AutoHotkey Script to read and activate hotkeys from a config file
#SingleInstance Force
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; Config file path - change this to your actual config file path
ConfigFilePath := A_ScriptDir . "\config.ini"

; Read and activate hotkeys on script startup
ReadAndActivateHotkeys(ConfigFilePath)

ReadAndActivateHotkeys(ConfigFile) {
    ; Read the hotkey configurations
    Loop, 9 {
        IniRead, HotkeyValue, %ConfigFile%, Hotkeys, Hotkey%A_Index%, %A_Space%
        
        ; Skip if the hotkey value is empty
        if (HotkeyValue = "" || HotkeyValue = " ") {
            continue
        }
        
        ; Dynamically create hotkey with appropriate function
        if (A_Index = 1)
            Hotkey, %HotkeyValue%, Hotkey1Function, On
        else if (A_Index = 2)
            Hotkey, %HotkeyValue%, Hotkey2Function, On
        else if (A_Index = 3)
            Hotkey, %HotkeyValue%, Hotkey3Function, On
        else if (A_Index = 4)
            Hotkey, %HotkeyValue%, Hotkey4Function, On
        else if (A_Index = 5)
            Hotkey, %HotkeyValue%, Hotkey5Function, On
        else if (A_Index = 6)
            Hotkey, %HotkeyValue%, Hotkey6Function, On
        else if (A_Index = 7)
            Hotkey, %HotkeyValue%, Hotkey7Function, On
        else if (A_Index = 8)
            Hotkey, %HotkeyValue%, Hotkey8Function, On
        else if (A_Index = 9)
            Hotkey, %HotkeyValue%, Hotkey9Function, On
        
        ; Log activated hotkey
        FileAppend, Activated Hotkey%A_Index%: %HotkeyValue%`n, *
    }
    return
}

; Individual functions for each hotkey
Hotkey1Function() {
    ; Custom function for Hotkey1 (F2 in your example)
    MsgBox, Hotkey1 Function Executed
    ; Add your custom code here
    return
}

Hotkey2Function() {
    ; Custom function for Hotkey2
    MsgBox, Hotkey2 Function Executed
    ; Add your custom code here
    return
}

Hotkey3Function() {
    ; Custom function for Hotkey3 (F1 in your example)
    MsgBox, Hotkey3 Function Executed
    ; Add your custom code here
    return
}

Hotkey4Function() {
    ; Custom function for Hotkey4
    MsgBox, Hotkey4 Function Executed
    ; Add your custom code here
    return
}

Hotkey5Function() {
    ; Custom function for Hotkey5 (!g - Alt+g in your example)
    MsgBox, Hotkey5 Function Executed
    ; Add your custom code here
    return
}

Hotkey6Function() {
    ; Custom function for Hotkey6
    MsgBox, Hotkey6 Function Executed
    ; Add your custom code here
    return
}

Hotkey7Function() {
    ; Custom function for Hotkey7
    MsgBox, Hotkey7 Function Executed
    ; Add your custom code here
    return
}

Hotkey8Function() {
    ; Custom function for Hotkey8
    MsgBox, Hotkey8 Function Executed
    ; Add your custom code here
    return
}

Hotkey9Function() {
    ; Custom function for Hotkey9
    MsgBox, Hotkey9 Function Executed
    ; Add your custom code here
    return
}

; Function to reload the script
ReloadScript() {
    Reload
    return
}

; Add a reload hotkey
^!r::ReloadScript()  ; Ctrl+Alt+R to reload
