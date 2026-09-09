#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Tutorial GIF Maker
; F8 start  |  F9 stop & edit  |  Esc cancel
; Left click / double-click capture an 800x800 region around the cursor.

try DllCall("SetProcessDpiAwarenessContext", "ptr", -4)

CoordMode("Mouse", "Screen")
CoordMode("ToolTip", "Screen")
SendMode("Input")

class GM {
    static CaptureSize := 800
    static DefaultDelay := 2000
    static CircleRadius := 40
    static CirclePen := 6
    static GdiToken := 0
    static Recording := false
    static Capturing := false
    static EditorOpen := false
    static Pending := false
    static PendingX := 0
    static PendingY := 0
    static SessionDir := ""
    static SessionName := ""
    static LastSessionDir := ""
    static Frames := []
    static Editor := 0
}

Gdip_Startup()
OnExit(Cleanup)

A_IconTip := "Tutorial GIF Maker"
TraySetIcon("shell32.dll", 239)
A_TrayMenu.Delete()
A_TrayMenu.Add("Start recording (F8)", TrayStart)
A_TrayMenu.Add("Stop recording (F9)", TrayStop)
A_TrayMenu.Add("Cancel recording (Esc)", TrayCancel)
A_TrayMenu.Add()
A_TrayMenu.Add("Open last recording", TrayOpenLast)
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Start recording (F8)"
ShowTip("GIF Maker running — F8 start, F9 stop, Esc cancel")

#InputLevel 1

#HotIf !GM.Recording && !GM.EditorOpen
F8:: StartRecording()
#HotIf

#HotIf GM.Recording
F9:: StopRecording()
Esc:: CancelRecording()
*$LButton:: HandleClick()
#HotIf

#InputLevel 0

OnMessage(0x201, Editor_OnDown)
OnMessage(0x202, Editor_OnUp)
OnMessage(0x200, Editor_OnMove)

TrayStart(*) {
    if GM.Recording || GM.EditorOpen
        return
    StartRecording()
}

TrayStop(*) {
    if GM.Recording
        StopRecording()
}

TrayCancel(*) {
    if GM.Recording
        CancelRecording()
}

TrayOpenLast(*) {
    if GM.LastSessionDir && DirExist(GM.LastSessionDir) {
        Run('explorer.exe "' GM.LastSessionDir '"')
        if !GM.Recording && !GM.EditorOpen
            OpenEditor(GM.LastSessionDir)
    } else {
        ShowTip("No recording yet")
    }
}

StartRecording() {
    if GM.Recording
        return
    if GM.Editor && GM.EditorOpen
        GM.Editor.Close()

    GM.SessionName := "tutorial_" FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    GM.SessionDir := A_ScriptDir "\recordings\" GM.SessionName
    DirCreate(GM.SessionDir)
    GM.Frames := []
    GM.Pending := false
    GM.Recording := true
    ShowTip("Recording started")
}

StopRecording() {
    if !GM.Recording
        return

    SetTimer(CommitSingle, 0)
    if GM.Pending
        CommitSingle()

    GM.Recording := false
    HideTip()

    if GM.Frames.Length = 0 {
        try DirDelete(GM.SessionDir, true)
        ShowTip("No pictures captured")
        return
    }

    SaveSession()
    GM.LastSessionDir := GM.SessionDir
    Run('explorer.exe "' GM.SessionDir '"')
    OpenEditor(GM.SessionDir)
}

CancelRecording() {
    if !GM.Recording
        return

    SetTimer(CommitSingle, 0)
    if GM.Pending {
        GM.Pending := false
        MouseClick("Left", GM.PendingX, GM.PendingY, 1, 0)
    }

    GM.Recording := false
    GM.Frames := []
    HideTip()
    Sleep(40)
    if GM.SessionDir && DirExist(GM.SessionDir) {
        try DirDelete(GM.SessionDir, true)
    }
    GM.SessionDir := ""
    ShowTip("Recording cancelled")
}

