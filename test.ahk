#Requires AutoHotkey v1.1
#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

OnMessage(0x200, "WM_MOUSEMOVE")

global OverrideCheckboxes := []
global HotkeyControls := []
global FKeyDropdowns := []

Gui, HotkeysManager:New ,+Hwndhwnd +HwndGuiID +AlwaysOnTop, Hotkeys Manager
Gui, HotkeysManager:Font, s10
Gui, HotkeysManager:Add, GroupBox, x10 y10 w430 h211, Paste Commands
Gui, HotkeysManager:Add, Text, vMyText x25 y40 w100 h25,  Account Number
Gui, HotkeysManager:Add, Picture, x145 y43  vHelpIconAccountNumber gShowHelp, %A_ScriptDir%\question.png
Gui, HotkeysManager:Add, Text, x25 y76 w100 h25,  Tech Number
Gui, HotkeysManager:Add, Picture, x145 y79  vHelpIconTechNumber gShowHelp, %A_ScriptDir%\question.png
Gui, HotkeysManager:Add, Text, x25 y112 w125 h25, Workorder Number
Gui, HotkeysManager:Add, Picture, x145 y115  vHelpIconWorkOrderNumber gShowHelp, %A_ScriptDir%\question.png
Gui, HotkeysManager:Add, Text, x25 y148 w100 h25, Notes in AOS
Gui, HotkeysManager:Add, Picture, x145 y151  vHelpIconNotesInAOS gShowHelp, %A_ScriptDir%\question.png
Gui, HotkeysManager:Add, Text, x25 y184 w100 h25, Sanitized Paste
Gui, HotkeysManager:Add, Picture, x145 y187  vHelpIconSanitizedPaste gShowHelp, %A_ScriptDir%\question.png
Gui, HotkeysManager:Add, GroupBox, x10 y220 w430 h175, Automation Commands
Gui, HotkeysManager:Add, Text, x25 y246 w100 h25, Open in SAT
Gui, HotkeysManager:Add, Picture, x145 y249  vHelpIconOpenInSat gShowHelp, %A_ScriptDir%\question.png
Gui, HotkeysManager:Add, Text, x25 y282 w100 h25, Open in ACSR
Gui, HotkeysManager:Add, Picture, x145 y285  vHelpIconOpenInACSR gShowHelp, %A_ScriptDir%\question.png
Gui, HotkeysManager:Add, ListView, x10 h200 w430 gMyListView vHotkeyList altsubmit LV0x10 NoSortHdr, Name|Hotkey|Hotstring|Command
LV_ModifyCol(2, 100)
LV_ModifyCol(4, 210)
LV_Add(, "Test", "Ctrl+Shift+Alt+v",,"Test This Bad Boi")

HelpIconAccountNumber_TT := "Pastes the Account number where the text cursor is."
HelpIconTechNumber_TT := "Pastes the Tech number where the text cursor is."
HelpIconWorkOrderNumber_TT := "Pastes the Work Order number where the text cursor is."
HelpIconNotesInAOS_TT := "Pastes the Notes in AOS requires AOS to be the last active tab in your web browser."
HelpIconSanitizedPaste_TT := "Removes colon, parenthesis, dashes, and new lines from your copied text and pastes it."
HelpIconOpenInSat_TT := "Opens the account in SAT. If you have a SAT tab open, it will use that tab otherwise it will open a new one."
HelpIconOpenInACSR_TT := "Opens the account in ACSR."
_TT := "TBD"
_TT := "TBD"

loop, 5 {
    yPos := 40 + (A_Index-1) * 36

    Gui, HotkeysManager:Add, Hotkey, x165 y%yPos% w120 h25 limit7 vHotkey%A_Index% gHotkeyChanged, 
    HotkeyControls.Push("Hotkey" . A_Index)
    
    Gui, HotkeysManager:Add, Checkbox, x295 y%yPos% w80 h25 vOverride%A_Index% gOverrideToggled, Use F-Key
    OverrideCheckboxes.Push("Override" . A_Index)
    
    Gui, HotkeysManager:Add, DropDownList, x385 y%yPos% w45 h120 vFKey%A_Index% Disabled Choose1, F1|F2|F3|F4|F6|F7|F8
    FKeyDropdowns.Push("FKey" . A_Index)
}

