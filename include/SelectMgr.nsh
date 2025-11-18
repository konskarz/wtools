; Variables
Var SSM	; section selection mode (selectable): exg - existing, msg - missing, skp - skip
Var MSM	; multiselection mode: allow/disallow multiple items selection
Var CSI	; current section index: init installer sections and indicate selected sections
Var ISN	; INI section name: to init installer section
Var ETF	; flags for sections with existing target
Var SSL	; selectable sections list, to search selected sections
Var NIB	; next/install button: disable on start and if all sections are deselected
!define InitSelect '!insertmacro InitSelect'
!macro InitSelect _MSF _MSM
	StrCpy $SSM ${_MSF}
	StrCpy $MSM ${_MSM}
	StrCpy $CSI 0
	Call InitSelect
!macroend
!include ".\include\LoopThroughValues.nsh"	; WordFunc.nsh required
!include ".\include\GetSectionNames.nsh"
Function InitSelect		; ConfigMgr.nsh($AUT,$DLM,$INI), LoopThroughValues.nsh, GetSectionNames.nsh
	StrCmp "'$AUT'" "''" NoAut
		SetAutoClose true
		${LoopThroughValues} "$AUT" "$DLM" "AutSelect"
		Return
	NoAut:
	${GetSectionNames} $INI "ManSelect"
FunctionEnd
Function AutSelect		; $3 = INI section name
	StrCpy $ISN "$3"
	Call AutFlags
	Call InitSection
	StrCmp "$MSM" "true" +3
		StrCpy $0 $3					; override $0 used by LoopThroughValues to stop loop
		Return
	IntOp $CSI $CSI + 1					; increase for next
FunctionEnd
Function ManSelect		; $9 = INI section name
	StrCpy $ISN "$9"
	StrCmp "$ISN" "${INSTNAME}" Done
		Call ManFlags
		Call InitSection
		Call CheckSelectable
	Done:
	IntOp $CSI $CSI + 1					; increase for next
	Push $0
FunctionEnd
Function InitSection
	SectionSetText $CSI "$ISN"			; important: IST identical to ISN, make section selectable(aut) and visible(man)
	StrCmp "$SSM" "skp" 0 +2
		Return
	${IfTarget} "$ISN" "CheckExisting"	; ConfigMgr.nsh required
FunctionEnd
Function CheckExisting
	SectionSetFlags $CSI $ETF
FunctionEnd
Function AutFlags
	StrCmp "$SSM" "skp" 0 +3			; skip target check
		SectionSetFlags $CSI 1			; selected by default
		Return
	StrCmp "$SSM" "msg" 0 +4			; sections with missing target
		StrCpy "$ETF" 16				; deselected & read-only if target exists
		SectionSetFlags $CSI 1			; selected by default
		Return
	StrCmp "$SSM" "exg" 0 +3			; sections with existing target
		StrCpy "$ETF" 1					; selected if target exists
		SectionSetFlags $CSI 16			; deselected & read-only by default
FunctionEnd
Function ManFlags
	StrCmp "$SSM" "skp" 0 +2			; skip target check
		Return							; keep deselected & selectable by default
	StrCmp "$SSM" "msg" 0 +3			; sections with missing target
		StrCpy "$ETF" 16				; deselected & read-only if target exists
		Return							; keep deselected & selectable by default
	StrCmp "$SSM" "exg" 0 +3			; sections with existing target
		StrCpy "$ETF" 0					; deselected & selectable if target exists
		SectionSetFlags $CSI 16			; deselected & read-only by default
FunctionEnd
Function CheckSelectable
	Push $0
	SectionGetFlags $CSI $0
	StrCmp $0 16 +2						; skip deselected and read-only
		Call AppendSelectable
	Pop $0
FunctionEnd
Function AppendSelectable
	StrCmp "'$SSL'" "''" +3
		StrCpy $SSL "$SSL$DLM$CSI"
		Return
	StrCpy $SSL "$CSI"
FunctionEnd
Page components componentsPre componentsShow
Page instfiles
Function componentsPre	; ConfigMgr.nsh($AUT) required
	StrCmp "'$AUT'" "''" +2
		Abort
	Pop $0
FunctionEnd
Function componentsShow
	GetDlgItem $NIB $HWNDPARENT 1
	EnableWindow $NIB 0					; disable next/install
FunctionEnd
Function .onSelChange
	StrCmp "$MSM" "true" +2
		SectionSetFlags $CSI 0			; disable multiselection
	StrCpy $CSI -1
	${LoopThroughValues} "$SSL" "$DLM" "FindSelSec"	; LoopThroughValues.nsh, ConfigMgr.nsh($DLM) required
	StrCmp $CSI -1 DisableBtn
		EnableWindow $NIB 1				; enable next/install
		Return
	DisableBtn:
	EnableWindow $NIB 0					; disable next/install
FunctionEnd
Function FindSelSec
	Push $0								; section_flags
	SectionGetFlags $3 $0
	StrCmp $0 1 FoundSelSec
		Pop $0							; restore $0 used by LoopThroughValues
		Return
	FoundSelSec:
	StrCpy $CSI "$3"					; save first found selected section index
	Pop $0								; restore $0 used by LoopThroughValues
	StrCpy $0 "$3"						; override it to stop loop
FunctionEnd
