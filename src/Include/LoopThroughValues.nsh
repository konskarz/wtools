!define LoopThroughValues '!insertmacro LoopThroughValues'
!macro LoopThroughValues _VALUES _DELIMITER _FUNCTION
	Push $0
	GetFunctionAddress $0 ${_FUNCTION}
	Push $0
	Push `${_DELIMITER}`
	Push `${_VALUES}`
	Call LoopThroughValues
	Pop $0
!macroend
Function LoopThroughValues
	ClearErrors
	Exch $0	; _VALUES
	Exch
	Exch $1	; _DELIMITER
	Exch
	Exch 2
	Exch $2	; _FUNCTION
	Exch 2
	Push $3	; _VALUE
	Loop:
		StrCmp "'$0'" "''" Done
		${WordFind} "$0" "$1" "+01" $3		; value
		${WordFind} "$0" "$1" "+02}*" $0	; next value
		Call $2
		StrCmp $0 $3 Done	; the same
		Goto Loop
	Done:
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd
