; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=4h, Verify Disk Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=4h, Verify Disk Sectors.
;
; AH4h_HandlerForVerifyDiskSectors
;	Parameters:
;		AL, CX, DH:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Parameters on INTPACK in SS:BP:
;		AL:		Number of sectors to verify (1...127)
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;	Returns with INTPACK in SS:BP:
;		AH:		Int 13h/40h floppy return status
;		CF:		0 if successfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH4h_HandlerForVerifyDiskSectors:
	cmp		al, 0
	jle		SHORT AH2h_ExitInt13hSinceSectorCountInIntpackIsZero

	mov		ah, COMMAND_VERIFY_SECTORS
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRDY)
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	jmp		Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
%else
	call	Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif
