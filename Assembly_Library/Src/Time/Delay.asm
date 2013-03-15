; Project name	:	Assembly Library
; Description	:	Delay functions.

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
; Delay is always at least one millisecond since
; RTC resolution is 977 microsecs.
;
; Delay_MicrosecondsFromAX
;	Parameters:
;		AX:		Number of microsecs to wait
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Delay_MicrosecondsFromAX:
	push	dx
	push	cx

	xor		cx, cx
	xchg	dx, ax							; Microsecs now in CX:DX
	mov		ah, EVENT_WAIT					; Event Wait
	int		BIOS_SYSTEM_INTERRUPT_15h
	sti										; XT BIOSes return with interrupt disabled

	pop		cx
	pop		dx
	mov		ax, 1							; Prepare to wait 1 timer tick
	jc		SHORT Delay_TimerTicksFromAX	; Event Wait was unsupported or busy
	ret


;--------------------------------------------------------------------
; First tick might take 0...54.9 ms and remaining ticks
; will occur at 54.9 ms intervals.
;
; Delay_TimerTicksFromAX
;	Parameters:
;		AX:		Number of timer ticks to wait
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Delay_TimerTicksFromAX:
	push	dx

	sti							; Make sure that interrupts are enabled
	xchg	dx, ax
	call	TimerTicks_ReadFromBdaToAX
	add		dx, ax				; DX = end time
.WaitLoop:
	call	TimerTicks_ReadFromBdaToAX
	cmp		ax, dx
	jb		SHORT .WaitLoop		; Loop until end time is reached

	pop		dx
	ret
