; File name		:	DialogSelection.asm
; Project name	:	Assembly Library
; Created date	:	13.8.2010
; Last update	:	13.8.2010
; Author		:	Tomi Tilli
; Description	:	Displays selection dialog.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DialogSelection_GetSelectionToAXwithInputInDSSI
;	Parameters:
;		DS:SI:	Ptr to DIALOG_INPUT
;		SS:BP:	Ptr to parent MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DialogSelection_GetSelectionToAXwithInputInDSSI:
	mov		bx, SelectionEventHandler
	jmp		Dialog_DisplayWithDialogInputInDSSIandHandlerInBX


;--------------------------------------------------------------------
; SelectionEventHandler
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
SelectionEventHandler:
	jmp		[cs:bx+.rgfnEventHandlers]


ALIGN JUMP_ALIGN
.InitializeMenuinitFromDSSI:
	mov		WORD [bp+MENU.wHighlightedItem], 0
	jmp		Dialog_EventInitializeMenuinitFromDSSI


ALIGN WORD_ALIGN
.rgfnEventHandlers:
istruc MENUEVENT
	at	MENUEVENT.InitializeMenuinitFromDSSI,	dw	.InitializeMenuinitFromDSSI
	at	MENUEVENT.ExitMenu,						dw	Dialog_EventNotHandled
	at	MENUEVENT.IdleProcessing,				dw	Dialog_EventNotHandled
	at	MENUEVENT.ItemHighlightedFromCX,		dw	Dialog_EventNotHandled
	at	MENUEVENT.ItemSelectedFromCX,			dw	Dialog_EventAnyThatClosesDialog
	at	MENUEVENT.KeyStrokeInAX,				dw	Dialog_EventNotHandled
	at	MENUEVENT.RefreshTitle,					dw	Dialog_EventRefreshTitle
	at	MENUEVENT.RefreshInformation,			dw	Dialog_EventRefreshInformation
	at	MENUEVENT.RefreshItemFromCX,			dw	Dialog_EventRefreshItemFromCX
iend
