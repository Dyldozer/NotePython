#SingleInstance Force
Gui, +AlwaysOnTop

; Main GUI
Gui, Add, Text, x10 y10 w300, This is a section that might need explanation
Gui, Add, Picture, x+5 y10  vHelpIcon gShowHelp, %A_ScriptDir%\question.png


;Gui, Add, Progress, x+5 y10 w16 h16 Background#4a86e8 vHelpCircle, 100
;Gui, Add, Text, xp+1 yp+1 w16 h16 BackgroundTrans cWhite Center vHelpText gShowHelp, ?

Gui, Add, Button, x10 y150 w100, OK
Gui, Show, w420 h180, Help Tooltip Demo
Return

ShowHelp:
    ToolTip, This is the helpful information about this section.
    SetTimer, RemoveToolTip, 3000  ; Hide after 3 seconds
Return

RemoveToolTip:
    ToolTip
    SetTimer, RemoveToolTip, Off
Return

GuiClose:
ExitApp