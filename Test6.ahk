; Sample text containing quoted items
text := "Here is some text with ""quoted items"" and ""another quoted phrase"" and even ""one more""."

; Create an array to store matches
matches := []

; Use O) modifier to get regex object instead of position
position := 1
while (position := RegExMatch(text, "O)""([^""]+)""", match, position)) {
    matches.Push(match.Value(1))  ; Value(1) gives the content of the first capturing group
    position += match.Len(0)      ; Move past this match
}

; Iterate through matches and display in MsgBox
for index, item in matches {
    MsgBox, % "Match " index ": " item
}
