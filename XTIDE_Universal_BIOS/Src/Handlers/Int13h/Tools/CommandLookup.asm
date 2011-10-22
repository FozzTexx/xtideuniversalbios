; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for loading correct transfer command.

; Section containing code
SECTION .text

%ifdef MODULE_EBIOS
;--------------------------------------------------------------------
; CommandLookup_GetEbiosIndexToBX
;	Parameters:
;		DS:DI:	Ptr to DPT
;		ES:SI:	Ptr to DAP (Disk Address Packet)
;	Returns:
;		BX:		Index to command lookup table
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CommandLookup_GetEbiosIndexToBX:
	; LBA28 or LBA48 command
	xor		dx, dx
	mov		al, [es:si+DAP.qwLBA+3]	; Load LBA48 byte 3 (bits 24...31)
	and		ax, 00F0h				; Clear LBA28 bits 24...27
	or		ax, [es:si+DAP.qwLBA+4]	; Set bits from LBA bytes 4 and 5
	cmp		dx, ax					; Set CF if any of bits 28...47 set
	rcl		dx, 1					; DX = 0 for LBA28, DX = 1 for LBA48
	call	CommandLookup_GetOldInt13hIndexToBX
	or		bx, dx					; Set block mode / single sector bit
	ret
%endif
		
;--------------------------------------------------------------------
; CommandLookup_GetOldInt13hIndexToBX
;	Parameters:
;		DS:DI:	Ptr to DPT
;	Returns:
;		BX:		Index to command lookup table
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CommandLookup_GetOldInt13hIndexToBX:
	; Block mode or single sector
	mov		bl, [di+DPT.bFlagsHigh]
	and		bx, BYTE FLGH_DPT_BLOCK_MODE_SUPPORTED	; Bit 1
	ret


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
