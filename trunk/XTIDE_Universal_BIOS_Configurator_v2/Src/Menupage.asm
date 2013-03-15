; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	Functions for accessing MENUPAGE structs.

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
; Menupage_ChangeToNewMenupageInDSSI
;	Parameters:
;		DS:SI:	Ptr to new MENUPAGE
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menupage_ChangeToNewMenupageInDSSI:
	mov		di, si
	call	Menupage_SetActiveMenupageFromDSDI
	call	Menupage_GetVisibleMenuitemsToAXfromDSDI
	CALL_MENU_LIBRARY SetTotalItemsFromAX
	xor		ax, ax
	CALL_MENU_LIBRARY HighlightItemFromAX
	JMP_MENU_LIBRARY RefreshWindow


;--------------------------------------------------------------------
; SetActiveMenupageFromDSDI
;	Parameters:
;		DS:DI:	Ptr to MENUPAGE to set active
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menupage_SetActiveMenupageFromDSDI:
	mov		[g_cfgVars+CFGVARS.pMenupage], di
	ret


;--------------------------------------------------------------------
; Menupage_GetActiveMenupageToDSDI:
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		DS:DI:	Ptr to MENUPAGE
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menupage_GetActiveMenupageToDSDI:
	push	cs
	pop		ds
	mov		di, [g_cfgVars+CFGVARS.pMenupage]
	ret


;--------------------------------------------------------------------
; Menupage_GetVisibleMenuitemsToAXfromDSDI
;	Parameters:
;		DS:DI:	Ptr to MENUPAGE
;	Returns:
;		AX:		Number of visible MENUITEMs in MENUPAGE
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menupage_GetVisibleMenuitemsToAXfromDSDI:
	xor		ax, ax
	mov		cx, [di+MENUPAGE.wMenuitems]
	lea		bx, [di+MENUPAGE.rgMenuitem]

ALIGN JUMP_ALIGN
.CheckVisibilityFromNextMenuitem:
	test	BYTE [bx+MENUITEM.bFlags], FLG_MENUITEM_VISIBLE
	jz		SHORT .PrepareToLoop
	inc		ax
.PrepareToLoop:
	add		bx, BYTE MENUITEM_size
	loop	.CheckVisibilityFromNextMenuitem
	ret


;--------------------------------------------------------------------
; Menupage_GetCXthVisibleMenuitemToDSSIfromDSDI
;	Parameters:
;		CX:		nth visible MENUITEM to find
;		DS:DI:	Ptr to MENUPAGE
;	Returns:
;		DS:SI:	Ptr to CXth visible MENUITEM
;		CF:		Set if MENUITEM found
;				Cleared if MENUITEM not found
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menupage_GetCXthVisibleMenuitemToDSSIfromDSDI:
	mov		ax, [di+MENUPAGE.wMenuitems]
	cmp		cx, ax
	jae		SHORT .MenuitemNotFound
	xchg	ax, cx
	inc		ax
	lea		si, [di+MENUPAGE.rgMenuitem]
ALIGN JUMP_ALIGN
.CheckNextMenuitem:
	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_VISIBLE
	jz		SHORT .PrepareToLoop
	dec		ax
	jz		SHORT .MenuitemFound
.PrepareToLoop:
	add		si, BYTE MENUITEM_size
	loop	.CheckNextMenuitem
.MenuitemNotFound:
	clc
	ret
ALIGN JUMP_ALIGN
.MenuitemFound:
	stc
	ret
