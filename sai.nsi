!define INSTNAME "sai"			; used in Name, OutFile, VIAddVersionKey
!define INSTDESC "System Applications Installer"	; used in Caption, VIAddVersionKey
!define INSTVERS "2.0.0.0"		; used VIProductVersion, VIAddVersionKey, First two digits are version numbers, last digit is packet revision
!define DINIPATH "resources"			; default ini path
OutFile "dist\${INSTNAME}.exe"
Caption "${INSTDESC}"			; default "Name Setup", where Name is specified with the Name instruction
SubCaption 0 " "				; default ": License Agreement"
SubCaption 1 " "				; default ": Installation Options"
SubCaption 2 " "				; default ": Installation Directory"
SubCaption 3 " "				; default ": Installing Files"
SubCaption 4 " "				; default ": Completed"
WindowIcon off					; on|off
ComponentText "$INSTDIR" "" "Applications:"	; [text [subtext] [subtext2]], if specified add componets page without command
SpaceTexts none					; [req text [avail text]]
BrandingText " "				; /TRIM(LEFT|RIGHT|CENTER) text
ShowInstDetails show			; hide|show|nevershow
; RequestExecutionLevel user	; none|user|highest|admin, none and admin have virtually the same effect, highest: highest execution level available for the current user
; Include
/* 
InstSections.nsh is requerd to compile this script
Elements: 1000 hidden sections unselected by default
Action: call Install function with section index on the stack
Requirements: Function Install
*/
!include ".\include\InstSections.nsh"
/*
Includes: FileFunc.nsh, WordFunc.nsh, GetFolderPath.nsh
Requirements: ${INSTNAME}, ${INSTDESC}, ${INSTVERS}, ${DINIPATH}
Elements: Installer attributes, main variables and functions to read ini and cmd
*/
!include ".\include\ConfigMgr.nsh"
/*
Includes: GetSectionNames.nsh, LoopThroughValues.nsh
Requirements: WordFunc.nsh, ConfigMgr.nsh, InstSections.nsh
Elements: variables and functions to init and manage installer sections and pages
*/
!include ".\include\SelectMgr.nsh"
/*
Plugins: Plugins\Inetc, Plugins\ZipDLL
Requirements: ConfigMgr.nsh, FileFunc.nsh
Elements: functions and macro to process installation
*/
!include ".\include\InstallWrk.nsh"
; Variables
Var UPD	; update installation type
/*
Installer configuration, called when the installer is nearly finished initializing
*/
Function .onInit
	Call InitConfig					; find/create ini, define main variables, ConfigMgr.nsh required
	${IsOption} "/U" $UPD			; ConfigMgr.nsh required
	StrCmp "$UPD" "true" Update
		${InitSelect} "msg" "true"	; make selectable only sections with missing target, enable multiselect, SelectMgr.nsh required
		Return
	Update:
	${InitSelect} "skp" "true"		; skip target check, enable multiselect, SelectMgr.nsh required
FunctionEnd
/*
Installer logic, required by InstSections.nsh, InstallWrk.nsh required
*/
Function Install
	Call InitInstall
	IfErrors 0 +2
		Return
	StrCmp "$UPD" "true" +3
		Call ProcessInstall
		Return
	Call UpdateSource
FunctionEnd
Function ProcessInstall
	Call ProcessSource
	IfErrors +2
		Call ProcessTarget
FunctionEnd
Function ProcessTarget
	Call ProcessExtract
	Call ProcessRename
	Call ProcessExecute
	Call ProcessCleanup
	Call ProcessShortcut
	Call ProcessReboot
FunctionEnd
Function ProcessShortcut
	Push $0											; shortcut cmd
	Push $1											; main executable
	Push $2											; shortcut name
	Push $3											; working directory
	${ReadAndExpandIniEntry} "$IST" "sca" $0		; ConfigMgr.nsh, InstallWrk.nsh($IST) required
	IfErrors Done
		${ReadAndExpandIniEntry} "$IST" "trg" $1	; ConfigMgr.nsh, InstallWrk.nsh($IST) required
		IfErrors Done
			StrCmp "$0" "false" 0 +2
				StrCpy $0 ""
			${GetBaseName} "$1" $2					; FileFunc.nsh required
			${GetParent} "$1" $3					; FileFunc.nsh required
			SetOutPath "$3"
			CreateShortCut "$DESKTOP\$2.lnk" "$1" "$0" "$1"
	Done:
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd
Function ProcessReboot
	Push $0							; rbt
	${ReadIniEntry} "$IST" "rbt" $0
	IfErrors +2
		SetRebootFlag true
	Pop $0
FunctionEnd
Function .onGUIEnd
	StrCmp "'$AUT'" "''" 0 +2		; ConfigMgr.nsh($AUT) required
		IfRebootFlag +2
			Return
	MessageBox MB_YESNO "A reboot is required to finish the installation. Do you wish to reboot now?" IDNO +2
		Reboot
FunctionEnd
