; File name		:	Delay.asm
; Project name	:	Assembly Library
; Created date	:	24.7.2010
; Last update	:	16.9.2010
; Author		:	Tomi Tilli
; Description	:	Delay functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Mimimun delays (without fetching) with some CPU architectures:
;	8088/8086:	17 cycles for jump + 5 cycles for last comparison
;	286:		10 cycles for jump + 4 cycles for last comparison
;	386:		13 cycles for jump + ? cycles for last comparison
;	486:		 7 cycles for jump + 6 cycles for last comparison
;
; DELAY_WITH_LOOP_INSTRUCTION
;	Parameters
;		CX:		Loop iterations (0 is maximum delay with 65536 iterations)
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
%macro DELAY_WITH_LOOP_INSTRUCTION 0
%%StartOfLoop:
	loop	%%StartOfLoop
%endmacro


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

	xchg	dx, ax
	call	TimerTicks_ReadFromBdaToAX
	add		dx, ax				; DX = end time
	sti							; Make sure that interrupts are enabled
.WaitLoop:
	call	TimerTicks_ReadFromBdaToAX
	cmp		ax, dx
	jb		SHORT .WaitLoop		; Loop until end time is reached

	pop		dx
	ret
