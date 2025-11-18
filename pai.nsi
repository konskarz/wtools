!define INSTNAME "pai"			; used in Name, OutFile, VIAddVersionKey
!define INSTDESC "Portable Applications Installer"	; used in Caption, VIAddVersionKey
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
RequestExecutionLevel user		; none|user|highest|admin, none and admin have virtually the same effect, highest: highest execution level available for the current user
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
	${InitSelect} "exg" "true"		; make selectable only sections with existing target, enable multiselect, SelectMgr.nsh required
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
	Call ProcessUpdate
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
FunctionEnd
Function ProcessUpdate
	Call UpdateSource
	IfErrors +2
		Call UpdateTarget
FunctionEnd
Function UpdateTarget
	Push $0										; directory or file to update
	${ReadAndExpandINIEntry} "$IST" "upd" $0	; ConfigMgr.nsh, InstallWrk.nsh($IST) required
	IfErrors 0 +3
		Pop $0
		Return
	IfFileExists "$0" 0 BakDone
		IfFileExists "$0.bak\*.*" 0 +2			; rm directory
			RMDir /r "$0.bak"
		${ProcessDelRen} "$0" "$0.bak"			; del file (directory is already removed), ren directory/file, InstallWrk.nsh required
	BakDone:
	ClearErrors
	Exch $0
	Call ProcessTarget
	Exch $0
	IfErrors Errors
		IfFileExists "$0.bak\*.*" 0 +2			; rm directory
			RMDir /r "$0.bak"
		IfFileExists "$0.bak" 0 +2				; del file (directory is already removed)
			Delete "$0.bak"
		Pop $0
		Return
	Errors:
	DetailPrint "Restore: $0"
	IfFileExists "$0.bak" 0 ResDone
		IfFileExists "$0\*.*" 0 +2				; rm directory
			RMDir /r "$0"
		${ProcessDelRen} "$0.bak" "$0"			; del file (directory is already removed), ren directory/file, InstallWrk.nsh required
	ResDone:
	SetErrors
	Pop $0
FunctionEnd