HandleClick() {
    if GM.Capturing
        return

    CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)

    if GM.Pending {
        dx := Abs(x - GM.PendingX)
        dy := Abs(y - GM.PendingY)
        boxX := SysGet(36)
        boxY := SysGet(37)
        SetTimer(CommitSingle, 0)
        GM.Pending := false
        if (dx <= boxX && dy <= boxY) {
            CaptureClick(x, y, true)
            return
        }
        CaptureClick(GM.PendingX, GM.PendingY, false)
    }

    GM.Pending := true
    GM.PendingX := x
    GM.PendingY := y
    SetTimer(CommitSingle, -DllCall("GetDoubleClickTime"))
}

CommitSingle() {
    if !GM.Pending
        return
    GM.Pending := false
    CaptureClick(GM.PendingX, GM.PendingY, false)
}

CaptureClick(x, y, isDouble) {
    GM.Capturing := true
    HideTip()
    Sleep(50)

    GetCaptureRect(x, y, &cx, &cy, &cw, &ch)
    if (cw < 2 || ch < 2) {
        GM.Capturing := false
        MouseClick("Left", x, y, isDouble ? 2 : 1, 0)
        return
    }

    hbm := ScreenCapture(cx, cy, cw, ch)
    pBmp := Gdip_CreateBitmapFromHBITMAP(hbm)
    DllCall("DeleteObject", "ptr", hbm)

    color := isDouble ? 0xFF1E90FF : 0xFFFF2020
    DrawClickCircle(pBmp, x - cx, y - cy, GM.CircleRadius, color, GM.CirclePen)

    idx := GM.Frames.Length + 1
    file := Format("frame_{:03}.png", idx)
    path := GM.SessionDir "\" file
    Gdip_SavePng(pBmp, path)
    Gdip_DisposeImage(pBmp)

    GM.Frames.Push({
        file: file,
        delay: GM.DefaultDelay,
        anns: []
    })
    SaveSession()

    if isDouble
        MouseClick("Left", x, y, 2, 0)
    else
        MouseClick("Left", x, y, 1, 0)

    GM.Capturing := false
    ShowTip("Picture taken")
}

GetCaptureRect(mx, my, &x, &y, &w, &h) {
    GetMonitorAt(mx, my, &ml, &mt, &mr, &mb)
    half := GM.CaptureSize // 2
    x1 := mx - half
    y1 := my - half
    x2 := mx + half
    y2 := my + half
    x1 := Max(x1, ml)
    y1 := Max(y1, mt)
    x2 := Min(x2, mr)
    y2 := Min(y2, mb)
    x := x1
    y := y1
    w := x2 - x1
    h := y2 - y1
}

GetMonitorAt(px, py, &l, &t, &r, &b) {
    loop MonitorGetCount() {
        MonitorGet(A_Index, &ml, &mt, &mr, &mb)
        if (px >= ml && px < mr && py >= mt && py < mb) {
            l := ml, t := mt, r := mr, b := mb
            return
        }
    }
    MonitorGet(MonitorGetPrimary(), &l, &t, &r, &b)
}

ScreenCapture(x, y, w, h) {
    hdcScreen := DllCall("GetDC", "ptr", 0, "ptr")
    hdcMem := DllCall("CreateCompatibleDC", "ptr", hdcScreen, "ptr")
    hbm := DllCall("CreateCompatibleBitmap", "ptr", hdcScreen, "int", w, "int", h, "ptr")
    old := DllCall("SelectObject", "ptr", hdcMem, "ptr", hbm, "ptr")
    DllCall("BitBlt", "ptr", hdcMem, "int", 0, "int", 0, "int", w, "int", h
        , "ptr", hdcScreen, "int", x, "int", y, "uint", 0x00CC0020)
    DllCall("SelectObject", "ptr", hdcMem, "ptr", old, "ptr")
    DllCall("DeleteDC", "ptr", hdcMem)
    DllCall("ReleaseDC", "ptr", 0, "ptr", hdcScreen)
    return hbm
}

