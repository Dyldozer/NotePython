#SingleInstance, force
Gui, +Resize +AlwaysOnTop
Gui, Font, s10, Segoe UI

; ----------- Group 1: Job Info -----------
Gui, Add, GroupBox, x10 y10 w280 h150, Job Information
Gui, Add, Text, x20 y35, Tech ID:
Gui, Add, Edit, x80 y30 w200 vTechID
Gui, Add, Text, x20 y65, Job #:
Gui, Add, Edit, x80 y60 w200 vJobNum
Gui, Add, Text, x20 y95, Call Back:
Gui, Add, Edit, x80 y90 w200 vCallBack
Gui, Add, Text, x20 y125, Acc #:
Gui, Add, Edit, x80 y120 w200 vAccNum

; ----------- Group 3: Notes -----------
Gui, Add, GroupBox, x10 y175 w280 h160, Notes
Gui, Add, Edit, x20 y195 w200 h120 vNotes -WantTab

; ----------- Group 4: Actions -----------
Gui, Add, GroupBox, x300 y10 w180 h200, Actions
Gui, Add, Button, x310 y30 w160 h30 gCopyFromAppbar, Copy From Appbar
Gui, Add, Button, x310 y70 w160 h30 gPasteInAOS, Paste in AOS
Gui, Add, Button, x310 y110 w160 h30 gOpenACSR, Open in ACSR

; ----------- Group 5: Quick Notes -----------
Gui, Add, GroupBox, x300 y220 w180 h180, Quick Notes
Gui, Add, Button, x310 y240 w75 h30 gSupApprove, Sup Approve
Gui, Add, Button, x395 y240 w75 h30 gCallCx, Call Cx
Gui, Add, Button, x310 y280 w75 h30 gLeftVM, Left VM
Gui, Add, Button, x395 y280 w75 h30 gNoVM, No VM
Gui, Add, Button, x310 y320 w75 h30 gAnsCall, Ans Call
Gui, Add, Button, x395 y320 w75 h30 gCustConf, Cust Conf
Gui, Add, Button, x310 y360 w75 h30 gTechEd, Tech Ed
Gui, Add, Button, x395 y360 w75 h30 gAccountSync, Account Sync

; ----------- Bottom Buttons -----------
Gui, Add, Button, x10 y420 w130 h30 gCopyNotes, Copy Notes
Gui, Add, Button, x160 y420 w130 h30 gClearNotes, Clear

Gui, Show,, Improved Tech Support GUI
Return

; ----------- Button Actions -----------
CopyFromAppbar:
    MsgBox, Copying from Appbar...
Return

PasteInAOS:
    MsgBox, Pasting into AOS...
Return

OpenACSR:
    MsgBox, Opening ACSR...
Return

SupApprove:
    GuiControl,, Notes, % "Sup Approve`n" 
Return

CallCx:
    GuiControl,, Notes, % "Call Customer`n" 
Return

LeftVM:
    GuiControl,, Notes, % "Left Voicemail`n" 
Return

NoVM:
    GuiControl,, Notes, % "No Voicemail`n" 
Return

AnsCall:
    GuiControl,, Notes, % "Answered Call`n" 
Return

CustConf:
    GuiControl,, Notes, % "Customer Confirmed`n" 
Return

TechEd:
    GuiControl,, Notes, % "Tech Ed`n" 
Return

AccountSync:
    GuiControl,, Notes, % "Account Sync`n" 
Return

CopyNotes:
    GuiControlGet, Notes, , Notes
    Clipboard := Notes
    MsgBox, Notes copied to clipboard!
Return

ClearNotes:
    GuiControl,, Notes
Return

GuiClose:
    ExitApp
Return
