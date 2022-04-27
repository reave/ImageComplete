#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\star.ico
#AutoIt3Wrapper_Outfile_x64=..\..\Builds\ImageCompletion\Join_Domain.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=PBSO Domain Join Tool
#AutoIt3Wrapper_Res_Fileversion=2.0.0.6
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=PBSO Domain Join Tool
#AutoIt3Wrapper_Res_ProductVersion=2.0.0.5
#AutoIt3Wrapper_Res_CompanyName=Palm Beach County Sheriff's Office
#AutoIt3Wrapper_Res_LegalCopyright=Copyright © 2019 Palm Beach County Sheriff's Office. All rights reserved.
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Run_After=ping 192.0.2.2 -n 1 -w 2000 > nul
#AutoIt3Wrapper_Run_After=C:\Tools\sysinternals\signtool.exe sign /fd sha256 "%outx64%"
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#Region ScriptHeader
; #HEADER# ======================================================================================================================
; Language ......: English
; Author(s) .....: Joseph Ascanio (shinta148)
; Parameter(s) ..: silent    - disables all gui elements and writes instead to logs or Stdout
;                    debug     - enables debug logging throughout the script
;                    cmtrace   - enables cmtrace logging format.
;                              Note: If this script has created a log file with the same name in a
;	                           non-cmtrace format, enabling cmtrace log format will no function as
;	                           intended. CMTrace will only detect log format if it's present in the
;	                           first line of a file.
;                    help/?    - displays help; if 'Silent' is also passed help will print to Stdout
;
; Usage .........: scriptname.exe -|--|/[Debug] -|--|/[Cmtrace] -|--|/[Silent] -|--|/[Help] -|--|/[?]
;                  Note: -, --, /, param, are all excpted ways to pass the parameters.
; Notes .........: Template Last Modified on 9/23/16
;
; ===============================================================================================================================
#EndRegion ScriptHeader

#Region AutoIT Configuration Items
; #CONFIGURATION# ===============================================================================================================
; Uncomment what you want to use. Or add others here
; ===============================================================================================================================

; Disable WOW6432 redirection on 64 bit systems

; Options
AutoItSetOption("GUIOnEventMode", 1) ; 0=disabled, 1=OnEvent mode enabled
AutoItSetOption("TrayAutoPause", 0) ; 0=no pause, 1=Pause
AutoItSetOption("TrayIconHide", 0) ; 0=show, 1=hide tray icon
AutoItSetOption("TrayMenuMode", 1) ; 0=append, 1=no default menu, 2=no automatic check, 4=menuitemID  not return
#EndRegion AutoIT Configuration Items

#Region ProgramConfiguration
; #VARIABLES# ====================================================================================================================
; Ensure these are set or the program_functions include will throw errors at you
;
; It is recommended that you use values from the uninstall key for the settings below.
; We search the uninstall keys for matches and using the correct data will ensure a good match.
; ================================================================================================================================

; Required Global Application Installation Variables
Global $appPublisher = 'Palm Beach County Sheriffs Office' ;- Application Publisher (From Uninstall Key if Possible)
Global $appDisplayName = 'Domain Join Utility' ;- Application Display Name (From Uninstall Key if Possible)
Global $appShortName = 'Join_Domain' ;- Short Name for the application
Global $appVersion = '2.0.0.0' ;- Application Version (From Uninstall Key if Possible)
Global $appArch = 'x86_64' ;- Application Architecture (x86;x86_64)
Global $appLang = 'en-US' ;- Appication Language (en-US)
Global $appRevision = '' ;- Application Revision
Global $appScriptVersion = '1.0.0.0' ;- Script Version
Global $appScriptDate = '10-04-2017' ;- Script Date
Global $appScriptAuthor = 'Joseph Ascanio' ;- Script Author

; Add additional Global Scope Variables here

#EndRegion ProgramConfiguration

#Region Library Includes
; #INCLUDES# ====================================================================================================================
; Ensure the below au3 files are in one of the defined include directories.
; Default Include Directory: C:\Program Files\Autoit3\include
; User Include Directories are defined here: HKEY_CURRENT_USER\SOFTWARE\AutoIt v3\AutoIt\Include
;
; Note: These primary includes contain includes for most common functions including:
;    ButtonConstants
;    ComboConstants
;    GUIConstantsEx
;    StaticConstants
;    WindowsConstants
;    EditConstants
;    array
;    File
;    MsgBoxConstants
;    WinAPI
;    FileConstants
;    AutoItConstants
;    UninstallList
;    MultidimensionalSearch
;    String
; ================================================================================================================================

