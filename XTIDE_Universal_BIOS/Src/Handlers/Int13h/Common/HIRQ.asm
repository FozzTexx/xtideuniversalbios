; File name		:	HIRQ.asm
; Project name	:	IDE BIOS
; Created date	:	11.12.2009
; Last update	:	23.8.2010
; Author		:	Tomi Tilli
; Description	:	Interrupt handling related functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Wait for IRQ.
;
; HIRQ_WaitIRQ
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		BIOS Error code
;		CF:		Cleared if wait succesfull
;				Set if any error
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HIRQ_WaitIRQ:
	push	es

	LOAD_BDA_SEGMENT_TO	es, ax
%ifdef USE_AT	; OS hook only available on AT+ machines
	call	.NotifyOperatingSystemAboutWaitingForIRQ
	cmc
	jnc		SHORT .TaskFlagPollingComplete
%endif
	call	.WaitUntilTaskFlagIsSet		; Process errors

ALIGN JUMP_ALIGN
.TaskFlagPollingComplete:
	pop		es
	jmp		HError_ProcessErrorsAfterPollingTaskFlag


;--------------------------------------------------------------------
; .NotifyOperatingSystemAboutWaitingForIRQ
;	Parameters:
;		ES:		BDA segment (zero)
;	Returns:
;		CF:		Set if wait done by operating system
;				Cleared if BIOS must perform task flag polling
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_AT
ALIGN JUMP_ALIGN
.NotifyOperatingSystemAboutWaitingForIRQ:
	cli									; Disable interrupts
	xor		ax, ax
	cmp		al, [es:BDA.bHDTaskFlg]		; Task flag already set?
	jc		SHORT .ReturnFromWaitNotify	;  If so, skip OS notification

	mov		ah, 90h						; Hard disk busy (AX=9000h)
	int		INTV_SYSTEM_SERVICES		; OS hook, device busy
	jnc		SHORT .ReturnFromWaitNotify	; CF cleared, BIOS handles waiting

	; Make sure that OS hooks are supported, otherwise the CF means unsupported function
	test	ah, ah						; OS hook supported? (clears CF)
	jnz		SHORT .ReturnFromWaitNotify	; AH has error, BIOS must do the wait
	stc									; Set CF since wait done by OS
.ReturnFromWaitNotify:
	sti									; Enable interrupts
	ret
%endif

;--------------------------------------------------------------------
; Polls IRQ Task Flag until it has been set or timeout.
;
; .WaitUntilTaskFlagIsSet
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment
;	Returns:
;		CF:		Set if timeout
;				Cleared if Task Flag set
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.WaitUntilTaskFlagIsSet:
	push	cx

	mov		cl, B_TIMEOUT_DRQ		; Load timeout ticks
	call	SoftDelay_InitTimeout	; Initialize timeout counter
	xor		ax, ax					; Zero AX
ALIGN JUMP_ALIGN
.PollIrqFlag:
	cli								; Disable interrupt until next HLT
	cmp		[es:BDA.bHDTaskFlg], al	; Task flag set? (clears CF)
	jne		SHORT .Return
	call	SoftDelay_UpdTimeout	; Update timeout
	jc		SHORT .Return			; Return if timeout
	sti								; Enable interrupts (STI has delay so HLT will catch all interrupts)
	hlt								; Sleep until any interrupt
	jmp		SHORT .PollIrqFlag		; Jump to check if IDE interrupt
ALIGN JUMP_ALIGN
.Return:
	pop		cx
	sti
	ret


;--------------------------------------------------------------------
; Clears task (interrupt) flag from BIOS Data Area.
;
; HIRQ_ClearTaskFlag
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HIRQ_ClearTaskFlag:
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, ax		; Also zero AX
	mov		[BDA.bHDTaskFlg], al
	pop		ds
	ret


;--------------------------------------------------------------------
; IDE Interrupt Service Routines.
;
; HIRQ_InterruptServiceRoutineForIrqs2to7
; HIRQ_InterruptServiceRoutineForIrqs8to15
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HIRQ_InterruptServiceRoutineForIrqs2to7:
	push	ax
	call	AcknowledgeIdeInterruptAndStoreStatusAndErrorRegistersToBDA

	mov		al, CMD_END_OF_INTERRUPT
	jmp		SHORT AcknowledgeMasterInterruptController

ALIGN JUMP_ALIGN
HIRQ_InterruptServiceRoutineForIrqs8to15:
	push	ax
	call	AcknowledgeIdeInterruptAndStoreStatusAndErrorRegistersToBDA

	mov		al, CMD_END_OF_INTERRUPT	; Load EOI command to AL
	out		WPORT_8259SL_COMMAND, al	; Acknowledge Slave 8259
AcknowledgeMasterInterruptController:
	out		WPORT_8259MA_COMMAND, al	; Acknowledge Master 8259

%ifdef USE_AT	; OS hook only available on AT+ machines
	; Issue Int 15h, function AX=9100h (Interrupt ready)
	mov		ax, 9100h					; Interrupt ready, device 0 (HD)
	int		INTV_SYSTEM_SERVICES
%endif

	pop		ax							; Restore AX
	iret

;--------------------------------------------------------------------
; Acknowledges IDE interrupt by reading status register and
; stores Status and Error Registers to BDA. Task flag in BDA will
; also be set.
;
; AcknowledgeIdeInterruptAndStoreStatusAndErrorRegistersToBDA
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AcknowledgeIdeInterruptAndStoreStatusAndErrorRegistersToBDA:
	push	ds
	push	di
	push	dx

	; Reading Status Register acknowledges IDE interrupt
	;call	RamVars_GetSegmentToDS
	;call	HError_GetStatusAndErrorRegistersToAXandStoreThemToBDA
	LOAD_BDA_SEGMENT_TO	ds, ax
	mov		BYTE [BDA.bHDTaskFlg], 0FFh		; Set task flag

	pop		dx
	pop		di
	pop		ds
	ret
