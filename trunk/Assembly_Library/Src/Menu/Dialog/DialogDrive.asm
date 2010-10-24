; File name		:	DialogDrive.asm
; Project name	:	Assembly Library
; Created date	:	22.10.2010
; Last update	:	23.10.2010
; Author		:	Tomi Tilli
; Description	:	Displays drive dialog.


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DialogDrive_GetDriveWithIoInDSSI
;	Parameters:
;		DS:SI:	Ptr to DRIVE_DIALOG_IO
;		SS:BP:	Ptr to parent MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DialogDrive_GetDriveWithIoInDSSI:
	mov		bx, DriveEventHandler
	mov		BYTE [si+DRIVE_DIALOG_IO.bUserCancellation], TRUE
	jmp		Dialog_DisplayWithDialogInputInDSSIandHandlerInBX


;--------------------------------------------------------------------
; DriveEventHandler
;	Common parameters for all events:
;		BX:			Menu event (anything from MENUEVENT struct)
;		SS:BP:		Ptr to DIALOG
;	Common return values for all events:
;		CF:			Set if event processed
;					Cleared if event not processed
;	Corrupts registers:
;		All
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DriveEventHandler:
	jmp		[cs:bx+.rgfnEventHandlers]


ALIGN JUMP_ALIGN
.InitializeMenuinitFromDSSI:
	xor		ax, ax
	call	Dialog_EventInitializeMenuinitFromDSSIforSingleItemWithHighlightedItemInAX
	call	Drive_GetFlagsForAvailableDrivesToDXAX
	mov		[bp+MENU.dwUserData], ax
	mov		[bp+MENU.dwUserData+2], dx

	call	Bit_GetSetCountToCXfromDXAX
	mov		[bp+MENUINIT.wItems], cx

	dec		cx			; Items initialized to one. Ignore it.
	add		cl, [bp+MENUINIT.bHeight]
	CALL_DISPLAY_LIBRARY GetColumnsToALandRowsToAH
	MIN_U	cl, ah
	mov		[bp+MENUINIT.bHeight], cl
	ret


ALIGN JUMP_ALIGN
.ItemSelectedFromCX:
	call	ConvertDriveLetterToBLfromItemIndexInCX
	lds		si, [bp+DIALOG.fpDialogIO]
	mov		BYTE [si+DRIVE_DIALOG_IO.bUserCancellation], FALSE
	mov		[si+DRIVE_DIALOG_IO.cReturnDriveLetter], bl
	sub		bl, 'A'
	mov		[si+DRIVE_DIALOG_IO.bReturnDriveNumber], bl
	jmp		MenuInit_CloseMenuWindow


ALIGN JUMP_ALIGN
.RefreshItemFromCX:
	push	bp

	call	ConvertDriveLetterToBLfromItemIndexInCX
	mov		bp, sp
	push	bx
	mov		si, g_szDriveFormat
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI

	pop		bp
	stc
	ret


.rgfnEventHandlers:
istruc MENUEVENT
	at	MENUEVENT.InitializeMenuinitFromDSSI,	dw	.InitializeMenuinitFromDSSI
	at	MENUEVENT.ExitMenu,						dw	Dialog_EventNotHandled
	at	MENUEVENT.IdleProcessing,				dw	Dialog_EventNotHandled
	at	MENUEVENT.ItemHighlightedFromCX,		dw	Dialog_EventNotHandled
	at	MENUEVENT.ItemSelectedFromCX,			dw	.ItemSelectedFromCX
	at	MENUEVENT.KeyStrokeInAX,				dw	Dialog_EventNotHandled
	at	MENUEVENT.RefreshTitle,					dw	Dialog_EventRefreshTitle
	at	MENUEVENT.RefreshInformation,			dw	Dialog_EventRefreshInformation
	at	MENUEVENT.RefreshItemFromCX,			dw	.RefreshItemFromCX
iend


;--------------------------------------------------------------------
; ConvertDriveLetterToBLfromItemIndexInCX
;	Parameters:
;		CX:		Item index
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		BL:		Drive letter
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConvertDriveLetterToBLfromItemIndexInCX:
	inc		cx			; Index to count
	mov		bl, 'A'-1
	mov		ax, [bp+MENU.dwUserData]
	mov		dx, [bp+MENU.dwUserData+2]
ALIGN JUMP_ALIGN
.CheckNextBit:
	inc		bx			; Increment drive letter
	shr		dx, 1
	rcr		ax, 1
	jnc		SHORT .CheckNextBit
	loop	.CheckNextBit
	ret
