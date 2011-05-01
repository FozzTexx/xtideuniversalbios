; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=3h, Write Disk Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=3h, Write Disk Sectors.
;
; AH3h_HandlerForWriteDiskSectors
;	Parameters:
;		AL, CX, DH, ES:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Parameters on INTPACK:
;		AL:		Number of sectors to write
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		ES:BX:	Pointer to source data
;	Returns with INTPACK:
;		AH:		Int 13h/40h floppy return status
;		CF:		0 if successfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH3h_HandlerForWriteDiskSectors:
	call	AH2h_ExitInt13hIfSectorCountInIntpackIsZero
	mov		ah, COMMAND_WRITE_SECTORS	; Load sector mode command
	test	WORD [di+DPT.wFlags], FLG_DPT_BLOCK_MODE_SUPPORTED
	eCMOVNZ	ah, COMMAND_WRITE_MULTIPLE	; Load block mode command
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
	mov		si, [bp+IDEPACK.intpack+INTPACK.bx]
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	jmp		Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
%else
	call	Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif
