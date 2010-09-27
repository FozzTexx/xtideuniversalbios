; File name		:	MenuText.asm
; Project name	:	Assembly Library
; Created date	:	21.7.2010
; Last update	:	27.9.2010
; Author		:	Tomi Tilli
; Description	:	Functions for drawing menu texts by the user.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuText_RefreshTitle
; MenuText_RefreshInformation
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuText_RefreshTitle:
	cmp		BYTE [bp+MENUINIT.bTitleLines], 0
	jz		SHORT NothingToRefresh

	mov		si, ATTRIBUTE_CHARS.cTitle
	call	AdjustDisplayContextForDrawingTexts
	call	MenuLocation_GetTitleTextTopLeftCoordinatesToAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	jmp		MenuEvent_RefreshTitle

ALIGN JUMP_ALIGN
MenuText_RefreshInformation:
	cmp		BYTE [bp+MENUINIT.bInfoLines], 0
	jz		SHORT NothingToRefresh

	mov		si, ATTRIBUTE_CHARS.cInformation
	call	AdjustDisplayContextForDrawingTexts
	call	MenuLocation_GetInformationTextTopLeftCoordinatesToAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	jmp		MenuEvent_RefreshInformation


;--------------------------------------------------------------------
; MenuText_RefreshAllItems
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuText_RefreshAllItems:
	push	cx

	call	MenuScrollbars_GetActualVisibleItemsOnPageToCX
	mov		ax, [bp+MENU.wFirstVisibleItem]
ALIGN JUMP_ALIGN
.ItemRefreshLoop:
	call	MenuText_RefreshItemFromAX
	inc		ax
	loop	.ItemRefreshLoop

	pop		cx
NothingToRefresh:
	ret

;--------------------------------------------------------------------
; MenuText_RefreshItemFromAX
;	Parameters
;		AX:		Item to refresh
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuText_RefreshItemFromAX:
	push	cx
	mov		cx, ax					; Backup item to CX

	call	MenuScrollbars_IsItemInCXonVisiblePage
	jnc		SHORT .InvalidItem
	mov		ax, cx
	call	MenuText_AdjustDisplayContextForDrawingItemFromAX
	call	MenuEvent_RefreshItemFromCX
	call	DrawScrollbarIfNecessary
.InvalidItem:
	xchg	ax, cx					; Restore AX
	pop		cx
	ret

;--------------------------------------------------------------------
; MenuText_AdjustDisplayContextForDrawingItemFromAX
;	Parameters
;		AX:		Item to refresh
;		SS:BP:	Ptr to MENU
;	Returns:
;		CX:		Item to refresh
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuText_AdjustDisplayContextForDrawingItemFromAX:
	mov		cx, ax
	call	MenuLocation_GetTextCoordinatesToAXforItemInAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	call	.GetItemTextAttributeTypeToSIforItemInCX
	jmp		SHORT AdjustDisplayContextForDrawingTexts

;--------------------------------------------------------------------
; .GetItemTextAttributeTypeToSIforItemInCX
;	Parameters
;		CX:		Item to refresh
;		SS:BP:	Ptr to MENU
;	Returns:
;		SI:		Text attribute type (ATTRIBUTE_CHARS)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetItemTextAttributeTypeToSIforItemInCX:
	mov		si, ATTRIBUTE_CHARS.cItem
	test	BYTE [bp+MENU.bFlags], FLG_MENU_NOHIGHLIGHT
	jnz		SHORT .ReturnAttributeTypeInSI
	cmp		cx, [bp+MENU.wHighlightedItem]
	jne		SHORT .ReturnAttributeTypeInSI
	sub		si, BYTE ATTRIBUTE_CHARS.cItem - ATTRIBUTE_CHARS.cHighlightedItem
ALIGN JUMP_ALIGN, ret
.ReturnAttributeTypeInSI:
	ret


;--------------------------------------------------------------------
; DrawScrollbarIfNecessary
;	Parameters
;		CX:		Item to refresh
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrawScrollbarIfNecessary:
	push	cx
	call	.DrawSpacesBeforeScrollbarCharacter
	call	MenuScrollbars_AreScrollbarsNeeded
	pop		cx
	jc		SHORT .DrawScrollbarCharacter
	ret

;--------------------------------------------------------------------
; .DrawSpacesBeforeScrollbarCharacter
;	Parameters
;		CX:		Item to refresh
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.DrawSpacesBeforeScrollbarCharacter:
	CALL_DISPLAY_LIBRARY GetSoftwareCoordinatesToAX
	xchg	dx, ax					; Current coordinates to DX
	mov		ax, cx
	call	MenuLocation_GetScrollbarCoordinatesToAXforItemInAX
	sub		al, dl
	sub		al, MENU_TEXT_COLUMN_OFFSET/2

	eMOVZX	cx, al
	jcxz	.NoSpacesNeeded
	mov		al, ' '
	CALL_DISPLAY_LIBRARY PrintRepeatedCharacterFromALwithCountInCX
ALIGN JUMP_ALIGN, ret
.NoSpacesNeeded:
	ret

;--------------------------------------------------------------------
; .DrawScrollbarCharacter
;	Parameters
;		CX:		Item to refresh
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.DrawScrollbarCharacter:
	push	cx

	mov		si, ATTRIBUTE_CHARS.cBordersAndBackground
	call	MenuAttribute_SetToDisplayContextFromTypeInSI

	mov		ax, cx
	call	MenuLocation_GetScrollbarCoordinatesToAXforItemInAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX

	mov		di, cx
	sub		di, [bp+MENU.wFirstVisibleItem]		; Item to line
	call	MenuScrollbars_GetScrollCharacterToALForLineInDI
	CALL_DISPLAY_LIBRARY PrintCharacterFromAL

	pop		cx
	ret


;--------------------------------------------------------------------
; AdjustDisplayContextForDrawingTexts
;	Parameters
;		SI:		Attribute type (from ATTRIBUTE_CHARS)
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AdjustDisplayContextForDrawingTexts:
	mov		dl, ATTRIBUTES_ARE_USED
	mov		ax, MenuCharOut_MenuTextTeletypeOutputWithAttribute
	CALL_DISPLAY_LIBRARY SetCharOutputFunctionFromAXwithAttribFlagInDL

	mov		ax, bp
	CALL_DISPLAY_LIBRARY SetCharacterOutputParameterFromAX

	jmp		MenuAttribute_SetToDisplayContextFromTypeInSI
