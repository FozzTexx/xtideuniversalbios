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
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Parameters on INTPACK:
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;	Returns with INTPACK:
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
	; Fall to AHCh_SeekToCylinder
%endif

;--------------------------------------------------------------------
; AHCh_SeekToCylinder
;	Parameters:
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
AHCh_SeekToCylinder:
	mov		ah, COMMAND_SEEK
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRDY)
	jmp		Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
