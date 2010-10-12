; File name		:	DialogWord.asm
; Project name	:	Assembly Library
; Created date	:	10.8.2010
; Last update	:	12.10.2010
; Author		:	Tomi Tilli
; Description	:	Displays word input dialog.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DialogWord_GetWordWithIoInDSSI
;	Parameters:
;		DS:SI:	Ptr to WORD_DIALOG_IO
;		SS:BP:	Ptr to parent MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DialogWord_GetWordWithIoInDSSI:
	mov		bx, WordEventHandler
	mov		BYTE [si+WORD_DIALOG_IO.bUserCancellation], TRUE
	jmp		Dialog_DisplayWithDialogInputInDSSIandHandlerInBX


;--------------------------------------------------------------------
; WordEventHandler
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
WordEventHandler:
	jmp		[cs:bx+.rgfnEventHandlers]


ALIGN JUMP_ALIGN
.InitializeMenuinitFromDSSI:
	xor		ax, ax
	jmp		Dialog_EventInitializeMenuinitFromDSSIforSingleItemWithHighlightedItemInAX


ALIGN JUMP_ALIGN
.IdleProcessing:
	xor		cx, cx						; Item 0 is used as input line
	call	MenuText_AdjustDisplayContextForDrawingItemFromCX
	call	GetWordFromUser
	call	MenuInit_CloseMenuWindow
	stc
	ret


ALIGN WORD_ALIGN
.rgfnEventHandlers:
istruc MENUEVENT
	at	MENUEVENT.InitializeMenuinitFromDSSI,	dw	.InitializeMenuinitFromDSSI
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
; GetWordFromUser
;	Parameters
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing (User input stored to WORD_DIALOG_IO)
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetWordFromUser:
	lds		si, [bp+DIALOG.fpDialogIO]
	eMOVZX	bx, BYTE [si+WORD_DIALOG_IO.bNumericBase]
ALIGN JUMP_ALIGN
.GetUserInputIntilValidOrCancelled:
	call	Keyboard_ReadUserInputtedWordWhilePrinting
	jz		SHORT .UserCancellation

	cmp		ax, [si+WORD_DIALOG_IO.wMin]
	jb		SHORT .InputtedWordNotInRange
	cmp		ax, [si+WORD_DIALOG_IO.wMax]
	ja		SHORT .InputtedWordNotInRange

	mov		[si+WORD_DIALOG_IO.bUserCancellation], bh	; Zero = FALSE
	mov		[si+WORD_DIALOG_IO.wReturnWord], ax
.UserCancellation:
	ret

.InputtedWordNotInRange:
	call	Keyboard_PlayBellForUnwantedKeystroke
	call	.ClearInputtedWordFromDialog
	jmp		SHORT .GetUserInputIntilValidOrCancelled

;--------------------------------------------------------------------
; .ClearInputtedWordFromDialog
;	Parameters
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ClearInputtedWordFromDialog:
	CALL_DISPLAY_LIBRARY GetSoftwareCoordinatesToAX
	xchg	dx, ax

	mov		al, ' '
	mov		cx, 5
	CALL_DISPLAY_LIBRARY PrintRepeatedCharacterFromALwithCountInCX

	xchg	ax, dx
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	ret
