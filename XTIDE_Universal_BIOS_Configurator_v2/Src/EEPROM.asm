; File name		:	EEPROM.asm
; Project name	:	XTIDE Univeral BIOS Configurator v2
; Created date	:	19.4.2010
; Last update	:	10.10.2010
; Author		:	Tomi Tilli
; Description	:	Functions for managing EEPROM contents.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; EEPROM_LoadXtideUniversalBiosFromRomToRamBuffer
;	Parameters:
;		Nothing
;	Returns:
;		CX:		BIOS size in bytes
;	Corrupts registers:
;		AX, BX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_LoadXtideUniversalBiosFromRomToRamBuffer:
	push	es

	call	EEPROM_FindXtideUniversalBiosROMtoESDI
	call	.GetXtideUniversalBiosSizeFromEStoCX
	xor		si, si				; Load from beginning of ROM
	call	LoadBytesFromRomToRamBuffer

	call	.GetXtideUniversalBiosSizeFromEStoCX
	pop		es
	ret

;--------------------------------------------------------------------
; .GetXtideUniversalBiosSizeFromEStoCX
;	Parameters:
;		Nothing
;	Returns:
;		AX:		Bios size in bytes
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetXtideUniversalBiosSizeFromEStoCX:
	eMOVZX	cx, BYTE [es:ROMVARS.bRomSize]
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
	add		bx, 200h				; Increment by 8kB
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
; EEPROM_GetPointerForFlashingToESDI
;	Parameters:
;		Nothing
;	Returns:
;		ES:DI:	Ptr to EEPROM to be flashed
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_GetPointerForFlashingToESDI:
	mov		es, [cs:g_cfgVars+CFGVARS.wEepromSegment]
	xor		di, di
	ret
