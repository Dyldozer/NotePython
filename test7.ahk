
#NoEnv
#SingleInstance Force
SetBatchLines, -1
SendMode Input

; Sample data
global items := ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Honeydew", "Kiwi", "Lemon", "Mango", "Nectarine", "Orange", "Papaya"]
global filteredItems := items.Clone()

; Create GUI
Gui, +Resize
Gui, Add, Text, x10 y10 w100 h20, Search:
Gui, Add, Edit, x110 y10 w200 h20 vSearchTerm gPerformSearch
Gui, Add, ListView, x10 y40 w300 h300 vItemList, Items
Gui, Show, w320 h350, Fuzzy Search ListView

; Populate ListView initially
PopulateListView(items)
return

; Search function
PerformSearch:
    Gui, Submit, NoHide
    filteredItems := FuzzySearch(items, SearchTerm)
    PopulateListView(filteredItems)
    return

; Populate ListView helper function
PopulateListView(itemArray) {
    Gui, ListView, ItemList
    LV_Delete()
    for index, item in itemArray {
        LV_Add("", item)
    }
    return
}

; Fuzzy search using n-gram approach
FuzzySearch(itemArray, searchTerm) {
    if (searchTerm = "")
        return itemArray.Clone()
    
    result := []
    searchTerm := LowerCase(searchTerm)
    
    for index, item in itemArray {
        itemLower := LowerCase(item)
        if (FuzzyMatch(itemLower, searchTerm))
            result.Push(item)
    }
    return result
}

; Fuzzy matching function using n-gram technique
FuzzyMatch(str, pattern) {
    ; Convert to lowercase for case-insensitive matching
    str := LowerCase(str)
    pattern := LowerCase(pattern)
    
    ; Split pattern into n-grams (using 2-grams/bigrams)
    patternLength := StrLen(pattern)
    
    ; For very short patterns, do a simple substring search
    if (patternLength <= 2)
        return InStr(str, pattern) > 0
    
    ; Match threshold - how many n-grams need to match
    ngramSize := 2
    matchThreshold := patternLength - ngramSize
    
    ; Count matches
    matches := 0
    
    ; Generate n-grams from pattern and check if they exist in str
    Loop, % patternLength - ngramSize + 1
    {
        ngram := SubStr(pattern, A_Index, ngramSize)
        if (InStr(str, ngram) > 0)
            matches++
    }
    
    return matches >= matchThreshold
}

; Helper function to convert to lowercase
LowerCase(str) {
    StringLower, result, str
    return result
}

GuiClose:
ExitApp
