#Persistent
#SingleInstance Force
#Include jsonParse.ahk

global maxAnswers := 5  
global answerCount := 2  
global problemSteps := Object()  
global stepMap := Object()  


Gui, -Resize
Gui, Add, Button, x10 y10 w120 gLoadFile, Load File
Gui, Add, Button, x140 y10 w120 gSaveFile, Save File

Gui, Add, TreeView, x10 y50 w250 h500 vStepTree gSelectStep

Gui, Add, GroupBox, x280 y10 w420 h550, Step Details
Gui, Add, Text, x290 y30 w400, Step Name:
Gui, Add, Edit, x290 y50 w400 vStepName,

Gui, Add, Text, x290 y90 w400, Instruction:
Gui, Add, Edit, x290 y110 w400 vInstructionText,

Gui, Add, Text, x290 y150 w400, Question:
Gui, Add, Edit, x290 y170 w400 vQuestionText,

Gui, Add, Text, x290 y210 w150, Number of answers:
Gui, Add, DropDownList, x450 y210 w60 vAnswerCount gUpdateAnswers, 1|2||3|4|5

Gui, Font, Bold
Gui, Add, Text, x290 y250 w400, Answers and Next Steps:



yPos := 280
Loop, % maxAnswers {
    Gui, Add, Edit, x290 y%yPos% w150 vAnswer%A_Index% Hidden,
    Gui, Add, Edit, x460 y%yPos% w80 vNextStep%A_Index% Hidden,
    yPos += 40
}
Gui, Add, Button, x290 y470 w400 h30 gGenerateFullCode, Generate Full Problem Tree Code
Gui, Add, Button, x290 y420 w400 h30 gClear, Clear
Gui, Add, Button, x290 y510 w200 h30 gGenerateCode, Generate/Update Step
Gui, Add, Button, x500 y510 w200 h30 gBuildTree, Refresh TreeView
Gui, Add, Edit, x290 y570 w400 h150 vOutputText ReadOnly, 

Gui, Show, w720 h750, Problem Step Editor
UpdateAnswers()
return

