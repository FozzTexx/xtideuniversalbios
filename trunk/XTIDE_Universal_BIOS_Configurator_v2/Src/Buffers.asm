; File name		:	Buffers.asm
; Project name	:	XTIDE Universal BIOS Configurator v2
; Created date	:	6.10.2010
; Last update	:	19.11.2010
; Author		:	Tomi Tilli
; Description	:	Functions for accessing file and flash buffers.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Buffers_Clear
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_Clear:
	call	Buffers_GetFileBufferToESDI
	mov		cx, ROMVARS_size
	jmp		Memory_ZeroESDIwithSizeInCX


;--------------------------------------------------------------------
; Buffers_IsXtideUniversalBiosLoaded
;	Parameters:
;		Nothing
;	Returns:
;		ZF:		Set if supported version of XTIDE Universal BIOS is loaded
;				Cleared no file or some other file is loaded
;	Corrupts registers:
;		CX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_IsXtideUniversalBiosLoaded:
	test	WORD [cs:g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_FILELOADED | FLG_CFGVARS_ROMLOADED
	jz		SHORT .NoFileOrBiosLoaded

	call	Buffers_GetFileBufferToESDI
	jmp		SHORT Buffers_IsXtideUniversalBiosSignatureInESDI
.NoFileOrBiosLoaded:
	or		cl, 1		; Clear ZF
	ret


;--------------------------------------------------------------------
; Buffers_IsXtideUniversalBiosSignatureInESDI
;	Parameters:
;		ES:DI:	Ptr to possible XTIDE Universal BIOS location
;	Returns:
;		ZF:		Set if supported version of XTIDE Universal BIOS is loaded
;				Cleared no file or some other file is loaded
;	Corrupts registers:
;		CX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_IsXtideUniversalBiosSignatureInESDI:
	push	di

	mov		si, g_szXtideUniversalBiosSignature
	add		di, BYTE ROMVARS.rgbSign
	mov		cx, XTIDE_SIGNATURE_LENGTH / 2
	cld
	eSEG_STR repe, cs, cmpsw

	pop		di
	ret


;--------------------------------------------------------------------
; Buffers_NewBiosWithSizeInCXandSourceInAXhasBeenLoadedForConfiguration
;	Parameters:
;		AX:		EEPROM source (FLG_CFGVARS_FILELOADED or FLG_CFGVARS_ROMLOADED)
;		CX:		EEPROM size in bytes
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_NewBiosWithSizeInCXandSourceInAXhasBeenLoadedForConfiguration:
	and		WORD [cs:g_cfgVars+CFGVARS.wFlags], ~(FLG_CFGVARS_FILELOADED | FLG_CFGVARS_ROMLOADED | FLG_CFGVARS_UNSAVED)
	or		WORD [cs:g_cfgVars+CFGVARS.wFlags], ax
	; Fall to .AdjustBiosImageSizeToSupportedEepromSize

;--------------------------------------------------------------------
; .AdjustBiosImageSizeInCXtoSupportedEepromSize
;	Parameters:
;		CX:		Size of loaded BIOS image
;	Returns:
;		CX:		Size of BIOS image (and EEPROM required)
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
.AdjustBiosImageSizeInCXtoSupportedEepromSize:
	mov		bx, .rgwSupportedEepromSizes
	mov		dx, NUMBER_OF_SUPPORTED_EEPROM_SIZES-1
ALIGN JUMP_ALIGN
.CheckNextEepromSize:
	cmp		cx, [cs:bx]
	je		SHORT .StoreImageSizeFromCX
	jb		SHORT .AppendZeroesToTheEndOfBuffer
	inc		bx
	inc		bx
	dec		dx
	jnz		SHORT .CheckNextEepromSize
	xor		cx, cx
	jmp		SHORT .StoreImageSizeFromCX	; 0 = 65536
ALIGN WORD_ALIGN
.rgwSupportedEepromSizes:
	dw		4<<10
	dw		8<<10
	dw		16<<10
	dw		32<<10

;--------------------------------------------------------------------
; .AppendZeroesToTheEndOfBuffer
;	Parameters:
;		CX:		Size of loaded BIOS image
;		CS:BX:	Ptr to EEPROM size
;	Returns:
;		CX:		EEPROM size
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.AppendZeroesToTheEndOfBuffer:
	push	es
	push	di

	call	Buffers_GetFileBufferToESDI
	mov		ax, [cs:bx]
	sub		ax, cx			; AX = zeroes to append
	xchg	ax, cx			; AX = BIOS image size, CX = zeroes to append
	add		di, ax
	call	Memory_ZeroESDIwithSizeInCX
	mov		cx, [cs:bx]

	pop		di
	pop		es
	; Fall to .StoreImageSizeFromCX

;--------------------------------------------------------------------
; .StoreImageSizeFromCX
;	Parameters:
;		CX:		Size of BIOS image (and EEPROM required)
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.StoreImageSizeFromCX:
	mov		[cs:g_cfgVars+CFGVARS.wImageSize], cx
	ret


;--------------------------------------------------------------------
; Buffers_SetUnsavedChanges
; Buffers_ClearUnsavedChanges
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_SetUnsavedChanges:
	or		WORD [g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_UNSAVED
	ret

ALIGN JUMP_ALIGN
Buffers_ClearUnsavedChanges:
	and		WORD [g_cfgVars+CFGVARS.wFlags], ~FLG_CFGVARS_UNSAVED
	ret


;--------------------------------------------------------------------
; Buffers_SaveChangesIfFileLoaded
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_SaveChangesIfFileLoaded:
	mov		ax, [cs:g_cfgVars+CFGVARS.wFlags]
	and		ax, BYTE (FLG_CFGVARS_FILELOADED | FLG_CFGVARS_UNSAVED)
	cmp		ax, BYTE (FLG_CFGVARS_FILELOADED | FLG_CFGVARS_UNSAVED)
	jne		SHORT .NothingToSave
	call	Dialogs_DisplaySaveChangesDialog
	jnz		SHORT .NothingToSave
	jmp		BiosFile_SaveUnsavedChanges
ALIGN JUMP_ALIGN
.NothingToSave:
	ret


;--------------------------------------------------------------------
; Buffers_GenerateChecksum
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_GenerateChecksum:
	push	es

	call	Buffers_GetFileBufferToESDI
	mov		cx, [cs:g_cfgVars+CFGVARS.wImageSize]
	dec		cx				; Leave space for checksum byte
	xor		ax, ax
ALIGN JUMP_ALIGN
.SumNextByte:
	add		al, [es:di]
	inc		di
	loop	.SumNextByte
	neg		al
	mov		[es:di], al

	pop		es
	ret


;--------------------------------------------------------------------
; Buffers_GetRomvarsFlagsToAX
;	Parameters:
;		Nothing
;	Returns:
;		AX:		ROMVARS.wFlags
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_GetRomvarsFlagsToAX:
	mov		bx, ROMVARS.wFlags
	; Fall to Buffers_GetRomvarsValueToAXfromOffsetInBX

;--------------------------------------------------------------------
; Buffers_GetRomvarsValueToAXfromOffsetInBX
;	Parameters:
;		BX:		ROMVARS offset
;	Returns:
;		AX:		Value
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_GetRomvarsValueToAXfromOffsetInBX:
	push	es
	push	di
	call	Buffers_GetFileBufferToESDI
	mov		ax, [es:bx+di]
	pop		di
	pop		es
	ret


;--------------------------------------------------------------------
; Buffers_GetFileBufferToESDI
; Buffers_GetFileDialogItemBufferToESDI
;	Parameters:
;		Nothing
;	Returns:
;		ES:DI:	Ptr to file buffer
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_GetFileDialogItemBufferToESDI:
	call	Buffers_GetFileBufferToESDI
	push	di
	mov		di, es
	add		di, 1000h		; Third 64k page
	mov		es, di
	pop		di
	ret
Buffers_GetFileBufferToESDI:
	mov		di, cs
	add		di, 1000h		; Change to next 64k page
	mov		es, di
	xor		di, di			; Ptr now in ES:DI
	ret
