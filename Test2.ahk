#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1


SplashScreenCreate("NFS Notes", "v1.0", "Script is starting...", "Automation - Efficiency - Accuracy", 5000)


SplashScreenCreate(title, version, message, tagline := "", duration := 3000) {

    SysGet, MonitorWorkArea, MonitorWorkArea
    screenWidth := MonitorWorkAreaRight - MonitorWorkAreaLeft
    screenHeight := MonitorWorkAreaBottom - MonitorWorkAreaTop
    

    Gui, Splash:New, +AlwaysOnTop +ToolWindow -SysMenu -Caption +Border
    Gui, Splash:Color, cddbf9
    

    Gui, Splash:Font, s16 bold, Arial
    Gui, Splash:Add, Text, x60 y10 w300 Center, %title%


    Gui, Splash:Font, s10 normal, Arial
    Gui, Splash:Add, Text, x60 y40 w300 Center, %version%
    

    Gui, Splash:Add, Text, x10 y65 w300 h1 0x10 Center, 
    

    Gui, Splash:Font, s10, Arial
    Gui, Splash:Add, Text, x60 y75 w300 Center, %message%
    
    if (tagline != "") {
        Gui, Splash:Font, s9 italic, Arial
        Gui, Splash:Add, Text, x60 y100 w300 Center cBlue, %tagline%
    }
    Gui, Splash:Add, Picture, x10 y20, spectrum.png

    Gui, Splash:Show, Hide, Splash Screen
    Gui, Splash:+LastFound
    WinGetPos,,, width, height
    xPos := (screenWidth - width) / 2
    yPos := (screenHeight - height) / 2
    
    Gui, Splash:Show, x%xPos% y%yPos% w320 h140, Splash Screen
    
    SetTimer, CloseSplash, %duration%
    return
    
    CloseSplash:
        Gui, Splash:Destroy
        SetTimer, CloseSplash, Off
        return
}