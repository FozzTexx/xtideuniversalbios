; Project name	:	Assembly Library
; Description	:	Functions for drawing menu texts by the user.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuText_ClearTitleArea
; MenuText_ClearInformationArea
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuText_ClearTitleArea:
	CALL_DISPLAY_LIBRARY PushDisplayContext		; Save cursor coordinates
	call	PrepareToDrawTitleArea
	mov		cl, [bp+MENUINIT.bTitleLines]
	jmp		SHORT ClearCLlinesOfText

ALIGN JUMP_ALIGN
MenuText_ClearInformationArea:
	CALL_DISPLAY_LIBRARY PushDisplayContext		; Save cursor coordinates
	call	MenuText_PrepareToDrawInformationArea
	mov		cl, [bp+MENUINIT.bInfoLines]
ClearCLlinesOfText:
	mov		al, [bp+MENUINIT.bWidth]
	sub		al, MENU_HORIZONTAL_BORDER_LINES+(MENU_TEXT_COLUMN_OFFSET/2)
	mul		cl
	xchg	cx, ax
	mov		al, ' '
	CALL_DISPLAY_LIBRARY PrintRepeatedCharacterFromALwithCountInCX
	CALL_DISPLAY_LIBRARY PopDisplayContext
	ret


;--------------------------------------------------------------------
; MenuText_RefreshTitle
; MenuText_RefreshInformation
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuText_RefreshTitle:
	cmp		BYTE [bp+MENUINIT.bTitleLines], 0
	jz		SHORT NothingToRefresh
	call	PrepareToDrawTitleArea
	jmp		MenuEvent_RefreshTitle

ALIGN JUMP_ALIGN
MenuText_RefreshInformation:
	cmp		BYTE [bp+MENUINIT.bInfoLines], 0
	jz		SHORT NothingToRefresh
	call	MenuText_PrepareToDrawInformationArea
	jmp		MenuEvent_RefreshInformation

;--------------------------------------------------------------------
; PrepareToDrawTitleArea
; PrepareToDrawInformationArea
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrepareToDrawTitleArea:
	mov		si, ATTRIBUTE_CHARS.cTitle
	call	MenuLocation_GetTitleTextTopLeftCoordinatesToAX
	jmp		SHORT FinishPreparationsToDrawTitleOrInformationArea

ALIGN JUMP_ALIGN
MenuText_PrepareToDrawInformationArea:
	mov		si, ATTRIBUTE_CHARS.cInformation
	call	MenuLocation_GetInformationTextTopLeftCoordinatesToAX
FinishPreparationsToDrawTitleOrInformationArea:
	mov		dx, MenuCharOut_MenuTeletypeOutputWithAutomaticLineChange
	jmp		SHORT AdjustDisplayContextForDrawingTextsAtCoordsInAXwithAttrTypeInSIandCharOutFunctionInDX


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
	push	ax

	xchg	cx, ax
	call	MenuScrollbars_IsItemInCXonVisiblePage
	jnc		SHORT .InvalidItem
	call	MenuText_AdjustDisplayContextForDrawingItemFromCX
	call	ClearPreviousItem
	call	MenuEvent_RefreshItemFromCX
	call	DrawScrollbarCharacterForItemInCXifNecessary
.InvalidItem:
	pop		ax
	pop		cx
	ret

;--------------------------------------------------------------------
; MenuText_AdjustDisplayContextForDrawingItemFromCX
;	Parameters
;		CX:		Item to refresh
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuText_AdjustDisplayContextForDrawingItemFromCX:
	mov		ax, cx
	call	GetItemTextAttributeTypeToSIforItemInCX
	call	MenuLocation_GetTextCoordinatesToAXforItemInAX
	mov		dx, MenuCharOut_MenuTeletypeOutput
	; Fall to AdjustDisplayContextForDrawingTextsAtCoordinatesInAXwithAttributeTypeInSI

;--------------------------------------------------------------------
; AdjustDisplayContextForDrawingTextsAtCoordsInAXwithAttrTypeInSIandCharOutFunctionInDX
;	Parameters
;		AX:		Cursor coordinates to set
;		DX:		Character output function
;		SI:		Attribute type (from ATTRIBUTE_CHARS)
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AdjustDisplayContextForDrawingTextsAtCoordsInAXwithAttrTypeInSIandCharOutFunctionInDX:
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX

	xchg	ax, dx
	mov		bl, ATTRIBUTES_ARE_USED
	CALL_DISPLAY_LIBRARY SetCharOutputFunctionFromAXwithAttribFlagInBL

	call	CharOutLineSplitter_PrepareForPrintingTextLines
	jmp		MenuAttribute_SetToDisplayContextFromTypeInSI


;--------------------------------------------------------------------
; ClearPreviousItem
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ClearPreviousItem:
	CALL_DISPLAY_LIBRARY GetSoftwareCoordinatesToAX
	xchg	bx, ax

	call	MenuBorders_GetNumberOfMiddleCharactersToDX
	sub		dx, BYTE MENU_TEXT_COLUMN_OFFSET
	mov		al, [cs:g_rgbTextBorderCharacters+BORDER_CHARS.cMiddle]
	call	MenuBorders_PrintMultipleBorderCharactersFromAL

	xchg	ax, bx
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	ret


;--------------------------------------------------------------------
; GetItemTextAttributeTypeToSIforItemInCX
;	Parameters
;		CX:		Item to refresh
;		SS:BP:	Ptr to MENU
;	Returns:
;		SI:		Text attribute type (ATTRIBUTE_CHARS)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetItemTextAttributeTypeToSIforItemInCX:
	mov		si, ATTRIBUTE_CHARS.cItem
	test	BYTE [bp+MENU.bFlags], FLG_MENU_NOHIGHLIGHT
	jnz		SHORT .ReturnAttributeTypeInSI

	cmp		cx, [bp+MENUINIT.wHighlightedItem]
	jne		SHORT .ReturnAttributeTypeInSI
	sub		si, BYTE ATTRIBUTE_CHARS.cItem - ATTRIBUTE_CHARS.cHighlightedItem
ALIGN JUMP_ALIGN, ret
.ReturnAttributeTypeInSI:
	ret


;--------------------------------------------------------------------
; DrawScrollbarCharacterForItemInCXifNecessary
;	Parameters
;		CX:		Item to refresh
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrawScrollbarCharacterForItemInCXifNecessary:
	call	MenuScrollbars_AreScrollbarsNeeded
	jc		SHORT .DrawScrollbarCharacter
	ret

ALIGN JUMP_ALIGN
.DrawScrollbarCharacter:
	call	MenuBorders_AdjustDisplayContextForDrawingBorders
	mov		ax, cx

	call	MenuLocation_GetTextCoordinatesToAXforItemInAX
	add		al, [bp+MENUINIT.bWidth]
	sub		al, MENU_TEXT_COLUMN_OFFSET*2
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX

	mov		di, cx
	sub		di, [bp+MENU.wFirstVisibleItem]		; Item to line
	call	MenuScrollbars_GetScrollCharacterToALForLineInDI
	jmp		MenuBorders_PrintSingleBorderCharacterFromAL
