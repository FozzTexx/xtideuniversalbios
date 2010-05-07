; File name		:	HIRQ.asm
; Project name	:	IDE BIOS
; Created date	:	11.12.2009
; Last update	:	28.3.2010
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
;		AL, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HIRQ_WaitIRQ:
	; Load BDA segment to ES
	push	es
	xor		ax, ax						; Zero AX and clear CF
	mov		es, ax						; Copy BDA segment (zero) to ES

	; Check if interrupt has already occurred
	cli									; Disable interrupts
	cmp		[es:BDA.bHDTaskFlg], al		; Interrupt ready?
	jne		SHORT .CheckIdeErrors		;  If so, return

%ifdef USE_AT	; OS hook only available on AT+ machines
	; OS device busy notification
	mov		ah, 90h						; Hard disk busy (AX=9000h)
	int		INTV_SYSTEM_SERVICES		; OS hook, device busy
	jnc		SHORT .WaitUntilTaskFlagSet	; CF cleared, BIOS handles waiting
	test	ah, ah						; OS hook supported? (clear CF)
	jz		SHORT .CheckIdeErrors		;  If so, waiting completed
ALIGN JUMP_ALIGN
.WaitUntilTaskFlagSet:
%endif

	; Poll task flag until it has been set by interrupt service routine
	call	HIRQ_WaitUntilTaskFlagIsSet
	jc		SHORT .ReturnTimeout		; Return if timeout

ALIGN JUMP_ALIGN
.CheckIdeErrors:
	mov		ax, [es:HDBDA.wHDStAndErr]	; Load Status and Error regs stored by ISR
	call	HError_ConvertIdeErrorToBiosRet
.ReturnTimeout:
	mov		BYTE [es:BDA.bHDTaskFlg], 0	; Clear Task Flag
	pop		es
	sti									; Enable interrupts
	ret


;--------------------------------------------------------------------
; Polls IRQ Task Flag until it has been set or timeout.
;
; HIRQ_WaitUntilTaskFlagIsSet
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment
;	Returns:
;		AH:		BIOS Error code
;		CF:		Cleared if wait succesfull
;				Set if timeout
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HIRQ_WaitUntilTaskFlagIsSet:
	sti								; Enable interrupts
	mov		cl, B_TIMEOUT_DRQ		; Load timeout ticks
	call	SoftDelay_InitTimeout	; Initialize timeout counter
	xor		ax, ax					; Zero AX
ALIGN JUMP_ALIGN
.PollIrqFlag:
	cli								; Disable interrupts
	cmp		[es:BDA.bHDTaskFlg], al	; Task flag set?
	jne		SHORT .TaskFlagIsSet	;  If so, return
	call	SoftDelay_UpdTimeout	; Update timeout
	jc		SHORT .Timeout			; Return if timeout
	sti								; Enable interrupts (one instruction delay)
	hlt								; Sleep until any interrupt
	jmp		SHORT .PollIrqFlag		; Jump to check if IDE interrupt

ALIGN JUMP_ALIGN
.TaskFlagIsSet:
	xor		ah, ah					; Zero AH, clear CF
	ret
.Timeout:
	mov		ah, RET_HD_TIMEOUT		; Load error code for timeout
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
	; Acknowledge IDE interrupt by reading status register
	push	ax
	call	ISR_IDE_AcknowledgeIdeAndStoreStatusToBDA
	mov		al, CMD_END_OF_INTERRUPT
	jmp		SHORT HIRQ_AcknowledgeMasterController

ALIGN JUMP_ALIGN
HIRQ_InterruptServiceRoutineForIrqs8to15:
	push	ax
	call	ISR_IDE_AcknowledgeIdeAndStoreStatusToBDA

	mov		al, CMD_END_OF_INTERRUPT	; Load EOI command to AL
	out		WPORT_8259SL_COMMAND, al	; Acknowledge Slave 8259
HIRQ_AcknowledgeMasterController:
	out		WPORT_8259MA_COMMAND, al	; Acknowledge Master 8259

%ifdef USE_AT	; OS hook only available on AT+ machines
	; Issue Int 15h, function AX=9100h (Interrupt ready)
	mov		ax, 9100h					; Interrupt ready, device 0 (HD)
	int		INTV_SYSTEM_SERVICES
%endif

	; Restore registers and return from interrupt
	pop		ax							; Restore AX
	iret


;--------------------------------------------------------------------
; Acknowledges IDE interrupt by reading status register and
; stores Status and Error Registers to BDA. Task flag in BDA will
; also be set.
;
; ISR_IDE_AcknowledgeIdeAndStoreStatusToBDA
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ISR_IDE_AcknowledgeIdeAndStoreStatusToBDA:
	push	ds
	push	di
	push	dx

	; Read Status and Error registers.
	; Reading Status Register acknowledges IDE interrupt
	call	RamVars_GetSegmentToDS
	mov		dx, [RAMVARS.wIdeBase]		; Load IDE base port address
	inc		dx							; Increment to Error Register
	in		al, dx						; Read Error Register...
	mov		ah, al						; ...and copy it to AH
	add		dx, REGR_IDE_ST-REGR_IDE_ERROR
	in		al, dx						; Read Status Register to AL

	; Store Status and Error register to BDA and set task flag
	LOAD_BDA_SEGMENT_TO	ds, dx
	mov		[HDBDA.wHDStAndErr], ax		; Store Status and Error Registers
	mov		BYTE [BDA.bHDTaskFlg], 0FFh	; Set task flag

	pop		dx
	pop		di
	pop		ds
	ret