loop, 4 {
    yPos := 246 + (A_Index-1) * 36

    ModifiedIndex := A_Index + 5

    Gui, HotkeysManager:Add, Hotkey, x165 y%yPos% w120 h25 limit7 vHotkey%ModifiedIndex% gHotkeyChanged, 
    HotkeyControls.Push("Hotkey" . ModifiedIndex)
    
    Gui, HotkeysManager:Add, Checkbox, x295 y%yPos% w80 h25 vOverride%ModifiedIndex% gOverrideToggled, Use F-Key
    OverrideCheckboxes.Push("Override" . ModifiedIndex)
    
    Gui, HotkeysManager:Add, DropDownList, x385 y%yPos% w45 h120 vFKey%ModifiedIndex% Disabled Choose1, F1|F2|F3|F4|F6|F7|F8
    FKeyDropdowns.Push("FKey" . ModifiedIndex)
}

Gui, HotkeysManager:Add, Button, x230 y640 w100 h30 gSaveConfig, Save
Gui, HotkeysManager:Add, Button, x340 y640 w100 h30 gCancelConfig, Close

Gui, HotkeysManager:Add, StatusBar,, Ready to configure hotkeys

Gui, HotkeysManager:Show, w450 h700

If (FileExist("hotkeys2.ini"))
    LoadSavedSettings()
Else
    LoadDefaultSettings()

Menu, HotkeyContextMenu, Add, Add Item, AddItem
Menu, HotkeyContextMenu, Add, Delete Item, DeleteItem

Return

HotkeysManagerGuiContextMenu:
    if (A_GuiControl = "HotkeyList") {
        Menu, HotkeyContextMenu, Show
    }
Return

AddItem:
Return

DeleteItem:
return

MyListView:
if (A_GuiEvent = "DoubleClick")
	{
        LV_GetText(HotkeyNameInput, A_EventInfo , 1)
        LV_GetText(HotkeyNameInput, A_EventInfo , 2)

		IniRead, InputHotkeyUsed, hotkeys2custom.ini, %HotkeyNameInput%, Hotkey
        IniRead, InputHotstringUsed, hotkeys2custom.ini, %HotkeyNameInput%, Hotstring



		Gui, Input:New, +AlwaysOnTop
		Gui, Input:Add, Text,, Name:
		Gui, Input:Add, Edit, w100 vName, % TextName

		Gui, Input:Add, Text,, Choose input type:
        Gui, Input:Add, Radio, vInputHotkeyRadio gInputRadioButtonSwitch, Hotkey
        Gui, Input:Add, Radio, vInputHotstringRadio gInputRadioButtonSwitch, Hotstring
        If (InputHotkeyUsed = "Error")
        {
            Guicontrol,Input:, InputHotstringRadio, 1
            Gui, Input:Add, Text,, Hotkey:
            Gui, Input:Add, Hotkey, Limit7 vInputHotkey Disabled, 
            Gui, Input:Add, Text,, Hotstring:
            Gui, Input:Add, Edit, vInputHotstring , 
        }
        Else
        {
            Guicontrol,Input:, InputHotkeyRadio, 1
            Gui, Input:Add, Text,, Hotkey:
            Gui, Input:Add, Hotkey, Limit7 vInputHotkey, 
            Gui, Input:Add, Text,, Hotstring:
            Gui, Input:Add, Edit, vInputHotstring Disabled, 
        }
		
		FixedCommand := StrReplace(TextCommand, "{newline}", "`n")

		Gui, Input:Add, Text,, Command:
		Gui, Input:Add,  Edit, +WantReturn +Multi vCommand r20 w500, % FixedCommand
		

		Gui, Input:Add, Button, gSaveHotkey, Save
		Gui, Input:Show, , Add Hotkey
		customHotkeySectiontoDelete := TextName
	}
return

InputRadioButtonSwitch:
GuiControlGet, InputRadioHotkey, Input:, InputHotkeyRadio
If (InputRadioHotkey)
{
    Guicontrol,Input:Enable, InputHotkey
    Guicontrol,Input:Disable, InputHotString
}
Else
{

    Guicontrol,Input:Disable, InputHotkey
    Guicontrol,Input:Enable, InputHotString
}
return

SaveHotkey:
return



LoadDefaultSettings() {

    GuiControl,HotkeysManager:, Hotkey1, ^a
    GuiControl,HotkeysManager:, Hotkey2, ^c
    GuiControl,HotkeysManager:, Hotkey3, ^v
    
    GuiControl,, Override4, 1
    GuiControl, HotkeysManager:Enable, FKey4
    GuiControl, HotkeysManager:Disable, Hotkey4
    GuiControl, HotkeysManager:Choose, FKey4, 4  
    
    SB_SetText("Default settings loaded")
}

