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
;		AL:		Number of sectors to write (1...128)
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		ES:BX:	Pointer to source data
;	Returns with INTPACK:
;		AH:		Int 13h/40h floppy return status
;		AL:		Number of sectors actually written (only valid if CF set for someBIOSes)
;		CF:		0 if successfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH3h_HandlerForWriteDiskSectors:
	call	Prepare_BufferToESSIforOldInt13hTransfer
	call	Prepare_GetOldInt13hCommandIndexToBX
	mov		ah, [cs:bx+g_rgbWriteCommandLookup]
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAHandTransferredSectorsFromCL
	jmp		Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
%else
	call	Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAHandTransferredSectorsFromCL
%endif
