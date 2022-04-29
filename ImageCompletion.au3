#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\icon.ico
#AutoIt3Wrapper_Outfile_x64=..\..\Builds\ImageCompletion\ImageCompletion.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Image Complete
#AutoIt3Wrapper_Res_Fileversion=4.0.0.115
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=Image Complete
#AutoIt3Wrapper_Res_ProductVersion=4.0.0.113
#AutoIt3Wrapper_Res_CompanyName=Ascanio.net
#AutoIt3Wrapper_Res_LegalCopyright=Copyright © 2022 Ascanio.net. All rights reserved.
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Res_HiDpi=y
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Tidy_Stop_OnError=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;**** Directives created by AutoIt3Wrapper_GUI ****

; Options
AutoItSetOption("GUIOnEventMode", 1)  ; 0=disabled, 1=OnEvent mode enabled
AutoItSetOption("TrayAutoPause", 0)   ; 0=no pause, 1=Pause
AutoItSetOption("TrayIconHide", 0)    ; 0=show, 1=hide tray icon
AutoItSetOption("TrayMenuMode", 1)    ; 0=append, 1=no default menu, 2=no automatic check, 4=menuitemID  not return

; #VARIABLES# ====================================================================================================================
; Required Global Application Installation Variables
Global $appPublisher = 'Ascanio.net'      ;- Application Publisher (From Uninstall Key if Possible)
Global $appDisplayName = 'Image Completion Tool'    ;- Application Display Name (From Uninstall Key if Possible)
Global $appShortName = 'Image Completion Tool'      ;- Short Name for the application
Global $appVersion = '4.0.0.0'        ;- Application Version (From Uninstall Key if Possible)
Global $appArch = 'x86_64'           ;- Application Architecture (x86;x86_64)
Global $appLang = 'en-US'           ;- Appication Language (en-US)
Global $appRevision = ''       ;- Application Revision
Global $appScriptVersion = '4.0.0.0'  ;- Script Version
Global $appScriptDate = '10-24-2019'     ;- Script Date
Global $appScriptAuthor = 'Joseph Ascanio'   ;- Script Author

; Add additional Global Scope Variables here
Global $SplashScreen, $init = 0, $Status

; Includes
#include <standard_functions.au3>
#include <RenameComputer.au3>
#include <MetroGUI_UDF.au3>
#include <_GUIDisable.au3>; For Dim effects when msgbox is displayed

; #MAIN SCRIPT ACTIONS# ==========================================================================================================
_Metro_EnableHighDPIScaling() ; Note: Requries "#AutoIt3Wrapper_Res_HiDpi=y" for compiling. To see visible changes without compiling, you have to disable dpi scaling in compatibility settings of Autoit3.exe

DisplaySplashScreen()

; This loop will continue until the initialization is complete or fails
; this is a loop so that we can display the splash screen for as long as
; needed.
While $init = 0
	; Script Initialization - Starts and expires logging as well as
	; writes log header and defines global scope variables
	$Result = Initialize()
	If $Result <> 1 Then
		; Initialization failed
		$mainReturnCode = 9098
		GUIDelete($SplashScreen)
		MsgBox($MB_APPLMODAL + $MB_TOPMOST + $MB_ICONERROR, 'Process failed...', 'Could not initiate the application. Please contact your administrator...', 30)
		ExitScript($mainReturnCode)
	EndIf

	; Begin application configuration either through defaults or through
	; settings.ini if present in the application directory
	; Initialization completed
	GUICtrlSetData($Status, 'Configuring Application...')
	LogIt($INFORMATION, "Configuration Application.", "Main")
	; Defining Settings Globals
	Global $TotalPackages, $Gui_Logo, $Gui_Icon, $ExecutionOrder, $RebootSettings, $CleanupSettings
	Global $PackagesDirectory = @ScriptDir & '\Packages'

	$Ret = ProcessSettings(@ScriptDir & '\settings.ini')
	If $Ret <> 1 Then
		LogIt($WARNING, 'Failed to read settings file.', 'Main')
		$mainReturnCode = 9099
		GUIDelete($SplashScreen)
		MsgBox($MB_APPLMODAL + $MB_TOPMOST + $MB_ICONERROR, 'Process failed...', 'Could not configure the application. Please contact your administrator...', 30)
		ExitScript($mainReturnCode)
	EndIf

	GUICtrlSetData($Status, 'Discovering Packages...')
	$Packages = DiscoverPackages($PackagesDirectory)
	If Not IsArray($Packages) Then
		Select
			Case $Packages = 2
				GUIDelete($SplashScreen)
				MsgBox($MB_APPLMODAL + $MB_TOPMOST + $MB_ICONERROR, 'Process failed...', 'There are less packages in the directory than are defined in the settings. Please contact your administrator...', 30)
				ExitScript($mainReturnCode)
			Case $Packages = 3
				GUIDelete($SplashScreen)
				MsgBox($MB_APPLMODAL + $MB_TOPMOST + $MB_ICONERROR, 'Process failed...', 'An unknown error occured. Please contact your administrator...', 30)
				ExitScript($mainReturnCode)
			Case $Packages = 4
				GUIDelete($SplashScreen)
				MsgBox($MB_APPLMODAL + $MB_TOPMOST + $MB_ICONERROR, 'Process failed...', 'No Packages were found. Cannot proceed. Please contact your administrator...', 30)
				ExitScript($mainReturnCode)
			Case $Packages = 5
				GUIDelete($SplashScreen)
				MsgBox($MB_APPLMODAL + $MB_TOPMOST + $MB_ICONERROR, 'Process failed...', 'Could not locate the packages directory. Please contact your administrator...', 30)
				ExitScript($mainReturnCode)
		EndSelect
	EndIf

	If $Gui_Logo = 'Null' Or $Gui_Logo = '' Or $Gui_Icon = '' Or $Gui_Icon = 'Null' Then
		$Result = ExpandRequiredFiles()
		If $Result <> 1 Then
			LogIt($ERROR, "Failed to extract required application files.", "Main")
			$mainReturnCode = 9099

			GUIDelete($SplashScreen)
			MsgBox($MB_APPLMODAL + $MB_TOPMOST + $MB_ICONERROR, 'Process failed...', 'Could not extract required application files. Please contact your administrator...', 30)
			ExitScript($mainReturnCode)
		EndIf

		Global $png = $TempDir & '\logo.png'
		Global $icon = $TempDir & '\icon.ico'
	EndIf

	;Defining Main Gui Globals
	; Configure the main GUI window and all of it's required variables
	; Also define the packages directory as adjacent to the EXE
	GUICtrlSetData($Status, 'Finishing up...')
	Global $main_gui, $overall_Progress, $current_Progress, $hostname, $ipaddress, $mac_address
	Global $TotalSteps, $CurrentStepNum, $overall_progress_action, $current_progress_action
	Global $oStepPercentLabel, $oCompletePercentLabel, $step_total, $cur_step, $overal_step_total
	Global $cur_overall_step, $countdown, $complete_GUI, $hImage, $marqProgress

	; Set init 1 to break out of the loop
	$init = 1

WEnd

;- Closing SplashScreen
GUIDelete($SplashScreen)

;- Displaying Main GUI
DisplayMainGUI()

;- Set Overall Progress for initial startup
If $DebugMode = 1 Then LogIt($DEBUG, "Setting overall progress in the GUI.", "Main")
SetOverallProgress($TotalPackages, '0', '0', '')

