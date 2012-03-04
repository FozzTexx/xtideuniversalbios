; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for preparing data buffer for transfer.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Prepare_ByLoadingDapToESSIandVerifyingForTransfer
;	Parameters:
;		SI:		Offset to DAP
;		DS:DI:	Ptr to DPT
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		DS:SI:	Ptr to Disk Address Packet
;	Returns:
;		BX:		Index to command lookup table
;		ES:SI:	Ptr to Disk Address Packet (DAP)
;		Exits from INT 13h if invalid DAP
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
%ifdef MODULE_EBIOS
ALIGN JUMP_ALIGN
Prepare_ByLoadingDapToESSIandVerifyingForTransfer:
	; Load pointer to DAP to ES:SI and make sure it is valid
	mov		es, [bp+IDEPACK.intpack+INTPACK.ds]	; ES:SI to point Disk Address Packet
	cmp		BYTE [es:si+DAP.bSize], MINIMUM_DAP_SIZE
	jb		SHORT InvalidDAP

	; Make sure that sector count is valid
	mov		ax, [es:si+DAP.wSectorCount]
	test	ax, ax
	jz		SHORT ZeroSectorsRequestedSoNoErrors
	cmp		ax, BYTE 127
	ja		SHORT InvalidNumberOfSectorsRequested

	; Get EBIOS command index to BX
	; LBA28 or LBA48 command
	cwd
	mov		al, [es:si+DAP.qwLBA+3]	; Load LBA48 byte 3 (bits 24...31)
	and		al, 0F0h				; Clear LBA28 bits 24...27
	or		ax, [es:si+DAP.qwLBA+4]	; Set bits from LBA bytes 4 and 5
	cmp		dx, ax					; Set CF if any of bits 28...47 set
	rcl		dx, 1					; DX = 0 for LBA28, DX = 1 for LBA48
	call	Prepare_GetOldInt13hCommandIndexToBX
	or		bx, dx					; Set block mode / single sector bit
	ret
%endif


;--------------------------------------------------------------------
; Prepare_GetOldInt13hCommandIndexToBX
;	Parameters:
;		DS:DI:	Ptr to DPT
;	Returns:
;		BX:		Index to command lookup table
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Prepare_GetOldInt13hCommandIndexToBX:
	; Block mode or single sector
	mov		bl, [di+DPT.bFlagsHigh]
	and		bx, BYTE FLGH_DPT_BLOCK_MODE_SUPPORTED	; Bit 1
	ret


;---------------------------------------------------------------------
; Prepare_BufferToESSIforOldInt13hTransfer
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
Prepare_BufferToESSIforOldInt13hTransfer:
	; Normalize buffer pointer
	mov		bx, [bp+IDEPACK.intpack+INTPACK.bx]	; Load offset
	mov		si, bx
	eSHR_IM	bx, 4								; Divide offset by 16
	add		bx, [bp+IDEPACK.intpack+INTPACK.es]
	mov		es, bx								; Segment normalized
	and		si, BYTE 0Fh						; Offset normalized
	; Fall to Prepare_ByValidatingSectorsInALforOldInt13h


;---------------------------------------------------------------------
; Prepare_ByValidatingSectorsInALforOldInt13h
;	Parameters:
;		AL:		Number of sectors to transfer
;	Returns:
;		Exits INT 13h if invalid number of sectors in AL
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Prepare_ByValidatingSectorsInALforOldInt13h:
	test	al, al
	js		SHORT .CheckZeroOffsetFor128Sectors		; 128 or more
	jz		SHORT InvalidNumberOfSectorsRequested	; Zero not allowed for old INT 13h
	ret		; Continue with transfer

ALIGN JUMP_ALIGN
.CheckZeroOffsetFor128Sectors:
	cmp		al, 128
	ja		SHORT InvalidNumberOfSectorsRequested
	mov		ah, RET_HD_BOUNDARY
	test	si, si								; Offset must be zero to xfer 128 sectors
	jnz		SHORT CannotAlignPointerProperly
	ret		; Continue with transfer

InvalidDAP:
InvalidNumberOfSectorsRequested:
Prepare_ReturnFromInt13hWithInvalidFunctionError:
	mov		ah, RET_HD_INVALID
ZeroSectorsRequestedSoNoErrors:
CannotAlignPointerProperly:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH



; Command lookup tables
g_rgbReadCommandLookup:
	db		COMMAND_READ_SECTORS		; 00b, CHS or LBA28 single sector
	db		COMMAND_READ_SECTORS_EXT	; 01b, LBA48 single sector
	db		COMMAND_READ_MULTIPLE		; 10b, CHS or LBA28 block mode
	db		COMMAND_READ_MULTIPLE_EXT	; 11b, LBA48 block mode

g_rgbWriteCommandLookup:
	db		COMMAND_WRITE_SECTORS
	db		COMMAND_WRITE_SECTORS_EXT
	db		COMMAND_WRITE_MULTIPLE
	db		COMMAND_WRITE_MULTIPLE_EXT

g_rgbVerifyCommandLookup:
	db		COMMAND_VERIFY_SECTORS
	db		COMMAND_VERIFY_SECTORS_EXT
	db		COMMAND_VERIFY_SECTORS
	db		COMMAND_VERIFY_SECTORS_EXT
