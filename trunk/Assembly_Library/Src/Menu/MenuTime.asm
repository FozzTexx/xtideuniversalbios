; Project name	:	Assembly Library
; Description	:	Menu timeouts other time related functions.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;


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
%ifndef EXCLUDE_FROM_XTIDECFG
ALIGN MENU_JUMP_ALIGN
MenuTime_StartSelectionTimeoutWithTicksInAX:
	push	ds
	call	PointDSBXtoTimeoutCounter
	call	TimerTicks_InitializeTimeoutFromAX
	or		BYTE [bp+MENU.bFlags], FLG_MENU_TIMEOUT_COUNTDOWN
	pop		ds
	ret
%endif


;--------------------------------------------------------------------
; MenuTime_StopSelectionTimeout
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
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
ALIGN MENU_JUMP_ALIGN
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

ALIGN MENU_JUMP_ALIGN
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
;		Nothing
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
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
	SKIP2B	dx
.TimeoutHasOccurredSoMakeSureTicksAreNotBelowZero:
	xor		ax, ax

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
ALIGN MENU_JUMP_ALIGN
PointDSBXtoTimeoutCounter:
	push	ss
	pop		ds
	lea		bx, [bp+MENU.wTimeoutCounter]
	ret
