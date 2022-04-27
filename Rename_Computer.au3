#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\icon.ico
#AutoIt3Wrapper_Outfile_x64=..\..\Builds\ImageCompletion\Rename_Computer_TimeoutTest.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Computer Rename Tool
#AutoIt3Wrapper_Res_Fileversion=2.0.0.27
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=Computer Rename Tool
#AutoIt3Wrapper_Res_ProductVersion=2.0.0.8
#AutoIt3Wrapper_Res_CompanyName=Ascanio.net
#AutoIt3Wrapper_Res_LegalCopyright=Copyright © 2022 Ascanio.net. All rights reserved.
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Run_After=ping 192.0.2.2 -n 1 -w 2000 > nul
#AutoIt3Wrapper_Run_After=C:\Tools\SysinternalsSuite\signtool.exe sign /fd sha256 "%outx64%"
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

AutoItSetOption("GUIOnEventMode", 1) ; 0=disabled, 1=OnEvent mode enabled
AutoItSetOption("TrayAutoPause", 0) ; 0=no pause, 1=Pause
AutoItSetOption("TrayIconHide", 0) ; 0=show, 1=hide tray icon
AutoItSetOption("TrayMenuMode", 1) ; 0=append, 1=no default menu, 2=no automatic check, 4=menuitemID  not return

Global $appPublisher = 'Ascanio.net' ;- Application Publisher (From Uninstall Key if Possible)
Global $appDisplayName = 'Device Rename Prompter' ;- Application Display Name (From Uninstall Key if Possible)
Global $appShortName = 'Rename_Computer' ;- Short Name for the application
Global $appVersion = '2.0.0.0' ;- Application Version (From Uninstall Key if Possible)
Global $appArch = 'x86_64' ;- Application Architecture (x86;x86_64)
Global $appLang = 'en-US' ;- Appication Language (en-US)
Global $appRevision = '' ;- Application Revision
Global $appScriptVersion = '1.0.0.0' ;- Script Version
Global $appScriptDate = '10-04-2017' ;- Script Date
Global $appScriptAuthor = 'Joseph Ascanio' ;- Script Author

#include <standard_functions.au3>
#include <GUIConstantsEx.au3>
#include <GDIPlus.au3>
#include <RenameComputer.au3>

$Result = Initialize()
If $DebugMode = 1 Then Logit($DEBUG, "Initialize returned " & $Result, "Main")

Global $objWMIService

;- Declare Variables Necessary for this action.
LogIt($INFORMATION, "Preparing GUI and Starting countdown Timer.", "MAIN")

