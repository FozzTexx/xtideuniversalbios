; Project name	:	Assembly Library
; Description	:	Functions for initializing menu system.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
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
; MenuInit_DisplayMenuWithHandlerInBXandUserDataInDXAX
;	Parameters
;		DX:AX:	User specified data
;		BX:		Menu event handler
;	Returns:
;		AX:		Index of selected item or NO_ITEM_SELECTED
;	Corrupts registers:
;		All except segments
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuInit_DisplayMenuWithHandlerInBXandUserDataInDXAX:
	push	es
	push	ds
	xchg	cx, ax			; Backup user data
	CALL_DISPLAY_LIBRARY	PushDisplayContext

	; Create MENU struct to stack
	mov		ax, MENU_size
	eENTER_STRUCT	ax
	xchg	ax, cx			; Restore user data to AX
	call	Memory_ZeroSSBPwithSizeInCX

	; Display menu
	call	MenuInit_EnterMenuWithHandlerInBXandUserDataInDXAX

	; Get menu selection and destroy menu variables from stack
	mov		dx, [bp+MENUINIT.wHighlightedItem]
	eLEAVE_STRUCT	MENU_size

	CALL_DISPLAY_LIBRARY	PopDisplayContext
	xchg	ax, dx			; Return highlighted item in AX
	pop		ds
	pop		es
	ret


;--------------------------------------------------------------------
; EnterMenuWithHandlerInBXandUserDataInDXAX
;	Parameters
;		DX:AX:	User specified data
;		BX:		Menu event handler
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except SS:BP
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuInit_EnterMenuWithHandlerInBXandUserDataInDXAX:
	mov		[bp+MENU.fnEventHandler], bx
	mov		[bp+MENU.dwUserData], ax
	mov		[bp+MENU.dwUserData+2], dx

	mov		ax, CURSOR_HIDDEN
	CALL_DISPLAY_LIBRARY SetCursorShapeFromAX
	call	MenuEvent_InitializeMenuinit	; User initialization
%ifndef USE_186
	call	MenuInit_RefreshMenuWindow
	jmp		MenuLoop_Enter
%else
	push	MenuLoop_Enter
	; Fall to MenuInit_RefreshMenuWindow
%endif


;--------------------------------------------------------------------
; MenuInit_RefreshMenuWindow
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuInit_RefreshMenuWindow:
	call	MenuBorders_RefreshAll			; Draw borders
	call	MenuText_RefreshTitle			; Draw title strings
	call	MenuText_RefreshAllItems		; Draw item strings
	jmp		MenuText_RefreshInformation		; Draw information strings


;--------------------------------------------------------------------
; MenuInit_CloseMenuIfExitEventAllows
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN MENU_JUMP_ALIGN
MenuInit_CloseMenuIfExitEventAllows:
	call	MenuEvent_ExitMenu
	jc		SHORT MenuInit_CloseMenuWindow
	ret
%endif


;--------------------------------------------------------------------
; MenuInit_CloseMenuWindow
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuInit_CloseMenuWindow:
	or		BYTE [bp+MENU.bFlags], FLG_MENU_EXIT
	ret


%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
;--------------------------------------------------------------------
; MenuInit_HighlightItemFromAX
;	Parameters
;		AX:		Item to highlight
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuInit_HighlightItemFromAX:
	sub		ax, [bp+MENUINIT.wHighlightedItem]
	jmp		MenuScrollbars_MoveHighlightedItemByAX
%endif


;--------------------------------------------------------------------
; MenuInit_GetHighlightedItemToAX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Index of highlighted item or NO_ITEM_HIGHLIGHTED
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN MENU_JUMP_ALIGN
MenuInit_GetHighlightedItemToAX:
	mov		ax, [bp+MENUINIT.wHighlightedItem]
	ret
%endif


;--------------------------------------------------------------------
; MenuInit_SetTitleHeightFromAL
; MenuInit_SetInformationHeightFromAL
; MenuInit_SetTotalItemsFromAX
;	Parameters
;		AX/AL:	Parameter
;		SS:BP:		Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN MENU_JUMP_ALIGN
MenuInit_SetTitleHeightFromAL:
	mov		[bp+MENUINIT.bTitleLines], al
	ret

ALIGN MENU_JUMP_ALIGN
MenuInit_SetInformationHeightFromAL:
	mov		[bp+MENUINIT.bInfoLines], al
	ret

ALIGN MENU_JUMP_ALIGN
MenuInit_SetTotalItemsFromAX:
	mov		[bp+MENUINIT.wItems], ax
	ret
%endif


;--------------------------------------------------------------------
; MenuInit_SetUserDataFromDSSI
; MenuInit_GetUserDataToDSSI
;	Parameters
;		DS:SI:	User data (MenuInit_SetUserDataFromDSSI)
;		SS:BP:	Ptr to MENU
;	Returns:
;		DS:SI:	User data (MenuInit_GetUserDataToDSSI)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN MENU_JUMP_ALIGN
MenuInit_SetUserDataFromDSSI:
	mov		[bp+MENU.dwUserData], si
	mov		[bp+MENU.dwUserData+2], ds
	ret

ALIGN MENU_JUMP_ALIGN
MenuInit_GetUserDataToDSSI:
	lds		si, [bp+MENU.dwUserData]
	ret
%endif
