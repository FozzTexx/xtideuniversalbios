; File name		:	MenuBorders.asm
; Project name	:	Assembly Library
; Created date	:	14.7.2010
; Last update	:	11.10.2010
; Author		:	Tomi Tilli
; Description	:	Functions for drawing menu borders.

; Struct containing border characters for different types of menu window lines
struc BORDER_CHARS
	.cLeft		resb	1
	.cMiddle	resb	1
	.cRight		resb	1
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuBorders_RefreshAll
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN	
MenuBorders_RefreshAll:
	call	MenuBorders_AdjustDisplayContextForDrawingBorders
	call	GetNumberOfMiddleCharactersToDX
	call	RefreshTitleBorders
	call	RefreshItemBorders
	call	RefreshInformationBorders
	call	DrawBottomBorderLine
	call	DrawBottomShadowLine
	jmp		MenuTime_DrawWithoutUpdating


;--------------------------------------------------------------------
; MenuBorders_AdjustDisplayContextForDrawingBorders
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuBorders_AdjustDisplayContextForDrawingBorders:
	mov		bl, ATTRIBUTES_ARE_USED
	mov		ax, MenuCharOut_MenuTeletypeOutput
	CALL_DISPLAY_LIBRARY SetCharOutputFunctionFromAXwithAttribFlagInBL

	call	CharOutLineSplitter_GetFirstBorderLineColumnOffsetToAX
	CALL_DISPLAY_LIBRARY SetCharacterOutputParameterFromAX

	call	MenuLocation_GetTitleBordersTopLeftCoordinatesToAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX

	mov		si, ATTRIBUTE_CHARS.cBordersAndBackground
	jmp		MenuAttribute_SetToDisplayContextFromTypeInSI


;--------------------------------------------------------------------
; MenuBorders_RefreshItemBorders
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuBorders_RefreshItemBorders:
	call	MenuBorders_AdjustDisplayContextForDrawingBorders
	call	MenuLocation_GetItemBordersTopLeftCoordinatesToAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX

	call	GetNumberOfMiddleCharactersToDX
	jmp		SHORT RefreshItemBorders


;--------------------------------------------------------------------
; GetNumberOfMiddleCharactersToDX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		DX:		Number of middle border characters when drawing border lines
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetNumberOfMiddleCharactersToDX:
	eMOVZX	dx, BYTE [bp+MENUINIT.bWidth]
	sub		dx, BYTE MENU_HORIZONTAL_BORDER_LINES
	ret


;--------------------------------------------------------------------
; RefreshTitleBorders
;	Parameters
;		DX:		Number of times to repeat middle character
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RefreshTitleBorders:
	call	DrawTopBorderLine
	eMOVZX	cx, BYTE [bp+MENUINIT.bTitleLines]
	jmp		SHORT DrawTextBorderLinesByCXtimes

;--------------------------------------------------------------------
; RefreshInformationBorders
;	Parameters
;		DX:		Number of times to repeat middle character
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RefreshInformationBorders:
	call	DrawSeparationBorderLine
	eMOVZX	cx, BYTE [bp+MENUINIT.bInfoLines]
	jmp		SHORT DrawTextBorderLinesByCXtimes

;--------------------------------------------------------------------
; RefreshItemBorders
;	Parameters
;		DX:		Number of times to repeat middle character
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RefreshItemBorders:
	call	DrawSeparationBorderLine
	call	MenuScrollbars_GetMaxVisibleItemsOnPageToCX
DrawTextBorderLinesByCXtimes:
	mov		bx, DrawTextBorderLine
	; Fall to DrawBorderLinesByCXtimes

;--------------------------------------------------------------------
; DrawBorderLinesByCXtimes
;	Parameters
;		BX:		Offset to border drawing function
;		CX:		Number of border lines to draw
;		DX:		Number of times to repeat middle character
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, SI, DI
;--------------------------------------------------------------------
DrawBorderLinesByCXtimes:
	jcxz	.Return
ALIGN JUMP_ALIGN
.DrawBordersWithFunctionInBX:
	call	bx
	loop	.DrawBordersWithFunctionInBX
.Return:
	ret


;--------------------------------------------------------------------
; DrawTopBorderLine
; DrawSeparationBorderLine
; DrawBottomBorderLine
; DrawBottomShadowLine
; DrawTextBorderLine
;	Parameters
;		DX:		Number of times to repeat middle character
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrawTopBorderLine:
	mov		si, g_rgbTopBorderCharacters
	call	PrintBorderCharactersFromCSSI
	jmp		SHORT PrintNewlineToEndBorderLine

ALIGN JUMP_ALIGN
DrawSeparationBorderLine:
	mov		si, g_rgbSeparationBorderCharacters
	jmp		SHORT PrintBorderCharactersFromCSSIandShadowCharacter

ALIGN JUMP_ALIGN
DrawBottomBorderLine:
	mov		si, g_rgbBottomBorderCharacters
	jmp		SHORT PrintBorderCharactersFromCSSIandShadowCharacter

