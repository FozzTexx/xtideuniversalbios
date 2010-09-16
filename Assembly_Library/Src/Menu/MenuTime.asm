; File name		:	MenuTime.asm
; Project name	:	Assembly Library
; Created date	:	25.7.2010
; Last update	:	13.8.2010
; Author		:	Tomi Tilli
; Description	:	Menu timeouts other time related functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuTime_SetSelectionTimeoutValueFromAX
;	Parameters
;		AX:		Selection timeout in system timer ticks
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuTime_SetSelectionTimeoutValueFromAX:
	mov		[bp+MENUINIT.wTimeoutTicks], ax
	ret


;--------------------------------------------------------------------
; MenuTime_RestartSelectionTimeout
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuTime_RestartSelectionTimeout:
	push	ds
	call	PointDSBXtoTimeoutCounter
	mov		ax, [bp+MENUINIT.wTimeoutTicks]
	call	TimerTicks_InitializeTimeoutFromAX	; End time to [DS:BX]
	pop		ds
	ret


;--------------------------------------------------------------------
; MenuTime_UpdateSelectionTimeout
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		CF:		Set if timeout
;				Cleared if time left
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuTime_UpdateSelectionTimeout:
	cmp		WORD [bp+MENUINIT.wTimeoutTicks], BYTE 0
	je		SHORT .ReturnSinceTimeoutDisabled	; CF cleared
	push	ds

	call	GetSecondsUntilTimeoutToAXandPtrToTimeoutCounterToDSBX
	cmp		al, [bp+MENU.bLastSecondPrinted]
	je		SHORT .SetCFifTimeoutAndReturn
	mov		[bp+MENU.bLastSecondPrinted], al
	call	DrawTimeoutInAXoverMenuBorders

ALIGN JUMP_ALIGN
.SetCFifTimeoutAndReturn:
	call	TimerTicks_SetCarryIfTimeoutFromDSBX
	pop		ds
.ReturnSinceTimeoutDisabled:
	ret


;--------------------------------------------------------------------
; MenuTime_DrawWithoutUpdating
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuTime_DrawWithoutUpdating:
	cmp		WORD [bp+MENUINIT.wTimeoutTicks], BYTE 0
	je		SHORT .ReturnSinceTimeoutDisabled

	push	ds
	call	GetSecondsUntilTimeoutToAXandPtrToTimeoutCounterToDSBX
	call	DrawTimeoutInAXoverMenuBorders
	pop		ds
.ReturnSinceTimeoutDisabled:
	ret


;--------------------------------------------------------------------
; PointDSBXtoTimeoutCounter
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		DS:BX:	Ptr to timeout counter
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PointDSBXtoTimeoutCounter:
	push	ss
	pop		ds
	lea		bx, [bp+MENU.wTimeoutCounter]
	ret


;--------------------------------------------------------------------
; GetSecondsUntilTimeoutToAXandPtrToTimeoutCounterToDSBX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Seconds until timeout
;		DS:BX:	Ptr to timeout counter
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetSecondsUntilTimeoutToAXandPtrToTimeoutCounterToDSBX:
	call	PointDSBXtoTimeoutCounter
	call	TimerTicks_GetElapsedToAXfromDSBX
	neg		ax			; Negate since DS:BX points to end time
	MAX_S	ax, 0		; Set to zero if overflow
	xchg	dx, ax
	jmp		TimerTicks_GetSecondsToAXfromTicksInDX


;--------------------------------------------------------------------
; DrawTimeoutInAXoverMenuBorders
;	Parameters
;		AX:		Seconds to draw
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrawTimeoutInAXoverMenuBorders:
	xchg	dx, ax
	call	MenuBorders_AdjustDisplayContextForDrawingBorders
	call	MenuLocation_GetBottomBordersTopLeftCoordinatesToAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	; Fall to .PrintTimeoutStringWithSecondsInDX

;--------------------------------------------------------------------
; .PrintTimeoutStringWithSecondsInDX
;	Parameters
;		DX:		Seconds to print
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI, DI
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
.PrintTimeoutStringWithSecondsInDX:
	push	bp

	mov		bp, sp
	call	.GetTimeoutAttributeToAXfromSecondsInDX
	mov		si, .szSelectionTimeout
	push	ax			; Push attribute
	push	dx			; Push seconds
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	pop		bp

	mov		al, DOUBLE_RIGHT_HORIZONTAL_TO_SINGLE_VERTICAL
	jmp		MenuBorders_PrintSingleBorderCharacterFromAL
.szSelectionTimeout:
	db		DOUBLE_BOTTOM_LEFT_CORNER
	db		DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL
	db		"%AAutoselection in %2ds",NULL

;--------------------------------------------------------------------
; .GetTimeoutAttributeToAXfromSecondsInDX
;	Parameters
;		DX:		Seconds to print
;	Returns:
;		AX:		Attribute byte for seconds
;		DX:		Seconds to print
;	Corrupts registers:
;		SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetTimeoutAttributeToAXfromSecondsInDX:
	mov		si, ATTRIBUTE_CHARS.cNormalTimeout
	cmp		dx, BYTE 3
	ja		SHORT .GetAttributeToAX
	add		si, BYTE ATTRIBUTE_CHARS.cHurryTimeout - ATTRIBUTE_CHARS.cNormalTimeout
ALIGN JUMP_ALIGN
.GetAttributeToAX:
	jmp		MenuAttribute_GetToAXfromTypeInSI
