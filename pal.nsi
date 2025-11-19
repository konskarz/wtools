!define INSTNAME "pal"			; used in Name, OutFile, VIAddVersionKey
!define INSTDESC "Portable Applications Launcher"	; used in Caption, VIAddVersionKey
!define INSTVERS "2.0.1.0"		; used VIProductVersion, VIAddVersionKey, First two digits are version numbers, last digit is packet revision
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
Plugins: Plugins\FindProc, Plugins\Textreplace
Includes: BackupAndRestore.nsh, PathFix.nsh
Requirements: FileFunc.nsh, WordFunc.nsh, LoopThroughValues.nsh, ConfigMgr.nsh
Elements: functions and macro to launch the program
*/
!include ".\include\LaunchWrk.nsh"
/*
Installer configuration, called when the installer is nearly finished initializing
*/
Function .onInit
	Call InitConfig				; find/create ini, define main variables, ConfigMgr.nsh required
	${InitSelect} "skp" "false"	; exg|msg|skp true|false, skip target check, disable multiselect
FunctionEnd
/*
Installer logic, required by InstSections.nsh, LaunchWrk.nsh required
*/
Function Install
	Call InitLaunch
	IfErrors 0 +2
		Return
	Call IsRunning
	IfErrors +3
		Call ExecuteAndContinue
		Return
	Call IsSimple
	IfErrors +3
		Call ExecuteAndContinue
		Return
	Call IsSemiPortable
	IfErrors +4
		Call ProcessSetup
		Call ExecuteAndContinue
		Return
	Call ProcessBackup
	Call ProcessSetup
	Call ExecuteAndWait
	Call ProcessRemove
	Call ProcessRestore
FunctionEnd