LogIt($INFORMATION, "Beginning Installation of Packages.", "Main")
For $j = 1 To $ExecutionOrder[0][0] Step 1
	If $DebugMode = 1 Then LogIt($DEBUG, "Checking for changes to the IP Address or Hostname", "Main")
	If StringLeft(GUICtrlRead($ipaddress), 4) = '169.' Then
		Local $aArray = _IPDetails()
		SetSysInfo($aArray)
	EndIf

	$PackagePath = $PackagesDirectory & '\' & $ExecutionOrder[$j][1]

	$Result = CheckINI($PackagePath)
	If $Result = 1 Then
		LogIt($INFORMATION, 'Reading Package Settings INI', 'Main')
		; Retrieve the package ini and read the section names to gather the step numbers
		; and if there is a settings section
		Local $PackageFile = $PackagePath & '\package.ini'
		Local $PackageSettings = IniReadSectionNames($PackageFile)

		;- Read the Settings Section
		If $DebugMode = 1 Then LogIt($DEBUG, "Configuring main package settings.", "Main")
		If _ArraySearch($PackageSettings, 'settings') <> -1 Then
			; Pull the packagename and the package version from the package file
			Local $PackageName = IniRead($PackageFile, 'settings', 'PackageName', 'Null')
			Local $PackageVersion = IniRead($PackageFile, 'settings', 'PackageVersion', 'Null')

			;- Validate PackageName is not null
			If $PackageName = 'Null' Then $PackageName = $ExecutionOrder[$j][1]
			;- Validate PackageVersion is not null
			If $PackageVersion = 'Null' Then $PackageVersion = '0.0.0.0'
		Else
			Local $PackageName = $ExecutionOrder[$j][1]
			Local $PackageVersion = '0.0.0.0'
		EndIf

		;- Setting Step in GUI
		SetOverallProgress($TotalPackages, $j, 'Null', $PackageName)

		;- Read the ExitCode Section
		Local $useCustomExit = 0
		If _ArraySearch($PackageSettings, 'ExitCodes') <> -1 Then
			Global $ExitCodes = IniReadSection($PackageFile, 'ExitCodes')

			If Not IsArray($ExitCodes) Then
				LogIt($WARNING, 'No custom Exit codes were defined. We will use 0 and 3010 as success. Everything else will be treated as a failure.', 'Main')
			Else
				$useCustomExit = 1
				LogIt($INFORMATION, 'Custom Exit Codes have been defined. We will use them in place of our default exit codes.', 'Main')
			EndIf
		Else
			LogIt($WARNING, 'No custom Exit codes were defined. We will use 0 and 3010 as success. Everything else will be treated as a failure.')
		EndIf

		If $DebugMode = 1 Then LogIt($DEBUG, "Counting Steps for package " & $PackageName, "Main")
		Dim $aSteps
		$aSteps = 0
		$Count = 0
		For $Section In $PackageSettings
			If StringInStr($Section, 'Step_') Then
				If $DebugMode = 1 Then LogIt($DEBUG, "Discovered Step " & $Section, "Main")
				$Count = $Count + 1
				If IsArray($aSteps) Then
					$Bound = UBound($aSteps)
					ReDim $aSteps[$Bound + 1]
					$aSteps[0] = $Count
					$aSteps[$Bound] = $section
					;_ArrayDisplay($aSteps)
				Else
					Dim $aSteps[2]
					$aSteps[0] = $Count
					$aSteps[1] = $section
					;_ArrayDisplay($aSteps)
				EndIf
			Else
				ContinueLoop
			EndIf
		Next

		LogIt($INFORMATION, 'Discovered ' & $Count & ' steps to process for ' & $PackageName, 'Main')

		;- Process Steps In Order
		_ArraySort($aSteps, 0, 1)
		;_ArrayDisplay($aSteps)
		For $k = 1 To $aSteps[0] Step 1
			Local $Step = 'Null'
			;- Get Step Number
			$Step = StringSplit($aSteps[$k], '_')[2]
			If StringLeft($Step, '1') = '0' Then $Step = StringTrimLeft($Step, 1)

			Local $StepTitle = IniRead($PackageFile, $aSteps[$k], 'Title', 'Step ' & $Step)

			If $DebugMode = 1 Then LogIt($DEBUG, "Working on step " & $Step & " of " & $Count & " : " & $StepTitle & " for package " & $PackageName, "Main")
			;- If the step count is 1 then we set % = 0 Otherwise we divide step by step count * 100
			If $Count = 1 And $Step = 1 Then
				;SetStepProgress($Step, $count, $StepTitle, '0')

				If $DebugMode = 1 Then LogIt($DEBUG, "Activating Marquee Progress bar for single step package.", "Main")
				GUICtrlSetState($marqProgress, @SW_ENABLE)
				GUICtrlSetState($marqProgress, @SW_SHOW)
				GUICtrlSetState($current_Progress, @SW_HIDE)
				GUICtrlSetState($current_Progress, @SW_DISABLE)

				Local $hProgress = GUICtrlGetHandle($marqProgress)
				_SendMessage($hProgress, $PBM_SETMARQUEE, True, 20)

				SetStepProgress($Step, $Count, $StepTitle)

				;- Setup Command to execute
				Local $CommandLine = IniRead($PackageFile, $aSteps[$Step], 'CommandLine', 'Null')
				Local $Arguments = IniRead($PackageFile, $aSteps[$Step], 'Arguments', 'Null')

				$Result = ExecutePackageStep($CommandLine, $Arguments, $PackagePath, $useCustomExit)
				If $Result <> 1 Then
					LogIt($WARNING, "A Package step has failed... read view the log for more information...", "Main")
				EndIf

				If $DebugMode = 1 Then LogIt($DEBUG, "Disabling Marquee Progress Bar.", "Main")
				GUICtrlSetState($marqProgress, @SW_DISABLE)
				GUICtrlSetState($marqProgress, @SW_HIDE)
				GUICtrlSetState($current_Progress, @SW_ENABLE)
				GUICtrlSetState($current_Progress, @SW_SHOW)
			ElseIf $Step = 1 Then
				If $DebugMode = 1 Then LogIt($DEBUG, "Working on first step. Setting Starting Progress to 0.", "Main")
				If GUICtrlGetState($marqProgress) = 80 Then
					If $DebugMode = 1 Then LogIt($DEBUG, "Disabling Marquee Progress Bar.", "Main")
					GUICtrlSetState($marqProgress, @SW_DISABLE)
					GUICtrlSetState($marqProgress, @SW_HIDE)
					GUICtrlSetState($current_Progress, @SW_ENABLE)
					GUICtrlSetState($current_Progress, @SW_SHOW)
				Else
					If $DebugMode = 1 Then LogIt($DEBUG, "Marquee Progress bar is not enabled.", "Main")
				EndIf

				SetStepProgress($Step, $Count, $StepTitle, '0')

				;- Setup Command to execute
				Local $CommandLine = IniRead($PackageFile, $aSteps[$Step], 'CommandLine', 'Null')
				Local $Arguments = IniRead($PackageFile, $aSteps[$Step], 'Arguments', 'Null')

				$Result = ExecutePackageStep($CommandLine, $Arguments, $PackagePath, $useCustomExit)
				If $Result <> 1 Then
					LogIt($WARNING, "A Package step has failed... read view the log for more information...", "Main")
				EndIf

				SetStepProgress($Step, $Count, $StepTitle, Round(($Step / $Count) * 100))
			Else
				If $DebugMode = 1 Then LogIt($DEBUG, "Working on first step. Setting Starting Progress to 0.", "Main")

				SetStepProgress($Step, $Count, $StepTitle, '0')

				;- Setup Command to execute
				Local $CommandLine = IniRead($PackageFile, $aSteps[$Step], 'CommandLine', 'Null')
				Local $Arguments = IniRead($PackageFile, $aSteps[$Step], 'Arguments', 'Null')

				$Result = ExecutePackageStep($CommandLine, $Arguments, $PackagePath, $useCustomExit)
				If $Result <> 1 Then
					LogIt($WARNING, "A Package step has failed... read view the log for more information...", "Main")
				EndIf

				SetStepProgress($Step, $Count, $StepTitle, Round(($Step / $Count) * 100))
			EndIf
		Next ;#> End Step Processing For Loop

		;- Set progress to 100% for completed actions
		If $DebugMode = 1 Then LogIt($DEBUG, "Package complete. Setting percentage to 100% on current action.", "Main")
		GUICtrlSetData($current_Progress, 100)
		GUICtrlSetData($oStepPercentLabel, "100%")

		;- Set Overall Progress
		If $DebugMode = 1 Then LogIt($DEBUG, "Setting overall progress in the GUI.", "Main")
		SetOverallProgress($TotalPackages, $j, Round(($j / $TotalPackages) * 100), $PackageName)
	Else
		LogIt($ERROR, "There was no package.ini file found for " & $PackageName, "Main")
		If $DebugMode = 1 Then LogIt($DEBUG, "Package.ini was not found in " & $PackagePath & ". Cannot process Package.", "Main")

		GUICtrlSetData($current_Progress, 100)
		GUICtrlSetData($oStepPercentLabel, "100%")

		If $DebugMode = 1 Then LogIt($DEBUG, "Setting overall progress in the GUI.", "Main")
		SetOverallProgress($TotalPackages, $j, Round(($j / $TotalPackages) * 100), $PackageName)
	EndIf
Next

;- While Loop for GUI
$i = 5
While $i > 0
	Sleep(1000)
	$i = $i - 1
WEnd

;- Delete Main GUI
GUIDelete($main_gui)

;- detroy the image we created in memory
_GDIPlus_ImageDispose($hImage)

If $CleanupSettings = 'True' Then
	;- Remove staged files
	LogIt($INFORMATION, "Cleaning up all staged files.", "Main")
	$Result = CleanUpStagedFiles($PackagesDirectory)
	If $Result <> 1 Then
		LogIt($WARNING, "One or more staged files, or settings was not cleaned up.", "Main")
	EndIf
EndIf

If $RebootSettings = 'True' Then
	;- Display the complete GUI for 15 seconds
	LogIt($INFORMATION, "Scheduling shutdown for 30 seconds from now.", "Main")
	DisplayCompleteGUI()
	For $x = 15 To 1 Step -1
		Sleep(1000)
		GUICtrlSetData($countdown, $x)
	Next

	;- Dispose of the Complete GUI
	GUIDelete($complete_GUI)

	;- Destroy the temp image we created in memory
	_GDIPlus_ImageDispose($hImage)

	;- Execute the shutdown with a 30 second timer
	RunWait(@ComSpec & ' /c shutdown /r /t 30 /c "This computer is about to restart to complete the finalization process." /f')
EndIf

;- Exit the Script
ExitScript($mainReturnCode)

