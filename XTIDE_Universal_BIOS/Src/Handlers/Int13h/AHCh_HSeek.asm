; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=Ch, Seek.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=Ch, Seek.
;
; AHCh_HandlerForSeek
;	Parameters:
;		CX, DH:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Parameters on INTPACK in SS:BP:
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;	Returns with INTPACK in SS:BP:
;		AH:		BIOS Error code
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AHCh_HandlerForSeek:
%ifndef USE_186
	call	AHCh_SeekToCylinder
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%else
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall through to AHCh_SeekToCylinder
%endif


;--------------------------------------------------------------------
; AHCh_SeekToCylinder
;	Parameters:
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
AHCh_SeekToCylinder:
	mov		ax, HCMD_SEEK<<8			; Load cmd to AH, AL=zero sector cnt
	call	HCommand_OutputCountAndLCHSandCommand
	jc		SHORT .ReturnWithErrorCodeInAH
	mov		bx, di						; DS:BX now points to DPT
	jmp		HStatus_WaitIrqOrRdy		; Wait for IRQ or RDY
.ReturnWithErrorCodeInAH:
	ret
