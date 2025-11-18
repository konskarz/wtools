; Variables
Var IST	; installer section text, same as INI section name in SelectMgr.nsh
Var TRG	; main program executable to launch
Var ARG	; command line arguments for main program executable
Var PTH	; string to append to %PATH% environment variable
Var ENV	; list of environment variables to set separated by $DLM
Var LFL	; list of local files to monitor (backup, remove, restore) separated by $DLM
Var LDL	; list of local directories to monitor (backup, remove, restore) separated by $DLM
Var LRL	; list of local registy keys to monitor (backup, remove, restore) separated by $DLM
Var TMP	; temporary directory with program settings, default: $TEMP\$IST
Var PSD	; program settings directory to copy in $TMP
Var PSR	; program settings registry file(*.reg) to import
Var PFC	; path fix configuration file in $TMP with search and replace values separated by $DLM
Var PRE	; command to execute after applying $PSD, $PFC, $PSR
Var PST	; command to execute before removing $TMP and restoring $LFL, $LDL, $LRL, spm: semi portable mode
Function InitLaunch		; LoopThroughValues.nsh
	Pop $IST									; _sectionindex
	SectionGetText $IST $IST
	DetailPrint "Section: $IST"
	${ReadAndExpandIniEntry} "$IST" "trg" $TRG	; ConfigMgr.nsh required
	IfErrors 0 +4
		DetailPrint "Main executable is not specified"
		SetErrors
		Return
	Push $0										; arg/ins
	${ReadOption} "/arg=" $ARG					; ConfigMgr.nsh required
	${ReadAndExpandIniEntry} "$IST" "arg" $0	; ConfigMgr.nsh required
	IfErrors +2
		StrCpy $ARG '$0 $ARG'
	${ReadAndExpandIniEntry} "$IST" "ins" $0	; ConfigMgr.nsh required
	IfErrors +3
		IfFileExists "$TRG" +2
			ExecWait $0
	${ReadAndExpandIniEntry} "$IST" "pth" $PTH	; ConfigMgr.nsh required
	IfErrors +3
		StrCmp "'$PTH'" "''" +2
			Call SetPath
	${ReadAndExpandIniEntry} "$IST" "env" $ENV	; ConfigMgr.nsh required
	IfErrors Done
		StrCmp "'$ENV'" "''" Done
			${LoopThroughValues} "$ENV" "$DLM" "SetEnv"		; _values _delimiter _function
	Done:
	Pop $0
	ClearErrors
FunctionEnd
Function SetPath
	Push $0								; buffer
	Push $1								; path
	ReadEnvStr $1 "PATH"
	StrCpy $1 "$1$PTH;"
	System::Call 'KERNEL32::SetEnvironmentVariable(t "PATH", t "$1")i.r2'
	StrCmp $0 0 0 +2
		DetailPrint "Error setting PATH variable"
	Pop $1
	Pop $0
FunctionEnd
Function SetEnv			; $3 = statement, WordFunc.nsh required
	Push $0								; buffer
	Push $1								; name
	Push $2								; value
	${WordFind} "$3" "=" "+01" $1
	${WordFind} "$3" "=" "+02}*" $2
	StrCmp "'$1'" "''" Done
	StrCmp "'$2'" "''" Done
		IfFileExists "$2" +2
			CreateDirectory "$2"
		System::Call 'KERNEL32::SetEnvironmentVariable(t "$1", t "$2")i.r2'
		StrCmp $0 0 0 Done
			DetailPrint "Error setting $1 variable"
	Done:
	Pop $2
	Pop $1
	Pop $0
FunctionEnd
!addPluginDir ".\plugins\FindProc"
Function IsRunning
	Push $R0						; name/status
	${GetFileName} "$TRG" $R0		; FileFunc.nsh required, _PATHSTRING _RESULT
	FindProcDLL::FindProc "$R0"		; Plugins\FindProcDLL required
	ClearErrors
	StrCmp "$R0" "1" +2
		SetErrors
	Pop $R0
FunctionEnd
Function IsSimple		; ConfigMgr.nsh required
	${ReadAndExpandIniEntry} "$IST" "lfl" $LFL
	${ReadAndExpandIniEntry} "$IST" "ldl" $LDL
	${ReadIniEntry} "$IST" "lrl" $LRL
	${ReadAndExpandIniEntry} "$IST" "psd" $PSD
	${ReadAndExpandIniEntry} "$IST" "psr" $PSR
	${ReadAndExpandIniEntry} "$IST" "pfc" $PFC
	${ReadAndExpandIniEntry} "$IST" "pre" $PRE
	${ReadAndExpandIniEntry} "$IST" "pst" $PST
	ClearErrors
	StrCmp "'$LFL$LDL$LRL$PSD$PSR$PFC$PRE$PST'" "''" +2
		SetErrors
