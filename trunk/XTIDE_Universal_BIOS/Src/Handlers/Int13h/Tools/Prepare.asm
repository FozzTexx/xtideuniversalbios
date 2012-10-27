; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for preparing data buffer for transfer.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;

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
	call	Prepare_GetOldInt13hCommandIndexToBX
	mov		al, [di+DPT.bFlagsLow]
	eSHL_IM	al, 1					; Set CF if LBA48 supported
	adc		bl, bh					; LBA48 EXT commands
	ret
%endif ; MODULE_EBIOS


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
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
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
	mov		si, [bp+IDEPACK.intpack+INTPACK.bx]	; Load offset
	mov		es, [bp+IDEPACK.intpack+INTPACK.es]	; Load segment
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
Prepare_ByValidatingSectorsInALforOldInt13h:
	test	al, al
	js		SHORT .CheckZeroOffsetFor128Sectors		; 128 or more
	jz		SHORT InvalidNumberOfSectorsRequested	; Zero not allowed for old INT 13h
	ret		; Continue with transfer

ALIGN JUMP_ALIGN
.CheckZeroOffsetFor128Sectors:
	cmp		al, 128
	ja		SHORT InvalidNumberOfSectorsRequested
	test	si, si								; Offset must be zero to xfer 128 sectors
	jnz		SHORT CannotAlignPointerProperly
	ret		; Continue with transfer

InvalidDAP:
InvalidNumberOfSectorsRequested:
Prepare_ReturnFromInt13hWithInvalidFunctionError:
	mov		ah, RET_HD_INVALID
	SKIP2B	f
CannotAlignPointerProperly:
	mov		ah, RET_HD_BOUNDARY
ZeroSectorsRequestedSoNoErrors:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH



; Command lookup tables
g_rgbReadCommandLookup:
	db		COMMAND_READ_SECTORS		; 00b, CHS or LBA28 single sector
	db		COMMAND_READ_SECTORS_EXT	; 01b, LBA48 single sector
	db		COMMAND_READ_MULTIPLE		; 10b, CHS or LBA28 block mode
%ifdef MODULE_EBIOS
	db		COMMAND_READ_MULTIPLE_EXT	; 11b, LBA48 block mode
%endif

g_rgbWriteCommandLookup:
	db		COMMAND_WRITE_SECTORS
	db		COMMAND_WRITE_SECTORS_EXT
	db		COMMAND_WRITE_MULTIPLE
%ifdef MODULE_EBIOS
	db		COMMAND_WRITE_MULTIPLE_EXT
%endif

g_rgbVerifyCommandLookup:
	db		COMMAND_VERIFY_SECTORS
	db		COMMAND_VERIFY_SECTORS_EXT
	db		COMMAND_VERIFY_SECTORS
%ifdef MODULE_EBIOS
	db		COMMAND_VERIFY_SECTORS_EXT
%endif