DrawClickCircle(pBitmap, cx, cy, radius, argb, penW) {
    g := Gdip_GraphicsFromImage(pBitmap)
    DllCall("gdiplus\GdipSetSmoothingMode", "ptr", g, "int", 4)
    fill := (argb & 0x00FFFFFF) | 0x44000000
    brush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "uint", fill, "ptr*", &brush)
    DllCall("gdiplus\GdipFillEllipse", "ptr", g, "ptr", brush
        , "float", cx - radius, "float", cy - radius, "float", radius * 2, "float", radius * 2)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", brush)
    pen := 0
    DllCall("gdiplus\GdipCreatePen1", "uint", argb, "float", penW, "int", 2, "ptr*", &pen)
    DllCall("gdiplus\GdipDrawEllipse", "ptr", g, "ptr", pen
        , "float", cx - radius, "float", cy - radius, "float", radius * 2, "float", radius * 2)
    DllCall("gdiplus\GdipDeletePen", "ptr", pen)
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", g)
}

OpenEditor(dir) {
    GM.SessionDir := dir
    LoadSession(dir)
    if GM.Frames.Length = 0 {
        ShowTip("No pictures in folder")
        return
    }
    GM.Editor := Editor()
    GM.Editor.Show()
    GM.EditorOpen := true
}

SaveSession() {
    if !GM.SessionDir
        return
    ini := GM.SessionDir "\session.ini"
    try FileDelete(ini)
    IniWrite(GM.SessionName, ini, "session", "name")
    IniWrite(GM.Frames.Length, ini, "session", "count")
    for i, f in GM.Frames {
        sec := "frame" i
        IniWrite(f.file, ini, sec, "file")
        IniWrite(f.delay, ini, sec, "delay")
        IniWrite(f.anns.Length, ini, sec, "annCount")
        for j, a in f.anns {
            asec := sec "_ann" j
            IniWrite(a.type, ini, asec, "type")
            IniWrite(Format("0x{:08X}", a.color), ini, asec, "color")
            switch a.type {
                case "arrow":
                    IniWrite(a.x1, ini, asec, "x1")
                    IniWrite(a.y1, ini, asec, "y1")
                    IniWrite(a.x2, ini, asec, "x2")
                    IniWrite(a.y2, ini, asec, "y2")
                case "circle":
                    IniWrite(a.x, ini, asec, "x")
                    IniWrite(a.y, ini, asec, "y")
                    IniWrite(a.r, ini, asec, "r")
                case "text":
                    IniWrite(a.x, ini, asec, "x")
                    IniWrite(a.y, ini, asec, "y")
                    IniWrite(a.size, ini, asec, "size")
                    IniWrite(EncodeText(a.text), ini, asec, "text")
            }
        }
    }
}

LoadSession(dir) {
    ini := dir "\session.ini"
    GM.Frames := []
    if !FileExist(ini) {
        loop files dir "\frame_*.png" {
            name := A_LoopFileName
            if InStr(name, "_original") || name = "_preview.png"
                continue
            GM.Frames.Push({file: name, delay: GM.DefaultDelay, anns: []})
        }
        return
    }
    GM.SessionName := IniRead(ini, "session", "name", "tutorial")
    count := ToInt(IniRead(ini, "session", "count", "0"))
    loop count {
        sec := "frame" A_Index
        file := IniRead(ini, sec, "file", "")
        if !file
            continue
        delay := ToInt(IniRead(ini, sec, "delay", GM.DefaultDelay), GM.DefaultDelay)
        anns := []
        annCount := ToInt(IniRead(ini, sec, "annCount", "0"))
        loop annCount {
            asec := sec "_ann" A_Index
            type := IniRead(ini, asec, "type", "")
            color := ToInt(IniRead(ini, asec, "color", "0xFFFF3333"), 0xFFFF3333)
            switch type {
                case "arrow":
                    anns.Push({
                        type: "arrow",
                        color: color,
                        x1: Number(IniRead(ini, asec, "x1", 0)),
                        y1: Number(IniRead(ini, asec, "y1", 0)),
                        x2: Number(IniRead(ini, asec, "x2", 0)),
                        y2: Number(IniRead(ini, asec, "y2", 0))
                    })
                case "circle":
                    anns.Push({
                        type: "circle",
                        color: color,
                        x: Number(IniRead(ini, asec, "x", 0)),
                        y: Number(IniRead(ini, asec, "y", 0)),
                        r: Number(IniRead(ini, asec, "r", 20))
                    })
                case "text":
                    anns.Push({
                        type: "text",
                        color: color,
                        x: Number(IniRead(ini, asec, "x", 0)),
                        y: Number(IniRead(ini, asec, "y", 0)),
                        size: Number(IniRead(ini, asec, "size", 28)),
                        text: DecodeText(IniRead(ini, asec, "text", ""))
                    })
            }
        }
        GM.Frames.Push({file: file, delay: delay, anns: anns})
    }
}