If $DebugMode = 1 Then LogIt($DEBUG, "Extracting resource files to " & $TempDir, "MAIN")
FileInstall("C:\SourceControl\Programs\ImageCompletion\Resources\logo.png", $TempDir & '\', $FC_OVERWRITE)
FileInstall("C:\SourceControl\Programs\ImageCompletion\Resources\icon.ico", $TempDir & '\', $FC_OVERWRITE)
FileInstall("C:\SourceControl\Programs\ImageCompletion\Resources\CompleteImage.xml", $TempDir & '\', $FC_OVERWRITE)

If $DebugMode = 1 Then LogIt($DEBUG, "Declaring GUI variables.", "MAIN")
Global $png = $TempDir & '\logo.png'
Global $_Seconds, $_Minutes, $TimeMax = 3600000, $himage
Global $dev_Name_Prompt, $dev_Name_Label, $dev_Name_Input, $timer_Label, $timer
Global $TimeTicks, $Submit, $gen_Random_Name, $Logo, $dev_Name_Prompt_Complete, $countdown

;- Checking if the Asset tag is set in the BIOS
LogIt($INFORMATION, "Checking for the asset tag in the BIOS. If its set we will attempt to automatically name the device.", "Main")
Local $AssetTag = CheckAssetTag()
Local $Model = CheckModel()
Local $Manufacturer = CheckManufacturer()
Local $Battery = CheckBattery()

If $DebugMode = 1 Then LogIt($DEBUG, "$AssetTag = " & $AssetTag, 'Main')
If $AssetTag = 0 Then
	LogIt($WARNING, "Autonaming failed. Will display GUI for user interaction.", "Main")
Else
	LogIt($WARNING, "Asset tag discovered. Attempting to rename the computer automatically.", "Main")
	If $DebugMode = 1 Then LogIt($DEBUG, "$Model = " & $Model, 'Main')
	If $DebugMode = 1 Then LogIt($DEBUG, "$Manufacturer = " & $Manufacturer, 'Main')
	If $DebugMode = 1 Then LogIt($DEBUG, "$Battery = " & $Battery, 'Main')
	;- Checking the Model in WMI
	Local $Result = AutoRename($AssetTag, $Model, $Manufacturer, $Battery)
	If $Result = 1 Then
		If $DebugMode = 1 Then LogIT($DEBUG, "Sleeping for 2 seconds to allow changes to complete.", 'Main')
		Sleep(2000)

		$Result = ConfigureImageComplete()
		If $Result <> 1 Then
			MsgBox($MB_SYSTEMMODAL, "Configuring the Image Completion Task failed.", "When the system reboots, please execute the ImageComplete.exe from C:\ProgramData\ImageComplete\Temp. This will complete the process.")
		EndIf

		RunWait(@ComSpec & ' /c shutdown /r /t 30 /c "This computer is about to restart to complete the rename process." /f')

		;- Exit the Script
		ExitScript($mainReturnCode)
	Else
		LogIt($WARNING, "Autonaming failed. Will display GUI for user interaction.", "Main")
	EndIf
EndIf

LogIT($WARNING, "Could not find Asset Tag. Prompting User.", "Main")
If $DebugMode = 1 Then LogIt($DEBUG, "Countdown set to " & ($TimeMax / 1000) / 60 & " minutes.", "MAIN")

DisplayGUI()

;- While loopo
While 1
	$Result = _Check()
	If $Result = 1 Then
		$mainReturnCode = 0
		ExitLoop
	ElseIf $Result = 0 Then
		$mainReturnCode = 9000
		ExitLoop
	ElseIf $Result = 3 Then
		ContinueLoop
	EndIf
WEnd

If $mainReturnCode = 0 Then
	$Result = ConfigureImageComplete()
	If $Result <> 1 Then
		MsgBox($MB_SYSTEMMODAL, "Configuring the Image Completion Task failed.", "When the system reboots, please execute the ImageComplete.exe from C:\ProgramData\ImageComplete\Temp. This will complete the process.")
	EndIf

	RunWait(@ComSpec & ' /c shutdown /r /t 30 /c "This computer is about to restart to complete the rename process." /f')
EndIf

;- Exit the Script
ExitScript($mainReturnCode)

#comments-start FUNCTION: _Check
	#FUNCTION# ===========================================================================================================
	Name...........: _Check
	Description ...: This function acts as a countdown clock

	Syntax.........: _Check()
	Parameters ....: None

	Return values .: Success - 1 if submit was clicked
							3 if the timer is incrimented
					Failure - 0

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: _Check
Func _Check()
	$TimeMax -= TimerDiff($TimeTicks)
	$TimeTicks = TimerInit()
	Local $_MinCalc = Int($TimeMax / (60 * 1000)), $_SecCalc = $TimeMax - ($_MinCalc * 60 * 1000)
	$_SecCalc = Int($_SecCalc / 1000)
	;If $DebugMode = 1 Then LogIt($DEBUG, 'Current Timer Place: ' & $_MinCalc & ' : ' & $_SecCalc, '_Check') ;; Commented out so that we don't fill the log for eternity.
	If $_MinCalc = 0 And $_SecCalc = 0 Then
		If $DebugMode = 1 Then LogIt($DEBUG, 'Timer has reached 0. Forcing Rename Now.', '_Check')
		GUICtrlSetData($timer, StringFormat("%02u" & ":" & "%02u", $_MinCalc, $_SecCalc))
		Sleep(1000)

		$Result = submit()
		If $Result = 1 Then
			Return 1
		ElseIf $Result = 0 Then
			Return 0
		EndIf
	Else
		If $_MinCalc <> $_Minutes Or $_SecCalc <> $_Seconds Then
			$_Minutes = $_MinCalc
			$_Seconds = $_SecCalc
			GUICtrlSetData($timer, StringFormat("%02u" & ":" & "%02u", $_Minutes, $_Seconds))

			If $_Minutes = 0 And $_Seconds <= 20 Then
				Beep(1200, 100)
			EndIf
		EndIf

		Sleep(850)
	EndIf

	Return 3
EndFunc   ;==>_Check

#comments-start FUNCTION: DisplayGUI
	#FUNCTION# ===========================================================================================================
	Name...........: DisplayGUI
	Description ...: Displays the main device name prompter GUI

	Syntax.........: DisplayGUI()
	Parameters ....: None

	Return values .: None

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: DisplayGUI
Func DisplayGUI()
	#Region ### START Koda GUI section ### Form=d:\codecontrol\program source\goldimagecompletion\gui\device name prompter.kxf
	$dev_Name_Prompt = GUICreate("Device Name Prompter", 401, 226, 454, 743, BitOR($WS_MINIMIZEBOX, $WS_GROUP), BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))
	Local $apos = WinGetPos($dev_Name_Prompt)
	WinMove($dev_Name_Prompt, "", (@DesktopWidth / 2) - ($apos[2] / 2), (@DesktopHeight / 2) - ($apos[3] / 2))
	GUISetIcon($TempDir & "\star.ico", -1)
	GUISetFont(10, 400, 0, "Segoe UI")
	GUISetBkColor(0xFFFFFF)
	$dev_Name_Label = GUICtrlCreateLabel("Enter a New Device Name: ", 41, 130, 163, 21)
	$dev_Name_Input = GUICtrlCreateInput("", 226, 128, 137, 25)
	GUICtrlSetTip($dev_Name_Input, 'Enter a valid Hostname. Valid Hostnames cannot contain any of the following characters: \/:*?"<>| and must be 15 characters or shorter.', 'Hostname', $TIP_INFOICON, $TIP_CENTER)
	$timer_Label = GUICtrlCreateLabel("Time Left:", 41, 172, 60, 21)
	$timer = GUICtrlCreateLabel("", 113, 172, 52, 21)
	$TimeTicks = TimerInit()
	$Submit = GUICtrlCreateButton("Submit", 297, 165, 75, 25)
	GUICtrlSetOnEvent($Submit, "submit")
	GUICtrlSetCursor($Submit, 0)
	$gen_Random_Name = GUICtrlCreateButton("Random", 216, 165, 75, 25)
	GUICtrlSetOnEvent($gen_Random_Name, "genRandomName")
	GUICtrlSetCursor($gen_Random_Name, 0)
	Local $Logo = GUICtrlCreatePic("", 11, 10, 378, 100)
	_GDIPlus_Startup()
	$himage = _GDIPlus_ImageLoadFromFile($png)
	Local $Bmp = _GDIPlus_BitmapCreateHBITMAPFromBitmap($himage)
	_WinAPI_DeleteObject(GUICtrlSendMsg($Logo, $STM_SETIMAGE, $IMAGE_BITMAP, $Bmp))
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###
EndFunc   ;==>DisplayGUI

#comments-start FUNCTION: submit
	#FUNCTION# ===========================================================================================================
	Name...........: submit
	Description ...: Handles the execution of the main script logic once the submit button has been clicked

	Syntax.........: submit()
	Parameters ....: None

	Return values .: The script's main actions occur from here so the script will exit before it ever returns

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: submit
Func submit()
	GUICtrlSetState($dev_Name_Input, @SW_DISABLE)
	GUICtrlSetState($Submit, @SW_DISABLE)

	$NewDeviceName = GUICtrlRead($dev_Name_Input)

	If $DebugMode = 1 Then Logit($DEBUG, 'Entered Submit function.', 'submit')
	If $DebugMode = 1 Then Logit($DEBUG, 'New Device Name: ' & $NewDeviceName, 'submit')

	If $NewDeviceName = "" Then
		If $DebugMode = 1 Then Logit($DEBUG, 'No Device Name Specified. Prompting User to confirm autonaming.', 'submit')
		$Answer = MsgBox($MB_SYSTEMMODAL + $MB_YESNO, "Confirmation", "If you leave the New Device Name field blank, we will randomly generate a name. Are you sure you do not want to specifiy a name?", 30, $dev_Name_Prompt)

		If $Answer = 6 Or $Answer = -1 Then
			If $DebugMode = 1 Then LogIt($DEBUG, "User responded Yes or Message box timed out. Generating automatic name for computer.", "submit")
			$RandomComputerName = genRandomName()
			If $DebugMode = 1 Then LogIt($DEBUG, "New Name: " & $RandomComputerName, "submit")

			$Result = _RenameComputer($RandomComputerName, "svc_landesk", "Acc0unt2!")
			If $Result = 1 Then
				LogIt($INFORMATION, "Computer has been renamed. A reboot is required for this change to take affect.", "submit")

				GUIDelete($dev_Name_Prompt)
				_GDIPlus_ImageDispose($himage)

				LogIt($INFORMATION, "Scheduling shutdown for 30 seconds from now.", "Main")
				RenameCompleteGUI()
				$i = 30

				While $i > 0
					Sleep(1000)
					GUICtrlSetData($countdown, $i)
					$i = $i - 1
				WEnd

				GUIDelete($dev_Name_Prompt_Complete)
				_GDIPlus_ImageDispose($himage)

				$Result = ConfigureImageComplete()
				If $Result <> 1 Then
					MsgBox($MB_SYSTEMMODAL, "Configuring the Image Completion Task failed.", "When the system reboots, please execute the ImageComplete.exe from C:\ProgramData\ImageComplete\Temp. This will complete the process.")
				EndIf

				RunWait(@ComSpec & ' /c shutdown /r /t 30 /c "This computer is about to restart to complete the rename process." /f')

				;- Exit the Script
				ExitScript($mainReturnCode)
			ElseIf $Result = 0 Then
				Select
					Case @error = 2
						;- Computer Name Contains Invalid Characters
						MsgBox($MB_SYSTEMMODAL, "Invalid Computer Name", "The Computer Name contains invalid characters. Please enter a new computer name.", 10)
						LogIt($WARNING, "The Computer Name contains invalid characters. Please enter a new computer name.", "SUBMIT")
						GUICtrlSetState($dev_Name_Input, @SW_ENABLE)
						GUICtrlSetState($Submit, @SW_ENABLE)
					Case @error = 5
						;- Computer Name is to long
						MsgBox($MB_SYSTEMMODAL, "Invalid Computer Name", "The Computer Name is to long. Please enter a new computer name less than 15 characters long.", 10)
						LogIt($WARNING, "The Computer Name is to long. Please enter a new computer name less than 15 characters long.", "SUBMIT")
						GUICtrlSetState($dev_Name_Input, @SW_ENABLE)
						GUICtrlSetState($Submit, @SW_ENABLE)
					Case @error = 3
						;- Current Account Does Not have Sufficient Rights to Join the Domain
						MsgBox($MB_SYSTEMMODAL, "Insufficient Rights", "The service account used for this process has changed. Please contact the Client Systems Administration team.")
						LogIt($ERROR, "The service account used for this process has changed. Please contact the Client Systems Administration team.", "SUBMIT")

						SetError(3)
						$mainReturnCode = 9003

						;- Exit the Script
						ExitScript($mainReturnCode)
					Case @error = 4
						;- Failed to create the COM Object required to perform the task.
						MsgBox($MB_SYSTEMMODAL, "Error", "Failed to create the COM Object required to perform this action. Please contact the Client Systems Administration team.")
						LogIt($ERROR, "Failed to create the COM Object required to perform this action. Please contact the Client Systems Administration team.", "SUBMIT")

						SetError(4)
						$mainReturnCode = 9004

						;- Exit the Script
						ExitScript($mainReturnCode)
				EndSelect
			Else
				;- Write Unknown Error Message and output WMI Exit Code
				MsgBox($MB_SYSTEMMODAL, "Unknown Error", "An unknown error occured. Please contact the Client Systems Administration team and provide them the following code: " & $Result & ".")
				LogIt($ERROR, "An unknown error occured. Please contact the Client Systems Administration team and provide them the following code: " & $Result & ".", "SUBMIT")

				SetError(1)
				$mainReturnCode = 9000

				GUIDelete($dev_Name_Prompt)
				_GDIPlus_ImageDispose($himage)
				GUIDelete($dev_Name_Prompt_Complete)
				_GDIPlus_ImageDispose($himage)

				;- Exit the Script
				ExitScript($mainReturnCode)
			EndIf
		ElseIf $Answer = 7 Then
			LogIt($INFORMATION, "User has choosen to enter a computer name rather than have an automatically generated one.", "submit")
			GUICtrlSetState($dev_Name_Input, @SW_ENABLE)
			GUICtrlSetState($Submit, @SW_ENABLE)
		EndIf
	Else
		$Result = _RenameComputer($NewDeviceName, "svc_landesk", "Acc0unt2!")
		If $Result = 1 Then
			LogIt($INFORMATION, "Computer has been renamed. A reboot is required for this change to take affect.", "submit")

			GUIDelete($dev_Name_Prompt)
			_GDIPlus_ImageDispose($himage)

			LogIt($INFORMATION, "Scheduling shutdown for 30 seconds from now.", "Main")
			RenameCompleteGUI()
			$i = 30

			While $i > 0
				Sleep(1000)
				GUICtrlSetData($countdown, $i)
				$i = $i - 1
			WEnd

			GUIDelete($dev_Name_Prompt_Complete)
			_GDIPlus_ImageDispose($himage)

			$Result = ConfigureImageComplete()
			If $Result <> 1 Then
				MsgBox($MB_SYSTEMMODAL, "Configuring the Image Completion Task failed.", "When the system reboots, please execute the ImageComplete.exe from C:\ProgramData\ImageComplete\Temp. This will complete the process.")
			EndIf

			RunWait(@ComSpec & ' /c shutdown /r /t 30 /c "This computer is about to restart to complete the rename process." /f')

			;- Exit the Script
			ExitScript($mainReturnCode)
		ElseIf $Result = 0 Then
			Select
				Case @error = 2
					;- Computer Name Contains Invalid Characters
					MsgBox($MB_SYSTEMMODAL, "Invalid Computer Name", "The Computer Name contains invalid characters. Please enter a new computer name.", 10)
					LogIt($WARNING, "The Computer Name contains invalid characters. Please enter a new computer name.", "SUBMIT")
					GUICtrlSetState($dev_Name_Input, @SW_ENABLE)
					GUICtrlSetState($Submit, @SW_ENABLE)
				Case @error = 5
					;- Computer Name is to long
					MsgBox($MB_SYSTEMMODAL, "Invalid Computer Name", "The Computer Name is to long. Please enter a new computer name less than 15 characters long.", 10)
					LogIt($WARNING, "The Computer Name is to long. Please enter a new computer name less than 15 characters long.", "SUBMIT")
					GUICtrlSetState($dev_Name_Input, @SW_ENABLE)
					GUICtrlSetState($Submit, @SW_ENABLE)
				Case @error = 3
					;- Current Account Does Not have Sufficient Rights to Join the Domain
					MsgBox($MB_SYSTEMMODAL, "Insufficient Rights", "The service account used for this process has changed. Please contact the Client Systems Administration team.")
					LogIt($ERROR, "The service account used for this process has changed. Please contact the Client Systems Administration team.", "SUBMIT")

					SetError(3)
					$mainReturnCode = 9003

					;- Exit the Script
					ExitScript($mainReturnCode)
				Case @error = 4
					;- Failed to create the COM Object required to perform the task.
					MsgBox($MB_SYSTEMMODAL, "Error", "Failed to create the COM Object required to perform this action. Please contact the Client Systems Administration team.")
					LogIt($ERROR, "Failed to create the COM Object required to perform this action. Please contact the Client Systems Administration team.", "SUBMIT")

					SetError(4)
					$mainReturnCode = 9004

					;- Exit the Script
					ExitScript($mainReturnCode)
			EndSelect
		Else
			;- Write Unknown Error Message and output WMI Exit Code
			MsgBox($MB_SYSTEMMODAL, "Unknown Error", "An unknown error occured. Please contact the Client Systems Administration team and provide them the following code: " & $Result & ".")
			LogIt($ERROR, "An unknown error occured. Please contact the Client Systems Administration team and provide them the following code: " & $Result & ".", "SUBMIT")

			SetError(1)
			$mainReturnCode = 9000

			;- Exit the Script
			ExitScript($mainReturnCode)
		EndIf
	EndIf
EndFunc   ;==>submit

Func _Timeout()
	$RandomComputerName = genRandomName()
	If $DebugMode = 1 Then LogIt($DEBUG, "New Name: " & $RandomComputerName, "_Timeout")

	$Result = _RenameComputer($RandomComputerName, "svc_landesk", "Acc0unt2!")
	If $Result = 1 Then
		LogIt($INFORMATION, "Computer has been renamed. A reboot is required for this change to take affect.", "_Timeout")

		GUIDelete($dev_Name_Prompt)
		_GDIPlus_ImageDispose($himage)

		LogIt($INFORMATION, "Scheduling shutdown for 30 seconds from now.", "_Timeout")
		RenameCompleteGUI()
		$i = 30

		While $i > 0
			Sleep(1000)
			GUICtrlSetData($countdown, $i)
			$i = $i - 1
		WEnd

		GUIDelete($dev_Name_Prompt_Complete)
		_GDIPlus_ImageDispose($himage)

		$Result = ConfigureImageComplete()
		If $Result <> 1 Then
			MsgBox($MB_SYSTEMMODAL, "Configuring the Image Completion Task failed.", "When the system reboots, please execute the ImageComplete.exe from C:\ProgramData\ImageComplete\Temp. This will complete the process.")
		EndIf

		RunWait(@ComSpec & ' /c shutdown /r /t 30 /c "This computer is about to restart to complete the rename process." /f')

		;- Exit the Script
		ExitScript($mainReturnCode)
	ElseIf $Result = 0 Then
		Select
			Case @error = 2
				;- Computer Name Contains Invalid Characters
				MsgBox($MB_SYSTEMMODAL, "Invalid Computer Name", "The Computer Name contains invalid characters. Please enter a new computer name.", 10)
				LogIt($WARNING, "The Computer Name contains invalid characters. Please enter a new computer name.", "_Timeout")
				GUICtrlSetState($dev_Name_Input, @SW_ENABLE)
				GUICtrlSetState($Submit, @SW_ENABLE)
			Case @error = 5
				;- Computer Name is to long
				MsgBox($MB_SYSTEMMODAL, "Invalid Computer Name", "The Computer Name is to long. Please enter a new computer name less than 15 characters long.", 10)
				LogIt($WARNING, "The Computer Name is to long. Please enter a new computer name less than 15 characters long.", "_Timeout")
				GUICtrlSetState($dev_Name_Input, @SW_ENABLE)
				GUICtrlSetState($Submit, @SW_ENABLE)
			Case @error = 3
				;- Current Account Does Not have Sufficient Rights to Join the Domain
				MsgBox($MB_SYSTEMMODAL, "Insufficient Rights", "The service account used for this process has changed. Please contact the Client Systems Administration team.")
				LogIt($ERROR, "The service account used for this process has changed. Please contact the Client Systems Administration team.", "_Timeout")

				SetError(3)
				$mainReturnCode = 9003

				;- Exit the Script
				ExitScript($mainReturnCode)
			Case @error = 4
				;- Failed to create the COM Object required to perform the task.
				MsgBox($MB_SYSTEMMODAL, "Error", "Failed to create the COM Object required to perform this action. Please contact the Client Systems Administration team.")
				LogIt($ERROR, "Failed to create the COM Object required to perform this action. Please contact the Client Systems Administration team.", "_Timeout")

				SetError(4)
				$mainReturnCode = 9004

				;- Exit the Script
				ExitScript($mainReturnCode)
		EndSelect
	Else
		;- Write Unknown Error Message and output WMI Exit Code
		MsgBox($MB_SYSTEMMODAL, "Unknown Error", "An unknown error occured. Please contact the Client Systems Administration team and provide them the following code: " & $Result & ".")
		LogIt($ERROR, "An unknown error occured. Please contact the Client Systems Administration team and provide them the following code: " & $Result & ".", "_Timeout")

		SetError(1)
		$mainReturnCode = 9000

		GUIDelete($dev_Name_Prompt)
		_GDIPlus_ImageDispose($himage)
		GUIDelete($dev_Name_Prompt_Complete)
		_GDIPlus_ImageDispose($himage)

		;- Exit the Script
		ExitScript($mainReturnCode)
	EndIf
EndFunc   ;==>_Timeout

#comments-start FUNCTION: genRandomName
	#FUNCTION# ===========================================================================================================
	Name...........: genRandomName
	Description ...: Generate a random name

	Syntax.........: genRandomName()
	Parameters ....: None

	Return values .: Success - Returns a random computer name to be used

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: genRandomName
Func genRandomName()
	LogIt($INFORMATION, "Generating Random Name.", "genRandomName")
	$RName = Random(1000, 2000, 1) & "-ChangeMe"

	LogIt($INFORMATION, "New Name: " & $RName & ".", "genRandomName")
	GUICtrlSetData($dev_Name_Input, $RName)

	Return $RName
EndFunc   ;==>genRandomName

#comments-start FUNCTION: RenameCompleteGUI
	#FUNCTION# ===========================================================================================================
	Name...........: RenameCompleteGUI
	Description ...: Displays the GUI for the computer rename

	Syntax.........: RenameCompleteGUI()
	Parameters ....: None

	Return values .: None

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: RenameCompleteGUI
Func RenameCompleteGUI()
	#Region ### START Koda GUI section ### Form=D:\CodeControl\Program Source\GoldImageCompletion\GUI\Configuration Complete.kxf
	$dev_Name_Prompt_Complete = GUICreate("Configuration Complete", 401, 250, 912, 359, BitOR($WS_MINIMIZEBOX, $WS_GROUP), BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))

	Local $apos = WinGetPos($dev_Name_Prompt_Complete)
	WinMove($dev_Name_Prompt_Complete, "", (@DesktopWidth / 2) - ($apos[2] / 2), (@DesktopHeight / 2) - ($apos[3] / 2))

	;- Define the GUI settings
	GUISetIcon($TempDir & "\star.ico", -1)
	GUISetFont(10, 400, 0, "Segoe UI")
	GUISetBkColor(0xFFFFFF)

	$it_Logo = GUICtrlCreatePic("", 11, 10, 378, 100)
	_GDIPlus_Startup()
	$himage = _GDIPlus_ImageLoadFromFile($png)
	Local $Bmp = _GDIPlus_BitmapCreateHBITMAPFromBitmap($himage)
	_WinAPI_DeleteObject(GUICtrlSendMsg($it_Logo, $STM_SETIMAGE, $IMAGE_BITMAP, $Bmp))

	$Label1 = GUICtrlCreateLabel("Computer Rename Complete.", 11, 136, 193, 25)
	GUICtrlSetFont($Label1, 12, 800, 0, "Segoe UI")
	$Label2 = GUICtrlCreateLabel("A reboot is required to finalize the configuration.", 11, 160, 289, 21)
	$Label3 = GUICtrlCreateLabel("Rebooting in ", 11, 184, 83, 21)
	$countdown = GUICtrlCreateLabel("", 96, 182, 22, 25)
	GUICtrlSetFont($countdown, 12, 800, 0, "Segoe UI")
	GUICtrlSetColor($countdown, 0xFF0000)
	$Label5 = GUICtrlCreateLabel("Seconds", 120, 184, 53, 21)
	GUISetState(@SW_SHOW)
EndFunc   ;==>RenameCompleteGUI

#comments-start FUNCTION: WMIService
	#FUNCTION# ===========================================================================================================
	Name...........: WMIService
	Description ...: Makes a connection to WMI and stores it as an object

	Syntax.........: WMIService($host)
	Parameters ....: $host - The device name to connect to in WMI

	Return values .: Success = 1
					Failure = 0

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: WMIService
Func WMIService($host)     ;Connects to WMI Service
	$objWMIService = ObjGet("winmgmts:{impersonationLevel=impersonate}!\\" & $host & "\root\cimv2")
	If Not IsObj($objWMIService) Then Return 0
	Return 1
EndFunc   ;==>WMIService

#comments-start FUNCTION: CheckAssetTag
	#FUNCTION# ===========================================================================================================
	Name...........: CheckAssetTag
	Description ...: Returns the current Asset Tag from WMI
	during program execution.
	Syntax.........: CheckAssetTag()
	Parameters ....: nONE

	Return values .: Success = Returns the Asset Tag as a string
					Failure = 0 Sets @error flag
						1 - Failed to connect to WMI
						2 - Asset tag is not set in the BIOS

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: CheckAssetTag
Func CheckAssetTag()
	LogIt($INFORMATION, "Checking if the asset tag is set in the BIOS.", "CheckAssetTag")
	Local $aTag

	Local $Result = WMIService(@ComputerName)
	If $Result <> 1 Then
		LogIt($WARNING, "Failed to connect to WMI. We won't be able to check for the asset tag in the BIOS.", "CheckAssetTag")
		SetError(1)
		Return 0
	EndIf

	Local $Col_Items = $objWMIService.ExecQuery('Select * from Win32_SystemEnclosure')
	Local $obj_item
	For $obj_item In $Col_Items
		$aTag = $obj_item.SMBIOSAssetTag
	Next

	If $aTag = "" Or $aTag = "No Asset Tag" Then
		LogIt($INFORMATION, "Asset tag is not set in the BIOS.", "CheckAssetTag")
		SetError(2)
		Return 0
	Else
		LogIt($INFORMATION, "Asset tag found in BIOS. Asset tag is set to: " & $aTag, "CheckAssetTag")
		Return $aTag
	EndIf

EndFunc   ;==>CheckAssetTag

#comments-start FUNCTION: CheckManufacturer
	#FUNCTION# ===========================================================================================================
	Name...........: CheckManufacturer
	Description ...: Returns the current Manufacturer from WMI
	during program execution.
	Syntax.........: CheckManufacturer()
	Parameters ....: nONE

	Return values .: Success = Returns the manufacturer as a string
					Failure = 0 Sets @error flag
						1 - Failed to connect to WMI
						2 - Could not retrieve manufacturer from wmi

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: CheckManufacturer
Func CheckManufacturer()
	LogIt($INFORMATION, "Checking Manufacturer in WMI.", "CheckManufacturer")
	Local $sManufacturer

	Local $Result = WMIService(@ComputerName)
	If $Result <> 1 Then
		LogIt($WARNING, "Failed to connect to WMI. We won't be able to check for the device manufacturer.", "CheckManufacturer")
		SetError(1)
		Return 0
	EndIf

	Local $Col_Items = $objWMIService.ExecQuery('Select * from Win32_ComputerSystem')
	Local $obj_item
	For $obj_item In $Col_Items
		$sManufacturer = $obj_item.Manufacturer
	Next

	If $sManufacturer = "" Then
		LogIt($INFORMATION, "Could not retrieve manufacturer from WMI.", "CheckManufacturer")
		SetError(2)
		Return 0
	Else
		LogIt($INFORMATION, "Manufacturer found in WMI. Manufacturer is set to: " & $sManufacturer, "CheckManufacturer")
		Return $sManufacturer
	EndIf

EndFunc   ;==>CheckManufacturer

#comments-start FUNCTION: CheckModel
	#FUNCTION# ===========================================================================================================
	Name...........: CheckModel
	Description ...: Returns the current model from WMI
	during program execution.
	Syntax.........: CheckModel()
	Parameters ....: nONE

	Return values .: Success = Returns the model as a string
					Failure = 0 Sets @Error Flag
						1 - Failed to connect to WMI
						2 - Could not retrieve the model

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: CheckModel
Func CheckModel()
	LogIt($INFORMATION, "Checking the model in WMI.", "CheckModel")
	Local $sModel

	Local $Result = WMIService(@ComputerName)
	If $Result <> 1 Then
		LogIt($WARNING, "Failed to connect to WMI. We won't be able to check for the device model.", "CheckModel")
		SetError(1)
		Return 0
	EndIf

	Local $Col_Items = $objWMIService.ExecQuery('Select * from Win32_ComputerSystem')
	Local $obj_item
	For $obj_item In $Col_Items
		$sModel = $obj_item.Model
	Next

	If $sModel = "" Then
		LogIt($INFORMATION, "Could not retrieve model from WMI.", "CheckModel")
		SetError(2)
		Return 0
	Else
		LogIt($INFORMATION, "Model found in WMI. Model is set to: " & $sModel, "CheckModel")
		Return $sModel
	EndIf

EndFunc   ;==>CheckModel

#comments-start FUNCTION: CheckBattery
	#FUNCTION# ===========================================================================================================
	Name...........: CheckBattery
	Description ...: Check and return the status of the battery if one exists or not
	during program execution.
	Syntax.........: CheckBattery()
	Parameters ....: nONE

	Return values .: Success = 1 for Battery 2 for no battery
					Failure = 0

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: CheckBattery
Func CheckBattery()
	LogIt($INFORMATION, "Checking if the device has a battery in WMI.", "CheckBattery")
	Local $Return = 2

	Local $Result = WMIService(@ComputerName)
	If $Result <> 1 Then
		LogIt($WARNING, "Failed to connect to WMI. We won't be able to check for a battery.", "CheckBattery")
		Return 0
	EndIf

	$Col_Items = $objWMIService.ExecQuery('Select * from Win32_Battery')
	For $Item In $Col_Items
		If Not $Item.Caption = '' Then
			LogIt($INFORMATION, "Device has a battery.", "CheckBattery")
			$Return = 1
		Else
			LogIt($INFORMATION, "Device does not have a battery.", "CheckBattery")
			$Return = 2
		EndIf
	Next

	Return $Return
EndFunc   ;==>CheckBattery

#comments-start FUNCTION: AutoRename
	#FUNCTION# ===========================================================================================================
	Name...........: AutoRename
	Description ...: Automatically renames the target computer based on provided parameters
	during program execution.
	Syntax.........: AutoRename($iAssetTag, $sModel, $sManufacturer, $bBattery)
	Parameters ....: $iAssetTag - The Asset tag discovered from WMI
					$sModel - The Model of the device from WMI
					$sManufacturer - The Manufacturer from WMI
					$bBattery - IF the device has a battery or not

	Return values .: Success = 1
					Failure = 0

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: AutoRename
Func AutoRename($iAssetTag, $sModel, $sManufacturer, $bBattery)
	If Not $sModel = 0 Then
		If $DebugMode = 1 Then LogIt($DEBUG, 'Model check complete. Model populated.', 'AutoRename')
		If Not $sManufacturer = 0 Then
			If $DebugMode = 1 Then LogIt($DEBUG, 'Manufacturer check complete. Manufacturer populated.', 'AutoRename')
			If Not $bBattery = 0 Then
				If $DebugMode = 1 Then LogIt($DEBUG, 'Battery check complete. Battery populated.', 'AutoRename')
				LogIt($INFORMATION, "Attempting to autoname the device using the Asset Tag.", "AutoRename")
				Select
					Case $sManufacturer = "Panasonic Corporation"
						$AutoComputerName = $AssetTag & "MD"
					Case $sManufacturer = "Dell Inc."
						If $sModel = 'Latitude 5414' Then
							$AutoComputerName = $AssetTag & "MD"     ;- Added to support Latitude 5414 Semi-Rugged devices
						ElseIf $sModel = 'Latitude 5420 Rugged' Then
							$AutoComputerName = $AssetTag & "MD"     ;- Added to support Latitude 5414 Semi-Rugged devices
						Else
							If $Battery = 1 Then
								$AutoComputerName = $AssetTag & "SL"
							ElseIf $Battery = 2 Then
								$AutoComputerName = $AssetTag & "SO"
							EndIf
						EndIf
					Case $sManufacturer = "HP"
						If $Battery = 1 Then
							$AutoComputerName = $AssetTag & "SL"
						ElseIf $Battery = 2 Then
							$AutoComputerName = $AssetTag & "SO"
						EndIf
					Case Else
						If $Battery = 1 Then
							$AutoComputerName = $AssetTag & "SL"
						ElseIf $Battery = 2 Then
							$AutoComputerName = $AssetTag & "SO"
						EndIf
				EndSelect

				Local $Result = _RenameComputer($AutoComputerName, "svc_landesk", "Acc0unt2!")
				If $Result = 1 Then
					LogIt($INFORMATION, "Computer has been renamed. A reboot is required for this change to take affect.", "AutoRename")
					Return 1
				ElseIf $Result = 0 Then
					Select
						Case @error = 2
							;- Computer Name Contains Invalid Characters
							LogIt($WARNING, "The Computer Name contains invalid characters. The asset tag must contain invalid characters.", "Main")
							Return 0
						Case @error = 5
							;- Computer Name is to long
							LogIt($WARNING, "The Computer Name is to long. We can't use the Asset Tag as is.", "Main")
							Return 0
						Case @error = 3
							;- Current Account Does Not have Sufficient Rights to Join the Domain
							LogIt($ERROR, "The service account used for this process has changed. Please contact the Client Systems Administration team.", "Main")
							SetError(3)
							$mainReturnCode = 9003

							;- Exit the Script
							ExitScript($mainReturnCode)
						Case @error = 4
							;- Failed to create the COM Object required to perform the task.
							LogIt($ERROR, "Failed to create the COM Object required to perform this action.", "Main")
							Return 0
					EndSelect
				Else
					;- Write Unknown Error Message and output WMI Exit Code
					LogIt($ERROR, "An unknown error occured. Please contact the Client Systems Administration team and provide them the following code: " & $Result & ".", "Main")
					SetError(1)
					$mainReturnCode = 9000

					;- Exit the Script
					ExitScript($mainReturnCode)
				EndIf
			Else
				LogIt($WARNING, "Autonaming failed. Will display GUI for user interaction.", "AutoRename")
				Return 0
			EndIf
		Else
			Select
				Case @error = 1
					LogIt($WARNING, "Autonaming failed. Will display GUI for user interaction.", "AutoRename")
					Return 0
				Case @error = 2
					LogIt($WARNING, "Autonaming failed. Will display GUI for user interaction.", "AutoRename")
					Return 0
				Case Else
					Return 0
			EndSelect
		EndIf
	Else
		Select
			Case @error = 1
				LogIt($WARNING, "Autonaming failed. Will display GUI for user interaction.", "AutoRename")
				Return 0
			Case @error = 2
				LogIt($WARNING, "Autonaming failed. Will display GUI for user interaction.", "AutoRename")
				Return 0
			Case Else
				Return 0
		EndSelect
	EndIf

EndFunc   ;==>AutoRename

Func ConfigureImageComplete()
	Local $XML = $TempDir & '\CompleteImage.xml'
	Local $Command = 'schtasks.exe /Create /XML "' & $XML & '" /TN CompleteImage'

	LogIt($INFORMATION, "Importing Scheduled Task", "ConfigureImageComplete")
	$Result = RunWait(@ComSpec & ' /c ' & $Command)
	If $Result <> 0 Then
		LogIt($ERROR, "An error occured importing the scheduled task for image complete.", "ConfigureImageComplete")
		Return 0
	EndIf

	Return 1
EndFunc   ;==>ConfigureImageComplete

