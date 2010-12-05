; File name		:	BiosFile.asm
; Project name	:	XTIDE Univeral BIOS Configurator v2
; Created date	:	10.10.2010
; Last update	:	30.11.2010
; Author		:	Tomi Tilli
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

	call	.OpenFileForLoadingFromDSSIandGetSizeToCX
	jc		SHORT .DisplayErrorMessage
	call	.LoadFileWithNameInDSSIhandleInBXandSizeInCXtoRamBuffer
	jc		SHORT .DisplayErrorMessage

	mov		ax, FLG_CFGVARS_FILELOADED
	call	Buffers_NewBiosWithSizeInCXandSourceInAXhasBeenLoadedForConfiguration
	call	DisplayFileLoadedSuccesfully
	call	FileIO_CloseUsingHandleFromBX
	jmp		SHORT .Return

.DisplayErrorMessage:
	call	FileIO_CloseUsingHandleFromBX
	call	DisplayFailedToLoadFile
ALIGN JUMP_ALIGN
.Return:
	pop		ds
	ret

;--------------------------------------------------------------------
; .OpenFileForLoadingFromDSSIandGetSizeToCX
;	Parameters:
;		DS:SI:	Name of file to open
;	Returns:
;		BX:		File handle (if succesfull)
;		CX:		File size (if succesfull)
;		CF:		Clear if successfull
;				Set if error
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.OpenFileForLoadingFromDSSIandGetSizeToCX:
	mov		al, FILE_ACCESS.ReadOnly
	call	FileIO_OpenWithPathInDSSIandFileAccessInAL
	jc		SHORT .FileError
	call	FileIO_GetFileSizeToDXAXusingHandleFromBXandResetFilePosition
	jc		SHORT .FileError

	cmp		dx, BYTE 1		; File size over 65536 bytes?
	ja		SHORT .FileTooBig
	jb		SHORT .CopyFileSizeToCX
	test	ax, ax
	jnz		SHORT .FileTooBig
	dec		ax				; Prepare to load 65535 bytes
.CopyFileSizeToCX:
	xchg	cx, ax
	clc
	ret
.FileTooBig:
	call	DisplayFileTooBig
	stc
.FileError:
	ret

;--------------------------------------------------------------------
; .LoadFileWithNameInDSSIhandleInBXandSizeInCXtoRamBuffer
;	Parameters:
;		BX:		File Handle
;		CX:		File size
;		DS:SI:	File name
;	Returns:
;		CF:		Clear if successfull
;				Set if error
;	Corrupts registers:
;		AX, SI, DI, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.LoadFileWithNameInDSSIhandleInBXandSizeInCXtoRamBuffer:
	push	es

	call	Buffers_GetFileBufferToESDI
	call	Registers_ExchangeDSSIwithESDI
	call	FileIO_ReadCXbytesToDSSIusingHandleFromBX
	jnc		SHORT .StoreFileNameToCfgvarsFromESDI

	pop		es
	ret

ALIGN JUMP_ALIGN
.StoreFileNameToCfgvarsFromESDI:
	push	cx

	call	Registers_CopyESDItoDSSI	; File name in DS:SI
	push	cs
	pop		es
	mov		di, g_cfgVars+CFGVARS.szOpenedFile
	cld
	call	String_CopyDSSItoESDIandGetLengthToCX

	pop		cx
	pop		es
	clc
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

	mov		al, FILE_ACCESS.WriteOnly
	call	FileIO_OpenWithPathInDSSIandFileAccessInAL
	jc		SHORT .DisplayErrorMessage

	call	Buffers_GenerateChecksum
	call	Buffers_GetFileBufferToESDI
	call	Registers_CopyESDItoDSSI
	mov		cx, [cs:g_cfgVars+CFGVARS.wImageSizeInWords]
	shl		cx, 1
	call	FileIO_WriteCXbytesFromDSSIusingHandleFromBX
	jc		SHORT .DisplayErrorMessage

	call	Buffers_ClearUnsavedChanges
	call	DisplayFileSavedSuccesfully
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
; DisplayFileLoadedSuccesfully
; DisplayFileSavedSuccesfully
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
DisplayFileLoadedSuccesfully:
	mov		dx, g_szDlgMainLoadFile
	jmp		Dialogs_DisplayNotificationFromCSDX

ALIGN JUMP_ALIGN
DisplayFileSavedSuccesfully:
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
