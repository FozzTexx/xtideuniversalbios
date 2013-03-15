; Project name	:	XTIDE Universal BIOS
; Description	:	Timeout and delay functions for INT 13h services.

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
; Timer_InitializeTimeoutWithTicksInCL
;	Parameters:
;		CL:		Timeout value in system timer ticks
;		DS:		Segment to RAMVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Timer_InitializeTimeoutWithTicksInCL:
	mov		[RAMVARS.bTimeoutTicksLeft], cl		; Ticks until timeout
	call	ReadTimeFromBdaToCX
	mov		[RAMVARS.bLastTimeoutUpdate], cl	; Start time
	ret


;--------------------------------------------------------------------
; Timer_SetCFifTimeout
;	Parameters:
;		DS:		Segment to RAMVARS
;	Returns:
;		CF:		Set if timeout
;				Cleared if time left
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Timer_SetCFifTimeout:
	call	ReadTimeFromBdaToCX
	cmp		cl, [RAMVARS.bLastTimeoutUpdate]
	je		SHORT .StillPollingTheSameTick
	mov		[RAMVARS.bLastTimeoutUpdate], cl
	sub		BYTE [RAMVARS.bTimeoutTicksLeft], 1	; DEC does not update CF
.StillPollingTheSameTick:
	ret


;--------------------------------------------------------------------
; Delay is always at least one millisecond since
; RTC resolution is 977 microsecs.
;
; Timer_DelayMicrosecondsFromAX
;	Parameters:
;		AX:		Number of microsecs to wait
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
Timer_DelayMicrosecondsFromAX:
%ifndef USE_AT
	mov		ax, 2
	; Fall to Timer_DelayTimerTicksFromAX
%else
	push	dx
	push	cx

	xor		cx, cx
	xchg	dx, ax						; Microsecs now in CX:DX
	mov		ah, EVENT_WAIT
	int		BIOS_SYSTEM_INTERRUPT_15h
	sti									; XT BIOSes return with interrupts disabled. TODO: Maybe we can remove this since it's in an AT-only block?

	pop		cx
	pop		dx
	mov		ax, 1								; Prepare to wait 1 timer tick
	jc		SHORT Timer_DelayTimerTicksFromAX	; Event Wait was unsupported or busy
	ret
%endif


;--------------------------------------------------------------------
; First tick might take 0...54.9 ms and remaining ticks
; will occur at 54.9 ms intervals.
;
; Timer_DelayTimerTicksFromAX
;	Parameters:
;		AX:		Number of timer ticks to wait
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
Timer_DelayTimerTicksFromAX:
	sti								; Make sure that interrupts are enabled
	call	ReadTimeFromBdaToCX
	add		ax, cx					; AX = end time
.WaitLoop:
	call	ReadTimeFromBdaToCX
	cmp		cx, ax
	jne		SHORT .WaitLoop			; Loop until end time is reached
	ret


;--------------------------------------------------------------------
; ReadTimeFromBdaToCX
;	Parameters
;		Nothing
;	Returns:
;		CX:		System time in 54.9 ms ticks
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadTimeFromBdaToCX:
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, cx
	mov		cx, [BDA.dwTimerTicks]	; Read low WORD only
	pop		ds
	ret
