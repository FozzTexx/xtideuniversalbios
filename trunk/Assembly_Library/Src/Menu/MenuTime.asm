; File name		:	MenuTime.asm
; Project name	:	Assembly Library
; Created date	:	25.7.2010
; Last update	:	28.9.2010
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
	push	ds

	call	MenuTime_DrawWithoutUpdating
	jnc		SHORT .TimeoutDisabled
	call	PointDSBXtoTimeoutCounter
	call	TimerTicks_SetCarryIfTimeoutFromDSBX

ALIGN JUMP_ALIGN
.TimeoutDisabled:
	pop		ds
	ret

;--------------------------------------------------------------------
; MenuTime_DrawWithoutUpdating
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		CF:		Set if timeout enabled
;				Cleared if timeout disabled
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuTime_DrawWithoutUpdating:
	cmp		WORD [bp+MENUINIT.wTimeoutTicks], BYTE 0
	je		SHORT .ReturnSinceTimeoutDisabled	; Clear CF

	push	ds
	call	GetSecondsLeftUntilTimeoutToAXandCounterToDSBX
	call	DrawTimeoutInAXoverMenuBorders
	pop		ds
	stc
ALIGN JUMP_ALIGN, ret
.ReturnSinceTimeoutDisabled:
	ret


;--------------------------------------------------------------------
; GetSecondsLeftUntilTimeoutToAXandCounterToDSBX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Seconds until timeout
;		DS:BX:	Ptr to timeout counter
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetSecondsLeftUntilTimeoutToAXandCounterToDSBX:
	call	PointDSBXtoTimeoutCounter
	call	TimerTicks_GetElapsedToAXfromDSBX
	neg		ax			; Negate since DS:BX points to end time
	MAX_S	ax, 0		; Set to zero if overflow
	xchg	dx, ax
	jmp		TimerTicks_GetSecondsToAXfromTicksInDX


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
; DrawTimeoutInAXoverMenuBorders
;	Parameters
;		AX:		Seconds to draw
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrawTimeoutInAXoverMenuBorders:
	xchg	cx, ax
	call	MenuBorders_AdjustDisplayContextForDrawingBorders
	call	MenuLocation_GetBottomBordersTopLeftCoordinatesToAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	; Fall to .PrintTimeoutStringWithSecondsInDX

;--------------------------------------------------------------------
; .PrintTimeoutStringWithSecondsInDX
;	Parameters
;		CX:		Seconds to print
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
	call	.GetTimeoutAttributeToAXfromSecondsInCX
	mov		si, .szSelectionTimeout
	push	ax			; Push attribute
	push	cx			; Push seconds
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	pop		bp

	; Draw right border with normal border color
	mov		al, DOUBLE_RIGHT_HORIZONTAL_TO_SINGLE_VERTICAL
	jmp		MenuBorders_PrintSingleBorderCharacterFromAL
.szSelectionTimeout:
	db		DOUBLE_BOTTOM_LEFT_CORNER
	db		DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL
	db		"%AAutoselection in %2-us",NULL

;--------------------------------------------------------------------
; .GetTimeoutAttributeToAXfromSecondsInCX
;	Parameters
;		CX:		Seconds to print
;	Returns:
;		AX:		Attribute byte for seconds
;		CX:		Seconds to print
;	Corrupts registers:
;		SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetTimeoutAttributeToAXfromSecondsInCX:
	mov		si, ATTRIBUTE_CHARS.cNormalTimeout
	cmp		cx, BYTE 3
	ja		SHORT .GetAttributeToAX
	add		si, BYTE ATTRIBUTE_CHARS.cHurryTimeout - ATTRIBUTE_CHARS.cNormalTimeout
ALIGN JUMP_ALIGN
.GetAttributeToAX:
	jmp		MenuAttribute_GetToAXfromTypeInSI