#include <standard_functions.au3>
#include <GUIConstantsEx.au3>
#include <GDIPlus.au3>

#EndRegion Library Includes

#Region MainScriptActions
; #MAIN SCRIPT ACTIONS# ==========================================================================================================
;
; Note: This section should always begin with the Initialize function. Without this none of the logging
; or global scope variables below will work unless they are defined within this main script.
; ================================================================================================================================
; Script Initialization - Starts and expires logging as well as
;  writes log header and defines global scope variables
$Result = Initialize()
If $Result <> 1 Then
	; Initialization failed
	$mainReturnCode = 9098
	MsgBox($MB_APPLMODAL + $MB_TOPMOST + $MB_ICONERROR, 'Join Domain Failed', 'Could not initiate the application. Please contact your administrator...', 30)
	ExitScript($mainReturnCode)
EndIf

If $DebugMode = 1 Then LogIt($DEBUG, "Instantiating required variables.", "Main")
Global $strDomain, $strDomainShort, $strUser, $strPassword
Global $objNetwork, $strComputer, $objComputer, $lngReturnValue
Global $strOU, $intRetryCount = 5


If $DebugMode = 1 Then LogIt($DEBUG, "Extracting resource files to " & $TempDir, "MAIN")
FileInstall("C:\SourceControl\Programs\ImageCompletion\Resources\logo.png", $TempDir & '\', $FC_OVERWRITE)
FileInstall("C:\SourceControl\Programs\ImageCompletion\Resources\star.ico", $TempDir & '\', $FC_OVERWRITE)

If $DebugMode = 1 Then LogIt($DEBUG, "Declaring GUI variables.", "MAIN")
Global $png = $TempDir & '\logo.png'
Global $domain_Name_Input, $domain_short_name_input, $domain_username_input
Global $domain_password_input, $domain_password_confirm_input, $join_domain_prompt
Global $domain_OU_input, $hImage
Global $submit_join, $cancel_join, $submit = False

;- Check for user / pass / ou / domain / domain short
LogIt($INFORMATION, "Checking for required command line parameters.", "Main")
$ParamCount = $CmdLine[0]

If ($ParamCount) Then
	For $i = 1 To $ParamCount Step 1
		If StringLeft($CmdLine[$i], 8) = "-domain:" Or StringLeft($CmdLine[$i], 9) = "--domain:" Or _
				StringLeft($CmdLine[$i], 8) = '/domain:' Or StringLeft($CmdLine[$i], 7) = 'domain:' Then

			$DomainArray = StringSplit($CmdLine[$i], ':')
			$strDomain = $DomainArray[2]

			If $DebugMode = 1 Then LogIt($DEBUG, "Setting Domain variable to: " & $strDomain, "Main")
		EndIf
	Next

	For $i = 1 To $ParamCount Step 1
		If StringInStr($CmdLine[$i], '-shortdomain:', 0) Or StringInStr($CmdLine[$i], '--shortdomain:', 0) Or _
				StringInStr($CmdLine[$i], '/shortdomain:', 0) Or StringInStr($CmdLine[$i], 'shortdomain:', 0) Then

			$ShortDomainArray = StringSplit($CmdLine[$i], ':')
			$strDomainShort = $ShortDomainArray[2]

			If $DebugMode = 1 Then LogIt($DEBUG, "Setting Short Domain variable to: " & $strDomainShort, "Main")
		EndIf
	Next

	For $i = 1 To $ParamCount Step 1
		If StringInStr($CmdLine[$i], '-ou:', 0) Or StringInStr($CmdLine[$i], '--ou:', 0) Or _
				StringInStr($CmdLine[$i], '/ou:', 0) Or StringInStr($CmdLine[$i], 'ou:', 0) Then

			$OUArray = StringSplit($CmdLine[$i], ':')
			$strOU = $OUArray[2]

			If $DebugMode = 1 Then LogIt($DEBUG, "Setting OU variable to: " & $strOU, "Main")
		EndIf
	Next

	For $i = 1 To $ParamCount Step 1
		If StringInStr($CmdLine[$i], '-username:', 0) Or StringInStr($CmdLine[$i], '--username:', 0) Or _
				StringInStr($CmdLine[$i], '/username:', 0) Or StringInStr($CmdLine[$i], 'username:', 0) Then

			$UserArray = StringSplit($CmdLine[$i], ':')
			$strUser = $UserArray[2]

			If $DebugMode = 1 Then LogIt($DEBUG, "Setting Username variable to: " & $strUser, "Main")
		EndIf
	Next

	For $i = 1 To $ParamCount Step 1
		If StringInStr($CmdLine[$i], '-password:', 0) Or StringInStr($CmdLine[$i], '--password:', 0) Or _
				StringInStr($CmdLine[$i], '/password:', 0) Or StringInStr($CmdLine[$i], 'password:', 0) Then

			$PasswordArray = StringSplit($CmdLine[$i], ':')
			$strPassword = $PasswordArray[2]

			If $DebugMode = 1 Then LogIt($DEBUG, "Setting Password variable to: " & $strPassword, "Main")
		EndIf
	Next

	If $strDomain = "" Or $strDomainShort = "" Or $strUser = "" Or $strPassword = "" Then
		LogIt($WARNING, "No required parameters were passed. Displaying GUI for user input.", "Main")
		DisplayDomainJoinGUI()

		While $submit = False
			Sleep(100)
		WEnd

		GUIDelete($join_domain_prompt)
		_GDIPlus_ImageDispose($hImage)
	EndIf

Else
	LogIt($WARNING, "No parameters were passed. Displaying GUI for user input.", "Main")
	DisplayDomainJoinGUI()

	While $submit = False
		Sleep(100)
	WEnd

	GUIDelete($join_domain_prompt)

EndIf

If $DebugMode = 1 Then LogIt($DEBUG, "Instantiating required constants.", "Main")
Const $JOIN_DOMAIN = 1
Const $ACCT_CREATE = 2
Const $ACCT_DELETE = 4
Const $WIN9X_UPGRADE = 16
Const $DOMAIN_JOIN_IF_JOINED = 32
Const $JOIN_UNSECURE = 64
Const $MACHINE_PASSWORD_PASSED = 128
Const $DEFERRED_SPN_SET = 256
Const $INSTALL_INVOCATION = 262144

If $DebugMode = 1 Then LogIt($DEBUG, "Creating Wscript Network Object.", "Main")
$objNetwork = ObjCreate("WScript.Network")
If IsObj($objNetwork) Then
	If $DebugMode = 1 Then LogIt($DEBUG, "Network object created successfully.", "Main")
Else
	LogIt($ERROR, "Could not create required network object to perform action. Cannot proceed.", "Main")
	$mainReturnCode = 9000
	ExitScript($mainReturnCode)
EndIf

$strComputer = $objNetwork.ComputerName
If $DebugMode = 1 Then LogIt($DEBUG, "Computer Hostname set to: " & $strComputer & ".", "Main")

If $DebugMode = 1 Then LogIt($DEBUG, "Creating WMI Computer Object.", "Main")
$objComputer = ObjGet("winmgmts:" & "{impersonationLevel=Impersonate,authenticationLevel=Pkt}!\\" & $strComputer & "\root\cimv2:Win32_ComputerSystem.Name='" & $strComputer & "'")
If @error Then
	LogIt($ERROR, "An error occured getting an active computer object. Cannot proceed.", "Main")
	$mainReturnCode = 9001
	ExitScript($mainReturnCode)
EndIf

If StringInStr($strComputer, "MD", $STR_NOCASESENSE) And $strOU = "" Then
	$strOU = "OU=Mobile Data Laptops,OU=Facilities,DC=pbso,DC=org"
EndIf

$lngReturnValue = $objComputer.JoinDomainOrWorkGroup($strDomain, $strPassword, $strDomainShort & "\" & $strUser, $strOU, $JOIN_DOMAIN + $ACCT_CREATE)
If String($lngReturnValue) <> 0 Then
	If $DebugMode = 1 Then LogIt($DEBUG, "First attempt to join the domain failed. Will try again up to a maximum of 5 additional tries.", "Main")
	While $intRetryCount > 0 And String($lngReturnValue) <> 0
		Sleep(5000)
		$lngReturnValue = $objComputer.JoinDomainOrWorkGroup($strDomain, $strPassword, $strDomainShort & "\" & $strUser, $strOU, $JOIN_DOMAIN + $ACCT_CREATE)
		If String($lngReturnValue) <> 0 Then
			If $DebugMode = 1 Then LogIt($DEBUG, "Attempt " & $intRetryCount & " to join the domain failed. Will try again.", "Main")
			$intRetryCount = $intRetryCount - 1
		Else
			ExitLoop
		EndIf
	WEnd
EndIf

Select
	Case $lngReturnValue = 0
		LogIt($INFORMATION, "Successfully joined the " & $strDomain & " domain.", "Main")
	Case $lngReturnValue = 5
		LogIt($ERROR, "Failed to join the " & $strDomain & " domain. Access is denied.", "Main")
	Case $lngReturnValue = 87
		LogIt($ERROR, "Failed to join the " & $strDomain & " domain. A parameter is incorrect.", "Main")
	Case $lngReturnValue = 110
		LogIt($ERROR, "Failed to join the " & $strDomain & " domain. The system cannot open the specified object.", "Main")
	Case $lngReturnValue = 1323
		LogIt($ERROR, "Failed to join the " & $strDomain & " domain. Unable to update the password.", "Main")
	Case $lngReturnValue = 1326
		LogIt($ERROR, "Failed to join the " & $strDomain & " domain. Logon failure: unknown username or bad password.", "Main")
	Case $lngReturnValue = 1355
		LogIt($ERROR, "Failed to join the " & $strDomain & " domain. The specified domain either does not exist or could not be contacted.", "Main")
	Case $lngReturnValue = 2224
		LogIt($ERROR, "Failed to join the " & $strDomain & " domain. The account already exists.", "Main")
	Case $lngReturnValue = 2691
		LogIt($ERROR, "Failed to join the " & $strDomain & " domain. The machine is already joined to the domain.", "Main")
	Case $lngReturnValue = 2692
		LogIt($ERROR, "Failed to join the " & $strDomain & " domain. The machine is not currently joined to a domain.", "Main")
	Case Else
		LogIt($ERROR, "Failed to join the " & $strDomain & " domain. An unknown error occured.", "Main")
EndSelect

$mainReturnCode = $lngReturnValue

;- Exit the Script
ExitScript($mainReturnCode)
#EndRegion MainScriptActions

#Region Additional Functions

#comments-start FUNCTION: DisplayDomainJoinGUI
	#FUNCTION# ===========================================================================================================
	Name...........: DisplayDomainJoinGUI
	Description ...: Displays the Main Domain Join GUI
	during program execution.
	Syntax.........: DisplayDomainJoinGUI()
    Parameters ....: None

	Return values .: None

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: DisplayDomainJoinGUI
Func DisplayDomainJoinGUI()
	#Region ### START Koda GUI section ### Form=D:\CodeControl\Program Source\GoldImageCompletion\GUI\domain join prompt.kxf
	$join_domain_prompt = GUICreate("Join a Domain", 401, 486, 379, 238, BitOR($WS_MINIMIZEBOX, $WS_GROUP), BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))

	;- Center the window on the screen
	Local $apos = WinGetPos($join_domain_prompt)
	WinMove($join_domain_prompt, "", (@DesktopWidth / 2) - ($apos[2] / 2), (@DesktopHeight / 2) - ($apos[3] / 2))

	;- Define the GUI settings
	GUISetIcon($TempDir & "\star.ico", -1)
	GUISetFont(10, 400, 0, "Segoe UI")
	GUISetBkColor(0xFFFFFF)

	;- Display the PNG logo
	$it_Logo = GUICtrlCreatePic("", 11, 10, 378, 100)
	_GDIPlus_Startup()
	$hImage = _GDIPlus_ImageLoadFromFile($png)
	Local $Bmp = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
	_WinAPI_DeleteObject(GUICtrlSendMsg($it_Logo, $STM_SETIMAGE, $IMAGE_BITMAP, $Bmp))

	;- Labels
	$domain_Name_Label = GUICtrlCreateLabel("Domain Name:", 16, 128, 97, 21)
	GUICtrlSetFont($domain_Name_Label, 10, 800, 0, "Segoe UI")

	$domain_short_name_Label = GUICtrlCreateLabel("Domain Short Name:", 16, 177, 134, 21)
	GUICtrlSetFont($domain_short_name_Label, 10, 800, 0, "Segoe UI")

	$domain_OU_label = GUICtrlCreateLabel("Organizational Unit:", 16, 223, 129, 21)
	GUICtrlSetFont($domain_OU_label, 10, 800, 0, "Segoe UI")

	$domain_username_label = GUICtrlCreateLabel("Username:", 16, 261, 69, 21)
	GUICtrlSetFont($domain_username_label, 10, 800, 0, "Segoe UI")

	$domain_password_label = GUICtrlCreateLabel("Password:", 15, 312, 66, 21)
	GUICtrlSetFont($domain_password_label, 10, 800, 0, "Segoe UI")

	$domain_password_confirm_label = GUICtrlCreateLabel("Confirm Password: ", 15, 362, 124, 21)
	GUICtrlSetFont($domain_password_confirm_label, 10, 800, 0, "Segoe UI")

	;- Inputs
	$domain_Name_Input = GUICtrlCreateInput("", 168, 126, 217, 25)
	GUICtrlSetTip($domain_Name_Input, 'Enter the FQDN of the domain you wish to join. Example: contoso.com', 'Domain Name', $TIP_INFOICON, $TIP_CENTER)
	If $strDomain <> "" Then GUICtrlSetData($domain_Name_Input, $strDomain)

	$domain_short_name_input = GUICtrlCreateInput("", 168, 175, 217, 25)
	GUICtrlSetTip($domain_short_name_input, 'Enter the short name of the domain you wish to join. Example: contoso', 'Domain Short Name', $TIP_INFOICON, $TIP_CENTER)
	If $strDomainShort <> "" Then GUICtrlSetData($domain_short_name_input, $strDomainShort)

	$domain_OU_input = GUICtrlCreateInput("", 168, 219, 217, 25)
	GUICtrlSetTip($domain_OU_input, 'Enter the FQDN of the Organizational Unit you wish to place this device in. Example: "OU=Computers,DC=Contoso,DC=com"', 'Organizational Unit', $TIP_INFOICON, $TIP_CENTER)
	If $strOU <> "" Then GUICtrlSetData($domain_OU_input, $strOU)

	$domain_username_input = GUICtrlCreateInput("", 168, 259, 217, 25)
	GUICtrlSetTip($domain_username_input, 'Enter the User Name of a Domain User with permission to join devices to your domain.', 'Domain User Name', $TIP_INFOICON, $TIP_CENTER)
	If $strUser <> "" Then GUICtrlSetData($domain_username_input, $strUser)

	$domain_password_input = GUICtrlCreateInput("", 168, 310, 217, 25, BitOR($GUI_SS_DEFAULT_INPUT, $ES_PASSWORD))
	GUICtrlSetTip($domain_password_input, 'Enter the Password of a Domain User with permission to join devices to your domain.', 'Domain Password', $TIP_INFOICON, $TIP_CENTER)
	If $strPassword <> "" Then GUICtrlSetData($domain_password_input, $strPassword)

	$domain_password_confirm_input = GUICtrlCreateInput("", 168, 360, 217, 25, BitOR($GUI_SS_DEFAULT_INPUT, $ES_PASSWORD))
	GUICtrlSetTip($domain_password_confirm_input, 'Confirm the Password of a Domain User with permission to join devices to your domain.', 'Confirm Domain Password', $TIP_INFOICON, $TIP_CENTER)
	If $strPassword <> "" Then GUICtrlSetData($domain_password_confirm_input, $strPassword)

	;- Buttons
	$submit_join = GUICtrlCreateButton("Join Domain", 83, 408, 83, 33)
	GUICtrlSetOnEvent($submit_join, "GUIActions")

	$cancel_join = GUICtrlCreateButton("Cancel", 235, 408, 83, 33)
	GUICtrlSetOnEvent($cancel_join, "GUIActions")

	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###
EndFunc   ;==>DisplayDomainJoinGUI

#comments-start FUNCTION: GUIActions
	#FUNCTION# ===========================================================================================================
	Name...........: GUIActions
	Description ...: Handles all actions from the GUI
	during program execution.
	Syntax.........: GUIActions()
    Parameters ....: None

	Return values .: None

	Author ........: shinta148
	=====================================================================================================================
#comments-end   FUNCTION: GUIActions
Func GUIActions()
	Select
		Case @GUI_CtrlId = $cancel_join
			LogIt($INFORMATION, "Close was pressed. Clossing the GUI and skipping Domain Join.", "GUIActions")
			GUIDelete($join_domain_prompt)
			_GDIPlus_ImageDispose($hImage)
			$mainReturnCode = 2
			ExitScript($mainReturnCode)
		Case @GUI_CtrlId = $submit_join
			If GUICtrlRead($domain_password_confirm_input) = GUICtrlRead($domain_password_input) Then
				LogIt($INFORMATION, "Password and confirmation match.", "GUIActions")

				If GUICtrlRead($domain_Name_Input) = "" Then
					LogIt($WARNING, "Domain name field is blank. This is a required field. Alerting the user.", "GUIActions")
					MsgBox($MB_APPLMODAL + $MB_ICONWARNING + $MB_SETFOREGROUND + $MB_TOPMOST, "Domain Name Required", "The Domain name field is blank. Please enter a fully qualified domain name and try again.")
					Return 0
				EndIf
				$strDomain = GUICtrlRead($domain_Name_Input)
				If $DebugMode = 1 Then LogIt($DEBUG, "Setting Domain variable to: " & $strDomain, "GUIActions")

				If GUICtrlRead($domain_short_name_input) = "" Then
					LogIt($WARNING, "Short Domain name field is blank. This is a required field. Alerting the user.", "GUIActions")
					MsgBox($MB_APPLMODAL + $MB_ICONWARNING + $MB_SETFOREGROUND + $MB_TOPMOST, "Short Domain Name Required", "The Short Domain name field is blank. Please enter a short domain name and try again.")
					Return 0
				EndIf
				$strDomainShort = GUICtrlRead($domain_short_name_input)
				If $DebugMode = 1 Then LogIt($DEBUG, "Setting Short Domain variable to: " & $strDomainShort, "GUIActions")

				$strOU = GUICtrlRead($domain_OU_input)
				If $DebugMode = 1 Then LogIt($DEBUG, "Setting Organizational Unit variable to: " & $strOU, "GUIActions")

				If GUICtrlRead($domain_username_input) = "" Then
					LogIt($WARNING, "Username field is blank. This is a required field. Alerting the user.", "GUIActions")
					MsgBox($MB_APPLMODAL + $MB_ICONWARNING + $MB_SETFOREGROUND + $MB_TOPMOST, "Username Required", "The Username field is blank. Please enter a Username and try again.")
					Return 0
				EndIf
				$strUser = GUICtrlRead($domain_username_input)
				If $DebugMode = 1 Then LogIt($DEBUG, "Setting Username variable to: " & $strUser, "GUIActions")

				If GUICtrlRead($domain_password_input) = "" Then
					LogIt($WARNING, "Password field is blank. This is a required field. Alerting the user.", "GUIActions")
					MsgBox($MB_APPLMODAL + $MB_ICONWARNING + $MB_SETFOREGROUND + $MB_TOPMOST, "Password Required", "The Password field is blank. Please enter a Password and try again.")
					Return 0
				EndIf
				$strPassword = GUICtrlRead($domain_password_input)
				If $DebugMode = 1 Then LogIt($DEBUG, "Setting Password variable to: " & $strPassword, "GUIActions")

				$submit = True
			Else
				LogIt($INFORMATION, "Password and confirmation do not match. Alerting User to try again.", "GUIActions")
				MsgBox($MB_APPLMODAL + $MB_ICONWARNING + $MB_SETFOREGROUND + $MB_TOPMOST, "Confirm Password", "The Password and Password confirmation does not match. Please re-enter your password and confirmation and try again.")
			EndIf
	EndSelect
EndFunc   ;==>GUIActions

#EndRegion Additional Functions
