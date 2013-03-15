; Project name	:	Assembly Library
; Description	:	Functions to operate with
;					8254 Programmable Interval Timer.

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
; SystemTimer_IntializePreciseEventTimer
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SystemTimer_IntializePreciseEventTimer:
	STOP_PRECISE_EVENT_TIMER
	OUTPUT_COUNTER_COMMAND_TO TIMER_2, READ_OR_WRITE_LSB_THEN_MSB, MODE_0_SINGLE_TIMEOUT, BINARY_COUNTER
	xor		ax, ax
	WRITE_COUNT_FROM_AX_TO TIMER_2
	ret


;--------------------------------------------------------------------
; This is how to use precise event timer:
; 1. Call SystemTimer_IntializePreciseEventTimer
; 2. Use START_PRECISE_EVENT_TIMER macro to start timer
; 3. Use STOP_PRECISE_EVENT_TIMER to stop timer (optional)
; 4. Call SystemTimer_GetPreciseEventTimerTicksToAX to get event duration
;
; SystemTimer_GetPreciseEventTimerTicksToAX
;	Parameters:
;		Nothing
;	Returns:
;		AX:		Event duration in timer ticks
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SystemTimer_GetPreciseEventTimerTicksToAX:
	OUTPUT_COUNTER_COMMAND_TO TIMER_2, LATCH, MODE_0_SINGLE_TIMEOUT, BINARY_COUNTER
	READ_COUNT_TO_AX_FROM TIMER_2
	neg		ax					; 0 - count (Mode 0 counts toward zero)
	ret
