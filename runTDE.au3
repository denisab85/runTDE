#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GUIListView.au3>
#include <file.au3>
#include <array.au3>
#include <String.au3>

#AutoIt3Wrapper_icon=D:\Soft\LdxCmd.ico

Global $subkey, $i, $DisplayVersion, $RootKey, $DisplayName, $InstallLocation, $VersionCount, $ListItemStr, $ProjectPath, $iDouble_Click_Event, $Param, $ShortVersion
Dim $MainWnd
Dim $szDrive, $szDir, $szFName, $szExt
Global $iDouble_Click_Event = False
$VersionCount = 0
$ShortVersion = ""
$iDouble_Click_Event = 0
$RootKey = "HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$i = 0
Global $VersionList[256][3]

While 1
   $i += 1
   $subkey = RegEnumKey($RootKey, $i)
   If $subkey == "" Then
	  ExitLoop
   Else
	  If StringRegExp($subkey, "\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\}$") Then
		 $DisplayName = RegRead ($RootKey & "\" & $subkey, "DisplayName")
		 If StringInStr ($DisplayName, "Load DynamiX TDE") Then
			$DisplayVersion = RegRead ($RootKey & "\" & $subkey, "DisplayVersion")
			$InstallLocation = RegRead ($RootKey & "\" & $subkey, "InstallLocation")
			If FileExists($InstallLocation & "LdxTDE.exe") Then
			   $VersionList[$VersionCount][0] = $DisplayName
			   $VersionList[$VersionCount][1] = $DisplayVersion
			   $VersionList[$VersionCount][2] = $InstallLocation
			   $VersionCount += 1
			EndIf
		 EndIf
	  EndIf
   EndIf
WEnd


; GUI

; Main window
$MainWnd = GUICreate("Choose the TDE version you want to use", 550, 300, @DesktopWidth/2 - 225, @DesktopHeight/2 - 150)
GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")

; ListView
$ListView = GUICtrlCreateListView("Name|Version|Install Location", 10, 10, 530, 280)
_GUICtrlListView_SetColumnWidth($ListView, 0, 250)
_GUICtrlListView_SetColumnWidth($ListView, 1, 80)
_GUICtrlListView_SetColumnWidth($ListView, 2, 350)
; ListView items
For $i = 0 To $VersionCount-1
   $ListItemStr = $VersionList[$i][0] & "|" & $VersionList[$i][1] & "|" & $VersionList[$i][2]
   GUICtrlCreateListViewItem ($ListItemStr, $ListView)
   ConsoleWrite($ListItemStr & @CRLF)
Next
; Sort ListView
_GUICtrlListView_SimpleSort($ListView, False, 1)

GUISetState()

While 1
   Switch GUIGetMsg()
	  Case $GUI_EVENT_CLOSE
		 Exit
   EndSwitch

   If $iDouble_Click_Event Then
	  $iDouble_Click_Event = 0
	  $iIndex = _GUICtrlListView_GetSelectedIndices($ListView)
	  Run_TDE ($iIndex)
   EndIf
WEnd

Func WM_NOTIFY($hWnd, $iMsg, $iwParam, $ilParam)
    Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR, $hWndListView = $ListView
    If Not IsHWnd($ListView) Then $hWndListView = GUICtrlGetHandle($ListView)

    $tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
    $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    $iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
    $iCode = DllStructGetData($tNMHDR, "Code")

    Switch $hWndFrom
        Case $hWndListView
            Switch $iCode
                Case $NM_DBLCLK
                    $iDouble_Click_Event = True
            EndSwitch
    EndSwitch

    Return $GUI_RUNDEFMSG
EndFunc

Func Run_TDE ($iIndex)
   ;$DisplayName     = $VersionList[$iIndex][0]
   ;$DisplayVersion  = $VersionList[$iIndex][1]
   ;$InstallLocation = $VersionList[$iIndex][2]
   $InstallLocation = _GUICtrlListView_GetItemTextArray($ListView)[3]
   MsgBox(0, "Information", $InstallLocation)
   ;$split = StringSplit($DisplayVersion, '.')
   ;If $split[0] > 2 Then
	;  $ShortVersion = $split[2]
	;  $ShortVersion = _StringInsert($ShortVersion, ".", 1)
   ;EndIf
   $Param = ""
   $ProjectFile = ""
   If UBound($cmdLine) > 1 Then
	  $Param = $cmdLine[1]
	  if FileExists($Param) Then
		 $TestPath = _PathSplit($Param, $szDrive, $szDir, $szFName, $szExt)
		 If $TestPath[4] == ".swift_test" Then
			$ProjectFile = '"' & $Param & '"'
		 EndIf
	  EndIf
   EndIf
   GUICtrlDelete ($ListView)

   ShellExecute ($InstallLocation & "LdxTDE.exe", $ProjectFile)
   Exit
EndFunc