; Project name	:	Assembly Library
; Description	:	Delay functions.

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