GenerateFullCode:
    output := ""
    output .= "problemSteps := Object()`n`n"
    
    for stepName, step in problemSteps {
        output .= "; Step: " . stepName . "`n"
        output .= "step := Object()`n"
        output .= "step.Insert(""Instruction"", """ . step.Instruction . """)`n"
        output .= "step.Insert(""Question"", """ . step.Question . """)`n"
        
        answersText := "step.Insert(""Answers"", Array("
        for index, answer in step.Answers {
            answersText .= """" . answer . """"
            if (index < step.Answers.MaxIndex())
                answersText .= ", "
        }
        answersText .= "))`n"
        output .= answersText
        
        nextStepsText := "step.Insert(""NextStep"", Object("
        for index, answer in step.Answers {
            if (step.NextStep[answer] != "") {
                nextStepsText .= """" . answer . """, """ . step.NextStep[answer] . """"
                if (index < step.Answers.MaxIndex())
                    nextStepsText .= ", "
            }
        }
        nextStepsText .= "))`n"
        output .= nextStepsText
        
        output .= "problemSteps[""" . stepName . """] := step`n`n"
    }
    
    GuiControl,, OutputText, % output
return
Clear:
guiControl,, StepName,
guiControl,, QuestionText,
guiControl,, InstructionText,
Loop, % maxAnswers {
    guiControl,, Answer%A_Index%,
    guiControl,, NextStep%A_Index%,
}
    
return

UpdateAnswers() {
    global answerCount, maxAnswers

    GuiControlGet, answerCount,, AnswerCount
    answerCount := answerCount > 0 ? answerCount : 1  

    
    Loop, % maxAnswers {
        GuiControl, Hide, Answer%A_Index%
        GuiControl, Hide, NextStep%A_Index%
    }

    
    Loop, % answerCount {
        GuiControl, Show, Answer%A_Index%
        GuiControl, Show, NextStep%A_Index%
    }
}

GenerateCode:
    GuiControlGet, stepName,, StepName
    GuiControlGet, instruction,, InstructionText
    GuiControlGet, question,, QuestionText
    GuiControlGet, answerCount,, AnswerCount

    stepName := Trim(stepName)
    if (stepName = "") {
        MsgBox, Please enter a step name!
        return
    }

    step := Object()
    step.Insert("Instruction", instruction)
    step.Insert("Question", question)

    answers := []
    nextSteps := Object()
    
    Loop, % answerCount {
        GuiControlGet, answer,, Answer%A_Index%
        GuiControlGet, nextStep,, NextStep%A_Index%
        
        if (answer != "") {
            answers.Push(answer)
            nextSteps.Insert(answer, nextStep)
        }
    }

    step.Insert("Answers", answers)
    step.Insert("NextStep", nextSteps)

    problemSteps[stepName] := step

    output := "step := Object()`n"
    output .= "step.Insert(""Instruction"", """ . instruction . """)`n"
    output .= "step.Insert(""Question"", """ . question . """)`n"
    output .= "step.Insert(""Answers"", Array(" . Join(",", answers, """") . "))`n"
    output .= "step.Insert(""NextStep"", Object(" . JoinPairs(nextSteps) . "))`n"
    output .= "problemSteps[""" . stepName . """] := step"

    GuiControl,, OutputText, % output
    BuildTree()
return

LoadFile:
    FileSelectFile, filePath, 3,, Select a file to load, Text Documents (*.json)
    if (filePath = "")
        return

    FileRead, fileContent, % filePath
    problemSteps := Object()
    
    try {
        problemSteps := JSON_Load(fileContent)
    } catch {
        MsgBox, Error loading file!
        return
    }

    BuildTree()
return

SaveFile:
    FileSelectFile, filePath, S16,, Save problem steps, Text Documents (*.json)
    if (filePath = "")
        return

    FileDelete, % filePath
    FileAppend, % JSON_Save(problemSteps), % filePath
    MsgBox, File saved successfully!
return

BuildTree()
{
    TV_Delete()  
    stepMap := Object()

    for stepName, step in problemSteps {
        parentID := TV_Add(stepName)
        stepMap[parentID] := stepName

        for _, answer in step.Answers {
            if (step.NextStep[answer] != "") {
                TV_Add(answer . " -> " . step.NextStep[answer], parentID)
            }
        }
    }
return
}


SelectStep:
    selectedID := TV_GetSelection()
    if (selectedID = 0)
        return

    selectedStep := stepMap[selectedID]
    if (!problemSteps.HasKey(selectedStep))
        return

    step := problemSteps[selectedStep]

    GuiControl,, StepName, % selectedStep
    GuiControl,, InstructionText, % step.Instruction
    GuiControl,, QuestionText, % step.Question
    GuiControl,Choose, AnswerCount, % step.Answers.MaxIndex()

    Loop, % maxAnswers {
        if (A_Index <= step.Answers.MaxIndex()) {
            GuiControl,, Answer%A_Index%, % step.Answers[A_Index]
            GuiControl,, NextStep%A_Index%, % step.NextStep[step.Answers[A_Index]]
        } else {
            GuiControl,, Answer%A_Index%, 
            GuiControl,, NextStep%A_Index%, 
        }
    }

    UpdateAnswers()
return

Join(delimiter, arr, quote := "") {
    result := ""
    for index, value in arr
        result .= quote . value . quote . delimiter
    return SubStr(result, 1, -StrLen(delimiter))  
}

JoinPairs(obj) {
    result := ""
    for key, value in obj
        result .= """" . key . """, " . value . ", "
    return SubStr(result, 1, -2)  
}

JSON_Load(json) {
    return Jxon_Load(json)
}

JSON_Save(obj) {
    return Jxon_Dump(obj)
}
