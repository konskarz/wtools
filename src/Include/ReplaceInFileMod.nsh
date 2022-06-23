; ReplaceInFile by Author: Datenbert (http://nsis.sourceforge.net/ReplaceInFile) modified by Konstantin Karzanov
; Usage:
; !include "WordFunc.nsh"
; !include ReplaceInFileMod.nsh
; {ReplaceInFile} SOURCE_FILE SEARCH_TEXT REPLACEMENT
!define ReplaceInFile '!insertmacro ReplaceInFile'
!macro ReplaceInFile SOURCE_FILE SEARCH_TEXT REPLACEMENT
	Push "${SOURCE_FILE}"
	Push "${SEARCH_TEXT}"
	Push "${REPLACEMENT}"
	Call ReplaceInFile
!macroend
Function ReplaceInFile
	ClearErrors  					; want to be a newborn
	Exch $0      					; REPLACEMENT
	Exch
	Exch $1      					; SEARCH_TEXT
	Exch 2
	Exch $2      					; SOURCE_FILE
	Push $R0     					; SOURCE_FILE file handle
	Push $R1     					; temporary file handle
	Push $R2     					; unique temporary file name
	Push $R3     					; a line to sar/save
	Push $R4     					; shift puffer
	IfFileExists $2 +1 RIF_error	; knock-knock
		FileOpen $R0 $2 "r"			; open the door
		GetTempFileName $R2			; who's new?
		FileOpen $R1 $R2 "w"		; the escape, please!
		RIF_loop:					; round'n'round we go
		FileRead $R0 $R3			; read one line
		IfErrors RIF_leaveloop		; enough is enough
			${WordReplace} "$R3" "$1" "$0" "+" "$R3"	; input_string word_to_replace replace_with options result
			FileWrite $R1 "$R3"		; save the newbie
			Goto RIF_loop			; gimme more
		RIF_leaveloop:				; over'n'out, Sir!
		FileClose $R1				; S'rry, Ma'am - clos'n now
		FileClose $R0				; me 2
		Rename "$2" "$2.old"		; step aside, Ma'am
		Rename "$R2" "$2"			; hi, baby!
		Delete "$2.old"				; go away, Sire
		ClearErrors					; now i AM a newborn
		Goto RIF_out				; out'n'away
	RIF_error:						; ups - s.th. went wrong...
	SetErrors						; ...so cry, boy!
	RIF_out:						; your wardrobe?
	Pop $R4
	Pop $R3
	Pop $R2
	Pop $R1
	Pop $R0
	Pop $2
	Pop $0
	Pop $1
FunctionEnd