ALIGN JUMP_ALIGN
DrawBottomShadowLine:
	CALL_DISPLAY_LIBRARY GetSoftwareCoordinatesToAX
	inc		ax			; Increment column
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	inc		dx			; Increment repeat count...
	inc		dx			; ...for both corner characters
	call	PrintShadowCharactersByDXtimes
	dec		dx			; Restore...
	dec		dx			; ...DX
	ret

ALIGN JUMP_ALIGN
DrawTextBorderLine:
	mov		si, g_rgbTextBorderCharacters
	; Fall to PrintBorderCharactersFromCSSIandShadowCharacter

;--------------------------------------------------------------------
; PrintBorderCharactersFromCSSIandShadowCharacter
;	Parameters
;		DX:		Number of times to repeat middle character
;		CS:SI:	Ptr to BORDER_CHARS
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrintBorderCharactersFromCSSIandShadowCharacter:
	call	PrintBorderCharactersFromCSSI
	push	dx
	mov		dx, 1
	call	PrintShadowCharactersByDXtimes
	pop		dx
	; Fall to PrintNewlineToEndBorderLine

;--------------------------------------------------------------------
; PrintNewlineToEndBorderLine
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrintNewlineToEndBorderLine:
	CALL_DISPLAY_LIBRARY PrintNewlineCharacters
	ret


;--------------------------------------------------------------------
; PrintShadowCharactersByDXtimes
;	Parameters
;		DX:		Number of shadow characters to print
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrintShadowCharactersByDXtimes:
	CALL_DISPLAY_LIBRARY PushDisplayContext

	mov		si, ATTRIBUTE_CHARS.cShadow
	call	MenuAttribute_SetToDisplayContextFromTypeInSI

	push	bx
	mov		bl, ATTRIBUTES_ARE_USED
	mov		ax, FAST_OUTPUT_WITH_ATTRIBUTE_ONLY
	CALL_DISPLAY_LIBRARY SetCharOutputFunctionFromAXwithAttribFlagInBL
	pop		bx

	call	PrintMultipleBorderCharactersFromAL	; AL does not matter

	CALL_DISPLAY_LIBRARY PopDisplayContext
	ret


;--------------------------------------------------------------------
; PrintBorderCharactersFromCSSI
;	Parameters
;		DX:		Number of times to repeat middle character
;		CS:SI:	Ptr to BORDER_CHARS
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrintBorderCharactersFromCSSI:
	cld
	eSEG	cs
	lodsb			; Load from [si+BORDER_CHARS.cLeft] to AL
	call	MenuBorders_PrintSingleBorderCharacterFromAL

	eSEG	cs
	lodsb			; Load from [si+BORDER_CHARS.cMiddle] to AL
	call	PrintMultipleBorderCharactersFromAL

	eSEG	cs
	lodsb			; Load from [si+BORDER_CHARS.cRight] to AL
	; Fall to MenuBorders_PrintSingleBorderCharacterFromAL

;--------------------------------------------------------------------
; MenuBorders_PrintSingleBorderCharacterFromAL
; PrintMultipleBorderCharactersFromAL
;	Parameters
;		AL:		Character to print
;		DX:		Repeat count (PrintMultipleBorderCharactersFromAL)
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuBorders_PrintSingleBorderCharacterFromAL:
	CALL_DISPLAY_LIBRARY PrintCharacterFromAL
	ret

ALIGN JUMP_ALIGN
PrintMultipleBorderCharactersFromAL:
	push	cx
	mov		cx, dx
	CALL_DISPLAY_LIBRARY PrintRepeatedCharacterFromALwithCountInCX
	pop		cx
	ret



; Lookup tables for border characters
g_rgbTopBorderCharacters:
istruc BORDER_CHARS
	at	BORDER_CHARS.cLeft,		db	DOUBLE_TOP_LEFT_CORNER
	at	BORDER_CHARS.cMiddle,	db	DOUBLE_HORIZONTAL
	at	BORDER_CHARS.cRight,	db	DOUBLE_TOP_RIGHT_CORNER
iend

g_rgbSeparationBorderCharacters:
istruc BORDER_CHARS
	at	BORDER_CHARS.cLeft,		db	DOUBLE_VERTICAL_TO_RIGHT_SINGLE
	at	BORDER_CHARS.cMiddle,	db	SINGLE_HORIZONTAL
	at	BORDER_CHARS.cRight,	db	DOUBLE_VERTICAL_TO_LEFT_SINGLE
iend

g_rgbBottomBorderCharacters:
istruc BORDER_CHARS
	at	BORDER_CHARS.cLeft,		db	DOUBLE_BOTTOM_LEFT_CORNER
	at	BORDER_CHARS.cMiddle,	db	DOUBLE_HORIZONTAL
	at	BORDER_CHARS.cRight,	db	DOUBLE_BOTTOM_RIGHT_CORNER
iend

g_rgbTextBorderCharacters:
istruc BORDER_CHARS
	at	BORDER_CHARS.cLeft,		db	DOUBLE_VERTICAL
	at	BORDER_CHARS.cMiddle,	db	' '
	at	BORDER_CHARS.cRight,	db	DOUBLE_VERTICAL
iend
