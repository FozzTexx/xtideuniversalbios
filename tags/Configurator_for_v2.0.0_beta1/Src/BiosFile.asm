; Project name	:	XTIDE Univeral BIOS Configurator v2
; Description	:	Functions for loading and saving BIOS image file.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; BiosFile_LoadFileFromDSSItoRamBuffer
;	Parameters:
;		DS:SI:	Name of file to open
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BiosFile_LoadFileFromDSSItoRamBuffer:
	push	ds

	call	.OpenFileForLoadingFromDSSIandGetSizeToDXCX
	jc		SHORT .DisplayErrorMessage
	call	.LoadFileWithNameInDSSIhandleInBXandSizeInDXCXtoRamBuffer
	jc		SHORT .DisplayErrorMessage

	mov		ax, FLG_CFGVARS_FILELOADED
	call	Buffers_NewBiosWithSizeInDXCXandSourceInAXhasBeenLoadedForConfiguration
	call	FileIO_CloseUsingHandleFromBX
	call	DisplayFileLoadedSuccessfully
	jmp		SHORT .Return

.DisplayErrorMessage:
	call	FileIO_CloseUsingHandleFromBX
	call	DisplayFailedToLoadFile
ALIGN JUMP_ALIGN
.Return:
	pop		ds
	ret

;--------------------------------------------------------------------
; .OpenFileForLoadingFromDSSIandGetSizeInBytesToDXCX
;	Parameters:
;		DS:SI:	Name of file to open
;	Returns:
;		BX:		File handle (if successful)
;		DX:CX:	File size (if successful)
;		CF:		Clear if successful
;				Set if error
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.OpenFileForLoadingFromDSSIandGetSizeToDXCX:
	mov		al, FILE_ACCESS.ReadOnly
	call	FileIO_OpenWithPathInDSSIandFileAccessInAL
	jc		SHORT .FileError
	call	FileIO_GetFileSizeToDXAXusingHandleFromBXandResetFilePosition
	jc		SHORT .FileError

	cmp		dx, MAX_EEPROM_SIZE_IN_BYTES >> 16
	ja		SHORT .FileTooBig
	jb		SHORT .FileNotTooBig
	cmp		ax, MAX_EEPROM_SIZE_IN_BYTES & 0FFFFh
	ja		SHORT .FileTooBig
.FileNotTooBig:
	xchg	cx, ax
	clc
	ret
.FileTooBig:
	call	DisplayFileTooBig
	stc
.FileError:
	ret

;--------------------------------------------------------------------
; .LoadFileWithNameInDSSIhandleInBXandSizeInDXCXtoRamBuffer
;	Parameters:
;		BX:		File Handle
;		DX:CX:	File size
;		DS:SI:	File name
;	Returns:
;		CF:		Clear if successful
;				Set if error
;	Corrupts registers:
;		AX, SI, DI, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.LoadFileWithNameInDSSIhandleInBXandSizeInDXCXtoRamBuffer:
	push	es

	call	Buffers_GetFileBufferToESDI
	call	Registers_ExchangeDSSIwithESDI
	call	FileIO_ReadDXCXbytesToDSSIusingHandleFromBX
	jc		SHORT .ReturnError

	; Store filename to Cfgvars from ESDI
	push	cx

	call	Registers_CopyESDItoDSSI	; File name in DS:SI
	push	cs
	pop		es
	mov		di, g_cfgVars+CFGVARS.szOpenedFile
	cld
	call	String_CopyDSSItoESDIandGetLengthToCX
	clc

	pop		cx
ALIGN JUMP_ALIGN
.ReturnError:
	pop		es
	ret


;--------------------------------------------------------------------
; BiosFile_SaveUnsavedChanges
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BiosFile_SaveUnsavedChanges:
	push	ds

	push	cs
	pop		ds
	mov		si, g_cfgVars+CFGVARS.szOpenedFile
	call	BiosFile_SaveRamBufferToFileInDSSI

	pop		ds
	ret


;--------------------------------------------------------------------
; BiosFile_SaveRamBufferToFileInDSSI
;	Parameters:
;		DS:SI:	Name of file to save
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BiosFile_SaveRamBufferToFileInDSSI:
	push	es
	push	ds

	call	Buffers_GenerateChecksum
	call	Buffers_GetFileBufferToESDI
	mov		ax, [cs:g_cfgVars+CFGVARS.wImageSizeInWords]
	call	EEPROM_GetSmallestEepromSizeInWordsToCXforImageWithWordSizeInAX
	xor		dx, dx
	shl		cx, 1
	rcl		dx, 1			; WORDs to BYTEs

	mov		al, FILE_ACCESS.WriteOnly
	call	FileIO_OpenWithPathInDSSIandFileAccessInAL
	jc		SHORT .DisplayErrorMessage

	call	Registers_CopyESDItoDSSI
	call	FileIO_WriteDXCXbytesFromDSSIusingHandleFromBX
	jc		SHORT .DisplayErrorMessage

	call	FileIO_CloseUsingHandleFromBX
	call	Buffers_ClearUnsavedChanges
	call	DisplayFileSavedSuccessfully
	jmp		SHORT .Return

.DisplayErrorMessage:
	call	FileIO_CloseUsingHandleFromBX
	call	DisplayFailedToSaveFile
ALIGN JUMP_ALIGN
.Return:
	pop		ds
	pop		es
	ret


;--------------------------------------------------------------------
; DisplayFileLoadedSuccessfully
; DisplayFileSavedSuccessfully
; DisplayFailedToLoadFile
; DisplayFailedToSaveFile
; DisplayFileTooBig
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayFileLoadedSuccessfully:
	mov		dx, g_szDlgMainLoadFile
	jmp		Dialogs_DisplayNotificationFromCSDX

ALIGN JUMP_ALIGN
DisplayFileSavedSuccessfully:
	mov		dx, g_szDlgMainSaveFile
	jmp		Dialogs_DisplayNotificationFromCSDX

DisplayFailedToLoadFile:
	mov		dx, g_szDlgMainLoadErr
	jmp		Dialogs_DisplayErrorFromCSDX

DisplayFailedToSaveFile:
	mov		dx, g_szDlgMainSaveErr
	jmp		Dialogs_DisplayErrorFromCSDX

DisplayFileTooBig:
	mov		dx, g_szDlgMainFileTooBig
	jmp		Dialogs_DisplayErrorFromCSDX
