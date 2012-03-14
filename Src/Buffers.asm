; Project name	:	XTIDE Universal BIOS Configurator v2
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
; Buffers_NewBiosWithSizeInDXCXandSourceInAXhasBeenLoadedForConfiguration
;	Parameters:
;		AX:		EEPROM source (FLG_CFGVARS_FILELOADED or FLG_CFGVARS_ROMLOADED)
;		DX:CX:	EEPROM size in bytes
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_NewBiosWithSizeInDXCXandSourceInAXhasBeenLoadedForConfiguration:
	and		WORD [cs:g_cfgVars+CFGVARS.wFlags], ~(FLG_CFGVARS_FILELOADED | FLG_CFGVARS_ROMLOADED | FLG_CFGVARS_UNSAVED)
	or		WORD [cs:g_cfgVars+CFGVARS.wFlags], ax
	shr		dx, 1
	rcr		cx, 1
	adc		cx, BYTE 0		; Round up to next WORD
	mov		[cs:g_cfgVars+CFGVARS.wImageSizeInWords], cx
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
; Buffers_AppendZeroesIfNeeded
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_AppendZeroesIfNeeded:
	push	es

	eMOVZX	di, [cs:g_cfgVars+CFGVARS.bEepromType]
	mov		cx, [cs:di+g_rgwEepromTypeToSizeInWords]
	sub		cx, [cs:g_cfgVars+CFGVARS.wImageSizeInWords]	; CX = WORDs to append
	jle		SHORT .NoNeedToAppendZeroes

	call	Buffers_GetFileBufferToESDI
	mov		ax, [cs:g_cfgVars+CFGVARS.wImageSizeInWords]
	shl		ax, 1
	add		di, ax			; ES:DI now point first unused image byte
	xor		ax, ax
	cld
	rep stosw
ALIGN JUMP_ALIGN
.NoNeedToAppendZeroes:
	pop		es
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
	mov		ax, [cs:g_cfgVars+CFGVARS.wImageSizeInWords]
	call	EEPROM_GetSmallestEepromSizeInWordsToCXforImageWithWordSizeInAX
	shl		cx, 1			; Words to bytes
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
; Buffers_GetIdeControllerCountToCX
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		CX:		Number of IDE controllers to configure
;		ES:DI:	Ptr to file buffer
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_GetIdeControllerCountToCX:
	call	Buffers_GetFileBufferToESDI
	mov		al, [es:di+ROMVARS.bIdeCnt]

	; Limit controller count for lite mode
	test	BYTE [es:di+ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jnz		SHORT .ReturnControllerCountInCX
	MIN_U	al, MAX_LITE_MODE_CONTROLLERS

.ReturnControllerCountInCX:
	cbw		; A maximum of 127 controllers should be sufficient
	xchg	cx, ax
	ret


;--------------------------------------------------------------------
; Buffers_GetFileBufferToESDI
; Buffers_GetFlashComparisonBufferToESDI
; Buffers_GetFileDialogItemBufferToESDI
;	Parameters:
;		Nothing
;	Returns:
;		ES:DI:	Ptr to file buffer
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Buffers_GetFlashComparisonBufferToESDI:
Buffers_GetFileDialogItemBufferToESDI:
	call	Buffers_GetFileBufferToESDI
	push	di
	mov		di, es
	add		di, 1000h		; Third 64k page
	mov		es, di
	pop		di
	ret
ALIGN JUMP_ALIGN
Buffers_GetFileBufferToESDI:
	mov		di, cs
	add		di, 1000h		; Change to next 64k page
	mov		es, di
	xor		di, di			; Ptr now in ES:DI
	ret
