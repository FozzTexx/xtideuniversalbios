; Project name	:	XTIDE Universal BIOS Configurator
; Description	:	Functions to access MENUPAGE structs.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Returns number of visible menuitems in MENUPAGE.
;
; MenuPage_GetNumberOfVisibleItems
;	Parameters:
;		DS:SI:	Ptr to MENUPAGE
;	Returns:
;		AX:		Number of visible menuitems
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPage_GetNumberOfVisibleItems:
	xor		ax, ax					; Zero visible menuitems
	mov		di, MenuPage_IterateForNumberOfVisibleItems
	jmp		SHORT MenuPage_IterateMenuPageItems

;--------------------------------------------------------------------
; Iteration callback function for MenuPage_GetNumberOfVisibleItems.
;
; MenuPage_IterateForNumberOfVisibleItems
;	Parameters:
;		AX:		Number of visible menuitems found so far
;		DS:BX:	Ptr to MENUPAGEITEM to examine
;	Returns:
;		AX:		Number of visible menuitems found so far
;		CF:		Cleared to continue iteration
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPage_IterateForNumberOfVisibleItems:
	test	BYTE [bx+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE	; Clears CF
	jz		SHORT .NextItem
	inc		ax						; Increment visible menuitems
ALIGN JUMP_ALIGN
.NextItem:
	ret


;--------------------------------------------------------------------
; Returns pointer to MENUPAGEITEM for visible index (menu library index).
;
; MenuPage_GetMenuPageItemForVisibleIndex
;	Parameters:
;		CX:		Index of visible menuitem
;		DS:SI:	Ptr to MENUPAGE
;	Returns:
;		DS:DI:	Ptr to MENUPAGEITEM
;		CF:		Set if MENUPAGEITEM was found
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPage_GetMenuPageItemForVisibleIndex:
	mov		ax, cx					; Menuitem index to menuitems to skip
	mov		di, MenuPage_IterateForVisibleIndex
	jmp		SHORT MenuPage_IterateMenuPageItems

;--------------------------------------------------------------------
; Iteration callback function for MenuPage_GetMenuPageItemForVisibleIndex.
;
; MenuPage_IterateForVisibleIndex
;	Parameters:
;		AX:		Number of visible menuitems left to skip
;		DS:BX:	Ptr to MENUPAGEITEM to examine
;	Returns:
;		AX:		Number of visible menuitems left to skip
;		CF:		Cleared to continue iteration
;				Set if correct MENUPAGEITEM was found
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPage_IterateForVisibleIndex:
	test	BYTE [bx+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE	; Clears CF
	jz		SHORT .NextItem
	sub		ax, BYTE 1				; Set CF if correct MENUITEM found
ALIGN JUMP_ALIGN
.NextItem:
	ret


;--------------------------------------------------------------------
; Iterates MENUPAGEITEMs until terminated by callback function or
; all MENUPAGEITEMs have been iterated.
;
; MenuPage_IterateMenuPageItems
;	Parameters:
;		AX,DX:	Parameters to callback function
;		DI:		Offset to iteration callback function
;		DS:SI:	Ptr to MENUPAGE
;	Returns:
;		AX,DX:	Return values from callback function
;		DS:DI:	Ptr to MENUPAGEITEM (only if CF set)
;		CF:		Cleared if terminated by end of menuitems
;				Set if terminated by callback function
;	Corrupts registers:
;		Nothing, unless corrupted by callback function
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPage_IterateMenuPageItems:
	push	cx
	push	bx
	eMOVZX	cx, [si+MENUPAGE.bItemCnt]
	lea		bx, [si+MENUPAGE.rgMenuPageItem]
ALIGN JUMP_ALIGN
.IterationLoop:
	call	di							; Callback function
	jc		SHORT .IterationComplete	; CF set, end iteration
	add		bx, BYTE MENUPAGEITEM_size
	loop	.IterationLoop
	clc									; Clear CF since end of MENUITEMs
ALIGN JUMP_ALIGN
.IterationComplete:
	mov		di, bx						; DS:DI points to MENUPAGEITEM
	pop		bx
	pop		cx
	ret


;--------------------------------------------------------------------
; Updates number of menuitems and redraws them.
;
; MenuPage_InvalidateItemCount
;	Parameters:
;		DS:SI:	Ptr to MENUPAGE
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPage_InvalidateItemCount:
	push	di
	call	MenuPage_GetNumberOfVisibleItems
	mov		cx, ax
	mov		dl, MFL_UPD_ITEM | MFL_UPD_NFO
	call	Menu_InvItemCnt
	pop		di
	ret
