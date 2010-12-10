; File name		:	Menupage.asm
; Project name	:	XTIDE Universal BIOS Configurator v2
; Created date	:	5.10.2010
; Last update	:	1.11.2010
; Author		:	Tomi Tilli
; Description	:	Functions for accessing MENUPAGE structs.

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
	CALL_MENU_LIBRARY RefreshWindow
	ret


;--------------------------------------------------------------------
; Menupage_SetActiveMenupageFromDSDI
;	Parameters:
;		DS:DI:	Ptr to MENUPAGE to set active
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
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
