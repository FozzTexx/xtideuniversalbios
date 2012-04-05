; File name		:	DialogMessage.asm
; Project name	:	Assembly Library
; Created date	:	6.8.2010
; Last update	:	18.11.2010
; Author		:	Tomi Tilli
; Description	:	Displays message dialog.

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.		
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;
		

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DialogMessage_DisplayMessageWithInputInDSSI
;	Parameters:
;		DS:SI:	Ptr to DIALOG_INPUT
;		SS:BP:	Ptr to parent MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DialogMessage_DisplayMessageWithInputInDSSI:
	mov		bx, MessageEventHandler
	jmp		Dialog_DisplayWithDialogInputInDSSIandHandlerInBX


;--------------------------------------------------------------------
; MessageEventHandler
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
MessageEventHandler:
	jmp		[cs:bx+.rgfnEventHandlers]


ALIGN JUMP_ALIGN
.InitializeMenuinitFromDSSI:
	or		BYTE [bp+MENU.bFlags], FLG_MENU_USER_HANDLES_SCROLLING | FLG_MENU_NOHIGHLIGHT
	xor		ax, ax		; Cannot be NO_ITEM_HIGHLIGHTED because of scrolling
	jmp		Dialog_EventInitializeMenuinitFromDSSIwithHighlightedItemInAX


ALIGN JUMP_ALIGN
.KeyStrokeInAX:
	call	ProcessMessageScrollingKeysFromAX
	stc
	ret


ALIGN WORD_ALIGN
.rgfnEventHandlers:
istruc MENUEVENT
	at	MENUEVENT.InitializeMenuinitFromDSSI,	dw	.InitializeMenuinitFromDSSI
	at	MENUEVENT.ExitMenu,						dw	Dialog_EventExitMenu
	at	MENUEVENT.IdleProcessing,				dw	Dialog_EventNotHandled
	at	MENUEVENT.ItemHighlightedFromCX,		dw	Dialog_EventNotHandled
	at	MENUEVENT.ItemSelectedFromCX,			dw	Dialog_EventAnyThatClosesDialog
	at	MENUEVENT.KeyStrokeInAX,				dw	.KeyStrokeInAX
	at	MENUEVENT.RefreshTitle,					dw	Dialog_EventRefreshTitle
	at	MENUEVENT.RefreshInformation,			dw	Dialog_EventRefreshInformation
	at	MENUEVENT.RefreshItemFromCX,			dw	Dialog_EventRefreshItemFromCX
iend


;--------------------------------------------------------------------
; ProcessMessageScrollingKeysFromAX
;	Parameters
;		AL:		ASCII character
;		AH:		BIOS scan code
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ProcessMessageScrollingKeysFromAX:
	cmp		ah, MENU_KEY_UP
	je		SHORT .DecrementLines
	cmp		ah, MENU_KEY_DOWN
	je		SHORT .IncrementLines
	jmp		MenuLoop_ProcessScrollingKeysFromAX

ALIGN JUMP_ALIGN
.DecrementLines:
	cmp		WORD [bp+MENUINIT.wHighlightedItem], BYTE 0
	je		SHORT .AlreadyAtTheTopOrBottom

	mov		ax, [bp+MENU.wFirstVisibleItem]
	mov		[bp+MENUINIT.wHighlightedItem], ax
	mov		ah, MENU_KEY_UP
	jmp		MenuLoop_ProcessScrollingKeysFromAX

ALIGN JUMP_ALIGN
.IncrementLines:
	mov		ax, [bp+MENUINIT.wItems]
	dec		ax						; Last possible item to highlight
	cmp		[bp+MENUINIT.wHighlightedItem], ax
	jae		SHORT .AlreadyAtTheTopOrBottom

	call	MenuScrollbars_GetLastVisibleItemOnPageToAX
	mov		[bp+MENUINIT.wHighlightedItem], ax
	mov		ah, MENU_KEY_DOWN
	jmp		MenuLoop_ProcessScrollingKeysFromAX

ALIGN JUMP_ALIGN
.AlreadyAtTheTopOrBottom:
	ret
