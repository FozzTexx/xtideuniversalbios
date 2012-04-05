; Project name	:	Assembly Library
; Description	:	Functions for initializing menu system.

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
; MenuEvent_InitializeMenuinit
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		DS:SI:	Ptr to MENU with MENUINIT initialized from user handler
;		CF:		Set if event processed
;				Cleared if event not processed
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuEvent_InitializeMenuinit:
	push	ss
	pop		ds
	mov		si, bp
	mov		bl, MENUEVENT_InitializeMenuinitFromDSSI
	jmp		SHORT MenuEvent_SendFromBX


;--------------------------------------------------------------------
; MenuEvent_ExitMenu
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		CF:		Set to exit from menu
;				Cleared to cancel exit
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuEvent_ExitMenu:
	mov		bl, MENUEVENT_ExitMenu
	jmp		SHORT MenuEvent_SendFromBX


%ifdef MENUEVENT_IDLEPROCESSING_ENABLE
;--------------------------------------------------------------------
; MenuEvent_IdleProcessing
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		CF:		Set if event processed
;				Cleared if event not processed
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuEvent_IdleProcessing:
	mov		bl, MENUEVENT_IdleProcessing
	jmp		SHORT MenuEvent_SendFromBX
%endif

;--------------------------------------------------------------------
; MenuEvent_RefreshTitle
; MenuEvent_RefreshInformation
;	Parameters
;		SS:BP:	Ptr to MENU
;		Cursor will be positioned to beginning of window
;	Returns:
;		CF:		Set if event processed
;				Cleared if event not processed
;	Corrupts registers:
;		AX, CX, BX, DX
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuEvent_RefreshTitle:
	mov		bl, MENUEVENT_RefreshTitle
	SKIP2B	cx	; mov cx, <next instruction>

MenuEvent_RefreshInformation:
	mov		bl, MENUEVENT_RefreshInformation
	mov		cx, [bp+MENUINIT.wHighlightedItem]
	jmp		SHORT MenuEvent_SendFromBX


;--------------------------------------------------------------------
; MenuEvent_RefreshItemFromCX
;	Parameters
;		CX:		Index of item to refresh
;		SS:BP:	Ptr to MENU
;		Cursor has been positioned to the beginning of item line
;	Returns:
;		CF:		Set if event processed
;				Cleared if event not processed
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuEvent_RefreshItemFromCX:
	mov		bl, MENUEVENT_RefreshItemFromCX
	jmp		SHORT MenuEvent_SendFromBX


;--------------------------------------------------------------------
; MenuEvent_HighlightItemFromCX
;	Parameters
;		CX:		Index of item to highlight
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuEvent_HighlightItemFromCX:
	mov		dx, cx
	xchg	dx, [bp+MENUINIT.wHighlightedItem]
	push	dx

	mov		bl, MENUEVENT_ItemHighlightedFromCX
	call	MenuEvent_SendFromBX

	pop		ax
	call	MenuText_RefreshItemFromAX
	mov		ax, [bp+MENUINIT.wHighlightedItem]
	jmp		MenuText_RefreshItemFromAX


;--------------------------------------------------------------------
; MenuEvent_KeyStrokeInAX
;	Parameters
;		AL:		ASCII character for the key
;		AH:		Keyboard library scan code for the key
;		SS:BP:	Ptr to MENU
;	Returns:
;		CF:		Set if event processed
;				Cleared if event not processed
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuEvent_KeyStrokeInAX:
	mov		bl, MENUEVENT_KeyStrokeInAX
	SKIP2B	dx	; mov dx, <next instruction>


;--------------------------------------------------------------------
; MenuEvent_ItemSelectedFromCX
;	Parameters
;		CX:		Index of selected item
;		SS:BP:	Ptr to MENU
;	Returns:
;		CF:		Set if event processed
;				Cleared if event not processed
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
MenuEvent_ItemSelectedFromCX:
	mov		bl, MENUEVENT_ItemSelectedFromCX
	; Fall to MenuEvent_SendFromBX


;--------------------------------------------------------------------
; MenuEvent_SendFromBX
;	Parameters
;		BL:					Menu event to send
;		SS:BP:				Ptr to MENU
;		Other registers:	Event specific parameters
;	Returns:
;		AX, DX:				Event specific return values
;		CF:					Set if event processed
;							Cleared if event not processed
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuEvent_SendFromBX:
	push	es
	push	ds
	push	di
	push	si
	push	cx
	xor		bh, bh
	call	[bp+MENU.fnEventHandler]
	pop		cx
	pop		si
	pop		di
	pop		ds
	pop		es
	ret
