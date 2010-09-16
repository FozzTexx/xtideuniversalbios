; File name		:	DialogString.asm
; Project name	:	Assembly Library
; Created date	:	12.8.2010
; Last update	:	7.9.2010
; Author		:	Tomi Tilli
; Description	:	Displays word input dialog.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DialogString_GetStringWithIoInDSSI
;	Parameters:
;		DS:SI:	Ptr to STRING_DIALOG_IO
;		SS:BP:	Ptr to parent MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DialogString_GetStringWithIoInDSSI:
	mov		bx, StringEventHandler
	mov		BYTE [si+STRING_DIALOG_IO.bUserCancellation], TRUE
	jmp		Dialog_DisplayWithDialogInputInDSSIandHandlerInBX


;--------------------------------------------------------------------
; StringEventHandler
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
StringEventHandler:
	jmp		[cs:bx+.rgfnEventHandlers]


ALIGN JUMP_ALIGN
.IdleProcessing:
	xor		ax, ax						; Item 0 is used as input line
	call	MenuText_AdjustDisplayContextForDrawingItemFromAX
	call	GetStringFromUser
	call	MenuInit_CloseMenuWindow
	stc
	ret


ALIGN WORD_ALIGN
.rgfnEventHandlers:
istruc MENUEVENT
	at	MENUEVENT.InitializeMenuinitFromDSSI,	dw	Dialog_EventInitializeMenuinitFromDSSIforSingleItem
	at	MENUEVENT.ExitMenu,						dw	Dialog_EventNotHandled
	at	MENUEVENT.IdleProcessing,				dw	.IdleProcessing
	at	MENUEVENT.ItemHighlightedFromCX,		dw	Dialog_EventNotHandled
	at	MENUEVENT.ItemSelectedFromCX,			dw	Dialog_EventNotHandled
	at	MENUEVENT.KeyStrokeInAX,				dw	Dialog_EventNotHandled
	at	MENUEVENT.RefreshTitle,					dw	Dialog_EventRefreshTitle
	at	MENUEVENT.RefreshInformation,			dw	Dialog_EventRefreshInformation
	at	MENUEVENT.RefreshItemFromCX,			dw	Dialog_EventNotHandled
iend


;--------------------------------------------------------------------
; GetStringFromUser
;	Parameters
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing (User input stored to STRING_DIALOG_IO)
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetStringFromUser:
	lds		si, [bp+DIALOG.fpDialogIO]
	mov		cx, [si+STRING_DIALOG_IO.wBufferSize]
	les		di, [si+STRING_DIALOG_IO.fpReturnBuffer]
	call	.GetCharacterFilterFunctionToDX

	call	Keyboard_ReadUserInputtedStringToESDIWhilePrinting
	jz		SHORT .UserCancellation

	mov		BYTE [si+STRING_DIALOG_IO.bUserCancellation], FALSE
	mov		[si+STRING_DIALOG_IO.wReturnLength], cx
.UserCancellation:
	ret

;--------------------------------------------------------------------
; .GetCharacterFilterFunctionToDX
;	Parameters
;		DS:SI:	Ptr to STRING_DIALOG_IO
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		CS:DX:	Ptr to character filter function
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetCharacterFilterFunctionToDX:
	mov		dx, [si+STRING_DIALOG_IO.fnCharFilter]
	test	dx, dx
	jnz		SHORT .ReturnFilterFunctionInDX
	mov		dx, Char_CharIsValid
ALIGN JUMP_ALIGN, ret
.ReturnFilterFunctionInDX:
	ret
