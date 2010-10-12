; File name		:	MenuScrollbars.asm
; Project name	:	Assembly Library
; Created date	:	20.7.2010
; Last update	:	12.10.2010
; Author		:	Tomi Tilli
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
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuScrollbars_AreScrollbarsNeeded:
	call	MenuScrollbars_GetMaxVisibleItemsOnPageToCX
	cmp		cx, [bp+MENUINIT.wItems]		; Set CF if max visible < total items
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
	call	.GetFirstThumbLineToAX
	cmp		di, ax				; Before first thumb line?
	jb		SHORT .ReturnTrackCharacter
	call	.GetLastThumbLineToAX
	cmp		di, ax				; After last thumb line?
	ja		SHORT .ReturnTrackCharacter
	mov		al, SCROLL_THUMB_CHARACTER
	ret
ALIGN JUMP_ALIGN
.ReturnTrackCharacter:
	mov		al, SCROLL_TRACK_CHARACTER
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
	jmp		SHORT .CalculateFirstOrLastThumbLineToAX

;--------------------------------------------------------------------
; .GetFirstThumbLineToAX
;	Parameters
;		CX:		Max visible items on page
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Item line for first thumb character
;	Corrupts registers:
;		CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetFirstThumbLineToAX:
	mov		ax, [bp+MENU.wFirstVisibleItem]
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
	call	.RotateItemInCX
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
.ScrollPageForNewItemInCX:
	call	MenuScrollbars_IsItemInCXonVisiblePage
	jc		SHORT .HighlightNewItemOnCX

	mov		dx, [bp+MENU.wFirstVisibleItem]
	sub		dx, [bp+MENUINIT.wHighlightedItem]
	add		dx, cx
	MAX_S	dx, 0
	call	.GetMaxFirstVisibleItemToAX
	MIN_U	ax, dx
	mov		[bp+MENU.wFirstVisibleItem], ax
	call	MenuText_RefreshAllItems

ALIGN JUMP_ALIGN
.HighlightNewItemOnCX:
	jmp		MenuEvent_HighlightItemFromCX

;--------------------------------------------------------------------
; .GetMaxFirstVisibleItemToAX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Max first visible item
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetMaxFirstVisibleItemToAX:
	push	cx

	call	MenuScrollbars_GetMaxVisibleItemsOnPageToCX
	mov		ax, [bp+MENUINIT.wItems]
	sub		ax, cx

	pop		cx
	ret

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
ALIGN JUMP_ALIGN
.RotateItemInCX:
	mov		dx, [bp+MENUINIT.wItems]
	cmp		cx, BYTE 0
	jl		SHORT .RotateNegativeItemInCX
	cmp		cx, dx
	jae		SHORT .RotatePositiveItemInCX
	ret

ALIGN JUMP_ALIGN
.RotatePositiveItemInCX:
	sub		cx, dx
	;jae	SHORT .RotatePositiveItemInCX	; Not needed by scrolling
	ret

ALIGN JUMP_ALIGN
.RotateNegativeItemInCX:
	add		cx, dx
	;js		SHORT .RotateNegativeItemInCX	; Not needed by scrolling
	ret


;--------------------------------------------------------------------
; .IsItemInCXonVisiblePage
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
	cmp		cx, [bp+MENUINIT.wItems]
	jae		SHORT .ItemIsNotVisible

	cmp		cx, [bp+MENU.wFirstVisibleItem]
	jb		SHORT .ItemIsNotVisible

	call	MenuScrollbars_GetLastVisibleItemOnPageToAX
	cmp		cx, ax
	ja		SHORT .ItemIsNotVisible
	stc		; Item is visible
	ret
ALIGN JUMP_ALIGN
.ItemIsNotVisible:
	clc
	ret


;--------------------------------------------------------------------
; MenuLocation_GetLastVisibleItemOnPageToAX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Index of last visible item on page
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuScrollbars_GetLastVisibleItemOnPageToAX:
	push	cx

	call	MenuScrollbars_GetActualVisibleItemsOnPageToCX
	xchg	ax, cx
	dec		ax
	add		ax, [bp+MENU.wFirstVisibleItem]

	pop		cx
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
	MIN_U	cx, [bp+MENUINIT.wItems]
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
