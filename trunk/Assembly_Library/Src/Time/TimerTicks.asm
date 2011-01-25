; File name		:	TimerTicks.asm
; Project name	:	Assembly Library
; Created date	:	24.7.2010
; Last update	:	22.11.2010
; Author		:	Tomi Tilli
; Description	:	Functions for system timer related operations.

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
ALIGN JUMP_ALIGN
TimerTicks_GetHoursToAXfromTicksInDXAX:
	mov		cx, TICKS_PER_HOUR
	div		cx		; Divide DX:AX by CX, Hours to AX, remainder ticks to DX
	ret

ALIGN JUMP_ALIGN
TimerTicks_GetMinutesToAXfromTicksInDX:
	xor		ax, ax
	xchg	ax, dx	; Ticks now in DX:AX
	mov		cx, TICKS_PER_MINUTE
	div		cx		; Divide DX:AX by CX, Minutes to AX, remainder ticks to DX
	ret

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
	add		[bx], ax					; Add latest time to timeout ticks
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
ALIGN JUMP_ALIGN
TimerTicks_GetElapsedToAXandResetDSBX:
	call	TimerTicks_ReadFromBdaToAX
	push	ax
	sub		ax, [bx]
	pop		WORD [bx]			; Latest time to [DS:BX]
	ret

;--------------------------------------------------------------------
; TimerTicks_GetElapsedToAXfromDSBX
;	Parameters
;		DS:BX:		Ptr to WORD containing previous update time
;	Returns:
;		AX:			54.9 ms ticks elapsed since initializing [DS:BX]
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
TimerTicks_GetElapsedToAXfromDSBX:
	call	TimerTicks_ReadFromBdaToAX
	sub		ax, [bx]
	ret


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