EncodeText(s) {
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, "`r`n", "\n")
    s := StrReplace(s, "`n", "\n")
    return s
}

DecodeText(s) {
    s := StrReplace(s, "\n", "`n")
    s := StrReplace(s, "\\", "\")
    return s
}

OriginalPath(file) {
    SplitPath(file, , , &ext, &noext)
    return GM.SessionDir "\" noext "_original." ext
}

EnsureOriginal(file) {
    orig := OriginalPath(file)
    src := GM.SessionDir "\" file
    if !FileExist(orig) && FileExist(src)
        FileCopy(src, orig, true)
    return orig
}

Editor_OnDown(wParam, lParam, msg, hwnd) {
    if GM.EditorOpen && GM.Editor
        GM.Editor.OnDown(hwnd)
}

Editor_OnUp(wParam, lParam, msg, hwnd) {
    if GM.EditorOpen && GM.Editor
        GM.Editor.OnUp()
}

Editor_OnMove(wParam, lParam, msg, hwnd) {
    if GM.EditorOpen && GM.Editor
        GM.Editor.OnMove()
}

class Editor {
    gui := 0
    pic := 0
    list := 0
    delayEdit := 0
    status := 0
    index := 1
    tool := "arrow"
    color := 0xFFFF3333
    dragging := false
    dragX := 0
    dragY := 0
    scale := 1
    imgW := 1
    imgH := 1
    previewPath := ""
    previewMax := 640

    Show() {
        this.previewPath := GM.SessionDir "\_preview.png"
        this.gui := Gui("+OwnDialogs", "Tutorial GIF Editor")
        this.gui.SetFont("s10", "Segoe UI")
        this.gui.OnEvent("Close", (*) => this.Close())
        this.gui.OnEvent("Escape", (*) => this.Close())

        this.pic := this.gui.Add("Picture", "x16 y16 w640 h640 0x100")
        this.gui.Add("Text", "x672 y16 w280", "Frames")
        this.list := this.gui.Add("ListBox", "x672 y40 w280 h240")
        this.list.OnEvent("Change", (*) => this.SelectFromList())

        this.gui.Add("Button", "x672 y292 w86 h28", "Move up").OnEvent("Click", (*) => this.Move(-1))
        this.gui.Add("Button", "x766 y292 w86 h28", "Move down").OnEvent("Click", (*) => this.Move(1))
        this.gui.Add("Button", "x860 y292 w86 h28", "Delete").OnEvent("Click", (*) => this.DeleteFrame())

        this.gui.Add("Text", "x672 y336 w80 h24 +0x200", "Delay ms")
        this.delayEdit := this.gui.Add("Edit", "x760 y336 w100 h24 Number", GM.DefaultDelay)
        this.gui.Add("UpDown", "Range50-60000", GM.DefaultDelay)
        this.delayEdit.OnEvent("Change", (*) => this.ApplyDelay())

        this.gui.Add("Text", "x672 y376 w280", "Draw on selected frame")
        this.gui.Add("Button", "x672 y400 w86 h28", "Arrow").OnEvent("Click", (*) => this.SetTool("arrow"))
        this.gui.Add("Button", "x766 y400 w86 h28", "Circle").OnEvent("Click", (*) => this.SetTool("circle"))
        this.gui.Add("Button", "x860 y400 w86 h28", "Text").OnEvent("Click", (*) => this.SetTool("text"))

        this.gui.Add("Text", "x672 y440 w280", "Color")
        this.gui.Add("Button", "x672 y464 w50 h28", "Red").OnEvent("Click", (*) => this.SetColor(0xFFFF3333))
        this.gui.Add("Button", "x728 y464 w50 h28", "Blue").OnEvent("Click", (*) => this.SetColor(0xFF1E90FF))
        this.gui.Add("Button", "x784 y464 w50 h28", "Yellow").OnEvent("Click", (*) => this.SetColor(0xFFFFCC00))
        this.gui.Add("Button", "x840 y464 w50 h28", "White").OnEvent("Click", (*) => this.SetColor(0xFFFFFFFF))
        this.gui.Add("Button", "x896 y464 w56 h28", "Black").OnEvent("Click", (*) => this.SetColor(0xFF111111))

        this.gui.Add("Button", "x672 y512 w280 h32", "Reset drawings on this frame").OnEvent("Click", (*) => this.ResetDrawings())
        this.gui.Add("Button", "x672 y556 w280 h40", "Create GIF").OnEvent("Click", (*) => this.CreateGif())
        this.gui.Add("Button", "x672 y604 w280 h32", "Open folder").OnEvent("Click", (*) => Run('explorer.exe "' GM.SessionDir '"'))

        this.status := this.gui.Add("Text", "x16 y668 w936 h24", "Arrow tool — drag on the picture. Default delay 2000 ms.")

        this.RefreshList(1)
        this.gui.Show("w976 h708")
        this.SetTool("arrow")
    }

    Close() {
        SaveSession()
        if this.previewPath && FileExist(this.previewPath)
            try FileDelete(this.previewPath)
        GM.EditorOpen := false
        GM.Editor := 0
        if this.gui
            this.gui.Destroy()
        this.gui := 0
    }

    SetTool(name) {
        this.tool := name
        label := Map("arrow", "Arrow — drag from tail to head", "circle", "Circle — drag from center"
            , "text", "Text — click where the label should go")
        this.status.Text := label.Has(name) ? label[name] : name
    }

    SetColor(argb) {
        this.color := argb
        this.status.Text := "Color updated"
    }

    ListIndex() {
        return SendMessage(0x188, 0, 0, this.list) + 1
    }

    RefreshList(choose := 0) {
        if choose
            this.index := choose
        this.index := Min(Max(this.index, 1), Max(GM.Frames.Length, 1))
        this.list.Delete()
        for i, f in GM.Frames
            this.list.Add([Format("{}. {}   {} ms", i, f.file, f.delay)])
        if GM.Frames.Length
            this.list.Choose(this.index)
        this.LoadCurrent()
    }

    SelectFromList() {
        this.index := this.ListIndex()
        this.LoadCurrent()
    }

    LoadCurrent() {
        if this.index < 1 || this.index > GM.Frames.Length
            return
        f := GM.Frames[this.index]
        this.delayEdit.Value := f.delay
        path := GM.SessionDir "\" f.file
        BakeFrame(this.index)
        this.ShowImage(path)
    }

    ShowImage(path) {
        if !FileExist(path)
            return
        pBmp := Gdip_LoadImage(path)
        this.imgW := Gdip_GetWidth(pBmp)
        this.imgH := Gdip_GetHeight(pBmp)
        Gdip_DisposeImage(pBmp)
        this.scale := Min(this.previewMax / this.imgW, this.previewMax / this.imgH)
        dw := Max(1, Round(this.imgW * this.scale))
        dh := Max(1, Round(this.imgH * this.scale))
        this.pic.Move(16, 16, dw, dh)
        this.pic.Value := ""
        this.pic.Value := path
    }

    ApplyDelay() {
        if this.index < 1 || this.index > GM.Frames.Length
            return
        val := ToInt(this.delayEdit.Value, GM.DefaultDelay)
        if val < 50
            val := 50
        GM.Frames[this.index].delay := val
        SaveSession()
        cur := this.index
        this.list.Delete()
        for i, f in GM.Frames
            this.list.Add([Format("{}. {}   {} ms", i, f.file, f.delay)])
        this.list.Choose(cur)
    }

    Move(dir) {
        i := this.index
        j := i + dir
        if j < 1 || j > GM.Frames.Length
            return
        tmp := GM.Frames[i]
        GM.Frames[i] := GM.Frames[j]
        GM.Frames[j] := tmp
        SaveSession()
        this.RefreshList(j)
    }

    DeleteFrame() {
        if GM.Frames.Length <= 1 {
            MsgBox("Keep at least one frame, or close and start a new recording.", "Tutorial GIF Maker")
            return
        }
        GM.Frames.RemoveAt(this.index)
        SaveSession()
        this.RefreshList(Min(this.index, GM.Frames.Length))
    }

    ResetDrawings() {
        f := GM.Frames[this.index]
        orig := OriginalPath(f.file)
        dst := GM.SessionDir "\" f.file
        if FileExist(orig)
            FileCopy(orig, dst, true)
        f.anns := []
        SaveSession()
        this.ShowImage(dst)
        this.status.Text := "Drawings cleared — original kept as *_original.png"
    }

    PicPos(&x, &y) {
        if !this.gui || !this.MouseOnPic() {
            x := 0, y := 0
            return false
        }
        pt := Buffer(8)
        DllCall("GetCursorPos", "ptr", pt)
        DllCall("ScreenToClient", "ptr", this.pic.Hwnd, "ptr", pt)
        px := NumGet(pt, 0, "int")
        py := NumGet(pt, 4, "int")
        x := px / this.scale
        y := py / this.scale
        return true
    }

    MouseOnPic() {
        if !this.pic
            return false
        MouseGetPos(, , , &ctrl, 2)
        return ctrl = this.pic.Hwnd
    }

    OnDown(hwnd) {
        if !this.gui
            return
        if !this.PicPos(&x, &y)
            return
        if this.tool = "text" {
            this.gui.Opt("+OwnDialogs")
            ib := InputBox("Text to add to this frame:", "Add text", "w360 h140")
            if ib.Result = "OK" && ib.Value != ""
                this.AddAnn({type: "text", x: x, y: y, size: 28, text: ib.Value, color: this.color})
            return
        }
        this.dragging := true
        this.dragX := x
        this.dragY := y
    }

    OnMove() {
        if !this.dragging
            return
        if !this.PicPos(&x, &y)
            return
        this.PreviewTemp(x, y)
    }

    OnUp() {
        if !this.dragging
            return
        this.dragging := false
        if !this.PicPos(&x, &y) {
            this.LoadCurrent()
            return
        }
        if this.tool = "arrow" {
            this.AddAnn({type: "arrow", x1: this.dragX, y1: this.dragY, x2: x, y2: y, color: this.color})
        } else if this.tool = "circle" {
            r := Dist(this.dragX, this.dragY, x, y)
            if r < 4
                r := 4
            this.AddAnn({type: "circle", x: this.dragX, y: this.dragY, r: r, color: this.color})
        }
    }

    PreviewTemp(x, y) {
        extra := 0
        if this.tool = "arrow"
            extra := {type: "arrow", x1: this.dragX, y1: this.dragY, x2: x, y2: y, color: this.color}
        else if this.tool = "circle" {
            r := Dist(this.dragX, this.dragY, x, y)
            extra := {type: "circle", x: this.dragX, y: this.dragY, r: Max(r, 4), color: this.color}
        }
        BakeFrame(this.index, extra, this.previewPath)
        this.pic.Value := ""
        this.pic.Value := this.previewPath
    }

    AddAnn(ann) {
        EnsureOriginal(GM.Frames[this.index].file)
        GM.Frames[this.index].anns.Push(ann)
        SaveSession()
        BakeFrame(this.index)
        this.ShowImage(GM.SessionDir "\" GM.Frames[this.index].file)
        this.status.Text := "Saved drawing (original kept as *_original.png)"
    }

    CreateGif() {
        this.ApplyDelay()
        SaveSession()
        jobPath := GM.SessionDir "\gif_job.json"
        outGif := GM.SessionDir "\" GM.SessionName ".gif"
        json := '{`n  "output": "' EscapeJson(outGif) '",`n  "frames": [`n'
        loop GM.Frames.Length {
            f := GM.Frames[A_Index]
            BakeFrame(A_Index)
            path := GM.SessionDir "\" f.file
            json .= '    {"path": "' EscapeJson(path) '", "delayMs": ' f.delay '}'
            json .= (A_Index < GM.Frames.Length) ? ",`n" : "`n"
        }
        json .= "  ]`n}`n"
        try FileDelete(jobPath)
        FileAppend(json, jobPath, "UTF-8-RAW")

        ShowTip("Creating GIF")
        this.status.Text := "Creating GIF..."
        ps := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
        script := A_ScriptDir "\Create-Gif.ps1"
        log := GM.SessionDir "\gif_log.txt"
        cmd := Format(
            '{1} /c ""{2}" -NoProfile -ExecutionPolicy Bypass -File "{3}" -Job "{4}" > "{5}" 2>&1"',
            A_ComSpec, ps, script, jobPath, log)
        this.gui.Opt("+Disabled")
        exitCode := RunWait(cmd, GM.SessionDir, "Hide")
        this.gui.Opt("-Disabled")
        HideTip()

        if exitCode != 0 || !FileExist(outGif) {
            detail := FileExist(log) ? FileRead(log) : "No log."
            MsgBox("GIF creation failed.`n`n" detail, "Tutorial GIF Maker", "Iconx")
            this.status.Text := "GIF failed"
            return
        }
        this.status.Text := "GIF created: " GM.SessionName ".gif"
        ShowTip("Creating GIF — done")
        Run('"' outGif '"')
    }
}

BakeFrame(index, extra := 0, dest := "") {
    f := GM.Frames[index]
    orig := OriginalPath(f.file)
    src := FileExist(orig) ? orig : (GM.SessionDir "\" f.file)
    if dest = ""
        dest := GM.SessionDir "\" f.file
    pBmp := Gdip_LoadImage(src)
    anns := f.anns.Clone()
    if extra
        anns.Push(extra)
    for a in anns
        DrawAnnotation(pBmp, a)
    Gdip_SavePng(pBmp, dest)
    Gdip_DisposeImage(pBmp)
}

DrawAnnotation(pBitmap, a) {
    g := Gdip_GraphicsFromImage(pBitmap)
    DllCall("gdiplus\GdipSetSmoothingMode", "ptr", g, "int", 4)
    DllCall("gdiplus\GdipSetTextRenderingHint", "ptr", g, "int", 4)
    switch a.type {
        case "arrow":
            DrawArrow(g, a.x1, a.y1, a.x2, a.y2, a.color)
        case "circle":
            pen := 0
            DllCall("gdiplus\GdipCreatePen1", "uint", a.color, "float", 6, "int", 2, "ptr*", &pen)
            DllCall("gdiplus\GdipDrawEllipse", "ptr", g, "ptr", pen
                , "float", a.x - a.r, "float", a.y - a.r, "float", a.r * 2, "float", a.r * 2)
            DllCall("gdiplus\GdipDeletePen", "ptr", pen)
        case "text":
            DrawOutlinedText(g, a.text, a.x, a.y, a.size, a.color)
    }
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", g)
}

DrawArrow(g, x1, y1, x2, y2, argb) {
    pen := 0
    DllCall("gdiplus\GdipCreatePen1", "uint", argb, "float", 6, "int", 2, "ptr*", &pen)
    DllCall("gdiplus\GdipSetPenEndCap", "ptr", pen, "int", 2)
    DllCall("gdiplus\GdipDrawLine", "ptr", g, "ptr", pen, "float", x1, "float", y1, "float", x2, "float", y2)
    ang := ATan2(y2 - y1, x2 - x1)
    head := 22
    spread := 0.45
    ax1 := x2 - head * Cos(ang - spread)
    ay1 := y2 - head * Sin(ang - spread)
    ax2 := x2 - head * Cos(ang + spread)
    ay2 := y2 - head * Sin(ang + spread)
    DllCall("gdiplus\GdipDrawLine", "ptr", g, "ptr", pen, "float", x2, "float", y2, "float", ax1, "float", ay1)
    DllCall("gdiplus\GdipDrawLine", "ptr", g, "ptr", pen, "float", x2, "float", y2, "float", ax2, "float", ay2)
    DllCall("gdiplus\GdipDeletePen", "ptr", pen)
}

DrawOutlinedText(g, text, x, y, size, argb) {
    family := 0
    font := 0
    format := 0
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", "Segoe UI", "ptr", 0, "ptr*", &family)
    DllCall("gdiplus\GdipCreateFont", "ptr", family, "float", size, "int", 1, "int", 2, "ptr*", &font)
    DllCall("gdiplus\GdipCreateStringFormat", "int", 0, "ushort", 0, "ptr*", &format)
    outline := IsLight(argb) ? 0xFF111111 : 0xFFFFFFFF
    rect := Buffer(16)
    for dx in [-2, 0, 2] {
        for dy in [-2, 0, 2] {
            if dx = 0 && dy = 0
                continue
            NumPut("float", x + dx, "float", y + dy, "float", 2000, "float", 400, rect)
            brush := 0
            DllCall("gdiplus\GdipCreateSolidFill", "uint", outline, "ptr*", &brush)
            DllCall("gdiplus\GdipDrawString", "ptr", g, "wstr", text, "int", -1, "ptr", font, "ptr", rect, "ptr", format, "ptr", brush)
            DllCall("gdiplus\GdipDeleteBrush", "ptr", brush)
        }
    }
    NumPut("float", x, "float", y, "float", 2000, "float", 400, rect)
    brush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "uint", argb, "ptr*", &brush)
    DllCall("gdiplus\GdipDrawString", "ptr", g, "wstr", text, "int", -1, "ptr", font, "ptr", rect, "ptr", format, "ptr", brush)
    DllCall("gdiplus\GdipDeleteBrush", "ptr", brush)
    DllCall("gdiplus\GdipDeleteStringFormat", "ptr", format)
    DllCall("gdiplus\GdipDeleteFont", "ptr", font)
    DllCall("gdiplus\GdipDeleteFontFamily", "ptr", family)
}

IsLight(argb) {
    r := (argb >> 16) & 0xFF
    gv := (argb >> 8) & 0xFF
    b := argb & 0xFF
    return (r * 0.3 + gv * 0.59 + b * 0.11) > 150
}

ATan2(y, x) {
    return DllCall("msvcrt\atan2", "double", y, "double", x, "cdecl double")
}

Dist(x1, y1, x2, y2) {
    return Sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
}

EscapeJson(s) {
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, '"', '\"')
    return s
}

ToInt(v, fallback := 0) {
    try
        return Integer(v)
    catch
        return fallback
}

ShowTip(text) {
    ToolTip(text)
    SetTimer(HideTip, -1600)
}

HideTip(*) {
    ToolTip()
}

Gdip_Startup() {
    si := Buffer(32, 0)
    NumPut("uint", 1, si, 0)
    token := 0
    if DllCall("gdiplus\GdiplusStartup", "ptr*", &token, "ptr", si, "ptr", 0)
        throw Error("GDI+ failed to start")
    GM.GdiToken := token
}

Gdip_CreateBitmapFromHBITMAP(hbm) {
    pBitmap := 0
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hbm, "ptr", 0, "ptr*", &pBitmap)
    return pBitmap
}

Gdip_LoadImage(path) {
    pBitmap := 0
    DllCall("gdiplus\GdipLoadImageFromFile", "wstr", path, "ptr*", &pBitmap)
    return pBitmap
}

Gdip_GetWidth(pBitmap) {
    w := 0
    DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap, "uint*", &w)
    return w
}

Gdip_GetHeight(pBitmap) {
    h := 0
    DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap, "uint*", &h)
    return h
}

Gdip_GraphicsFromImage(pBitmap) {
    g := 0
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pBitmap, "ptr*", &g)
    return g
}

Gdip_SavePng(pBitmap, path) {
    clsid := Buffer(16)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid, "hresult")
    DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", path, "ptr", clsid, "ptr", 0)
}

Gdip_DisposeImage(pBitmap) {
    if pBitmap
        DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
}

Cleanup(*) {
    if GM.GdiToken
        DllCall("gdiplus\GdiplusShutdown", "ptr", GM.GdiToken)
}
