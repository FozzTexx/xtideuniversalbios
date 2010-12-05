; File name		:	Dialogs.asm
; Project name	:	XTIDE Univeral BIOS Configurator v2
; Created date	:	10.10.2010
; Last update	:	2.12.2010
; Author		:	Tomi Tilli
; Description	:	Functions for displaying dialogs.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Dialogs_DisplayHelpFromCSDXwithTitleInCSDI
;	Parameters:
;		CS:DX:	Ptr to help string to display
;		CS:DI:	Ptr to title string for help dialog
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialogs_DisplayHelpFromCSDXwithTitleInCSDI:
	push	ds
	push	si
	push	di
	push	cx

	mov		cx, DIALOG_INPUT_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	InitializeDialogInputFromDSSI
	mov		[si+DIALOG_INPUT.fszTitle], di
	jmp		SHORT DisplayMessageDialogWithMessageInCSDXandDialogInputInDSSI

;--------------------------------------------------------------------
; Dialogs_DisplayNotificationFromCSDX
; Dialogs_DisplayErrorFromCSDX
;	Parameters:
;		CS:DX:	Ptr to notification string to display
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialogs_DisplayNotificationFromCSDX:
	push	ds
	push	si
	push	di
	push	cx

	mov		cx, DIALOG_INPUT_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	InitializeDialogInputFromDSSI
	mov		WORD [si+DIALOG_INPUT.fszTitle], g_szNotificationDialog
	jmp		SHORT DisplayMessageDialogWithMessageInCSDXandDialogInputInDSSI

ALIGN JUMP_ALIGN
Dialogs_DisplayErrorFromCSDX:
	push	ds
	push	si
	push	di
	push	cx

	mov		cx, DIALOG_INPUT_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	mov		WORD [si+DIALOG_INPUT.fszTitle], g_szErrorDialog
ALIGN JUMP_ALIGN
DisplayMessageDialogWithMessageInCSDXandDialogInputInDSSI:
	call	InitializeDialogInputFromDSSI
	mov		[si+DIALOG_INPUT.fszItems], dx
	CALL_MENU_LIBRARY DisplayMessageWithInputInDSSI

	add		sp, BYTE DIALOG_INPUT_size
	pop		cx
	pop		di
	pop		si
	pop		ds
	ret


;--------------------------------------------------------------------
; Dialogs_DisplayFileDialogWithDialogIoInDSSI
;	Parameters:
;		DS:SI:	Ptr to FILE_DIALOG_IO
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialogs_DisplayFileDialogWithDialogIoInDSSI:
	push	es

	call	Buffers_GetFileDialogItemBufferToESDI
	mov		WORD [si+FILE_DIALOG_IO.fszTitle], g_szDlgFileTitle
	mov		[si+FILE_DIALOG_IO.fszTitle+2], cs
	mov		[si+FILE_DIALOG_IO.fszItemBuffer], di
	mov		[si+FILE_DIALOG_IO.fszItemBuffer+2], es
	mov		BYTE [si+FILE_DIALOG_IO.bDialogFlags], FLG_FILEDIALOG_DRIVES
	mov		BYTE [si+FILE_DIALOG_IO.bFileAttributes], FLG_FILEATTR_DIRECTORY | FLG_FILEATTR_ARCHIVE
	mov		WORD [si+FILE_DIALOG_IO.fpFileFilterString], g_szDlgFileFilter
	mov		[si+FILE_DIALOG_IO.fpFileFilterString+2], cs
	CALL_MENU_LIBRARY GetFileNameWithIoInDSSI

	pop		es
	ret


;--------------------------------------------------------------------
; Dialogs_DisplayQuitDialog
; Dialogs_DisplaySaveChangesDialog
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		ZF:		Set if user wants to do the action
;				Cleared if user wants to cancel
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialogs_DisplayQuitDialog:
	push	ds

	mov		cx, DIALOG_INPUT_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	InitializeDialogInputFromDSSI
	mov		WORD [si+DIALOG_INPUT.fszTitle], g_szDlgExitToDos
	mov		WORD [si+DIALOG_INPUT.fszItems], g_szMultichoiseBooleanFlag
	CALL_MENU_LIBRARY GetSelectionToAXwithInputInDSSI
	add		sp, BYTE DIALOG_INPUT_size
	cmp		ax, BYTE 1		; 1 = YES

	pop		ds
	ret


ALIGN JUMP_ALIGN
Dialogs_DisplaySaveChangesDialog:
	push	ds

	mov		cx, DIALOG_INPUT_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	InitializeDialogInputFromDSSI
	mov		WORD [si+DIALOG_INPUT.fszTitle], g_szDlgSaveChanges
	mov		WORD [si+DIALOG_INPUT.fszItems], g_szMultichoiseBooleanFlag
	CALL_MENU_LIBRARY GetSelectionToAXwithInputInDSSI
	add		sp, BYTE DIALOG_INPUT_size
	cmp		ax, BYTE 1		; 1 = YES

	pop		ds
	ret


;--------------------------------------------------------------------
; Dialogs_DisplayProgressDialogForFlashingWithDialogIoInDSSIandFlashvarsInDSBX
;	Parameters:
;		DS:BX:	Ptr to FLASHVARS
;		DS:SI:	Ptr to PROGRESS_DIALOG_IO
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialogs_DisplayProgressDialogForFlashingWithDialogIoInDSSIandFlashvarsInDSBX:
	call	.InitializeProgressDialogIoInDSSIwithFlashvarsInDSBX
	mov		dx, ds
	mov		ax, bx
	CALL_MENU_LIBRARY StartProgressTaskWithIoInDSSIandParamInDXAX
	ret

ALIGN JUMP_ALIGN
.InitializeProgressDialogIoInDSSIwithFlashvarsInDSBX:
	call	InitializeDialogInputFromDSSI
	mov		WORD [si+DIALOG_INPUT.fszTitle], g_szEEPROM

	xor		ax, ax
	mov		[si+PROGRESS_DIALOG_IO.wCurrentProgressValue], ax
	mov		dx, [bx+FLASHVARS.wPagesToFlash]
	mov		[si+PROGRESS_DIALOG_IO.wMaxProgressValue], dx
	mov		[si+PROGRESS_DIALOG_IO.wMinProgressValue], ax
	mov		WORD [si+PROGRESS_DIALOG_IO.fnTaskWithParamInDSSI], Flash_EepromWithFlashvarsInDSSI
	mov		[si+PROGRESS_DIALOG_IO.fnTaskWithParamInDSSI+2], cs
	ret


;--------------------------------------------------------------------
; InitializeDialogInputFromDSSI
;	Parameters:
;		DS:SI:	Ptr to DIALOG_INPUT
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
InitializeDialogInputFromDSSI:
	mov		[si+DIALOG_INPUT.fszTitle+2], cs
	mov		[si+DIALOG_INPUT.fszItems+2], cs
	mov		WORD [si+DIALOG_INPUT.fszInfo], g_szGenericDialogInfo
	mov		[si+DIALOG_INPUT.fszInfo+2], cs
	ret
