; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for loading correct transfer command.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; CommandLookup_GetEbiosIndexToBX
; CommandLookup_OrOldInt13hIndexToBL
;	Parameters:
;		DS:DI:	Ptr to DPT
;		ES:SI:	Ptr to DAP (Disk Address Packet)
;	Returns:
;		BX:		Index to command lookup table
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CommandLookup_GetEbiosIndexToBX:
	; LBA28 or LBA48 command
	xor		bx, bx
	mov		ax, [es:si+DAP.qwLBA+3]	; Load LBA48 bytes 3 and 4
	and		al, ~0Fh				; Clear LBA28 bits 24...27
	or		al, [es:si+DAP.qwLBA+5]
	cmp		bx, ax					; Set CF if any of bits 28...47 set
	rcl		bx, 1					; BX = 0 for LBA28, BX = 1 for LBA48

	; Block mode or single sector
ALIGN JUMP_ALIGN
CommandLookup_OrOldInt13hIndexToBL:
	mov		al, FLGH_DPT_BLOCK_MODE_SUPPORTED	; Bit 1
	and		al, [di+DPT.bFlagsHigh]
	or		bl, al					; BX = index to lookup table
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