#comments-start FUNCTION: ExecutePackageStep
	#FUNCTION# ===========================================================================================================
	Name...........: ExecutePackageStep
	Description ...: Defines files to be included in the compiled executable and then extracted
	during program execution.
	Syntax.........: ExecutePackageStep($Command,$Parameters,$WorkingPath,$customExit)
    Parameters ....: $Command - Command to execute
                        $Parameters - Parameters to pass to the command
                        $WorkingPath - Path to execute the command in
                        $customexit - 1 or 0 determines if the custom exit parameters will be used

	Return values .: Success - Returns 1
	Failure - Returns 0

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: ExecutePackageStep
Func ExecutePackageStep($Command, $Parameters, $WorkingPath, $customExit = 0)
	Select
		Case $CommandLine = 'Null'
			LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
			Return 0
		Case $CommandLine = 'CMD'
			If $DebugMode = 1 Then LogIt($DEBUG, 'CMD variable detected. Executing command as batch.', 'ExecutePackageStep')
			If Not $Arguments = '' Then
				If $DebugMode = 1 Then LogIt($DEBUG, 'Arguments found for CMD.', 'ExecutePackageStep')
				$Params = StringSplit($Arguments, ';')
				If IsArray($Params) Then
					If UBound($Params) = 3 Then
						$Root = $Params[1]
						If $DebugMode = 1 Then LogIt($DEBUG, '$Root  = ' & $Root, 'ExecutePackageStep')

						$Args = $Params[2]
						If $DebugMode = 1 Then LogIt($DEBUG, '$Args  = ' & $Args, 'ExecutePackageStep')
					Else
						LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
						LogIt($ERROR, 'Incorrect Number of parameters detected for CMD.', 'ExecutePackageStep')
						LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
						$mainReturnCode = 2901

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				Else
					LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
					LogIt($ERROR, 'Expected Arguments for ComSpec and found none.', 'ExecutePackageStep')
					LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf

				If StringInStr($Root, '.cmd') Or StringInStr($Root, '.bat') Then
					If $DebugMode = 1 Then LogIt($DEBUG, 'Script detected as command string.', 'ExecutePackageStep')
					If FileExists($Root) Then
						If $DebugMode = 1 Then LogIt($DEBUG, 'Verified script exsits.', 'ExecutePackageStep')
						$Command = @ComSpec & ' /c ' & $Root & ' ' & $Args
						If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
					Else
						If $DebugMode = 1 Then LogIt($DEBUG, 'Could not verify script exists. Checking in current directory.', 'ExecutePackageStep')
						If FileExists($WorkingPath & '\' & $Root) Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Discovered Script in Working Directory. Updating Command Root.', 'ExecutePackageStep')
							$Root = $WorkingPath & '\' & $Root

							$Command = @ComSpec & ' /c ' & $Root & ' ' & $Args
							If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
						Else
							LogIT($ERROR, 'Cannot find script to execute.', 'ExecutePackageStep')
							$mainReturnCode = 2901

							;- Set the Current step progress based on the action we are currently doing in the step array

							Return 0
						EndIf
					EndIf
				Else
					If $DebugMode = 1 Then LogIt($DEBUG, 'Standard dos command found.', 'ExecutePackageStep')
					$Command = @ComSpec & ' /c ' & $Root & ' ' & $Args
					If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
				EndIf
			Else
				LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
				LogIt($ERROR, 'Expected Arguments for ComSpec and found none.', 'ExecutePackageStep')
				LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
				$mainReturnCode = 2901

				;- Set the Current step progress based on the action we are currently doing in the step array

				Return 0
			EndIf
		Case $CommandLine = 'CSCRIPT'
			If $DebugMode = 1 Then LogIt($DEBUG, 'CSCRIPT variable detected. Executing script with cscript handler.', 'ExecutePackageStep')
			If Not $Arguments = '' Then
				If $DebugMode = 1 Then LogIt($DEBUG, 'Arguments detected for cscript.', 'ExecutePackageStep')
				$Params = StringSplit($Arguments, ';')
				If IsArray($Params) Then
					If UBound($Params) = 3 Then
						$Root = $Params[1]
						If $DebugMode = 1 Then LogIt($DEBUG, '$Root  = ' & $Root, 'ExecutePackageStep')

						$Args = $Params[2]
						If $DebugMode = 1 Then LogIt($DEBUG, '$Args  = ' & $Args, 'ExecutePackageStep')
					Else
						LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
						LogIt($ERROR, 'Incorrect Number of parameters detected for CSCRIPT.', 'ExecutePackageStep')
						LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
						$mainReturnCode = 2901

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				Else
					LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
					LogIt($ERROR, 'Expected Script file to execute with CSCRIPT and found none.', 'ExecutePackageStep')
					LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf

				If StringInStr($Root, '.vbs') Or StringInStr($Root, '.wsf') Then
					If FileExists($Root) Then
						If $DebugMode = 1 Then LogIt($DEBUG, 'Verified script exists.', 'ExecutePackageStep')
						$Command = @ComSpec & ' /c cscript //B //NoLogo ' & $Root & ' ' & $Args
						If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
					Else
						If $DebugMode = 1 Then LogIt($DEBUG, 'Could not verify if script exists. Checking current directory', 'ExecutePackageStep')
						If FileExists($WorkingPath & '\' & $Root) Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Discovered Script in Working Directory. Updating Command Root.', 'ExecutePackageStep')
							$Root = $WorkingPath & '\' & $Root

							$Command = @ComSpec & ' /c cscript //B //NoLogo ' & $Root & ' ' & $Args
							If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
						Else
							LogIT($ERROR, 'Cannot find script to execute.', 'ExecutePackageStep')
							$mainReturnCode = 2901

							;- Set the Current step progress based on the action we are currently doing in the step array

							Return 0
						EndIf
					EndIf
				Else
					LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
					LogIt($ERROR, 'Expected Script file to execute with CSCRIPT and found none.', 'ExecutePackageStep')
					LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf
			Else
				LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
				LogIt($ERROR, 'Expected Arguments for ComSpec and found none.', 'ExecutePackageStep')
				LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
				$mainReturnCode = 2901

				;- Set the Current step progress based on the action we are currently doing in the step array

				Return 0
			EndIf
		Case $CommandLine = 'PS1'
			If $DebugMode = 1 Then LogIt($DEBUG, 'PS1 Variable detected. Executing command or script using powershell.', 'ExecutePackageStep')
			;- Validate the parameters aren't empty
			If Not $Arguments = '' Then
				If $DebugMode = 1 Then LogIt($DEBUG, 'Arguments for PS1 detected', 'ExecutePackageStep')
				;- Split the parameter set on the semi-colon
				$Params = StringSplit($Arguments, ';')
				If IsArray($Params) Then
					If UBound($Params) = 3 Then
						$Root = $Params[1]
						If $DebugMode = 1 Then LogIt($DEBUG, '$Root  = ' & $Root, 'ExecutePackageStep')

						$Args = $Params[2]
						If $DebugMode = 1 Then LogIt($DEBUG, '$Args  = ' & $Args, 'ExecutePackageStep')
					Else
						LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
						LogIt($ERROR, 'Incorrect Number of parameters detected for PS1.', 'ExecutePackageStep')
						LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
						$mainReturnCode = 2901

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				Else
					LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
					LogIt($ERROR, 'Expected Script file to execute with PS1 and found none.', 'ExecutePackageStep')
					LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf

				;- Check if our root is a script or cmdlet
				If StringInStr($Root, '.ps1') Then
					If $DebugMode = 1 Then LogIt($DEBUG, 'Found script as first argument. Valdiating existence.', 'ExecutePackageStep')
					;- Validate we can find the script
					If FileExists($Root) Then
						If $DebugMode = 1 Then LogIt($DEBUG, 'Verified script exists.', 'ExecutePackageStep')
						$Command = @SystemDir & '\WindowsPowerShell\v1.0\powershell.exe' & ' -NoLogo -NoProfile -ExecutionPolicy Bypass -File ' & $Root & ' ' & $Args
						If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
					Else
						If $DebugMode = 1 Then LogIt($DEBUG, 'Could not verify script exists. Checking current directory.', 'ExecutePackageStep')
						If FileExists($WorkingPath & '\' & $Root) Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Discovered Script in Working Directory. Updating Command Root.', 'ExecutePackageStep')
							$Root = $WorkingPath & '\' & $Root

							$Command = @SystemDir & '\WindowsPowerShell\v1.0\powershell.exe' & ' -NoLogo -NoProfile -ExecutionPolicy Bypass -File ' & $Root & ' ' & $Args
							If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
						Else
							LogIT($ERROR, 'Cannot find script to execute.', 'ExecutePackageStep')
							$mainReturnCode = 2901

							;- Set the Current step progress based on the action we are currently doing in the step array

							Return 0
						EndIf
					EndIf
				Else
					If $DebugMode = 1 Then LogIt($DEBUG, 'Verifing that the command is a proper cmdlet.', 'ExecutePackageStep')
					;- Ensure we have a cmdlet by Root on - and checking for 2 attributes. Any more or less isn't a valid cmdlet (Verb-Noun)
					Local $cmdlet = StringSplit($Root, '-')

					If $cmdlet[0] = 2 Then
						If $DebugMode = 1 Then LogIt($DEBUG, 'Proper Cmdlet detected.', 'ExecutePackageStep')
						$Command = @SystemDir & '\WindowsPowerShell\v1.0\powershell.exe' & ' -NoLogo -NoProfile -ExecutionPolicy Bypass ' & '-Command "& {' & $Root & $Args & '}"'
						If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
					Else
						LogIT($ERROR, 'Command string is not a valid PowerShell Cmdlet. A proper cmdlet is identified by a Verb-Noun pair seperated by a "-".', 'ExecutePackageStep')
						$mainReturnCode = 2901


						Return 0
					EndIf
				EndIf
			Else
				LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
				LogIt($ERROR, 'Expected Arguments for Powershell.exe and found none.', 'ExecutePackageStep')
				LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
				$mainReturnCode = 2901

				;- Set the Current step progress based on the action we are currently doing in the step array

				Return 0
			EndIf
		Case $CommandLine = 'COPYFILE'
			If $DebugMode = 1 Then LogIt($DEBUG, 'COPYFILE variable detected.', 'ExecutePackageStep')
			If Not $Arguments = '' Then
				If $DebugMode = 1 Then LogIt($DEBUG, 'Arguments detected for COPYFILE.', 'ExecutePackageStep')
				$Params = StringSplit($Arguments, ';')
				If IsArray($Params) Then
					If UBound($Params) = 3 Then
						$Source = $Params[1]
						If $DebugMode = 1 Then LogIt($DEBUG, '$Source  = ' & $Source, 'ExecutePackageStep')

						$Destination = $Params[2]
						If $DebugMode = 1 Then LogIt($DEBUG, '$Destination  = ' & $Destination, 'ExecutePackageStep')
					Else
						LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
						LogIt($ERROR, 'Incorrect Number of parameters detected for COPYFILE.', 'ExecutePackageStep')
						LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
						$mainReturnCode = 2901

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				Else
					LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
					LogIt($ERROR, 'Expected Parameters for COPYFILE and found none.', 'ExecutePackageStep')
					LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf

				;- Validate Source Exists
				If $DebugMode = 1 Then LogIt($DEBUG, 'Checking that source exists.', 'ExecutePackageStep')
				If FileExists($Source) Then
					If $DebugMode = 1 Then LogIt($DEBUG, 'Validated Source exists for COPYFOLDER Action.', 'ExecutePackageStep')
				Else
					;- Try appending the working directory to the source and see if we find it
					If FileExists($WorkingPath & '\' & $Source) Then
						If $DebugMode = 1 Then LogIt($DEBUG, 'Validated Source exists in Working Directory for COPYFOLDER Action. Updating Source Variable.', 'ExecutePackageStep')
						$Source = $WorkingPath & '\' & $Source
					Else
						LogIt($ERROR, 'Could not locate source file.', 'ExecutePackageStep')

						$mainReturnCode = 2

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				EndIf

				If $DebugMode = 1 Then LogIt($DEBUG, 'Checking for Destination.', 'ExecutePackageStep')
				;- Validate Destination Exists
				If Not FileExists($Destination) Then
					LogIt($WARNING, 'Destination directory does not exist. Will create it.', 'ExecutePackageStep')
					Local $Result = DirCreate($Destination)
					If $Result = 1 Then
						LogIt($INFORMATION, 'Successfully created destination directory.', 'ExecutePackageStep')
					Else
						LogIt($ERROR, 'Could not create destination directory.', 'ExecutePackageStep')

						$mainReturnCode = 2

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				EndIf

				Local $Result
				$Result = FileCopy($Source, $Destination, $FC_OVERWRITE + $FC_CREATEPATH)
				If $Result = 1 Then
					LogIt($INFORMATION, 'File Copy from ' & $Source & ' to ' & $Destination & ' was successfull.', 'ExecutePackageStep')
					$mainReturnCode = 0

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				Else
					LogIT($ERROR, 'File Copy from ' & $Source & ' to ' & $Destination & ' was unsuccessfull.', 'ExecutePackageStep')
					$mainReturnCode = 2

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf
			Else
				LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
				LogIt($ERROR, 'Expected Arguments for COPYFILE and found none.', 'ExecutePackageStep')
				LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
				$mainReturnCode = 2901

				;- Set the Current step progress based on the action we are currently doing in the step array

				Return 0
			EndIf
		Case $CommandLine = 'REG'
			If $DebugMode = 1 Then LogIt($DEBUG, 'REG variable detected.', 'ExecutePackageStep')
			If Not $Arguments = '' Then
				If $DebugMode = 1 Then LogIt($DEBUG, 'Arguments detected for REG.', 'ExecutePackageStep')
				$Params = StringSplit($Arguments, ';')
				If IsArray($Params) Then
					If UBound($Params) = 7 Then
						$ACTION = $Params[1]
						If $DebugMode = 1 Then LogIt($DEBUG, '$ACTION  = ' & $ACTION, 'ExecutePackageStep')

						$RegHIVE = $Params[2]
						If $DebugMode = 1 Then LogIt($DEBUG, '$RegHIVE  = ' & $RegHIVE, 'ExecutePackageStep')

						$RegPATH = $Params[3]
						If $DebugMode = 1 Then LogIt($DEBUG, '$RegPATH  = ' & $RegPATH, 'ExecutePackageStep')

						$VALUENAME = $Params[4]
						If $DebugMode = 1 Then LogIt($DEBUG, '$VALUENAME  = ' & $VALUENAME, 'ExecutePackageStep')

						$VALUETYPE = $Params[5]
						If $DebugMode = 1 Then LogIt($DEBUG, '$VALUETYPE  = ' & $VALUETYPE, 'ExecutePackageStep')

						$VALUEDATA = $Params[6]
						If $DebugMode = 1 Then LogIt($DEBUG, '$VALUEDATA  = ' & $VALUEDATA, 'ExecutePackageStep')
					Else
						LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
						LogIt($ERROR, 'Incorrect Number of parameters detected for REG.', 'ExecutePackageStep')
						LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
						$mainReturnCode = 2901

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				Else
					LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
					LogIt($ERROR, 'Expected Parameters for REG and found none.', 'ExecutePackageStep')
					LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf

				If StringLower($ACTION) = 'add' Then
					Local $Result
					$Result = RegWrite($RegHIVE & '\' & $RegPATH, $VALUENAME, $VALUETYPE, $VALUEDATA)
					If $Result = 1 Then
						LogIt($INFORMATION, 'Successfully wrote registry key or value.', 'ExecutePackageStep')
						$mainReturnCode = 0

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					Else
						LogIT($ERROR, 'Failed to write registry key or value.', 'ExecutePackageStep')
						Select
							Case @error = 1
								If $DebugMode = 1 Then LogIt($DEBUG, 'unable to open requested key ' & $RegHIVE & '\' & $RegPATH, 'ExecutePackageStep')
								$mainReturnCode = 1
							Case @error = 2
								If $DebugMode = 1 Then LogIt($DEBUG, 'unable to open requested ExecutePackageStep key ' & $RegHIVE & '\' & $RegPATH, 'ExecutePackageStep')
								$mainReturnCode = 2
							Case @error = 3
								If $DebugMode = 1 Then LogIt($DEBUG, 'unable to remote connect to the registry ' & $RegHIVE & '\' & $RegPATH, 'ExecutePackageStep')
								$mainReturnCode = 3
							Case @error = -1
								If $DebugMode = 1 Then LogIt($DEBUG, 'unable to open requested value' & $RegHIVE & '\' & $RegPATH & '\' & $VALUENAME, 'ExecutePackageStep')
								$mainReturnCode = -1
							Case @error = -2
								If $DebugMode = 1 Then LogIt($DEBUG, 'value type not supported ' & $VALUETYPE, 'ExecutePackageStep')
								$mainReturnCode = -2
						EndSelect

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				ElseIf StringLower($ACTION) = 'remove' Then
					Local $Result
					$Result = RegDelete($RegHIVE & '\' & $RegPATH, $VALUENAME)
					If $Result = 1 Then
						LogIt($INFORMATION, 'Successfully deleted registry key or value.', 'ExecutePackageStep')
						$mainReturnCode = 0

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					Else
						LogIT($ERROR, 'Failed to write registry key.', 'ExecutePackageStep')
						Select
							Case @error = 1
								If $DebugMode = 1 Then LogIt($DEBUG, 'unable to open requested key ' & $RegHIVE & '\' & $RegPATH, 'ExecutePackageStep')
								$mainReturnCode = 1
							Case @error = 2
								If $DebugMode = 1 Then LogIt($DEBUG, 'unable to open requested ExecutePackageStep key ' & $RegHIVE & '\' & $RegPATH, 'ExecutePackageStep')
								$mainReturnCode = 2
							Case @error = 3
								If $DebugMode = 1 Then LogIt($DEBUG, 'unable to remote connect to the registry ' & $RegHIVE & '\' & $RegPATH, 'ExecutePackageStep')
								$mainReturnCode = 3
							Case @error = -1
								If $DebugMode = 1 Then LogIt($DEBUG, 'unable to open requested value' & $RegHIVE & '\' & $RegPATH & '\' & $VALUENAME, 'ExecutePackageStep')
								$mainReturnCode = -1
							Case @error = -2
								If $DebugMode = 1 Then LogIt($DEBUG, 'unable to delete requested key/value ' & $RegHIVE & '\' & $RegPATH & '\' & $VALUENAME, 'ExecutePackageStep')
								$mainReturnCode = -2
						EndSelect

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				EndIf
			Else
				LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
				LogIt($ERROR, 'Expected Arguments for REG and found none.', 'ExecutePackageStep')
				LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
				$mainReturnCode = 2901

				;- Set the Current step progress based on the action we are currently doing in the step array

				Return 0
			EndIf
		Case $CommandLine = 'COPYFOLDER'
			If $DebugMode = 1 Then LogIt($DEBUG, 'COPYFOLDER variable detected.', 'ExecutePackageStep')
			If Not $Arguments = '' Then
				If $DebugMode = 1 Then LogIt($DEBUG, 'Arguments detected for COPYFILE.', 'ExecutePackageStep')
				$Params = StringSplit($Arguments, ';')
				If IsArray($Params) Then
					If UBound($Params) = 3 Then
						$Source = $Params[1]
						If $DebugMode = 1 Then LogIt($DEBUG, '$Source  = ' & $Source, 'ExecutePackageStep')

						$Destination = $Params[2]
						If $DebugMode = 1 Then LogIt($DEBUG, '$Destination  = ' & $Destination, 'ExecutePackageStep')
					Else
						LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
						LogIt($ERROR, 'Incorrect Number of parameters detected for COPYFOLDER.', 'ExecutePackageStep')
						LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
						$mainReturnCode = 2901

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				Else
					LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
					LogIt($ERROR, 'Expected Parameters for COPYFOLDER and found none.', 'ExecutePackageStep')
					LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf

				If $DebugMode = 1 Then LogIt($DEBUG, 'Checking that source exists.', 'ExecutePackageStep')
				;- Validate Source Exists
				If FileExists($Source) Then
					If $DebugMode = 1 Then LogIt($DEBUG, 'Validated Source exists for COPYFOLDER Action.', 'ExecutePackageStep')
				Else
					;- Try appending the working directory to the source and see if we find it
					If FileExists($WorkingPath & '\' & $Source) Then
						If $DebugMode = 1 Then LogIt($DEBUG, 'Validated Source exists in Working Directory for COPYFOLDER Action. Updating Source Variable.', 'ExecutePackageStep')
						$Source = $WorkingPath & '\' & $Source
					Else
						LogIt($ERROR, 'Could not locate source directory.', 'ExecutePackageStep')

						$mainReturnCode = 2

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				EndIf

				If $DebugMode = 1 Then LogIt($DEBUG, 'Checking for Destination.', 'ExecutePackageStep')
				;- Validate Destination Exists
				If Not FileExists($Destination) Then
					LogIt($WARNING, 'Destination directory does not exist. Will create it.', 'ExecutePackageStep')
					Local $Result = DirCreate($Destination)
					If $Result = 1 Then
						LogIt($INFORMATION, 'Successfully created destination directory.', 'ExecutePackageStep')
					Else
						LogIt($ERROR, 'Could not create destination directory.', 'ExecutePackageStep')

						$mainReturnCode = 2

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				EndIf

				;- Copy the directroy
				Local $Result
				$Result = DirCopy($Source, $Destination, $FC_OVERWRITE)
				If $Result = 1 Then
					LogIt($INFORMATION, 'Folder Copy from ' & $Source & ' to ' & $Destination & ' was successfull.', 'ExecutePackageStep')
					$mainReturnCode = 0

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				Else
					LogIT($ERROR, 'Folder Copy from ' & $Source & ' to ' & $Destination & ' was unsuccessfull.', 'ExecutePackageStep')
					$mainReturnCode = 2

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf
			Else
				LogIt($ERROR, 'Command line for Step ' & $Step & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
				LogIt($ERROR, 'Expected Arguments for COPYFOLDER and found none.', 'ExecutePackageStep')
				LogIt($ERROR, "Step " & $Step & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
				$mainReturnCode = 2901

				;- Set the Current step progress based on the action we are currently doing in the step array

				Return 0
			EndIf
		Case $CommandLine = 'FIREWALL'
			If $DebugMode = 1 Then LogIt($DEBUG, 'FIREWALL variable detected.', 'ExecutePackageStep')
			If Not $Arguments = '' Then
				If $DebugMode = 1 Then LogIt($DEBUG, 'Arguments detected for FIREWALL.', 'ExecutePackageStep')
				$Params = StringSplit($Arguments, ';')
				If IsArray($Params) Then
					If UBound($Params) = 6 Then
						$RuleName = $Params[1]
						$Direction = $Params[2]
						$ACTION = $Params[3]
						$Program = $Params[4]
						$Profile = $Params[5]

						If $DebugMode = 1 Then LogIt($DEBUG, 'Validating Parameters for FIREWALL.', 'ExecutePackageStep')
						If $RuleName = '' Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Rule Name was blank. Filling in with current package name.', 'ExecutePackageStep')
							$RuleName = StringSplit($Packages[$j], '_')[2]
						EndIf

						If $Direction = '' Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Direction was not specified. Assuming direction in.', 'ExecutePackageStep')
							$Direction = 'in'
						EndIf

						If $ACTION = '' Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Action was not specified. Using action "allow".', 'ExecutePackageStep')
							$ACTION = 'allow'
						EndIf

						If $Profile = '' Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Profile was not specified. Using profile "any".', 'ExecutePackageStep')
							$Profile = 'any'
						EndIf

						If $Program = '' Then
							LogIt($ERROR, 'No program was specified for the Firewall rule to apply too. This is required.', 'ExecutePackageStep')
							$mainReturnCode = 2901


							Return 0
						EndIf

						$Command = @ComSpec & ' /c netsh advfirewall firewall add rule name="' & $RuleName & '" dir=' & $Direction & ' action=' & $ACTION & ' program="' & $Program & '" profile=' & $Profile & ' enable=yes'
						If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
					ElseIf UBound($Params) = 7 Then
						$RuleName = $Params[1]
						$Direction = $Params[2]
						$ACTION = $Params[3]
						$Protocol = $Params[4]
						$LocalPort = $Params[5]
						$Profile = $Params[6]

						If $DebugMode = 1 Then LogIt($DEBUG, 'Validating Parameters for FIREWALL.', 'ExecutePackageStep')
						If $RuleName = '' Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Rule Name was blank. Filling in with current package name.', 'ExecutePackageStep')
							$RuleName = StringSplit($Packages[$j], '_')[2]
						EndIf

						If $Direction = '' Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Direction was not specified. Assuming direction in.', 'ExecutePackageStep')
							$Direction = 'in'
						EndIf

						If $Profile = '' Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Profile was not specified. Using profile "any".', 'ExecutePackageStep')
							$Profile = 'any'
						EndIf

						If $ACTION = '' Then
							If $DebugMode = 1 Then LogIt($DEBUG, 'Action was not specified. Using action "allow".', 'ExecutePackageStep')
							$ACTION = 'allow'
						EndIf

						If $Protocol = '' Then
							LogIt($ERROR, 'No protocol was specified in the command line. This is required.', 'ExecutePackageStep')
							$mainReturnCode = 2901


							Return 0
						EndIf

						If $LocalPort = '' Then
							LogIt($ERROR, 'No Local Port was specified in the command line. This is required.', 'ExecutePackageStep')
							$mainReturnCode = 2901


							Return 0
						EndIf

						$Command = @ComSpec & ' /c netsh advfirewall firewall add rule name="' & $RuleName & '" dir=' & $Direction & ' action=' & $ACTION & ' protocol=' & $Protocol & ' localport=' & $LocalPort & ' profile=' & $Profile & ' enable=yes'
						If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
					Else
						LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
						LogIt($ERROR, 'Incorrect Number of parameters detected for FIREWALL.', 'ExecutePackageStep')
						LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
						$mainReturnCode = 2901

						;- Set the Current step progress based on the action we are currently doing in the step array

						Return 0
					EndIf
				Else
					LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
					LogIt($ERROR, 'Expected Parameters for FIREWALL and found none.', 'ExecutePackageStep')
					LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf
			Else
				LogIt($ERROR, 'Command line for Step ' & $StepTitle & ' of package ' & $PackageName & ' is invalid.', 'ExecutePackageStep')
				LogIt($ERROR, 'Expected Arguments for FIREWALL and found none.', 'ExecutePackageStep')
				LogIt($ERROR, "Step " & $StepTitle & " of " & $PackageName & " failed to install.", "ExecutePackageStep")
				$mainReturnCode = 2901

				;- Set the Current step progress based on the action we are currently doing in the step array

				Return 0
			EndIf
		Case Else
			If $DebugMode = 1 Then LogIt($DEBUG, 'No specialized actions were detected. Executing normally', 'ExecutePackageStep')

			If StringRight(StringLower($CommandLine), 3) = 'msi' Then
				If $DebugMode = 1 Then LogIt($DEBUG, "Command string is referencing an MSI. Prefacing command with msiexec /i", "ExecutePackageStep")

				If $DebugMode = 1 Then LogIt($DEBUG, "Validating Commandline exists", "ExecutePackageStep")
				If FileExists($CommandLine) Then
					If $DebugMode = 1 Then LogIt($DEBUG, "Validated CommandLine exists.", "ExecutePackageStep")
					$Command = 'msiexec /i ' & $CommandLine & ' ' & $Arguments
					If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
				ElseIf FileExists($WorkingPath & '\' & $CommandLine) Then
					If $DebugMode = 1 Then LogIt($DEBUG, "Validated CommandLine exists in current directory. Updating CommandLine.", "ExecutePackageStep")
					$CommandLine = $WorkingPath & '\' & $CommandLine

					$Command = 'msiexec /i ' & $CommandLine & ' ' & $Arguments
					If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
				Else
					LogIt($ERROR, 'Could not find CommandLine to execute. Cannot proceed.', 'ExecutePackageStep')
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf
			ElseIf StringRight(StringLower($CommandLine), 3) = 'msp' Then
				If $DebugMode = 1 Then LogIt($DEBUG, "Command string is referencing an MSP. Prefacing command with msiexec /update", "ExecutePackageStep")

				If $DebugMode = 1 Then LogIt($DEBUG, "Validating Commandline exists", "ExecutePackageStep")
				If FileExists($CommandLine) Then
					If $DebugMode = 1 Then LogIt($DEBUG, "Validated CommandLine exists.", "ExecutePackageStep")
					$Command = 'msiexec /update ' & $CommandLine & ' ' & $Arguments
					If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
				ElseIf FileExists($WorkingPath & '\' & $CommandLine) Then
					If $DebugMode = 1 Then LogIt($DEBUG, "Validated CommandLine exists in current directory. Updating CommandLine.", "ExecutePackageStep")
					$CommandLine = $WorkingPath & '\' & $CommandLine

					$Command = 'msiexec /update ' & $CommandLine & ' ' & $Arguments
					If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
				Else
					LogIt($ERROR, 'Could not find CommandLine to execute. Cannot proceed.', 'ExecutePackageStep')
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf
			ElseIf StringRight(StringLower($CommandLine), 3) = 'msu' Then
				If $DebugMode = 1 Then LogIt($DEBUG, "Command string is referencing an MSU. Prefacing command with wusa", "ExecutePackageStep")

				If $DebugMode = 1 Then LogIt($DEBUG, "Validating Commandline exists", "ExecutePackageStep")
				If FileExists($CommandLine) Then
					If $DebugMode = 1 Then LogIt($DEBUG, "Validated CommandLine exists.", "ExecutePackageStep")
					$Command = 'wusa ' & $CommandLine & ' ' & $Arguments
					If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
				ElseIf FileExists($WorkingPath & '\' & $CommandLine) Then
					If $DebugMode = 1 Then LogIt($DEBUG, "Validated CommandLine exists in current directory. Updating CommandLine.", "ExecutePackageStep")
					$CommandLine = $WorkingPath & '\' & $CommandLine

					$Command = 'wusa ' & $CommandLine & ' ' & $Arguments
					If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
				Else
					LogIt($ERROR, 'Could not find CommandLine to execute. Cannot proceed.', 'ExecutePackageStep')
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf
			Else
				If $DebugMode = 1 Then LogIt($DEBUG, "Checking for CommandLine existence.", "ExecutePackageStep")
				If FileExists($CommandLine) Then
					If $DebugMode = 1 Then LogIt($DEBUG, "Validated CommandLine exists.", "ExecutePackageStep")
					$Command = $CommandLine & ' ' & $Arguments
					If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
				ElseIf FileExists($WorkingPath & '\' & $CommandLine) Then
					If $DebugMode = 1 Then LogIt($DEBUG, "Validated CommandLine exists in current directory. Updating CommandLine.", "ExecutePackageStep")
					$CommandLine = $WorkingPath & '\' & $CommandLine

					$Command = $CommandLine & ' ' & $Arguments
					If $DebugMode = 1 Then LogIt($DEBUG, "Command: " & $Command, 'ExecutePackageStep')
				Else
					LogIt($ERROR, 'Could not find CommandLine to execute. Cannot proceed.', 'ExecutePackageStep')
					$mainReturnCode = 2901

					;- Set the Current step progress based on the action we are currently doing in the step array

					Return 0
				EndIf
			EndIf
	EndSelect

	If $DebugMode = 1 Then LogIt($DEBUG, "Executing action: " & $Command, "ExecutePackageStep")
	Local $Result
	$Result = RunWait($Command, $WorkingPath, @SW_HIDE)
	If $DebugMode = 1 Then LogIt($DEBUG, "Action returned " & $Result, "ExecutePackageStep")

	If $useCustomExit = 1 Then
		$CustomReturns = _ArraySearch($ExitCodes, $Result, 1)
		If $CustomReturns <> -1 Then
			If $ExitCodes[$CustomReturns][1] = 'Fail' Then
				LogIT($ERROR, 'Action ' & $StepTitle & ' failed for ' & $PackageName, "ExecutePackageStep")
				$mainReturnCode = $Result
			ElseIf $ExitCodes[$CustomReturns][1] = 'Success' Then
				LogIt($INFORMATION, "" & $StepTitle & " completed successfully.", "ExecutePackageStep")
				$mainReturnCode = $Result
			EndIf
		Else
			If $DebugMode = 1 Then LogIt($DEBUG, "Did not find matching custom return code. Assuming failed.", "ExecutePackageStep")
			LogIT($ERROR, 'Action ' & $StepTitle & ' failed for ' & $PackageName & ". Return Code: " & $Result, "ExecutePackageStep")
			$mainReturnCode = $Result
		EndIf
	Else
		If $Result = 0 Then
			LogIt($INFORMATION, "" & $StepTitle & " completed successfully.", "ExecutePackageStep")
			$mainReturnCode = 0
		ElseIf $Result = 3010 Then
			LogIt($INFORMATION, "" & $StepTitle & " completed successfully.", "ExecutePackageStep")
			$mainReturnCode = 0
		Else
			LogIt($WARNING, "" & $StepTitle & " failed to install. Return Code: " & $Result, " ExecutePackageStep")
			$mainReturnCode = $Result
		EndIf
	EndIf

	Return 1
EndFunc   ;==>ExecutePackageStep


#comments-start FUNCTION: ExpandRequiredFiles
	#FUNCTION# ===========================================================================================================
	Name...........: ProcessSettings
    Description ...: Read the provided settings.ini file in the known format and
    set the global variables as defined in the settings
	Syntax.........: ProcessSettings($SettingsFile)
	Parameters ....: SettingsFile - Defines the path of the settings.ini

	Return values .: Success - Returns 1
	Failure - Returns 0

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: ExpandRequiredFiles
Func ProcessSettings($SettingsFile)
	If FileExists($SettingsFile) Then
		; Process Main Settings
		$TotalPackages = IniRead($SettingsFile, 'Main', 'TotalPackages', '0')
		$CleanupSettings = IniRead($SettingsFile, 'Main', 'CleanUpFolders', 'True')
		$RebootSettings = IniRead($SettingsFile, 'Main', 'Reboot', 'False')
		; Process branding Settings
		$Gui_Logo = IniRead($SettingsFile, 'branding', 'Logo', 'Null')
		$Gui_Icon = IniRead($SettingsFile, 'branding', 'Icon', 'Null')
		; Process ExecutionOrder
		$ExecutionOrder = IniReadSection($SettingsFile, 'ExecutionOrder')
	Else
		Return 0
	EndIf

	Return 1
EndFunc   ;==>ProcessSettings

#comments-start FUNCTION: ExpandRequiredFiles
	#FUNCTION# ===========================================================================================================
	Name...........: ExpandRequiredFiles
	Description ...: Defines files to be included in the compiled executable and then extracted
	during program execution.
	Syntax.........: ExpandRequiredFiles()
	Parameters ....: None

	Return values .: Success - Returns 1
	Failure - Returns 0 if one or more files fails to extract

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: ExpandRequiredFiles
Func ExpandRequiredFiles()
	LogIt($INFORMATION, "Extracting any defined required files to " & $TempDir, "ExpandRequiredFiles")

	Local $Result, $Return = 1

	If $DebugMode = 1 Then LogIt($DEBUG, "Extracting resource files.", "Main")
	$Result = FileInstall("Resources\logo.png", $TempDir & '\', $FC_OVERWRITE)
	If $Result = 1 Then
		If $DebugMode = 1 Then LogIt($DEBUG, "File extracted successfully.", "ExpandRequiredFiles")
	Else
		If $DebugMode = 1 Then LogIt($DEBUG, "File failed to extract.", "ExpandRequiredFiles")
		$Return = 0
	EndIf
	$Result = FileInstall("Resources\icon.ico", $TempDir & '\', $FC_OVERWRITE)
	If $Result = 1 Then
		If $DebugMode = 1 Then LogIt($DEBUG, "File extracted successfully.", "ExpandRequiredFiles")
	Else
		If $DebugMode = 1 Then LogIt($DEBUG, "File failed to extract.", "ExpandRequiredFiles")
		$Return = 0
	EndIf

	Return $Return
EndFunc   ;==>ExpandRequiredFiles

#comments-start FUNCTION: DisplaySplashScreen
	#FUNCTION# ===========================================================================================================
	Name...........: DisplaySplashScreen
	Description ...: Display the splash screen during initialization
	Syntax.........: DisplaySplashScreen()
	Parameters ....: None
	Return values .: None
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: DisplaySplashScreen
Func DisplaySplashScreen()
	$SplashScreen = GUICreate("Image Complete Tool", 442, 252, @DesktopWidth / 2.95, @DesktopHeight / 3.2, $WS_POPUP)
	GUISetBkColor(0x2b579a)     ;Word Blue

	Local $apos = WinGetPos($SplashScreen)
	WinMove($SplashScreen, "", (@DesktopWidth / 2) - ($apos[2] / 2), (@DesktopHeight / 2) - ($apos[3] / 2))

	$Publisher = GUICtrlCreateLabel("Ascanio.net", 8, 8, 250, 21)
	GUICtrlSetFont($Publisher, 10, 400, 0, "Segoe UI Light")
	GUICtrlSetColor($Publisher, 0xFFFFFF)

	$AppName = GUICtrlCreateLabel("Image Completion Tool", 54, 72, 330, 75, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetFont($AppName, 26, 400, 0, "Segoe UI Light")
	GUICtrlSetColor($AppName, 0xFFFFFF)

	$Status = GUICtrlCreateLabel("Starting...", 10, 205, 200, 21)
	GUICtrlSetFont($Status, 10, 400, 0, "Segoe UI Light")
	GUICtrlSetColor($Status, 0xFFFFFF)

	GUISetState(@SW_SHOW)
EndFunc   ;==>DisplaySplashScreen

#comments-start FUNCTION: DisplayMainGUI
	#FUNCTION# ===========================================================================================================
	Name...........: DisplayMainGUI
	Description ...: Initialize and display the main gui window
	Syntax.........: DisplayMainGUI()
	Parameters ....: None
	Return values .: None
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: DisplayMainGUI
Func DisplayMainGUI()
	### START Koda GUI section ### Form=D:\CodeControl\Program Source\GoldImageCompletion\GUI\Factory Image Completion.kxf
	;- Create the GUI Object
	$main_gui = GUICreate("Completing Image", 800, 278, 290, 770, 0, BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))

	Local $apos = WinGetPos($main_gui)
	WinMove($main_gui, "", (@DesktopWidth / 2) - ($apos[2] / 2), (@DesktopHeight / 2) - ($apos[3] / 2))

	;- Define the GUI settings
	GUISetIcon($icon, -1)
	GUISetFont(10, 400, 0, "Segoe UI")
	GUISetBkColor(0xFFFFFF)

	;- Create the GUI Logo Object
	Local $it_Logo = GUICtrlCreatePic("", 8, 8, 378, 100)
	_GDIPlus_Startup()
	$hImage = _GDIPlus_ImageLoadFromFile($png)
	Local $Bmp = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
	_WinAPI_DeleteObject(GUICtrlSendMsg($it_Logo, $STM_SETIMAGE, $IMAGE_BITMAP, $Bmp))

	;- Creating the Progress Labels
	$overall_Label = GUICtrlCreateLabel("Overall Progress:", 40, 190, 132, 25)
	$current_Progress_Label = GUICtrlCreateLabel("Current Step Progress:", 40, 129, 172, 25)

	;- Creating the Progress Bars
	$overall_Progress = GUICtrlCreateProgress(40, 216, 700, 20)
	$current_Progress = GUICtrlCreateProgress(40, 160, 700, 20)
	$marqProgress = GUICtrlCreateProgress(40, 160, 700, 20, BitOR($PBS_MARQUEE, $PBS_SMOOTH))
	$oStepPercentLabel = GUICtrlCreateLabel("", 741, 160, 31, 21)
	$oCompletePercentLabel = GUICtrlCreateLabel("", 741, 216, 31, 21)

	;- Progress Action Indicator
	$current_progress_action = GUICtrlCreateLabel("", 207, 131, 400, 21)
	$overall_progress_action = GUICtrlCreateLabel("", 177, 190, 400, 21)

	;- Creating the Device info Group
	$dev_Info = GUICtrlCreateGroup("Device Information", 536, 8, 240, 97)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	;- Create Device Information Labels
	$hostname_Label = GUICtrlCreateLabel("Hostname:", 551, 32, 90, 21)
	$ip_label = GUICtrlCreateLabel("IP Address:", 551, 54, 90, 21)
	$mac_address_label = GUICtrlCreateLabel("MAC Address:", 551, 76, 90, 21)

	;- Create Device Information Value Labels
	$hostname = GUICtrlCreateLabel('', 647, 32, 120, 21)
	$ipaddress = GUICtrlCreateLabel('', 647, 54, 120, 21)
	$mac_address = GUICtrlCreateLabel('', 647, 76, 120, 21)

	;- Create Step Counters
	$step_total = GUICtrlCreateLabel('', 722, 136, 22, 21)
	$cur_step = GUICtrlCreateLabel('', 695, 136, 22, 21)
	$step_seperator = GUICtrlCreateLabel("/", 709, 136, 6, 21)

	$overal_step_total = GUICtrlCreateLabel('', 722, 191, 22, 21)
	$cur_overall_step = GUICtrlCreateLabel('', 695, 191, 22, 21)
	$overall_step_sep = GUICtrlCreateLabel("/", 709, 191, 6, 21)

	;- Set Label Font Settings
	GUICtrlSetFont($overall_Label, 10, 800, 0, "Segoe UI")
	GUICtrlSetFont($current_Progress_Label, 10, 800, 0, "Segoe UI")
	GUICtrlSetFont($hostname_Label, 8, 800, 0, "Segoe UI")
	GUICtrlSetFont($ip_label, 8, 800, 0, "Segoe UI")
	GUICtrlSetFont($mac_address_label, 8, 800, 0, "Segoe UI")

	;- Disable marqprogress until needed
	GUICtrlSetState($marqProgress, @SW_DISABLE)
	GUICtrlSetState($marqProgress, @SW_HIDE)

	;- Configure SysInfo
	Local $aArray = _IPDetails()
	SetSysInfo($aArray)

	GUISetState(@SW_SHOW)
	### END Koda GUI section ###

EndFunc   ;==>DisplayMainGUI

#comments-start FUNCTION: DisplaySplashScreen
	#FUNCTION# ===========================================================================================================
	Name...........: DiscoverPackages
    Description ...: Search the provided directory for sub directories. if the count of directories found
    isn't greater than or equal to the total packages in settings we'll fail
	Syntax.........: DiscoverPackages($Directory)
	Parameters ....: Directory - The directory to search
    Return values .:
        Success - $Packages - Array of SubFolders
        Failure - 2: There are less packages in the directory then are defined
                    3: An unknown error occured
                    4: No Packages were found in the directory
                    5: The directory wasn't found
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: DisplaySplashScreen
Func DiscoverPackages($Directory)
	If FileExists($Directory) Then
		LogIt($INFORMATION, 'Packages directory was discovered.', 'DiscoverPackages')
		LogIt($INFORMATION, "Searching for Packages to Install.", "DiscoverPackages")
		$Packages = _FileListToArray($Directory, '*', $FLTA_FOLDERS)
		If IsArray($Packages) Then
			; Packages were found in the packages directory
			If $Packages[0] < $TotalPackages Then
				LogIt($ERROR, 'There are less packages in the directory than are defined in the settings. Please contact the system administrator.', 'DiscoverPackages')
				Return 2
			ElseIf $Packages[0] >= $TotalPackages Then
				Return $Packages
			Else
				LogIt($ERROR, 'An unknown error occured. Please contact the system administrator.', 'DiscoverPackages')
				Return 3
			EndIf
		Else
			; No packages were found!
			LogIt($ERROR, "No Packages were found. Cannot proceed.", "DiscoverPackages")
			Return 4
		EndIf

	Else
		LogIt($ERROR, 'Could not discover packages directory.', 'DiscoverPackages')
		Return 5
	EndIf
EndFunc   ;==>DiscoverPackages

#comments-start FUNCTION: SetSysInfo
	#FUNCTION# ===========================================================================================================
	Name...........: SetSysInfo
	Description ...: Set System information in the GUI Window
	Syntax.........: SetSysInfo($aAdapterInfo)
	Parameters ....: $aAdapterInfo - Adapter information that you would want to set
	We are expecting the IP to be $array[1] and the MAC to be $array[2]
	Return values .: None
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: SetSysInfo
Func SetSysInfo($aAdapterInfo)
	GUICtrlSetData($hostname, @ComputerName)
	GUICtrlSetData($ipaddress, $aAdapterInfo[1])
	GUICtrlSetData($mac_address, $aAdapterInfo[2])
EndFunc   ;==>SetSysInfo

#comments-start FUNCTION: _IPDetails
	#FUNCTION# ===========================================================================================================
	Name...........: _IPDetails
	Description ...: Get Network interface details for what we think is the primary Network Adapter
	We determine if it's the primary adapter using a combination of AutoIT and WMI
	We compare @IPAddress1 to the Addresses returned by the WMI Query
	Syntax.........: _IPDetails()
	Parameters ....: None
	Return values .: $aReturn - An array containing the IP, MAC, Gateway and Comma Seperated list of DNS Servers
	Author ........: Not sure ... I tried to find it again but can't find the original author
	=====================================================================================================================
#comments-end   FUNCTION: _IPDetails
Func _IPDetails()
	Local $oWMIService = ObjGet('winmgmts:{impersonationLevel = impersonate}!\\' & '.' & '\root\cimv2')
	Local $oColItems = $oWMIService.ExecQuery('Select * From Win32_NetworkAdapterConfiguration Where IPEnabled = True', 'WQL', 0x30), $aReturn[5] = [0]
	If IsObj($oColItems) Then
		For $oObjectItem In $oColItems
			If $oObjectItem.IPAddress(0) == @IPAddress1 Then
				$aReturn[0] = 4
				$aReturn[1] = $oObjectItem.IPAddress(0)
				$aReturn[2] = $oObjectItem.MACAddress
				$aReturn[3] = $oObjectItem.DefaultIPGateway(0)
				$aReturn[4] = _WMIArrayToString($oObjectItem.DNSServerSearchOrder(), ', ')     ; You could use _ArrayToString() but I like creating my own Functions especially when I don't need alot of error checking.
			EndIf
		Next
	EndIf
	Return SetError($aReturn[0] = 0, 0, $aReturn)
EndFunc   ;==>_IPDetails

#comments-start FUNCTION: _WMIArrayToString
	#FUNCTION# ===========================================================================================================
	Name...........: _WMIArrayToString
	Description ...: Convert a WMIArray to a string
	Syntax.........: _WMIArrayToString($aArray, $sDelimeter = '|')
	Parameters ....: $aArray - The array to convert to a string
	$sDelimeter - The delimeter to use in the new string (Default: | )
	Return values .: $sString - A delimeted string
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: _WMIArrayToString
Func _WMIArrayToString($aArray, $sDelimeter = '|')
	Local $sString = 'Not Available'
	If UBound($aArray) Then
		For $i = 0 To UBound($aArray) - 1
			$sString &= $aArray[$i] & $sDelimeter
		Next
		$sString = StringTrimRight($sString, StringLen($sDelimeter))
	EndIf
	Return $sString
EndFunc   ;==>_WMIArrayToString

#comments-start FUNCTION: fGrabPercentComplete
	#FUNCTION# ===========================================================================================================
	Name...........: fGrabPercentComplete
	Description ...: Calculate the current step percentage based on the passed values
	Syntax.........: fGrabPercentComplete($sCurrentStep)
	Parameters ....: sCurrentStep - The current step you are on

	This function is relying on $TotalSteps being set outside this function
	and not as a parameter. We may need to change this
	Return values .: Rounded Percentage complete
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: fGrabPercentComplete
Func fGrabPercentComplete($sCurrentStep)
	Return Round(($sCurrentStep / $TotalSteps) * 100)
EndFunc   ;==>fGrabPercentComplete

#comments-start FUNCTION: SetStepProgress
	#FUNCTION# ===========================================================================================================
	Name...........: SetStepProgress
	Description ...: Sets the package step progress bar in the GUI
	Syntax.........: SetStepProgress($iStep, $iTotalSteps, $sStepText, $iStepPercent)
	Parameters ....: $iStep - The current step within the current package we are running
	$iTotalSteps - The total number of steps in the current package
	$sStepText - The text to display for the current step
	$iStepPercent - The percentage of steps completed for this package
	Return values .: None
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: SetStepProgress
Func SetStepProgress($iStep = 'Null', $iTotalSteps = 'Null', $sStepText = 'Null', $iStepPercent = 'Null')
	;- Set Step Percentage
	If $iStep <> 'Null' Then
		GUICtrlSetData($cur_step, $iStep)
	EndIf

	If $iTotalSteps <> 'Null' Then
		GUICtrlSetData($step_total, $iTotalSteps)
	EndIf

	If $sStepText <> 'Null' Then
		GUICtrlSetData($current_progress_action, $sStepText)
	EndIf

	If $iStepPercent <> 'Null' Then
		GUICtrlSetData($current_Progress, $iStepPercent)
		GUICtrlSetData($oStepPercentLabel, $iStepPercent & "%")
	EndIf
EndFunc   ;==>SetStepProgress

#comments-start FUNCTION: SetOverallProgress
	#FUNCTION# ===========================================================================================================
	Name...........: SetOverallProgress
	Description ...: Sets the OVERALL progress bar in the GUI
	Syntax.........: SetOverallProgress($iTotalSteps, $iCurrentStep, $sCompleteBarPerc, $sCompleteBarText)
	Parameters ....: $iTotalSteps - The total number of packages we are running
	$iCurrentStep - The current package we are working on
	$sCompleteBarPerc - The overal progress percentage
	$sCompleteBarText - The text to use for the current package
	Return values .: None
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: SetOverallProgress
Func SetOverallProgress($iTotalSteps, $iCurrentStep, $sCompleteBarPerc, $sCompleteBarText)
	If $iTotalSteps <> 'Null' Then
		GUICtrlSetData($overal_step_total, $iTotalSteps)
	EndIf

	If $iCurrentStep <> 'Null' Then
		GUICtrlSetData($cur_overall_step, $iCurrentStep)
	EndIf

	If $sCompleteBarPerc <> 'Null' Then
		GUICtrlSetData($overall_Progress, $sCompleteBarPerc)
		GUICtrlSetData($oCompletePercentLabel, $sCompleteBarPerc & "%")
	EndIf

	If $sCompleteBarText <> 'Null' Then
		GUICtrlSetData($overall_progress_action, $sCompleteBarText)
	EndIf
EndFunc   ;==>SetOverallProgress

#comments-start FUNCTION: DisplayCompleteGUI
	#FUNCTION# ===========================================================================================================
	Name...........: DisplayCompleteGUI
	Description ...: Display the complete window GUI
	Syntax.........: DisplayCompleteGUI()
	Parameters ....: None
	Return values .: None
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: DisplayCompleteGUI
Func DisplayCompleteGUI()
	### START Koda GUI section ### Form=D:\CodeControl\Program Source\GoldImageCompletion\GUI\Configuration Complete.kxf
	$complete_GUI = GUICreate("Configuration Complete", 401, 250, 912, 359, BitOR($WS_MINIMIZEBOX, $WS_GROUP), BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))

	Local $apos = WinGetPos($complete_GUI)
	WinMove($complete_GUI, "", (@DesktopWidth / 2) - ($apos[2] / 2), (@DesktopHeight / 2) - ($apos[3] / 2))

	;- Define the GUI settings
	GUISetIcon($TempDir & "\star.ico", -1)
	GUISetFont(10, 400, 0, "Segoe UI")
	GUISetBkColor(0xFFFFFF)

	$it_Logo = GUICtrlCreatePic("", 11, 10, 378, 100)
	_GDIPlus_Startup()
	$hImage = _GDIPlus_ImageLoadFromFile($png)
	Local $Bmp = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
	_WinAPI_DeleteObject(GUICtrlSendMsg($it_Logo, $STM_SETIMAGE, $IMAGE_BITMAP, $Bmp))

	$Label1 = GUICtrlCreateLabel("Configuration Complete.", 11, 136, 193, 25)
	GUICtrlSetFont($Label1, 12, 800, 0, "Segoe UI")
	$Label2 = GUICtrlCreateLabel("A reboot is required to finalize the configuration.", 11, 160, 289, 21)
	$Label3 = GUICtrlCreateLabel("Rebooting in ", 11, 184, 83, 21)
	$countdown = GUICtrlCreateLabel("", 96, 182, 22, 25)
	GUICtrlSetFont($countdown, 12, 800, 0, "Segoe UI")
	GUICtrlSetColor($countdown, 0xFF0000)
	$Label5 = GUICtrlCreateLabel("Seconds", 120, 184, 53, 21)
	GUISetState(@SW_SHOW)
	### END Koda GUI section ###
EndFunc   ;==>DisplayCompleteGUI

#comments-start FUNCTION: CheckINI
	#FUNCTION# ===========================================================================================================
	Name...........: CheckINI
	Description ...: Check for a package.ini file the specified directory
	Syntax.........: CheckINI($WorkingDirectory)
	Parameters ....: $WorkingDirectory - The directory in which to check for a package file
	Return values .: 	Success = 1
	Failute = 0
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: CheckINI
Func CheckINI($WorkingDirectory)
	If FileExists($WorkingDirectory) Then
		LogIt($INFORMATION, 'CheckINI() - Checking if we have a package.ini in ' & $WorkingDirectory, 'CheckINI')
		If FileExists($WorkingDirectory & '\package.ini') Then
			LogIt($INFORMATION, 'CheckINI() - Detected package.ini', 'CheckINI')
			Return 1
		Else
			LogIt($INFORMATION, 'CheckINI() - No package.ini detected. Using default settings.', 'CheckINI')
			Return 0
		EndIf
	Else
		LogIt($ERROR, 'CheckINI() - Cannot find ' & $WorkingDirectory, 'CheckINI')
		SetError(-1)
		Return 0
	EndIf
EndFunc   ;==>CheckINI

#comments-start FUNCTION: CleanUpStagedFiles
	#FUNCTION# ===========================================================================================================
	Name...........: CleanUpStagedFiles
	Description ...: Cleanup the staged files that this tool used
	Syntax.........: CleanUpStagedFiles($Path)
	Parameters ....: $Path - The directory in which the packages were stored
	Return values .: 	Success = 1
                            Failute = 0
	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: CleanUpStagedFiles
Func CleanUpStagedFiles($Path)
	Local $Return = 1

	If FileExists($Path) Then
		Local $aFileList = _FileListToArray($Path, Default, Default, True)
		For $l = 1 To $aFileList[0] Step 1
			If FileExists($aFileList[$l]) Then
				Local $Result = DirRemove($aFileList[$l], $DIR_REMOVE)
				If $Result = 1 Then
					If $DebugMode = 1 Then LogIt($DEBUG, "Successfully removed " & $aFileList[$l], "CleanUpStagedFiles")
				Else
					If $DebugMode = 1 Then LogIt($DEBUG, "Failed to remove " & $aFileList[$l], "CleanUpStagedFiles")
					$Return = 0
				EndIf
			EndIf
		Next

		Local $Result = DirRemove($Path, $DIR_REMOVE)
		If $Result = 1 Then
			If $DebugMode = 1 Then LogIt($DEBUG, "Successfully removed " & $Path, "CleanUpStagedFiles")
		Else
			If $DebugMode = 1 Then LogIt($DEBUG, "Failed to remove " & $Path, "CleanUpStagedFiles")
			$Return = 0
		EndIf

	EndIf

	;- Delete the Rename_Computer executable as we don't need it anymore
	If FileExists(@ScriptDir & '\Rename_Computer.exe') Then
		Local $Result = FileDelete(@ScriptDir & '\Rename_Computer.exe')
		If $Result = 1 Then
			If $DebugMode = 1 Then LogIt($DEBUG, "Rename computer removed.", "CleanUpStagedFiles")
		Else
			If $DebugMode = 1 Then LogIt($DEBUG, "Failed to remove Rename Computer.", "CleanUpStagedFiles")
			$Return = 0
		EndIf
	EndIf

	;- Remove Run Command from Registry
	Local $Result = RunWait(@ComSpec & ' /c schtasks.exe /Delete /TN "\CompleteImage" /F')
	If $Result = 1 Then
		LogIt($ERROR, "An error has occured attempting to delete the scheduled task.", "CleanUpStagedFiles")
		$Return = 1
	Else
		LogIt($INFORMATION, "Successfully removed the scheduled task.", "CleanUpStagedFiles")
		$Return = 0
	EndIf

	Local $Result = RegDelete("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "_Finalize")
	If $Result = 1 Then
		LogIt($INFORMATION, "_Finalize removed from registry.", "CleanUpStagedFiles")
	ElseIf $Result = 0 Then
		LogIt($WARNING, "The _Finalize key did not exist.", "CleanUpStagedFiles")
	ElseIf $Result = 2 Then
		Select
			Case @error = 1
				LogIt($ERROR, "Failed to remove _Finalize. Unabled to open requested key.", "CleanUpStagedFiles")
			Case @error = 2
				LogIt($ERROR, "Failed to remove _Finalize. Unabled to open requested main key.", "CleanUpStagedFiles")
			Case @error = 3
				LogIt($ERROR, "Failed to remove _Finalize. to remote connect to the registry.", "CleanUpStagedFiles")
			Case @error = -1
				LogIt($ERROR, "Failed to remove _Finalize. Unable to delete requested value.", "CleanUpStagedFiles")
			Case @error = -2
				LogIt($ERROR, "Failed to remove _Finalize. Unabled to delete requested key/value.", "CleanUpStagedFiles")
		EndSelect

		$Return = 0
	EndIf

	;- Remove Run Command from Registry
	Local $Result = RegDelete("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run", "_Finalize")
	If $Result = 1 Then
		LogIt($INFORMATION, "_Finalize removed from registry.", "CleanUpStagedFiles")
	ElseIf $Result = 0 Then
		LogIt($WARNING, "The _Finalize key did not exist.", "CleanUpStagedFiles")
	ElseIf $Result = 2 Then
		Select
			Case @error = 1
				LogIt($ERROR, "Failed to remove _Finalize. Unabled to open requested key.", "CleanUpStagedFiles")
			Case @error = 2
				LogIt($ERROR, "Failed to remove _Finalize. Unabled to open requested main key.", "CleanUpStagedFiles")
			Case @error = 3
				LogIt($ERROR, "Failed to remove _Finalize. to remote connect to the registry.", "CleanUpStagedFiles")
			Case @error = -1
				LogIt($ERROR, "Failed to remove _Finalize. Unable to delete requested value.", "CleanUpStagedFiles")
			Case @error = -2
				LogIt($ERROR, "Failed to remove _Finalize. Unabled to delete requested key/value.", "CleanUpStagedFiles")
		EndSelect

		$Return = 0
	EndIf

	;- Cleanup Autologon if needed
	;- Delete the AutoLogon AutoAdminLogon key
	Local $Result = RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoAdminLogon", 'REG_SZ', '0')
	If $Result = 1 Then
		LogIt($INFORMATION, "AutoAdminLogon set to 0.", "CleanUpStagedFiles")
	ElseIf $Result = 0 Then
		LogIt($WARNING, "AutoAdminLogon did not exist.", "CleanUpStagedFiles")
	ElseIf $Result = 2 Then
		Select
			Case @error = 1
				LogIt($ERROR, "Failed to reset AutoAdminLogon to 0. Unabled to open requested key.", "CleanUpStagedFiles")
			Case @error = 2
				LogIt($ERROR, "Failed to reset AutoAdminLogon to 0. Unabled to open requested main key.", "CleanUpStagedFiles")
			Case @error = 3
				LogIt($ERROR, "Failed to reset AutoAdminLogon to 0. to remote connect to the registry.", "CleanUpStagedFiles")
			Case @error = -1
				LogIt($ERROR, "Failed to reset AutoAdminLogon to 0. Unable to delete requested value.", "CleanUpStagedFiles")
			Case @error = -2
				LogIt($ERROR, "Failed to reset AutoAdminLogon to 0. Unabled to delete requested key/value.", "CleanUpStagedFiles")
		EndSelect

		$Return = 0
	EndIf

	;- Delete the AutoLogon Default Username key
	Local $Result = RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName", 'REG_SZ', '')
	If $Result = 1 Then
		LogIt($INFORMATION, "DefaultUserName set to nothing.", "CleanUpStagedFiles")
	ElseIf $Result = 0 Then
		LogIt($WARNING, "DefaultUserName did not exist.", "CleanUpStagedFiles")
	ElseIf $Result = 2 Then
		Select
			Case @error = 1
				LogIt($ERROR, "Failed to reset DefaultUserName. Unabled to open requested key.", "CleanUpStagedFiles")
			Case @error = 2
				LogIt($ERROR, "Failed to reset DefaultUserName. Unabled to open requested main key.", "CleanUpStagedFiles")
			Case @error = 3
				LogIt($ERROR, "Failed to reset DefaultUserName. to remote connect to the registry.", "CleanUpStagedFiles")
			Case @error = -1
				LogIt($ERROR, "Failed to reset DefaultUserName. Unable to delete requested value.", "CleanUpStagedFiles")
			Case @error = -2
				LogIt($ERROR, "Failed to reset DefaultUserName. Unabled to delete requested key/value.", "CleanUpStagedFiles")
		EndSelect

		$Return = 0
	EndIf

	;- Delete the AutoLogon Default Password key
	Local $Result = RegDelete("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword")
	If $Result = 1 Then
		LogIt($INFORMATION, "DefaultPassword removed from registry.", "CleanUpStagedFiles")
	ElseIf $Result = 0 Then
		LogIt($WARNING, "The DefaultPassword did not exist.", "CleanUpStagedFiles")
	ElseIf $Result = 2 Then
		Select
			Case @error = 1
				LogIt($ERROR, "Failed to remove DefaultPassword. Unabled to open requested key.", "CleanUpStagedFiles")
			Case @error = 2
				LogIt($ERROR, "Failed to remove DefaultPassword. Unabled to open requested main key.", "CleanUpStagedFiles")
			Case @error = 3
				LogIt($ERROR, "Failed to remove DefaultPassword. to remote connect to the registry.", "CleanUpStagedFiles")
			Case @error = -1
				LogIt($ERROR, "Failed to remove DefaultPassword. Unable to delete requested value.", "CleanUpStagedFiles")
			Case @error = -2
				LogIt($ERROR, "Failed to remove DefaultPassword. Unabled to delete requested key/value.", "CleanUpStagedFiles")
		EndSelect

		$Return = 0
	EndIf

	Return $Return
EndFunc   ;==>CleanUpStagedFiles
