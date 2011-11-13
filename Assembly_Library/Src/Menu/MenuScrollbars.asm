; Project name	:	Assembly Library
; Description	:	Functions for drawing scroll bars over menu borders.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuScrollbars_AreScrollbarsNeeded
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		CF:		Set if scroll bars are needed
;				Cleared if no scroll bars needed
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuScrollbars_AreScrollbarsNeeded:
	xchg	ax, cx
	call	MenuScrollbars_GetMaxVisibleItemsOnPageToCX
	cmp		cx, [bp+MENUINIT.wItems]		; Set CF if max visible < total items
	xchg	cx, ax
	ret


;--------------------------------------------------------------------
; MenuScrollbars_GetScrollCharacterToALForLineInDI
;	Parameters
;		DI:		Index of item line to draw
;		SS:BP:	Ptr to MENU
;	Returns:
;		AL:		Scroll track or thumb character
;	Corrupts registers:
;		AH, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuScrollbars_GetScrollCharacterToALForLineInDI:
	call	MenuScrollbars_GetMaxVisibleItemsOnPageToCX
	; Get first thumb line to AX
	mov		ax, [bp+MENU.wFirstVisibleItem]
	call	.CalculateFirstOrLastThumbLineToAX

	cmp		di, ax				; Before first thumb line?
	jb		SHORT .ReturnTrackCharacter
	call	.GetLastThumbLineToAX
	cmp		ax, di				; After last thumb line?
ALIGN JUMP_ALIGN
.ReturnTrackCharacter:
	mov		al, SCROLL_TRACK_CHARACTER
	jb		SHORT .Return
	mov		al, SCROLL_THUMB_CHARACTER
ALIGN JUMP_ALIGN, ret
.Return:
	ret

;--------------------------------------------------------------------
; .GetLastThumbLineToAX
;	Parameters
;		CX:		Max visible items on page
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Item line for last thumb character
;	Corrupts registers:
;		CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetLastThumbLineToAX:
	call	MenuScrollbars_GetLastVisibleItemOnPageToAX
	; Fall to .CalculateFirstOrLastThumbLineToAX

;--------------------------------------------------------------------
; .CalculateFirstOrLastThumbLineToAX
;	Parameters
;		AX:		Index of first or last visible item on page
;		CX:		Max visible items on page
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Item line for first thumb character
;	Corrupts registers:
;		CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.CalculateFirstOrLastThumbLineToAX:
	mul		cx
	div		WORD [bp+MENUINIT.wItems]
	ret		; (Visible items on page * First visible item on page) / total items


;--------------------------------------------------------------------
; MenuScrollbars_MoveHighlightedItemByAX
;	Parameters
;		AX:		Signed offset to new item to be highlighted
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuScrollbars_MoveHighlightedItemByAX:
	mov		cx, [bp+MENUINIT.wHighlightedItem]
	add		cx, ax
	; Fall to .RotateItemInCX

;--------------------------------------------------------------------
; .RotateItemInCX
;	Parameters
;		CX:		Possibly under of overflown item to be rotated
;		SS:BP:	Ptr to MENU
;	Returns:
;		CX:		Valid item index
;	Corrupts registers:
;		DX
;--------------------------------------------------------------------
;.RotateItemInCX:
	mov		dx, [bp+MENUINIT.wItems]
	test	cx, cx
	js		SHORT .RotateNegativeItemInCX
	sub		cx, dx
	jae		SHORT .ScrollPageForNewItemInCX

ALIGN JUMP_ALIGN
.RotateNegativeItemInCX:
	add		cx, dx
	; Fall to .ScrollPageForNewItemInCX

;--------------------------------------------------------------------
; .ScrollPageForNewItemInCX
;	Parameters
;		CX:		New item to be highlighted
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ScrollPageForNewItemInCX:
	call	MenuScrollbars_IsItemInCXonVisiblePage
	jc		SHORT .HighlightNewItemOnCX

	mov		dx, [bp+MENU.wFirstVisibleItem]
	sub		dx, [bp+MENUINIT.wHighlightedItem]

	; Get MaxFirstVisibleItem to AX
	push	cx
	call	MenuScrollbars_GetMaxVisibleItemsOnPageToCX
	mov		ax, [bp+MENUINIT.wItems]
	sub		ax, cx
	pop		cx

	add		dx, cx
	jns		.DXisPositive
	cwd		; This won't work if MaxFirstVisibleItem > 32767

ALIGN JUMP_ALIGN
.DXisPositive:
	cmp		ax, dx
	jb		.AXisLessThanDX
	xchg	dx, ax

ALIGN JUMP_ALIGN
.AXisLessThanDX:
	mov		[bp+MENU.wFirstVisibleItem], ax
	call	MenuText_RefreshAllItems

ALIGN JUMP_ALIGN
.HighlightNewItemOnCX:
	jmp		MenuEvent_HighlightItemFromCX


;--------------------------------------------------------------------
; MenuScrollbars_IsItemInCXonVisiblePage
;	Parameters
;		CX:		Item whose visibility is to be checked
;		SS:BP:	Ptr to MENU
;	Returns:
;		CF:		Set if item is on visible page
;				Cleared if item is not on visible page
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuScrollbars_IsItemInCXonVisiblePage:
	cmp		[bp+MENU.wFirstVisibleItem], cx
	ja		SHORT .ItemIsNotVisible

	call	MenuScrollbars_GetLastVisibleItemOnPageToAX
	cmp		cx, ax
	ja		SHORT .ItemIsNotVisible
	stc		; Item is visible
ALIGN JUMP_ALIGN, ret
.ItemIsNotVisible:
	ret


;--------------------------------------------------------------------
; MenuScrollbars_GetLastVisibleItemOnPageToAX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Index of last visible item on page
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuScrollbars_GetLastVisibleItemOnPageToAX:
	xchg	cx, ax
	call	MenuScrollbars_GetActualVisibleItemsOnPageToCX
	xchg	ax, cx
	dec		ax
	add		ax, [bp+MENU.wFirstVisibleItem]
	ret


;--------------------------------------------------------------------
; MenuScrollbars_GetActualVisibleItemsOnPageToCX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		CX:		Currently visible items
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuScrollbars_GetActualVisibleItemsOnPageToCX:
	call	MenuScrollbars_GetMaxVisibleItemsOnPageToCX
	cmp		cx, [bp+MENUINIT.wItems]
	jb		SHORT .Return
	mov		cx, [bp+MENUINIT.wItems]
ALIGN JUMP_ALIGN, ret
.Return:
	ret


;--------------------------------------------------------------------
; MenuScrollbars_GetMaxVisibleItemsOnPageToCX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		CX:		Maximum number of visible items
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuScrollbars_GetMaxVisibleItemsOnPageToCX:
	eMOVZX	cx, BYTE [bp+MENUINIT.bHeight]
	sub		cl, [bp+MENUINIT.bTitleLines]
	sub		cl, [bp+MENUINIT.bInfoLines]
	sub		cl, MENU_VERTICAL_BORDER_LINES
	ret
