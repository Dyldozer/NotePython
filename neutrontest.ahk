#SingleInstance Force
#NoEnv
SetBatchLines -1

; Include Neutron library - make sure you have this file in the same directory
#Include Neutron.ahk

; Global variables to store current category
global currentCategory := "General"
global noteButtons := {}


; Create the GUI
neutron := new NeutronWindow()
neutron.load("base.html")
neutron.Gui("+LabelNeutron")

; Register AHK Functions to be called from JS
neutron.On("categoryChanged", Func("CategoryChanged"))
neutron.On("copyNotes", Func("CopyNotes"))
neutron.On("clearFields", Func("ClearFields"))

; Set the GUI title
neutron.Title := "Call Notes Taker"
neutron.Show("w900 h700")
return

; Function called when category is changed
CategoryChanged(category) {
    currentCategory := category
    return
}

; Function to handle copying formatted notes
CopyNotes(tecId, jobNumber, callbackNumber, accountNumber, notes) {
    ; Format the notes string
    formattedNotes := "Tech ID: " . tecId . "`r`n"
    formattedNotes .= "Job #: " . jobNumber . "`r`n"
    formattedNotes .= "Callback #: " . callbackNumber . "`r`n"
    formattedNotes .= "Account #: " . accountNumber . "`r`n"
    formattedNotes .= "--- Notes ---`r`n" . notes
    
    ; Copy to clipboard
    Clipboard := formattedNotes
    MsgBox, 64, Notes Copied, The formatted notes have been copied to clipboard!
    return
}

; Function to handle clearing fields
ClearFields() {
    return
}

; Handle GUI Close
GuiClose:
ExitApp