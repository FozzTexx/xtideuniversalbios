; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=2h, Read Disk Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=2h, Read Disk Sectors.
;
; AH2h_HandlerForReadDiskSectors
;	Parameters:
;		AL, CX, DH, ES:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		AL:		Number of sectors to read (1...127)
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		ES:BX:	Pointer to buffer recieving data
;	Returns with INTPACK:
;		AH:		Int 13h/40h floppy return status
;		AL:		Burst error length if AH returns 11h, undefined otherwise
;		CF:		0 if successfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH2h_HandlerForReadDiskSectors:
	cmp		BYTE [bp+IDEPACK.intpack+INTPACK.al], 0
	jle		SHORT AH2h_ExitInt13hSinceSectorCountInIntpackIsZero

	xor		bx, bx
	call	CommandLookup_OrOldInt13hIndexToBL
	mov		ah, [cs:bx+g_rgbReadCommandLookup]
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
	mov		si, [bp+IDEPACK.intpack+INTPACK.bx]
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	jmp		Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
%else
	call	Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif


;--------------------------------------------------------------------
; AH2h_ExitInt13hSinceSectorCountInIntpackIsZero
;	Parameters:
;		Nothing
;	Returns:
;		Jumps to Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
;--------------------------------------------------------------------
AH2h_ExitInt13hSinceSectorCountInIntpackIsZero:
	mov		ah, RET_HD_INVALID
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH

