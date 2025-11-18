!define REG "$WINDIR\system32\reg.exe"
Function BackupReg						; $3 = registry key
	Push $0								; rootkey
	Push $1								; subkey
	Push '"${REG}" query "$3"'
	Call ExecuteToLog
	IfErrors Done
		${WordFind} "$3" "\" "+01" $0	; WordFunc.nsh required
		${WordFind} "$3" "\" "-01" $1	; WordFunc.nsh required
		Push '"${REG}" export "$3" "$TEMP\$0_$1.reg"'
		Call ExecuteToLog
	Done:
	Pop $1
	Pop $0
FunctionEnd
Function RestoreReg						; $3 = registry key
	Push $0								; rootkey
	Push $1								; subkey
	Push '"${REG}" query "$3"'
	Call ExecuteToLog
	IfErrors Done
		Push '"${REG}" delete "$3" /f'
		Call ExecuteToLog
		${WordFind} "$3" "\" "+01" $0	; WordFunc.nsh required
		${WordFind} "$3" "\" "-01" $1	; WordFunc.nsh required
		IfFileExists "$TEMP\$0_$1.reg" +1 Done
			Push '"${REG}" import "$TEMP\$0_$1.reg"'
			Call ExecuteToLog
			Delete /REBOOTOK "$TEMP\$0_$1.reg"
	Done:
	Pop $1
	Pop $0
FunctionEnd
Function BackupFile						; $3 = file path
	IfFileExists "$3" 0 +2
		Rename "$3" "$3-Backup"
FunctionEnd
Function RestoreFile					; $3 = file path
	IfFileExists "$3" 0 +2
		Delete /REBOOTOK "$3"
	IfFileExists "$3-Backup" 0 +2
		Rename "$3-Backup" "$3"
FunctionEnd
Function BackupDir						; $3 = directory path
	IfFileExists "$3" 0 +2
		Rename "$3" "$3-Backup"
FunctionEnd
Function RestoreDir						; $3 = directory path
	IfFileExists "$3" 0 +2
		RMDir "/r" "$3"
	IfFileExists "$3-Backup" 0 +2
		Rename "$3-Backup" "$3"
FunctionEnd
Function ExecuteToLog
	Exch $0
	DetailPrint 'Execute: $0'
	nsExec::ExecToLog /OEM '$0'
	Pop $0
	StrCmp $0 0 +2
		SetErrors
	Pop $0
FunctionEnd
