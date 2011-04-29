; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=10h, Check Drive Ready.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=10h, Check Drive Ready.
;
; AH10h_HandlerForCheckDriveReady
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH10h_HandlerForCheckDriveReady:
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	jmp		Device_SelectDrive
%else
	call	Device_SelectDrive
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif
