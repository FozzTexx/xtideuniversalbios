; Project name	:	XTIDE Univeral BIOS Configurator
; Description	:	Functions for managing EEPROM contents.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Loads XTIDE Universal BIOS from ROM to RAM to be configured.
;
; EEPROM_LoadBiosFromROM
;	Parameters:
;		Nothing
;	Returns:
;		CX:		BIOS size in bytes
;	Corrupts registers:
;		AX, BX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_LoadBiosFromROM:
	push	si
	call	EEPROM_FindXtideUniversalBiosROM
	xor		si, si									; Load from beginning of ROM
	eMOVZX	cx, [es:ROMVARS.bRomSize]
	eSHL_IM	cx, 9									; *= 512 for byte count
	call	EEPROM_LoadBytesFromROM
	pop		si
	ret


;--------------------------------------------------------------------
; Loads old XTIDE Universal BIOS settings from ROM to RAM.
;
; EEPROM_LoadSettingsFromRomToRam
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_LoadSettingsFromRomToRam:
	mov		cx, ROMVARS_size - ROMVARS.wFlags	; Number of bytes to load
	mov		si, ROMVARS.wFlags					; Offset where to start loading
	; Fall to EEPROM_LoadBytesFromROM

;--------------------------------------------------------------------
; Loads wanted number of bytes from XTIDE Universal BIOS ROM.
;
; EEPROM_LoadBytesFromROM
;	Parameters:
;		CX:		Number of bytes to load from beginning of ROM
;		SI:		Offset to first byte
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_LoadBytesFromROM:
	push	ds
	push	di
	push	cx

	call	EEPROM_FindXtideUniversalBiosROM
	push	es
	pop		ds											; DS:SI points to ROM
	push	cs
	pop		es
	lea		di, [si+g_cfgVars+CFGVARS.rgbEepromBuffers]	; ES:DI points to RAM buffer
	shr		cx, 1										; Byte count to word count
	cld													; MOVSW to increment SI and DI
	rep movsw											; Read from ROM to RAM

	pop		cx
	pop		di
	pop		ds
	ret


;--------------------------------------------------------------------
; Finds EEPROM using known signature.
;
; EEPROM_FindXtideUniversalBiosROM
;	Parameters:
;		Nothing
;	Returns:
;		ES:		EEPROM segment
;		CF:		Set if EEPROM was found
;				Cleared if EEPROM not found
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_FindXtideUniversalBiosROM:
	push	di
	xor		di, di					; Zero DI
	mov		bx, 0C000h				; First possible ROM segment
ALIGN JUMP_ALIGN
.SegmentLoop:
	mov		es, bx					; Possible ROM segment to ES
	call	EEPROM_IsXtideUniversalBiosSignaturePresent
	je		SHORT .RomFound
	add		bx, 200h				; Increment by 8kB
	jnc		SHORT .SegmentLoop		; Loop until segment overflows
	pop		di
	clc
	ret
ALIGN JUMP_ALIGN
.RomFound:
	pop		di
	stc
	ret


;--------------------------------------------------------------------
; Checks if XTIDE Universal BIOS is loaded to be configured.
;
; EEPROM_IsXtideUniversalBiosLoaded
;	Parameters:
;		Nothing
;	Returns:
;		ZF:		Set if signature found
;				Cleared if signature not present
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_IsXtideUniversalBiosLoaded:
	push	es
	push	di

	push	cs
	pop		es
	mov		di, g_cfgVars+CFGVARS.rgbEepromBuffers
	call	EEPROM_IsXtideUniversalBiosSignaturePresent

	pop		di
	pop		es
	ret


;--------------------------------------------------------------------
; Checks if ROM contains Xtide Universal BIOS signature.
;
; EEPROM_IsXtideUniversalBiosSignaturePresent
;	Parameters:
;		ES:DI:	Ptr to ROM contents
;	Returns:
;		ZF:		Set if signature found
;				Cleared if signature not present
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_IsXtideUniversalBiosSignaturePresent:
	push	ds
	push	di
	push	si
	push	cx

	push	cs
	pop		ds
	mov		si, g_szSignature			; DS:SI points to known signature string
	add		di, BYTE ROMVARS.rgbSign	; ES:DI points to possible ROM signature
	mov		cx, LEN_SIGNATURE/2			; Signature string length in words
	cld									; CMPSW to increment DI and SI
	repe cmpsw

	pop		cx
	pop		si
	pop		di
	pop		ds
	ret


;--------------------------------------------------------------------
; Called when new BIOS has been loaded to be flashed.
;
; EEPROM_NewBiosLoadedFromFileOrROM
;	Parameters:
;		AX:		EEPROM source (FLG_CFGVARS_FILELOADED or FLG_CFGVARS_ROMLOADED)
;		CX:		EEPROM size in bytes
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_NewBiosLoadedFromFileOrROM:
	and		WORD [cs:g_cfgVars+CFGVARS.wFlags], ~(FLG_CFGVARS_FILELOADED | FLG_CFGVARS_ROMLOADED | FLG_CFGVARS_UNSAVED)
	or		WORD [cs:g_cfgVars+CFGVARS.wFlags], ax
	mov		WORD [cs:g_cfgVars+CFGVARS.wEepromSize], cx
	ret


;--------------------------------------------------------------------
; Generated checksum byte to the end of BIOS image buffer.
;
; EEPROM_GenerateChecksum
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_GenerateChecksum:
	xor		ax, ax
	mov		bx, g_cfgVars+CFGVARS.rgbEepromBuffers
	mov		cx, [cs:g_cfgVars+CFGVARS.wEepromSize]
	dec		cx
ALIGN JUMP_ALIGN
.ByteLoop:
	add		al, [cs:bx]
	inc		bx
	loop	.ByteLoop
	neg		al
	mov		[cs:bx], al
	ret


;--------------------------------------------------------------------
; Returns pointer source data to be flashed to EEPROM.
;
; EEPROM_GetSourceBufferPointerToDSSI
;	Parameters:
;		Nothing
;	Returns:
;		DS:SI:		Ptr to source buffer
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_GetSourceBufferPointerToDSSI:
	push	cs
	pop		ds
	mov		si, g_cfgVars+CFGVARS.rgbEepromBuffers
	ret


;--------------------------------------------------------------------
; Returns pointer to comparison buffer for old EEPROM data.
;
; EEPROM_GetComparisonBufferPointerToDSBX
;	Parameters:
;		Nothing
;	Returns:
;		DS:BX:		Ptr to verify buffer
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_GetComparisonBufferPointerToDSBX:
	push	cs
	pop		ds
	mov		bx, [cs:g_cfgVars+CFGVARS.wEepromSize]
	add		bx, g_cfgVars+CFGVARS.rgbEepromBuffers
	ret


;--------------------------------------------------------------------
; Returns pointer to EEPROM where to flash.
;
; EEPROM_GetEepromPointerToESDI
;	Parameters:
;		Nothing
;	Returns:
;		ES:DI:		Ptr to EEPROM
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EEPROM_GetEepromPointerToESDI:
	mov		es, [cs:g_cfgVars+CFGVARS.wEepromSegment]
	xor		di, di
	ret
