; Project name	:	Assembly Library
; Description	:	Functions to operate with
;					8254 Programmable Interval Timer.

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
; 4. Call SystemTimer_ReadNanosecsToDXAXfromPreciseEventTimer to get event duration
;
; SystemTimer_ReadNanosecsToDXAXfromPreciseEventTimer
;	Parameters:
;		Nothing
;	Returns:
;		DX:AX:	Event duration in nanosecs
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SystemTimer_ReadNanosecsToDXAXfromPreciseEventTimer:
	OUTPUT_COUNTER_COMMAND_TO TIMER_2, LATCH, MODE_0_SINGLE_TIMEOUT, BINARY_COUNTER
	READ_COUNT_TO_AX_FROM TIMER_2
	neg		ax					; 0 - count (Mode 0 counts toward zero)
	mov		dx, TIMER_CYCLE_TIME
	mul		dx
	ret
