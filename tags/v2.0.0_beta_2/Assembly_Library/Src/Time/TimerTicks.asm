; Project name	:	Assembly Library
; Description	:	Functions for system timer related operations.

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
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

; System timer ticks 18.2 times per second = 54.9 ms / tick
TICKS_PER_HOUR			EQU		65520
TICKS_PER_MINUTE		EQU		1092
TICKS_PER_SECOND		EQU		18


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; TimerTicks_GetHoursToAXfromTicksInDXAX
; TimerTicks_GetMinutesToAXfromTicksInDX
; TimerTicks_GetSecondsToAXfromTicksInDX
;	Parameters
;		DX(:AX):	Timer ticks to convert
;	Returns:
;		AX:			Hours, minutes or seconds
;		DX:			Remainder ticks
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
%ifndef EXCLUDE_FROM_XTIDECFG
ALIGN JUMP_ALIGN
TimerTicks_GetHoursToAXfromTicksInDXAX:
	mov		cx, TICKS_PER_HOUR
	div		cx		; Divide DX:AX by CX, Hours to AX, remainder ticks to DX
	ret
%endif ; EXCLUDE_FROM_XTIDECFG

ALIGN JUMP_ALIGN
TimerTicks_GetMinutesToAXfromTicksInDX:
	xor		ax, ax
	xchg	ax, dx	; Ticks now in DX:AX
	mov		cx, TICKS_PER_MINUTE
	div		cx		; Divide DX:AX by CX, Minutes to AX, remainder ticks to DX
	ret
%endif ; EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS

ALIGN JUMP_ALIGN
TimerTicks_GetSecondsToAXfromTicksInDX:
	xchg	ax, dx	; Ticks now in AX
	mov		cl, TICKS_PER_SECOND
	div		cl		; Divide AX by CL, Seconds to AL, remainder ticks to AH
	xor		dx, dx
	xchg	dl, ah	; Seconds in AX, remainder in DX
	ret


;--------------------------------------------------------------------
; First tick might take 0...54.9 ms and remaining ticks
; will occur at 54.9 ms intervals. Use delay of two (or more) ticks to
; ensure at least 54.9 ms timeout.
;
; TimerTicks_InitializeTimeoutFromAX
;	Parameters:
;		AX:			Timeout ticks (54.9 ms) before timeout
;		DS:BX:		Ptr to timeout variable WORD
;	Returns:
;		[DS:BX]:	Initialized for TimerTicks_SetCarryIfTimeoutFromDSBX
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
TimerTicks_InitializeTimeoutFromAX:
	mov		[bx], ax					; Store timeout ticks
	call	TimerTicks_ReadFromBdaToAX
	add		[bx], ax					; [bx] now contains end time for timeout
	ret


;--------------------------------------------------------------------
; TimerTicks_GetTimeoutTicksLeftToAXfromDSBX
;	Parameters:
;		DS:BX:		Ptr to timeout variable WORD
;	Returns:
;		AX:			Number of ticks left before timeout
;		CF:			Set if timeout
;					Cleared if time left
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
TimerTicks_GetTimeoutTicksLeftToAXfromDSBX:
	push	dx
	mov		dx, [bx]
	call	TimerTicks_ReadFromBdaToAX
	xchg	ax, dx
	sub		ax, dx		; AX = End time - current time
	pop		dx
	ret


;--------------------------------------------------------------------
; TimerTicks_GetElapsedToAXandResetDSBX
;	Parameters
;		DS:BX:		Ptr to WORD containing previous reset time
;	Returns:
;		AX:			54.9 ms ticks elapsed since last reset
;		[DS:BX]:	Reset to latest time
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN JUMP_ALIGN
TimerTicks_GetElapsedToAXandResetDSBX:
	call	TimerTicks_ReadFromBdaToAX
	push	ax
	sub		ax, [bx]
	pop		WORD [bx]			; Latest time to [DS:BX]
	ret
%endif

;--------------------------------------------------------------------
; TimerTicks_GetElapsedToAXfromDSBX
;	Parameters
;		DS:BX:		Ptr to WORD containing previous update time
;	Returns:
;		AX:			54.9 ms ticks elapsed since initializing [DS:BX]
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN JUMP_ALIGN
TimerTicks_GetElapsedToAXfromDSBX:
	call	TimerTicks_ReadFromBdaToAX
	sub		ax, [bx]
	ret
%endif


;--------------------------------------------------------------------
; TimerTicks_ReadFromBdaToAX
;	Parameters
;		Nothing
;	Returns:
;		AX:		System time in 54.9 ms ticks
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
TimerTicks_ReadFromBdaToAX:
	push	ds

	LOAD_BDA_SEGMENT_TO	ds, ax
	mov		ax, [BDA.dwTimerTicks]	; Read low WORD only

	pop		ds
	ret
