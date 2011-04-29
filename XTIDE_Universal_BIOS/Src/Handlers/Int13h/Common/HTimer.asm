; Project name	:	XTIDE Universal BIOS
; Description	:	Timeout and delay functions for INT 13h services.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; HTimer_InitializeTimeoutWithTicksInCX
;	Parameters:
;		CX:		Timeout value in system timer ticks
;		DS:		Segment to RAMVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HTimer_InitializeTimeoutWithTicksInCX:
	mov		[RAMVARS.wTimeoutCounter], cx	; Store timeout ticks
	call	ReadTimeFromBdaToCX
	add		[RAMVARS.wTimeoutCounter], cx	; End time for timeout
	ret


;--------------------------------------------------------------------
; HTimer_SetCFifTimeout
;	Parameters:
;		DS:		Segment to RAMVARS
;	Returns:
;		CF:		Set if timeout
;				Cleared if time left
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HTimer_SetCFifTimeout:
	call	ReadTimeFromBdaToCX
	cmp		[RAMVARS.wTimeoutCounter], cx
	ret


;--------------------------------------------------------------------
; Delay is always at least one millisecond since
; RTC resolution is 977 microsecs.
;
; HTimer_DelayMicrosecondsFromAX
;	Parameters:
;		AX:		Number of microsecs to wait
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
HTimer_DelayMicrosecondsFromAX:
%ifndef USE_AT
	mov		ax, 2
	; Fall to Delay_TimerTicksFromAX
%else
	push	dx
	push	cx

	xor		cx, cx
	xchg	dx, ax						; Microsecs now in CX:DX
	mov		ah, EVENT_WAIT
	int		BIOS_SYSTEM_INTERRUPT_15h
	sti									; XT BIOSes return with interrupt disabled

	pop		cx
	pop		dx
	mov		ax, 1								; Prepare to wait 1 timer tick
	jc		SHORT HTimer_DelayTimerTicksFromAX	; Event Wait was unsupported or busy
	ret
%endif


;--------------------------------------------------------------------
; First tick might take 0...54.9 ms and remaining ticks
; will occur at 54.9 ms intervals.
;
; HTimer_DelayTimerTicksFromAX
;	Parameters:
;		AX:		Number of timer ticks to wait
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
HTimer_DelayTimerTicksFromAX:
	sti								; Make sure that interrupts are enabled
	call	ReadTimeFromBdaToCX
	add		ax, cx					; AX = end time
.WaitLoop:
	call	ReadTimeFromBdaToCX
	cmp		cx, ax
	jb		SHORT .WaitLoop			; Loop until end time is reached
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
