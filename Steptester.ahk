#Persistent
#SingleInstance Force

global stepID := "tcStart"
global answerButtons := []
global answerCount := 0


;---------------- generated code ------------------
problemSteps := Object()

; Step: tcAged
step := Object()
step.Insert("Instruction", "Call Customer and see if they still need tech out.")
step.Insert("Question", "Does the customer still need a technician out?")
step.Insert("Answers", Array("Yes", "No", "No contact"))
step.Insert("NextStep", Object("Yes", "rescheduleTC", "No", "cancelTC", "No contact", "cancelTcNoContact"))
problemSteps["tcAged"] := step

; Step: tcNotAged
step := Object()
step.Insert("Instruction", "Call Customer and see if they still need tech out.")
step.Insert("Question", "Does the customer still need a technician out?")
step.Insert("Answers", Array("Yes", "No", "No Answer"))
step.Insert("NextStep", Object("Yes", "rescheduleTc", "No", "DispositionTask", "No Answer", "DispositionTaskNoAnswer"))
problemSteps["tcNotAged"] := step

; Step: tcStart
step := Object()
step.Insert("Instruction", "Check trouble call info.")
step.Insert("Question", "Is the tc 14 days old and 3+ reschedules have been made?")
step.Insert("Answers", Array("Yes", "No"))
step.Insert("NextStep", Object("Yes", "tcAged", "No", "tcNotAged"))
problemSteps["tcStart"] := step



;---------------- end of generated code ------------------

Gui, Font, s07
Gui, Add, Text, x10 y10 w400 vInstructionText, 

Gui, Add, Text, x10 y50 w400 vQuestionText, 

yPos := 90
Loop, 5 { 
    Gui, Add, Button, x10 y%yPos% w200 h30 gAnswerSelected vAnswer%A_Index% Hidden, 
    yPos += 40
}

Gui, Show, w450 h250 Center, Step Tester
UpdateStep(stepID)

return


UpdateStep(stepID) {
    global problemSteps, answerButtons, answerCount

    step := problemSteps[stepID]
    if (!step) {
        MsgBox, Error: Step %stepID% not found!
        return
    }

    
    GuiControl,, InstructionText, % step["Instruction"]
    GuiControl,, QuestionText, % step["Question"]

    
    Loop, % answerCount {
        GuiControl, Hide, Answer%A_Index%
    }

    
    answerCount := step["Answers"].MaxIndex()
    Loop, % answerCount {
        answer := step["Answers"][A_Index]
        GuiControl,, Answer%A_Index%, % answer
        GuiControl, Show, Answer%A_Index%
    }
}

AnswerSelected:
    global problemSteps, stepID, answerButtons, answerCount

    
    Loop, % answerCount {
        if (A_GuiControl = "Answer" A_Index) {
            selectedAnswer := problemSteps[stepID]["Answers"][A_Index]
            break
        }
    }

    
    nextStep := problemSteps[stepID]["NextStep"][selectedAnswer]

    if (nextStep == "") {
        MsgBox, Error: No next step defined for answer: %selectedAnswer%
        return
    }

    
    if (!problemSteps.HasKey(nextStep)) {
        MsgBox, % problemSteps[nextStep]["Instruction"]
        ExitApp
    }

    
    stepID := nextStep
    UpdateStep(stepID)

return
