; Project name	:	Assembly Library
; Description	:	Menu timeouts other time related functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuTime_StartSelectionTimeoutWithTicksInAX
;	Parameters
;		AX:		Timeout ticks
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuTime_StartSelectionTimeoutWithTicksInAX:
	push	ds
	call	PointDSBXtoTimeoutCounter
	call	TimerTicks_InitializeTimeoutFromAX
	or		BYTE [bp+MENU.bFlags], FLG_MENU_TIMEOUT_COUNTDOWN
	pop		ds
	ret


;--------------------------------------------------------------------
; MenuTime_StopSelectionTimeout
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuTime_StopSelectionTimeout:
	test	BYTE [bp+MENU.bFlags], FLG_MENU_TIMEOUT_COUNTDOWN
	jz		SHORT TimeoutAlreadyStopped
	and		BYTE [bp+MENU.bFlags], ~FLG_MENU_TIMEOUT_COUNTDOWN
	jmp		MenuBorders_RedrawBottomBorderLine


;--------------------------------------------------------------------
; MenuTime_UpdateSelectionTimeout
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		CF:		Set if timeout
;				Cleared if time left
;	Corrupts registers:
;		AX, BX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuTime_UpdateSelectionTimeout:
	test	BYTE [bp+MENU.bFlags], FLG_MENU_TIMEOUT_COUNTDOWN
	jz		SHORT .ReturnSinceTimeoutDisabled

	push	ds
	call	PointDSBXtoTimeoutCounter
	call	TimerTicks_GetTimeoutTicksLeftToAXfromDSBX
	pop		ds
	jnc		SHORT .RedrawSinceNoTimeout
	and		BYTE [bp+MENU.bFlags], ~FLG_MENU_TIMEOUT_COUNTDOWN
	stc
	ret

ALIGN JUMP_ALIGN
.RedrawSinceNoTimeout:
	call	MenuBorders_RedrawBottomBorderLine
	clc
.ReturnSinceTimeoutDisabled:
TimeoutAlreadyStopped:
	ret


;--------------------------------------------------------------------
; MenuTime_GetTimeoutSecondsLeftToAX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Seconds until timeout
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuTime_GetTimeoutSecondsLeftToAX:
	push	ds
	push	dx
	push	cx
	push	bx

	call	PointDSBXtoTimeoutCounter
	call	TimerTicks_GetTimeoutTicksLeftToAXfromDSBX
	jc		SHORT .TimeoutHasOccurredSoMakeSureTicksAreNotBelowZero

	xchg	dx, ax
	call	TimerTicks_GetSecondsToAXfromTicksInDX
	jmp		SHORT .PopRegistersAndReturn
.TimeoutHasOccurredSoMakeSureTicksAreNotBelowZero:
	xor		ax, ax
.PopRegistersAndReturn:
	pop		bx
	pop		cx
	pop		dx
	pop		ds
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
