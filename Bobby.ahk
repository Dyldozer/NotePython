#Persistent
SetTimer, CheckClipboard, 100  ; Run the function every 100ms
return

CheckClipboard:
    ClipSaved := ClipboardAll  ; Save the clipboard content to restore later if needed
    ClipWait, 0.1, 1  ; Ensure we have clipboard data (0.1s timeout, don't show errors)
    
    ClipText := Clipboard  ; Get clipboard text
    
    ; Check if clipboard contains "notes:"
    Pos := InStr(ClipText, "notes:")
    if (Pos) {
        AfterColonPos := Pos + 6  ; Position of the character right after "notes:"
        
        if (StrLen(ClipText) >= AfterColonPos) {  ; Ensure there's a character after ":"
            NextChar := SubStr(ClipText, AfterColonPos, 1)  ; Get next character
            
            if (NextChar != " ") {  ; If the next character isn't a space, fix it
                Clipboard := SubStr(ClipText, 1, AfterColonPos - 1) . " " . SubStr(ClipText, AfterColonPos)
            }
        }
    }
return
