; File name		:	MenuText.asm
; Project name	:	Assembly Library
; Created date	:	21.7.2010
; Last update	:	7.10.2010
; Author		:	Tomi Tilli
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
	call	PrepareToDrawTitleArea
	mov		cl, [bp+MENUINIT.bTitleLines]
	jmp		SHORT ClearCLlinesOfText

ALIGN JUMP_ALIGN
MenuText_ClearInformationArea:
	call	PrepareToDrawInformationArea
	mov		cl, [bp+MENUINIT.bInfoLines]
ClearCLlinesOfText:
	mov		al, [bp+MENUINIT.bWidth]
	sub		al, MENU_HORIZONTAL_BORDER_LINES+MENU_TEXT_COLUMN_OFFSET
	mul		cl
	xchg	cx, ax
	mov		al, ' '
	CALL_DISPLAY_LIBRARY PrintRepeatedCharacterFromALwithCountInCX
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
	call	PrepareToDrawInformationArea
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
	mov		ax, MenuCharOut_MenuTextTeletypeOutputWithAttributeAndAutomaticLineChange
	call	AdjustDisplayContextForDrawingTextsWithCharOutFunctionFromAX
	call	MenuLocation_GetTitleTextTopLeftCoordinatesToAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	ret

ALIGN JUMP_ALIGN
PrepareToDrawInformationArea:
	mov		si, ATTRIBUTE_CHARS.cInformation
	mov		ax, MenuCharOut_MenuTextTeletypeOutputWithAttributeAndAutomaticLineChange
	call	AdjustDisplayContextForDrawingTextsWithCharOutFunctionFromAX
	call	MenuLocation_GetInformationTextTopLeftCoordinatesToAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	ret


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
	mov		ax, MenuCharOut_MenuTextTeletypeOutputWithAttribute
	jmp		SHORT AdjustDisplayContextForDrawingTextsWithCharOutFunctionFromAX

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
;		AX, BX, DX, SI, DI
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
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.DrawScrollbarCharacter:
	push	cx

	call	MenuBorders_AdjustDisplayContextForDrawingBorders

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
; AdjustDisplayContextForDrawingTextsWithCharOutFunctionFromAX
;	Parameters
;		AX:		Character output function
;		SI:		Attribute type (from ATTRIBUTE_CHARS)
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AdjustDisplayContextForDrawingTextsWithCharOutFunctionFromAX:
	mov		bl, ATTRIBUTES_ARE_USED
	CALL_DISPLAY_LIBRARY SetCharOutputFunctionFromAXwithAttribFlagInBL

	mov		ax, bp
	CALL_DISPLAY_LIBRARY SetCharacterOutputParameterFromAX

	jmp		MenuAttribute_SetToDisplayContextFromTypeInSI