FunctionEnd
Function IsSemiPortable
	ClearErrors
	StrCmp "$PST" "spm" +2
		SetErrors
FunctionEnd
Function ExecuteAndContinue
	Push $R0						; path
	${GetParent} "$TRG" $R0			; FileFunc.nsh required, _PATHSTRING _RESULT
	SetOutPath "$R0"				; Some programs attempt to read from it
	Pop $R0
	StrCmp "'$ARG'" "''" NoArg
		DetailPrint 'Parameters: $ARG'
		ExecShell "open" '"$TRG"' '$ARG'
		IfErrors 0 +2
			Exec '"$TRG" $ARG'
		Return
	NoArg:
	ExecShell "open" '"$TRG"'
	IfErrors 0 +2
		Exec '"$TRG"'
FunctionEnd
!include ".\include\BackupAndRestore.nsh"	; WordFunc.nsh required
Function ProcessSetup
	${ReadAndExpandIniEntry} "$IST" "tmp" $TMP	; ConfigMgr.nsh required
	IfErrors 0 +2
		StrCpy $TMP "$TEMP\$IST"
	IfFileExists "$TMP" +2						; semi portable mode
		Call CopySettings
	Call FixSettings
	Call ImportSettings
	StrCmp "'$PRE'" "''" +3
		Push '$PRE'
		Call ExecuteToLog						; BackupAndRestore.nsh required
FunctionEnd
Function CopySettings
	StrCmp "'$PSD'" "''" +2
		IfFileExists "$PSD" +2
			Return
	CreateDirectory "$TMP"
	CopyFiles /SILENT "$PSD\*.*" "$TMP"
	${Locate} "$TMP" "/L=F" "FixFileAttr"		; FileFunc.nsh required
FunctionEnd
Function FixFileAttr	; $R9 = file
	SetFileAttributes $R9 0
	Push $0
FunctionEnd
!addPluginDir ".\plugins\Textreplace"
!include ".\include\PathFix.nsh"			; Plugins\Textreplace, WordFunc.nsh required
Function FixSettings	; PathFix.nsh, ConfigMgr.nsh required
	StrCmp "'$PFC'" "''" +2
		IfFileExists "$TMP\$PFC" +2
			Return
	DetailPrint "PathFix: $TMP\$PFC"
	${PathFix} "$TMP\$PFC" "$DLM" "ExpandEnvStrPlus"		; _file _delimiter _function
FunctionEnd
Function ImportSettings	; BackupAndRestore.nsh required
	StrCmp "'$PSR'" "''" +2
		IfFileExists "$PSR" +2
			Return
	Push '"$WINDIR\system32\reg.exe" import "$PSR"'
	Call ExecuteToLog
FunctionEnd
Function ProcessBackup	; LoopThroughValues.nsh, BackupAndRestore.nsh required
	StrCmp "'$LRL'" "''" NoLrl
		${LoopThroughValues} "$LRL" "$DLM" "BackupReg"		; _values _delimiter _function
	NoLrl:
	StrCmp "'$LFL'" "''" NoLfl
		${LoopThroughValues} "$LFL" "$DLM" "BackupFile"		; _values _delimiter _function
	NoLfl:
	StrCmp "'$LDL'" "''" NoLdl
		${LoopThroughValues} "$LDL" "$DLM" "BackupDir"		; _values _delimiter _function
	NoLdl:
FunctionEnd
Function ExecuteAndWait
	StrCpy $TRG '"$TRG"'
	StrCmp "'$ARG'" "''" +2
		StrCpy $TRG '$TRG $ARG'
	SetOutPath "$TMP"				; Some programs attempt to write in it
	ExecWait $TRG
	SetOutPath "$PROFILE"
FunctionEnd
Function ProcessRemove
	StrCmp "'$PST'" "''" +3
		Push '$PST'
		Call ExecuteToLog			; BackupAndRestore.nsh required
	IfFileExists "$TMP" 0 +2
		RMDir /r "$TMP\"
FunctionEnd
Function ProcessRestore	; LoopThroughValues.nsh, BackupAndRestore.nsh required
	StrCmp "'$LDL'" "''" NoLdl
		${LoopThroughValues} "$LDL" "$DLM" "RestoreDir"		; _values _delimiter _function
	NoLdl:
	StrCmp "'$LFL'" "''" NoLfl
		${LoopThroughValues} "$LFL" "$DLM" "RestoreFile"	; _values _delimiter _function
	NoLfl:
	StrCmp "'$LRL'" "''" NoLrl
		${LoopThroughValues} "$LRL" "$DLM" "RestoreReg"		; _values _delimiter _function
	NoLrl:
FunctionEnd
