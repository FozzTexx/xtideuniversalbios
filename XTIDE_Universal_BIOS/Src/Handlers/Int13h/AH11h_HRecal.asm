; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=11h, Recalibrate.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=11h, Recalibrate.
;
; AH11h_HandlerForRecalibrate
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns with INTPACK:
;		AH:		BIOS Error code
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH11h_HandlerForRecalibrate:
%ifndef USE_186
	call	AH11h_RecalibrateDrive
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%else
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall to AH11h_RecalibrateDrive
%endif


;--------------------------------------------------------------------
; AH11h_HRecalibrate
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
AH11h_RecalibrateDrive:
	; Recalibrate command is optional, vendor specific and not even
	; supported on later ATA-standards. Let's do seek instead.
	mov		cx, 1						; Seek to Cylinder 0, Sector 1
	xor		dh, dh						; Head 0
	jmp		AHCh_SeekToCylinder
