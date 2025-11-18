; Variables
Var IST	; installer section text, same as INI section name in SelectMgr.nsh
Var SRC	; installation source file
Function InitInstall
	Pop $IST										; sectionindex
	SectionGetText $IST $IST
	DetailPrint "Section: $IST"
	${ReadAndExpandINIEntry} "$IST" "src" $SRC		; ConfigMgr.nsh required
	IfErrors 0 +3									; no/blank src property
		DetailPrint "Source file is not specified"
		SetErrors
FunctionEnd
!addPluginDir ".\plugins\Inetc"
Function ProcessSource
	IfFileExists "$SRC" 0 +2
		Return
	Push $0											; directory/cookies/status
	Push $1											; download url
	${ReadINIEntry} "$IST" "url" $1					; ConfigMgr.nsh required
	IfErrors Errors									; no/blank url property
		${GetParent} "$SRC" $0						; FileFunc.nsh required
		IfFileExists "$0" +2
			CreateDirectory "$0"
		Push /end
		Push "$SRC"
		Push "$1"
		${ReadINIEntry} "$IST" "coo" $0				; ConfigMgr.nsh required
		IfErrors ProcessDownload
			Push "Cookie: $0"
			Push /HEADER
			Push /NOCOOKIES
		ProcessDownload:
		DetailPrint "Download: $1 to $SRC"
		inetc::get									; Plugins\Inetc required
		Pop $0
		StrCmp $0 "OK" Done
			DetailPrint "Status: $0"
	Errors:
	SetErrors
	Done:
	Pop $1
	Pop $0
FunctionEnd
!define ProcessDelRen '!insertmacro ProcessDelRen'
!macro ProcessDelRen _SRC _DST
	IfFileExists "${_DST}" 0 +2
		Delete "${_DST}"							; old/corrupted
	IfFileExists "${_SRC}" 0 +2
		Rename "${_SRC}" "${_DST}"
!macroend
Function UpdateSource
	${ProcessDelRen} "$SRC" "$SRC.bak"
	IfErrors Errors									; old src file in use
		Call ProcessSource
		IfErrors +2
			Return									; do not delete backup
		IfFileExists "$SRC.bak" 0 Errors
			${ProcessDelRen} "$SRC.bak" "$SRC"
	Errors:
	SetErrors
FunctionEnd
!addPluginDir ".\plugins\ZipDLL"
Function ProcessExtract
	Push $0											; directory/status
	${ReadAndExpandINIEntry} "$IST" "unz" $0		; ConfigMgr.nsh required
	IfErrors Done									; no/blank unz property
		ZipDLL::extractall "$SRC" "$0"				; Plugins\ZipDLL required
		Pop $0
		StrCmp $0 "success" Done
			SetErrors
	Done:
	Pop $0
FunctionEnd
Function ProcessRename
	Push $0											; parent item
	Push $1											; item to rename
	${ReadAndExpandINIEntry} "$IST" "ren" $1		; ConfigMgr.nsh required
	IfErrors Done									; no/blank ren property
		IfFileExists "$1" 0 Done
			${GetParent} "$1" $0					; FileFunc.nsh required
			Rename "$1" "$0\$IST"
	Done:
	Pop $1
	Pop $0
FunctionEnd
Function ProcessExecute
	Push $0											; string/status
	Push $1											; counter
	StrCpy $1 1
	Loop:
		${ReadAndExpandINIEntry} "$IST" "ex$1" $0	; ConfigMgr.nsh required
		IfErrors Done								; no/blank ex# property
			DetailPrint "Execute $1: $0"
			nsExec::ExecToLog '$0'
			Pop $0
			StrCmp $0 0 +3
				DetailPrint "Status: $0"
				SetErrors
			IntOp $1 $1 + 1
			Goto Loop
	Done:
	Pop $1
	Pop $0
FunctionEnd
Function ProcessCleanup
	IfErrors 0 +3
		SetErrors
		Return
	IfFileExists "$SRC.unp\*.*" 0 +2
		RMDir /r "$SRC.unp"
	IfFileExists "$SRC.bak" 0 +2
		Delete "$SRC.bak"
FunctionEnd
