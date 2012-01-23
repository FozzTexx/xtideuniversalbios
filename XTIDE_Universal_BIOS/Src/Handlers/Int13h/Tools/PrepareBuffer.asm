; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for preparing data buffer for transfer.

; Section containing code
SECTION .text

;---------------------------------------------------------------------
; PrepareBuffer_ToESSIforOldInt13hTransfer
;	Parameters:
;		AL:		Number of sectors to transfer
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		ES:BX:	Ptr to data buffer
;	Returns:
;		ES:SI:	Ptr to normalized data buffer
;		Exits INT 13h if error
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrepareBuffer_ToESSIforOldInt13hTransfer:
	; Normalize buffer pointer
	mov		bx, [bp+IDEPACK.intpack+INTPACK.bx]	; Load offset
	mov		si, bx
	eSHR_IM	bx, 4								; Divide offset by 16
	add		bx, [bp+IDEPACK.intpack+INTPACK.es]
	mov		es, bx								; Segment normalized
	and		si, BYTE 0Fh						; Offset normalized

	; Check if valid number of sectors
	test	al, al
	js		SHORT .CheckZeroOffsetFor128Sectors
	jz		SHORT .InvalidNumberOfSectorsRequested
	ret		; Continue with transfer

ALIGN JUMP_ALIGN
.CheckZeroOffsetFor128Sectors:
	cmp		al, 128
	ja		SHORT .InvalidNumberOfSectorsRequested
	mov		ah, RET_HD_BOUNDARY
	test	si, si								; Offset must be zero to xfer 128 sectors
	jnz		SHORT .CannotAlignPointerProperly
	ret		; Continue with transfer

.InvalidNumberOfSectorsRequested:
	mov		ah, RET_HD_INVALID
.CannotAlignPointerProperly:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH

