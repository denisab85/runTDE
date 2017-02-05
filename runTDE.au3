#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GUIListView.au3>
#include <File.au3>
#include <Array.au3>
#include <String.au3>
#include <GuiStatusBar.au3>
#include <FileConstants.au3>
#include <GuiComboBox.au3>

#AutoIt3Wrapper_icon=D:\Soft\LdxCmd.ico

Global $subkey, $DisplayVersion, $RootKey, $DisplayName, $InstallLocation, $VersionCount, $ListItemStr, $ProjectPath, $iDouble_Click_Event, $Param, $ShortVersion
Dim $MainWnd
Dim $szDrive, $szDir, $szFName, $szExt
Global $iDouble_Click_Event = False
$ShortVersion = ""
$iDouble_Click_Event = 0

Global $VersionList[256][4]
$sIni_File = ".\runTDE.ini"

Func PopulateTable($_listView)
   ; Populate ListView with TDE items
   $VersionCount = 0
   $i = 0
   $RootKey = "HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

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
			   $UninstallString = RegRead ($RootKey & "\" & $subkey, "UninstallString")
			   If FileExists($InstallLocation & "LdxTDE.exe") Then
				  $VersionList[$VersionCount][0] = $DisplayName
				  $VersionList[$VersionCount][1] = $DisplayVersion
				  $VersionList[$VersionCount][2] = $InstallLocation
				  $VersionList[$VersionCount][3] = $UninstallString
				  $VersionCount += 1
			   EndIf
			EndIf
		 EndIf
	  EndIf
   WEnd

   ;MsgBox(0, "Found", "Items found: " & $VersionCount & ". Cleaning table...")

   _GUICtrlListView_DeleteAllItems ($_listView)

   ;MsgBox(0, "Cleaned", "Table cleaned. Populating...")

   For $i = 0 To $VersionCount-1
	  $ListItemStr = ""
	  For $j = 0 To 3
		 $ListItemStr = $ListItemStr & $VersionList[$i][$j] & "|"
	  Next
	  GUICtrlCreateListViewItem ($ListItemStr, $_listView)
	  ConsoleWrite($ListItemStr & @CRLF)
   Next
   ; Sort ListView
   _GUICtrlListView_SimpleSort($_listView, False, 1)
EndFunc



; GUI

; Main window
$MainWnd = GUICreate("Choose the TDE version you want to use", 540, 300, @DesktopWidth/2 - 225, @DesktopHeight/2 - 150, $WS_SIZEBOX + $WS_MAXIMIZEBOX + $WS_MINIMIZEBOX, $WS_EX_ACCEPTFILES)
GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
GUISetOnEvent($GUI_EVENT_DROPPED, "Exit")

; Buttons
Local $btnDelete = GUICtrlCreateButton("Delete selected", 5, 5, 85, 25)
Local $btnDnlInst = GUICtrlCreateButton("Downld + Install", 105, 5, 85, 25)

; ListView
$ListView = GUICtrlCreateListView("Name|Version|Install Location|UninstallString|", 5, 35, 530, 240, $LVS_NOSORTHEADER + $LVS_SINGLESEL, $LVS_EX_CHECKBOXES + $LVS_EX_FULLROWSELECT + $LVS_EX_GRIDLINES )
GUICtrlSetState(-1, $GUI_DROPACCEPTED)
_GUICtrlListView_SetColumnWidth($ListView, 0, 250)
_GUICtrlListView_SetColumnWidth($ListView, 1, 80)
_GUICtrlListView_SetColumnWidth($ListView, 2, 350)

; Status window
$statusBar = GUICtrlCreateLabel ("Double-click the version to TDE. Use checkboxes to delete ", 200, 10, 336, 16)


PopulateTable($ListView)

GUISetState()

While 1
   Switch GUIGetMsg()
	  Case $GUI_EVENT_CLOSE
		 Exit
	  Case $btnDelete
		 ; Delete selected items silently
		 For $x = 0 To _GUICtrlListView_GetItemCount ($ListView) - 1
			If _GUICtrlListView_GetItemChecked($ListView, $x) Then
			   Local $UninstallString = _GUICtrlListView_GetItemTextArray($ListView, $x)[4]
			   If StringLeft($UninstallString, 15) = "MsiExec.exe /I{" Then
				  ;MsgBox(0, "Uninstalling", "Uninstalling " & _GUICtrlListView_GetItemTextArray($ListView, $x)[1])
				  $iPID = RunWait($UninstallString & " /qn REMOVE=ALL", "", @SW_HIDE)
				  ;MsgBox(0, "Uninstall finished", "Uninstall finished")
			   EndIf
			EndIf
		 Next
		 PopulateTable($ListView)

	  Case $btnDnlInst
		 Download ()

	  Case $GUI_EVENT_DROPPED
		 $file = @GUI_DragFile
		 ConsoleWrite($file & @CRLF)
		 Install ($file)
		 PopulateTable($ListView)

   EndSwitch

   If $iDouble_Click_Event Then
	  $iDouble_Click_Event = 0
	  $iIndex = _GUICtrlListView_GetSelectedIndices($ListView)
	  If $iIndex >= 0 Then
		 Run_TDE ()
	  EndIf
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


Func Run_TDE ()
   $InstallLocation = _GUICtrlListView_GetItemTextArray($ListView)[3]
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


Func Install ($filePath)
   Local $sDrive, $sDir, $sFileName, $sExtension
   _PathSplit ( $filePath, $sDrive, $sDir, $sFileName, $sExtension )
   GUICtrlSetData($statusBar, "Installing: " & $sFileName)
   Run($filePath)
   Local $stage = "Welcome"
   ConsoleWrite("Stage: " & $stage & @CRLF)
   Local $hWnd = WinWait("Load DynamiX TDE", $stage)
   ;Sleep(1000)
   WinActivate($hWnd)
   ;Sleep(1000)
   $version = WinGetTitle ("Load DynamiX TDE", "Welcome")
   ConsoleWrite("	Version installed: " & $version & @CRLF)
   ControlClick("Load DynamiX TDE", $stage, "Button1")

   $stage = "Configure Shortcuts"
   ConsoleWrite("Stage: " & $stage & @CRLF)
   $hWnd = WinWait("Load DynamiX TDE", $stage)
   WinActivate($hWnd)
   ControlClick("Load DynamiX TDE", $stage, "Button4")
   ControlClick("Load DynamiX TDE", $stage, "Button5")
   ControlClick("Load DynamiX TDE", $stage, "Button1")

   $stage = "End User License Agreement"
   ConsoleWrite("Stage: " & $stage & @CRLF)
   $hWnd = WinWait("Load DynamiX TDE", $stage)
   WinActivate($hWnd)
   ControlClick("Load DynamiX TDE", $stage, "Button4")
   ControlClick("Load DynamiX TDE", $stage, "Button1")

   $stage = "Select Installation Folder"
   ConsoleWrite("Stage: " & $stage & @CRLF)
   $hWnd = WinWait("Load DynamiX TDE", $stage)
   WinActivate($hWnd)
   $path = ControlGetText($hWnd, "", "Edit1")
   $path = $path & $version
   ConsoleWrite("	Installation path: " & $path & @CRLF)
   ControlFocus ($hWnd, "", "Edit1")
   $result = ControlSetText("Load DynamiX TDE", $stage, "Edit1", $path)
   ConsoleWrite("	Result: " & $result & @CRLF)
   ControlClick("Load DynamiX TDE", $stage, "Button1")

   $stage = "Upgrade Older Versions"
   ConsoleWrite("Stage: " & $stage & @CRLF)
   $hWnd = WinWait("Load DynamiX TDE", $stage)
   WinActivate($hWnd)
   ControlClick("Load DynamiX TDE", $stage, "Button6")
   ControlClick("Load DynamiX TDE", $stage, "Button1")

   $stage = 'Click "Install" to begin the installation'
   ConsoleWrite("Stage: " & $stage & @CRLF)
   $hWnd = WinWait("Load DynamiX TDE", $stage)
   WinActivate($hWnd)
   ControlClick("Load DynamiX TDE", $stage, "Button1")

   $stage = "Completing the Load DynamiX TDE"
   ConsoleWrite("Stage: " & $stage & @CRLF)
   $hWnd = WinWait("Load DynamiX TDE", $stage)
   WinActivate($hWnd)
   ControlClick("Load DynamiX TDE", $stage, "Button1")

   GUICtrlSetData($statusBar, "Installation finished.")
EndFunc


Func _UnicodeURLDecode($toDecode)
    Local $strChar = "", $iOne, $iTwo
    Local $aryHex = StringSplit($toDecode, "")
    For $i = 1 To $aryHex[0]
        If $aryHex[$i] = "%" Then
            $i = $i + 1
            $iOne = $aryHex[$i]
            $i = $i + 1
            $iTwo = $aryHex[$i]
            $strChar = $strChar & Chr(Dec($iOne & $iTwo))
        Else
            $strChar = $strChar & $aryHex[$i]
        EndIf
    Next
    $Process = StringToBinary (StringReplace($strChar, "+", " "))
    $DecodedString = BinaryToString ($Process, 4)
    Return $DecodedString
EndFunc   ;==>_UnicodeURLDecode


Func FileNameFormURI($uri)
   $split = StringSplit($uri, "/")
   $name = $split[$split[0]]
   $name = _UnicodeURLDecode($name)
   Return $name
EndFunc


Func _GetURI($uri, $filepath)
   ProgressOn("Download", "Downloading...", "0%")
   $hInet = InetGet($uri, $filepath, 1, 1) ;Forces a reload from the remote site and return immediately and download in the background
   $FileSize = InetGetSize($uri) ;Get file size
   While Not InetGetInfo($hInet, 2) ;Loop until download is finished
	  Sleep(500) ;Sleep for half a second to avoid flicker in the progress bar
	  $BytesReceived = InetGetInfo($hInet, 0) ;Get bytes received
	  $Pct = Int($BytesReceived / $FileSize * 100) ;Calculate percentage
	  ProgressSet($Pct, $Pct & "%") ;Set progress bar
   WEnd
   ProgressOff()
EndFunc


Func Download()
   $popup = GUICreate("Download TDE", 400, 100, -1, -1, BitOR ($WS_DLGFRAME, $WS_SYSMENU, $WS_CAPTION), $WS_EX_TOPMOST)

   Local $Input = GUICtrlCreateInput("", 50, 5, 342, 20)
   Local $OKButton = GUICtrlCreateButton("OK", 50, 73, 80, 20)
   Local $Combo = GUICtrlCreateCombo("", 50, 40, 185, 20)
   Local $LabelURI = GUICtrlCreateLabel ("URI:", 5, 10, 26, 16)
   Local $LabelSaveTo = GUICtrlCreateLabel ("Save to:", 5, 45, 40, 16)

   ; Read the ini content
   Local $branchesRoot = IniRead($sIni_File, "Branches", "path", "." )
   Local $branchesDefault = IniRead($sIni_File, "Branches", "default", "MAIN" )

   $clpbd = ClipGet()
   if ( (StringRight($clpbd, 4) == ".exe") And ( (StringLeft($clpbd, 7) == "http://") Or (StringLeft($clpbd, 8) == "https://") Or (StringLeft($clpbd, 6) == "ftp://") ) ) Then
	  GUICtrlSetData($Input, $clpbd)
   EndIf

   if not FileExists ($branchesRoot) Then
	  MsgBox(0, "", "Folder does not exists: " & $branchesRoot)
	  Exit
   EndIf
   $sCombo_List = ""
   $FileList = _FileListToArray($branchesRoot, "*", $FLTA_FOLDERS)
   If @error = 1 Then
	  MsgBox(0, "", "No subfolders found in'" & $branchesRoot & "'")
	  Exit
   EndIf
   For $i = 1 To $FileList[0]
	  $sCombo_List &= "|" & $branchesRoot & $FileList[$i]
   Next

    GUICtrlSetData($Combo, $sCombo_List)

	_GUICtrlComboBox_SelectString($Combo, $branchesRoot & $branchesDefault)

   GUISetState()


   While 1
	  $msg2 = GUIGetMsg()
	  Select
	  Case $msg2 = $GUI_EVENT_CLOSE
			GUIDelete ($popup)
			;GUISetState(@SW_HIDE, $popup)
			ExitLoop
		 Case $msg2 = $OKButton
			$uri = GUICtrlRead($Input)
			$folder = _GUICtrlComboBox_GetEditText($Combo)
			$fileName = $folder & "\" & FileNameFormURI($uri)
			GUICtrlSetData($statusBar, "Downloading: " & $uri)
			_GetURI($uri, $fileName)
			GUICtrlSetData($statusBar, "Download finished.")

			if FileExists($fileName) Then
			   Install ($fileName)
			   PopulateTable($ListView)
			EndIf

			ExitLoop
		 Case Else
            ;;;
        EndSelect
   WEnd
   GUIDelete($popup)
EndFunc  ;==>_Input

