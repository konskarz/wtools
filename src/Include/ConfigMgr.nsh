!define DID "$TEMP"					; default installation directory
!define DDD "$DOCUMENTS\Downloads"	; default downloads directory
; General Attributes
Name "${INSTNAME}"
InstallDir "${DID}"
; Compiler Flags
SetCompressor /SOLID /FINAL lzma
SetOverwrite ifnewer
; Version Information
VIProductVersion "${INSTVERS}"
VIAddVersionKey "ProductName" "${INSTNAME}"
VIAddVersionKey "LegalCopyright" "Konstantin Karzanov"
VIAddVersionKey "FileDescription" "${INSTDESC}"
VIAddVersionKey "FileVersion" "${INSTVERS}"
; Include
!include "FileFunc.nsh"
!include "WordFunc.nsh"
!include ".\Include\GetFolderPath.nsh"
; Variables
Var LOC	; located drive
Var EDR	; installer drive
Var DLS	; downloads directory
Var CMD	; command line parameters
Var INI	; installer configuration file
Var IND	; installer configuration file directory
Var DLM	; delimiter for lists of items
Var AUT	; sections to process automatically
!define ExpandEnvStrPlus '!insertmacro ExpandEnvStrPlus'
!macro ExpandEnvStrPlus _STRING _RESULT
	StrCmp "'${_STRING}'" "''" +4
		Push ${_STRING}
		Call ExpandEnvStrPlus
		Pop ${_RESULT}
!macroend
Function ExpandEnvStrPlus	; WordFunc.nsh required
	Exch $0
	${WordReplace} "$0" "%ROOT%" "$EDR" "+" $0
	${WordReplace} "$0" "%DOWNLOADS%" "$DLS" "+" $0
	${WordReplace} "$0" "%INIDIR%" "$IND" "+" $0
	${WordReplace} "$0" "%EXEDIR%" "$EXEDIR" "+" $0
	${WordReplace} "$0" "%INSTDIR%" "$INSTDIR" "+" $0
	${WordReplace} "$0" "%DOCUMENTS%" "$DOCUMENTS" "+" $0
	${WordReplace} "$0" "%LOCALAPPDATA%" "$LOCALAPPDATA" "+" $0
	ExpandEnvStrings $0 "$0"		; result input
	Exch $0
FunctionEnd
!define ReadOption '!insertmacro ReadOption'
!macro ReadOption _OPTION _RESULT
	Push ${_OPTION}
	Call ReadOption
	IfErrors +2						; no cmd/option, stack is empty
		Pop ${_RESULT}				; empty stack
!macroend
Function ReadOption
	Exch $0							; _option, $0 on top of the stack
	Push $1							; _temp, $1 on top of the stack
	StrCmp "'$CMD'" "''" Errors
	${GetOptionsS} "$CMD" "$0" $1	; FileFunc.nsh required, blank _temp if no/blank option
	IfErrors Errors					; no option
		Exch $1						; restore $1, _temp on top of the stack
		Exch						; $0 on top of the stack
		Pop $0						; restore $0, _temp on top of the stack
		Return
	Errors:
	Pop $1							; restore $1, $0 on top of the stack
	Pop $0							; restore $0, stack is empty
	SetErrors
FunctionEnd
!define IsOption '!insertmacro IsOption'
!macro IsOption _OPTION _RESULT
	Push ${_OPTION}
	Call ReadOption
	IfErrors +3						; no cmd/option, stack is empty
		Pop ${_RESULT}				; empty stack
		StrCpy ${_RESULT} "true"
!macroend
!define ReadIniEntry '!insertmacro ReadIniEntry'
!macro ReadIniEntry _SECTION _ENTRY _RESULT
	ReadINIStr ${_RESULT} "$INI" ${_SECTION} ${_ENTRY}
	StrCmp "'${_RESULT}'" "''" 0 +2
		SetErrors
!macroend
!define ReadAndExpandIniEntry '!insertmacro ReadAndExpandIniEntry'
!macro ReadAndExpandIniEntry _SECTION _ENTRY _RESULT
	${ReadIniEntry} ${_SECTION} ${_ENTRY} ${_RESULT}
	${ExpandEnvStrPlus} ${_RESULT} ${_RESULT}
!macroend
!define IfTarget '!insertmacro IfTarget'
!macro IfTarget _SECTION _FUNCTION
	Push $0							; target/function
	${ReadAndExpandIniEntry} "${_SECTION}" "trg" $0
	IfErrors +4
		IfFileExists "$0" 0 +3
			GetFunctionAddress $0 ${_FUNCTION}
			Call $0
	Pop $0
!macroend
!define LocateDrive '!insertmacro LocateDrive'
!macro LocateDrive _STRING _RESULT
	StrCmp "'${_STRING}'" "''" +4
		Push ${_STRING}
		Call LocateDrive
		Pop ${_RESULT}
!macroend
Function "LocateDrive"
	Exch $0
	Push $R9									; path, $R0-$R9 not used by GetDrives
	ClearErrors
	${WordFind} "$0" "[locate]" "E+1}" $R9		; WordFunc.nsh required
	IfErrors Done
		StrCmp "'$LOC'" "''" +2
			IfFileExists "$LOC$R9" Defined		; use last location
				StrCpy $0 "$TEMP\$R9"			; assign default value
				${GetDrives} "ALL" "CheckPath"	; FileFunc.nsh required
				StrCmp "'$LOC'" "''" Done		; keep default value
			Defined:
			StrCpy $0 "$LOC$R9"
	Done:
	Pop $R9
	Exch $0
FunctionEnd
Function "CheckPath"		; $9 = drive, $R9 = path
	IfFileExists "$9$R9" FoundPath
		Push $0
		Return
	FoundPath:
	Push StopGetDrives
	StrCpy $LOC "$9"
FunctionEnd
Function InitConfig
	${GetRoot} "$EXEDIR" $EDR		; FileFunc.nsh required
	${SHGetKnownFolderPath} "${FOLDERID_Downloads}" "" $DLS	; GetFolderPath.nsh required
	StrCmp "'$DLS'" "''" 0 +2
		StrCpy $DLS "${DDD}"
	StrCpy $IND "${DINIPATH}"
	${GetParameters} $CMD			; FileFunc.nsh required
	${ExpandEnvStrPlus} "$CMD" $CMD
	Call DefineIni
	${GetParent} "$INI" $IND		; FileFunc.nsh required
	Call DefineInstDir
	${ReadINIEntry} "${INSTNAME}" "dlm" $DLM
	${ReadINIEntry} "${INSTNAME}" "aut" $AUT
	ClearErrors
	${ReadOption} "/dlm=" $DLM
	${ReadOption} "/A=" $AUT
	StrCmp "'$DLM'" "''" 0 +2
		StrCpy $DLM ";"				; no/blank dlm property
FunctionEnd
Function DefineIni
	${ReadOption} "/C=" $INI		; FileFunc.nsh required
	StrCmp "'$INI'" "''" +3
		IfFileExists "$INI" 0 +2
			Return
	StrCpy $INI "$EXEDIR\${INSTNAME}.ini"
	IfFileExists "$INI" +3
		SetOutPath $EXEDIR
		File "${DINIPATH}\${INSTNAME}.ini"
FunctionEnd
Function DefineInstDir
	StrCmp "$INSTDIR" "${DID}" +2
		Return						; modified with /D=path switch
	${ReadAndExpandINIEntry} "${INSTNAME}" "dir" $INSTDIR
	${LocateDrive} "$INSTDIR" $INSTDIR
	IfErrors 0 +2					; no/blank dir property
		StrCpy $INSTDIR "${DID}"
FunctionEnd
