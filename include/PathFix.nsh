!define PathFix '!insertmacro PathFix'
!macro PathFix _CONFIG_FILE _DELIMITER _FUNC
	Push $0
	GetFunctionAddress $0 "${_FUNC}"
	Push $0
	Push "${_DELIMITER}"
	Push "${_CONFIG_FILE}"
	Call PathFix
	Pop $0
!macroend
Function PathFix
	ClearErrors
	Exch $0		; _CONFIG_FILE
	Exch
	Exch $1		; _DELIMITER
	Exch
	Exch 2
	Exch $2		; _FUNC
	Exch 2
	Push $3		; _CONFIG_FILE file handle
	Push $4     ; LINE_TEXT
	Push $5     ; SOURCE_DIR
	Push $6		; SOURCE_FILE
	Push $7     ; SEARCH_TEXT
	Push $8     ; REPLACEMENT
	Push $9     ; FILE_SEPARATOR
	IfFileExists "$0" +1 Done
		FileOpen $3 $0 r
		IfErrors Done
			Loop:
			FileRead $3 $4
			IfErrors ExitLoop
				${StrFilter} $4 "" "" "$\r$\n" $4
				${WordFind} $4 $1 "+3" $6
				IfErrors Loop
					${WordFind} "$0" "\" "-2{*" $5
					IfFileExists "$5\$6" +1 Loop
						${WordFind} $4 $1 "+1" $7
						IfErrors Loop
							Call GetReplacement
							IfErrors Loop
								${WordFind} $4 $1 "+2" $9
								IfErrors Loop
									Call SeparatorFix
									DetailPrint "Replace: $7$9 with $8$9 in $5\$6"
									textreplace::_ReplaceInFile /NOUNLOAD "$5\$6" "$5\$6" "$7$9" "$8$9" "/S=1 /C=0 /AO=1"
									Goto Loop
			ExitLoop:
			textreplace::_Unload
			FileClose $3
			Delete "$0"
	Done:
	Pop $9
	Pop $8
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd
Function GetReplacement	;$2=FUNCTION, $5: SOURCE_DIR, $7: SEARCH_TEXT, $8: REPLACEMENT
	StrCmp "$7" "%PFCDIR%" +1 +3
		StrCpy $8 "$5"
		Return
	Push $7
	Call $2
	Pop $8
	StrCmp "$7" "$8" +2
		Return
	SetErrors
FunctionEnd
Function SeparatorFix	; $8: REPLACEMENT, $9: FILE_SEPARATOR
	StrCmp "$9" "\\" Fix
		StrCmp "$9" "/" Fix
			Return
	Fix:
	${WordReplace} "$8" "\" "$9" "+" "$8"	; input_string word_to_replace replace_with options result
FunctionEnd