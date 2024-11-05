;SORRY MY BAD ENGLISH

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance Off ;MORE THAN ONE CLIENT INSTANCE
#Include %A_ScriptDir%\Scripts\Sockets.ahk

;GLOBAL VARS FOR PERSIST IN FUNCTIONS
global sServer, TEXT1, TEXT2, TEXT3, TEXT4, TEXT5, TEXT6, ParcialTCP

;ON EXIT CLOSE SOCKETS
OnExit, Exit

;INPUT FOR SERVER IP
InputBox, sServer, SERVER IP,,,,,,,,, %A_IPAddress1%

;REFRESH FOR SEND AND RECEIVE
SetTimer, RefreshSend, 5000
SetTimer, RefreshReceive, 100
gosub RefreshSend

;MY EXAMPLE GUI
GUI:
Gui, add, edit, w300 vTEXT1,
Gui, add, edit, w300 vTEXT2,
Gui, add, edit, w300 vTEXT3,
Gui, add, text, w300 vTEXT4,
Gui, add, text, w300 vTEXT5,
Gui, add, text, w300 vTEXT6,
Gui, add, text, w300 vsServer,
Gui, Show,, Client
return

;REFRESH THE RECEIVE AND GUI
RefreshReceive:
if sServer
	AHKsock_Connect(sServer, 65432, "TCPRECEIVE") ;CONNECT...
GuiControlGet, Text1,, Text1 ;GET TEXT IN EDITBOX 1
GuiControlGet, Text2,, Text2 ;GET TEXT IN EDITBOX 2
GuiControlGet, Text3,, Text3 ;GET TEXT IN EDITBOX 3
GuiControl,, Text4, %Text4% ;WRITE TEXT IN TEXT 1
GuiControl,, Text5, %Text5% ;WRITE TEXT IN TEXT 2
GuiControl,, Text6, %Text6% ;WRITE TEXT IN TEXT 3
GuiControl,, sServer, %sServer% ;WRITE SERVER IP IN TEXT 4
return

;REFRESH SEND (NOT NECESSARY TO RUN AWAYS (ONLY ONE), BUT DISCONECT AND RECONECT SOCKETS)
RefreshSend:
AHKsock_Close() ;CLOSE ALL CONECTIONS TWICE (REDUNDANCE)
AHKsock_Close()
ParcialTCP= ;NULL RECEIVER PARTIAL VAR
AHKsock_Listen(27014, "TCPSEND") ;START LISTEN...
return

;FUNCTION CALLED BY AHK_SOCK FOR SEND DATA
;SEND VARS SEPARATED BY | AND ALL VARS TERMINATOR IS `n
TCPSEND(sEvent, iSocket = 0, sName = 0, sAddr = 0, sPort = 0)
{
If (sEvent = "SEND") ;sEvent SEND START TRANSMISSION OF VARS
{
SendText= %TEXT1%|%TEXT2%|%TEXT3%|`n ;SEPARATED BY | AND TERMINATED BY `n
iLength:= StrLen(SendText) * 2 ;THE LENGHT OF STRING * 2
AHKsock_Send(iSocket, &SendText, iLength) ;SEND
AHKsock_Close(iSocket) ;CLOSE SOCKET
}
return
}

;FUNCTION CALLED BY AHK_SOCK FOR RECEIVE DATA
;PARSE bData TWO TIMES TO DETECT | (DELIMIT VARS) AND `n (MARK END OF ALL VARS)
TCPRECEIVE(sEvent, iSocket = 0, sName = 0, sAddr = 0, sPort = 0, ByRef bData = 0, iLength = 0)
{
	If (sEvent = "RECEIVED") ;sEvent RECEIVED: THE VARS ARE RECEIVED
	{
		ParcialTCP= %ParcialTCP%%bData% ;ADD bData AT END OF PARTIAL VAR
		Loop, Parse, ParcialTCP,| ;PARSE ParcialTCP TO SEARCH FOR TERMINATOS `n
		{
			if A_Index= 4 ;IF NUMBER OF VARS + 1 (`n POSITION)
			{
				if (A_LoopField = "`n") ;FOUND `n AFTER LAST VAR (REMEMBER HAVE 3 VARS)
				{
					Loop, Parse, ParcialTCP,| ;PARSE PARTIAL VAR TO SEPARATE RECEIVED VARS (TEXT4, TEXT5, TEXT6)
					{
						if A_Index= 1
							TEXT4= %A_LoopField%
						if A_Index= 2
							TEXT5= %A_LoopField%
						if A_Index= 3
							TEXT6= %A_LoopField%
					}
				}
			}
		}
		Loop, Parse, bData,`n
		{
			if A_Index= 2 ;IF HAVE ANY AFTER TERMINATOR `n, ADD TO PARTIAL VAR (AND RESET ParcialTCP)
				ParcialTCP= %A_LoopField%
		}
	}
    return
}

;EXIT CLOSE ALL SOCKETS
GuiClose:
Exit:
AHKsock_Close() ;REDUNDANT
AHKsock_Close()
ExitApp