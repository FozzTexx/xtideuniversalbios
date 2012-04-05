; Project name	:	XTIDE Univeral BIOS Configurator v2
; Description	:	Functions for managing EEPROM contents.

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

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_rgwEepromTypeToSizeInWords:
	dw		(2<<10) / 2		; EEPROM_TYPE.2816_2kiB
	dw		(8<<10) / 2
	dw		(8<<10) / 2		; EEPROM_TYPE.2864_8kiB_MOD
	dw		(32<<10) / 2
	dw		(64<<10) / 2

g_rgwEepromPageToSizeInBytes:
	dw		1				; EEPROM_PAGE.1_byte
	dw		2
	dw		4
	dw		8
	dw		16
	dw		32
	dw		64



; Section containing code
SECTION .text

;--------------------------------------------------------------------
; EEPROM_GetSmallestEepromSizeInWordsToCXforImageWithWordSizeInAX
;	Parameters:
;		AX:		Image size in WORDs
;	Returns:
;		CX:		Required EEPROM size in WORDs
;		CF:		Set if EEPROM size found
;				Cleared if no valid EEPROM found
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_GetSmallestEepromSizeInWordsToCXforImageWithWordSizeInAX:
	mov		bx, g_rgwEepromTypeToSizeInWords
	mov		cx, NUMBER_OF_EEPROM_TYPES
ALIGN JUMP_ALIGN
.CheckNextEepromSize:
	cmp		ax, [cs:bx]
	jbe		SHORT .ReturnEepromSizeInCX
	inc		bx
	inc		bx
	loop	.CheckNextEepromSize
	ret		; Return with CF cleared (none of the supported EEPROMs are large enough)
ALIGN JUMP_ALIGN
.ReturnEepromSizeInCX:
	mov		cx, [cs:bx]
	stc
	ret


;--------------------------------------------------------------------
; EEPROM_LoadXtideUniversalBiosFromRomToRamBufferAndReturnSizeInDXCX
;	Parameters:
;		Nothing
;	Returns:
;		DX:CX:	BIOS size in bytes
;	Corrupts registers:
;		AX, BX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_LoadXtideUniversalBiosFromRomToRamBufferAndReturnSizeInDXCX:
	push	es

	call	EEPROM_FindXtideUniversalBiosROMtoESDI
	call	.GetXtideUniversalBiosSizeFromEStoDXCX
	xor		si, si				; Load from beginning of ROM
	call	LoadBytesFromRomToRamBuffer

	call	.GetXtideUniversalBiosSizeFromEStoDXCX
	pop		es
	ret

;--------------------------------------------------------------------
; .GetXtideUniversalBiosSizeFromEStoDXCX
;	Parameters:
;		Nothing
;	Returns:
;		DX:CX:	Bios size in bytes
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetXtideUniversalBiosSizeFromEStoDXCX:
	xor		dx, dx
	eMOVZX	cx, [es:ROMVARS.bRomSize]
	eSHL_IM	cx, 9				; *= 512 for byte count
	ret


;--------------------------------------------------------------------
; EEPROM_LoadOldSettingsFromRomToRamBuffer
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Set if EEPROM was found
;				Cleared if EEPROM not found
;	Corrupts registers:
;		AX, BX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_LoadOldSettingsFromRomToRamBuffer:
	mov		cx, ROMVARS_size - ROMVARS.wFlags	; Number of bytes to load
	mov		si, ROMVARS.wFlags					; Offset where to start loading
	; Fall to LoadBytesFromRomToRamBuffer

;--------------------------------------------------------------------
; LoadBytesFromRomToRamBuffer
;	Parameters:
;		CX:		Number of bytes to load from ROM
;		SI:		Offset to first byte to load
;	Returns:
;		CF:		Set if EEPROM was found
;				Cleared if EEPROM not found
;	Corrupts registers:
;		AX, BX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
LoadBytesFromRomToRamBuffer:
	push	es
	push	ds

	call	EEPROM_FindXtideUniversalBiosROMtoESDI
	jnc		SHORT .XtideUniversalBiosNotFound
	push	es
	pop		ds											; DS:SI points to ROM

	call	Buffers_GetFileBufferToESDI
	mov		di, si										; ES:DI points to RAM buffer

	cld
	call	Memory_CopyCXbytesFromDSSItoESDI
	stc

.XtideUniversalBiosNotFound:
	pop		ds
	pop		es
	ret


;--------------------------------------------------------------------
; EEPROM_FindXtideUniversalBiosROMtoESDI
;	Parameters:
;		Nothing
;	Returns:
;		ES:DI:	EEPROM segment
;		CF:		Set if EEPROM was found
;				Cleared if EEPROM not found
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_FindXtideUniversalBiosROMtoESDI:
	push	si
	push	cx

	xor		di, di					; Zero DI (offset)
	mov		bx, 0C000h				; First possible ROM segment
ALIGN JUMP_ALIGN
.SegmentLoop:
	mov		es, bx					; Possible ROM segment to ES
	call	Buffers_IsXtideUniversalBiosSignatureInESDI
	je		SHORT .RomFound
	add		bh, 2					; Increment by 8kB
	jnc		SHORT .SegmentLoop		; Loop until segment overflows
	clc
	jmp		SHORT .ReturnWithoutUpdatingCF
ALIGN JUMP_ALIGN
.RomFound:
	stc
.ReturnWithoutUpdatingCF:
	pop		cx
	pop		si
	ret


;--------------------------------------------------------------------
; EEPROM_LoadFromRomToRamComparisonBuffer
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_LoadFromRomToRamComparisonBuffer:
	push	es
	push	ds

	mov		ds, [cs:g_cfgVars+CFGVARS.wEepromSegment]
	xor		si, si
	call	Buffers_GetFlashComparisonBufferToESDI
	eMOVZX	bx, [cs:g_cfgVars+CFGVARS.bEepromType]
	mov		cx, [cs:bx+g_rgwEepromTypeToSizeInWords]
	cld
	rep movsw

	pop		ds
	pop		es
	ret
