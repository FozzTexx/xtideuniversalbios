; File name		:	SoftDelay.asm
; Project name	:	IDE BIOS
; Created date	:	22.9.2007
; Last update	:	13.4.2010
; Author		:	Tomi Tilli
; Description	:	Software delay loops for I/O timeout and other loops.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; There should be at least 400ns delay between outputting
; IDE command / drive selection and reading IDE Status Register.
;
; SoftDelay_BeforePollingStatusRegister
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN						; Cycles required
SoftDelay_BeforePollingStatusRegister:	; 8088 | 286 | 386 | 486
	push	cx							;   15 |   3 |   2 |   1
	mov		cx, 2						;    4 |   2 |   2 |   1
.DelayLoop:
	loop	.DelayLoop					;      |  10 |  12 |   6
	pop		cx							;    8 |   5 |   4 |   4
	ret									;   20 |  11m|  10m|   5


;--------------------------------------------------------------------
; Initializes timeout counter. Timeouts are implemented using system
; timer ticks. First tick might take 0...54.9ms and remaining ticks
; will occur at 54.9ms intervals. Use delay of two (or more) ticks to
; ensure at least 54.9ms wait.
;
; SoftDelay_InitTimeout
;	Parameters:
;		CL:		Number of system timer ticks before timeout
;		DS:		Segment to RAMVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SoftDelay_InitTimeout:
	mov		[RAMVARS.bEndTime], cl		; Store timeout ticks
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, cx
	mov		cl, [BDA.dwTimerTicks]		; Load current time lowest byte
	pop		ds
	add		[RAMVARS.bEndTime], cl		; Timeout to end time
	sti									; Enable interrupts
	ret


;--------------------------------------------------------------------
; Updates timeout counter. Timeout counter can be
; initialized with SoftDelay_InitTimeout.
;
; SoftDelay_UpdTimeout
;	Parameters:
;		DS:		Segment to RAMVARS
;	Returns:
;		CF:		Set if timeout
;				Cleared if time left
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SoftDelay_UpdTimeout:
	push	ax
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, ax
	mov		al, [BDA.dwTimerTicks]		; Load current time lowest byte
	pop		ds

	cmp		al, [RAMVARS.bEndTime]		; End time reached?
	pop		ax
	je		SHORT .ReturnTimeout
	clc
	ret
.ReturnTimeout:
	stc
	ret


;--------------------------------------------------------------------
; Microsecond delay.
; Current implementation uses BIOS event wait services that are not
; available on XT systems. Calling overhead should be enough so it does
; not matter for IDE waits. On AT+ the delay will be at least 1ms since
; RTC resolution is 977 microsecs.
;
; SoftDelay_us
;	Parameters:
;		CX:		Number of microsecs to wait
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SoftDelay_us:
	push	dx
	push	ax

	xor		dx, dx						; Zero DX
	xchg	cx, dx						; Microsecs now in CX:DX
	mov		ah, 86h						; Event Wait
	int		INTV_SYSTEM_SERVICES

	pop		ax
	pop		dx
	mov		cx, 2						; Prepare to wait 2 timer ticks
	jc		SHORT SoftDelay_TimerTicks	; Unsupported or busy
	ret


;--------------------------------------------------------------------
; Timer tick delay.
; One tick is about 54.9ms but first tick may occur anytime between
; 0...54.9ms!
;
; SoftDelay_TimerTicks
;	Parameters:
;		CX:		Number of timer ticks to wait
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SoftDelay_TimerTicks:
	push	ds
	push	ax
	LOAD_BDA_SEGMENT_TO	ds, ax
	add		cx, [BDA.dwTimerTicks]		; CX to end time
	sti									; Enable interrupts
.DelayLoop:
	cmp		cx, [BDA.dwTimerTicks]		; Wait complete?
	jne		SHORT .DelayLoop			;  If not, loop
	pop		ax
	pop		ds
	ret
