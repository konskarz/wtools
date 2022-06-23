; Author: nechai
; URL: http://nsis.sourceforge.net/Get_all_section_names_of_INI_file
; Description: Loop over all available sections in an INI file.
; Syntax:
; ${GetSectionNames} "File" "Function"
; "File"     ; name of the initialization file
; "Function" ; Callback function
; Function "Function"
	; $9    "section name"
	; $R0-$R9  are not used (save data in them).
	; ...
	; Push $var    ; If $var="StopGetSectionNames" Then exit from function
; FunctionEnd

!define GetSectionNames '!insertmacro GetSectionNames'
 
!macro GetSectionNames _FILE _FUNC
	Push $0
	Push `${_FILE}`
	GetFunctionAddress $0 `${_FUNC}`
	Push `$0`
	Call GetSectionNames
	Pop $0
!macroend
 
Function GetSectionNames
	Exch $1
	Exch
	Exch $0
	Exch
	Push $2
	Push $3
	Push $4
	Push $5
	Push $8
	Push $9
 
	System::Alloc 1024
	Pop $2
        StrCpy $3 $2
 
        System::Call "kernel32::GetPrivateProfileSectionNamesA(i, i, t) i(r3, 1024, r0) .r4"
 
	enumok:
        System::Call 'kernel32::lstrlenA(t) i(i r3) .r5'
	StrCmp $5 '0' enumex
 
	System::Call '*$3(&t1024 .r9)'
 
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $8
	Call $1
	Pop $9
	Pop $8
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
        StrCmp $9 'StopGetSectionNames' enumex
 
	; enumnext:
	IntOp $3 $3 + $5
	IntOp $3 $3 + 1
	goto enumok
 
	enumex:
	System::Free $2
 
	Pop $9
	Pop $8
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd