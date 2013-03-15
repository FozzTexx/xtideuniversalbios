; Project name	:	Assembly Library
; Description	:	Functions for system timer related operations.

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

; With a PIT input clock of 1193181.6666... Hz and a maximum
; 16 bit divisor of 65536 (if PIT programmed with 0) we get:
;
; Clock / Divisor = ~18.2065 ticks per second
; Clock * SecondsPerMinute / Divisor = ~1092 ticks per minute
; Clock * SecondsPerHour / Divisor = ~65543 ticks per hour
;
; Since 65543 can't fit in a 16 bit register we use the
; maximum possible instead and disregard the last ~8 ticks.

TICKS_PER_HOUR			EQU		65535
TICKS_PER_MINUTE		EQU		1092
TICKS_PER_SECOND		EQU		18


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; TimerTicks_GetHoursToAXandRemainderTicksToDXfromTicksInDXAX
; TimerTicks_GetMinutesToAXandRemainderTicksToDXfromTicksInDX
; TimerTicks_GetSecondsToAXandRemainderTicksToDXfromTicksInDX
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
TimerTicks_GetHoursToAXandRemainderTicksToDXfromTicksInDXAX:
	mov		cx, TICKS_PER_HOUR
	div		cx		; Divide DX:AX by CX, Hours to AX, remainder ticks to DX
	ret
%endif ; EXCLUDE_FROM_XTIDECFG

ALIGN JUMP_ALIGN
TimerTicks_GetMinutesToAXandRemainderTicksToDXfromTicksInDX:
	xor		ax, ax
	xchg	ax, dx	; Ticks now in DX:AX
	mov		cx, TICKS_PER_MINUTE
	div		cx		; Divide DX:AX by CX, Minutes to AX, remainder ticks to DX
	ret
%endif ; EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS

%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS OR EXCLUDE_FROM_XTIDECFG
ALIGN JUMP_ALIGN
TimerTicks_GetSecondsToAXandRemainderTicksToDXfromTicksInDX:
	; This procedure can handle at most 4607 ticks in DX (almost 256 seconds)
	; More than 4607 ticks will generate a divide overflow exception!
	xchg	ax, dx	; Ticks now in AX
	mov		cl, TICKS_PER_SECOND
	div		cl		; Divide AX by CL, Seconds to AL, remainder ticks to AH
	xor		dx, dx
	xchg	dl, ah	; Seconds in AX, remainder in DX
	ret
%endif


%ifdef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%ifndef MODULE_BOOT_MENU
		%define EXCLUDE
	%endif
%endif
;--------------------------------------------------------------------
; TimerTicks_GetSecondsToAXfromTicksInDX
;	Parameters
;		DX:			Timer ticks to convert
;	Returns:
;		AX:			Seconds
;	Corrupts registers:
;		DX
;--------------------------------------------------------------------
%ifndef EXCLUDE	; 1 of 3
ALIGN JUMP_ALIGN
TimerTicks_GetSecondsToAXfromTicksInDX:
	mov		ax, 3600	; Approximately 65536 / (Clock / Divisor)
	mul		dx
	xchg	dx, ax
	ret
%endif


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
%ifndef EXCLUDE	; 2 of 3
ALIGN JUMP_ALIGN
TimerTicks_InitializeTimeoutFromAX:
	mov		[bx], ax					; Store timeout ticks
	call	TimerTicks_ReadFromBdaToAX
	add		[bx], ax					; [bx] now contains end time for timeout
	ret
%endif


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
%ifndef EXCLUDE	; 3 of 3
ALIGN JUMP_ALIGN
TimerTicks_GetTimeoutTicksLeftToAXfromDSBX:
	push	dx
	mov		dx, [bx]
	call	TimerTicks_ReadFromBdaToAX
	xchg	ax, dx
	sub		ax, dx		; AX = End time - current time
	pop		dx
	ret
%endif

%undef EXCLUDE


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
%ifdef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%ifndef MODULE_BOOT_MENU OR MODULE_HOTKEYS
		%define EXCLUDE
	%endif
%endif

%ifndef EXCLUDE
ALIGN JUMP_ALIGN
TimerTicks_ReadFromBdaToAX:
	push	ds

	LOAD_BDA_SEGMENT_TO	ds, ax
	mov		ax, [BDA.dwTimerTicks]	; Read low WORD only

	pop		ds
	ret
%endif
%undef EXCLUDE