LoadSavedSettings() {
    Loop, 9 {
        IniRead, hotkeyValue, hotkeys2.ini, Hotkeys, Hotkey%A_Index%, Error
        
        if (InStr(hotkeyValue, "F")) {
            GuiControl,, Override%A_Index%, 1
            GuiControl, HotkeysManager:Enable, FKey%A_Index%
            GuiControl, HotkeysManager:Disable, Hotkey%A_Index%
            GuiControl, HotkeysManager:Choose, FKey%A_Index%, % SubStr(hotkeyValue, 2)
        } else {
            GuiControl,, Override%A_Index%, 0
            GuiControl, HotkeysManager:Disable, FKey%A_Index%
            GuiControl, HotkeysManager:Enable, Hotkey%A_Index%
            GuiControl,, Hotkey%A_Index%, %hotkeyValue%
        }
    }
    
    SB_SetText("Saved settings loaded")
}

OverrideToggled:
    controlNum := RegExReplace(A_GuiControl, "Override", "")
    isChecked := 0
    
    GuiControlGet, isChecked,HotkeysManager:, %A_GuiControl%
    
    if (isChecked) {
        GuiControl, HotkeysManager:Enable, FKey%controlNum%
        GuiControl, HotkeysManager:Disable, Hotkey%controlNum%
        
        GuiControl,HotkeysManager:, Hotkey%controlNum%
        
        SB_SetText("Hotkey " . controlNum . " will use an F-key")
    } else {
        GuiControl, HotkeysManager:Disable, FKey%controlNum%
        GuiControl, HotkeysManager:Enable, Hotkey%controlNum%
        
        SB_SetText("Hotkey " . controlNum . " will use a custom key combination")
    }
Return

HotkeyChanged:

    controlNum := RegExReplace(A_GuiControl, "Hotkey", "")
    
    GuiControlGet, hotkeyValue,HotkeysManager:, %A_GuiControl%
    
    if (hotkeyValue)
    {
        hotkeyValueParsed := StrReplace(hotkeyValue, "+", "Shift+")
        hotkeyValueParsed := StrReplace(hotkeyValueParsed, "^", "Ctrl+")
        hotkeyValueParsed := StrReplace(hotkeyValueParsed, "!", "Alt+")
        SB_SetText("Hotkey " . controlNum . " set to " . hotkeyValueParsed)
    }
    else
        SB_SetText("Hotkey " . controlNum . " cleared")
Return


SaveConfig:
    hotkeyConfig := []
    usedHotkeys := {}
    bannedHotkeys := {}
    ;bannedHotkeys["^!s"] := true

    Loop, 9 {
        isOverrideEnabled := 0
        GuiControlGet, isOverrideEnabled,HotkeysManager:, Override%A_Index%
        
        if (isOverrideEnabled) {
            GuiControlGet, selectedFKey,HotkeysManager:, FKey%A_Index%
            hotkeyConfig[A_Index] := selectedFKey
        } else {
            GuiControlGet, hotkeyValue,HotkeysManager:, Hotkey%A_Index%
            hotkeyConfig[A_Index] := hotkeyValue
        }
        if (usedHotkeys.HasKey(hotkeyConfig[A_Index]) && NOT hotkeyConfig[A_Index] = "") {
            MsgBox, 16, Error, Duplicate hotkey detected: Please use unique hotkeys.
            Return
        } else {
            usedHotkeys[hotkeyConfig[A_Index]] := true
        }
        if (bannedHotkeys.HasKey(hotkeyConfig[A_Index]))
        {
            bannedKey := hotkeyConfig[A_Index]
            bannedKey := StrReplace(bannedKey, "+", "Shift+")
            bannedKey := StrReplace(bannedKey, "^", "Ctrl+")
            bannedKey := StrReplace(bannedKey, "!", "Alt+")
            
            MsgBox, 16, Error, Banned Hotkey Used: %bannedKey% is not allowed.
            Return
        }
    }

    FileDelete, hotkeys2.ini
    Loop, 9 {
        IniWrite, % hotkeyConfig[A_Index], hotkeys2.ini, Hotkeys, Hotkey%A_Index%
    }
    SB_SetText("Config saved")
Return

CancelConfig:
    MsgBox, 4, Confirm Exit, Are you sure you want to exit? Any unsaved changes will be lost.
    IfMsgBox Yes
    {
        Gui, Destroy
        ExitApp
    }
Return

HotkeysManagerGuiClose:
HotkeysManagerGuiEscape:
    MsgBox, 4, Confirm Exit, Are you sure you want to exit? Any unsaved changes will be lost.
    IfMsgBox Yes
    {
        ExitApp
    }
Return

ShowHelp:

    ToolTip, % %A_GuiControl%_TT
    SetTimer, RemoveToolTip, -3000 
Return

RemoveToolTip:
    ToolTip
Return

