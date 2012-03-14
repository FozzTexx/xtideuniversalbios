; Project name	:	XTIDE Universal BIOS
; Description	:	Interrupt handling related functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeIrq_WaitForIRQ
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		CF:		Set if wait done by operating system
;				Cleared if BIOS must perform task flag polling
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeIrq_WaitForIRQ:

;--------------------------------------------------------------------
; .NotifyOperatingSystemAboutWaitingForIRQ
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Set if wait done by operating system
;				Cleared if BIOS must perform task flag polling
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.NotifyOperatingSystemAboutWaitingForIRQ:
	push	ds

	LOAD_BDA_SEGMENT_TO	ds, ax, !		; Zero AX
	mov		ah, OS_HOOK_DEVICE_BUSY		; Hard disk busy (AX=9000h)
	cli									; Disable interrupts
	cmp		al, [BDA.bHDTaskFlg]		; Task flag already set?
	jc		SHORT .ReturnFromWaitNotify	;  If so, skip OS notification
	int		BIOS_SYSTEM_INTERRUPT_15h	; OS hook, device busy
	jnc		SHORT .ReturnFromWaitNotify	; CF cleared, BIOS handles waiting

	; Make sure that OS hooks are supported, otherwise the CF means unsupported function
	test	ah, ah						; OS hook supported? (clears CF)
	jnz		SHORT .ReturnFromWaitNotify	; AH has error, BIOS must do the wait
	stc									; Set CF since wait done by OS
.ReturnFromWaitNotify:
	sti									; Enable interrupts
	pop		ds
	ret


;--------------------------------------------------------------------
; IDE Interrupt Service Routines.
;
; IdeIrq_InterruptServiceRoutineForIrqs2to7
; IdeIrq_InterruptServiceRoutineForIrqs8to15
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeIrq_InterruptServiceRoutineForIrqs2to7:
	push	di
	push	ax
	call	AcknowledgeIdeInterruptAndSetTaskFlag

	mov		al, COMMAND_END_OF_INTERRUPT
	jmp		SHORT AcknowledgeMasterInterruptController


ALIGN JUMP_ALIGN
IdeIrq_InterruptServiceRoutineForIrqs8to15:
	push	di
	push	ax
	call	AcknowledgeIdeInterruptAndSetTaskFlag

	mov		al, COMMAND_END_OF_INTERRUPT
	out		SLAVE_8259_COMMAND_out, al	; Acknowledge Slave 8259
AcknowledgeMasterInterruptController:
	out		MASTER_8259_COMMAND_out, al	; Acknowledge Master 8259

	; Issue Int 15h, function AX=9100h (Interrupt ready)
	mov		ax, OS_HOOK_DEVICE_POST<<8	; Interrupt ready, device 0 (HD)
	int		BIOS_SYSTEM_INTERRUPT_15h

	pop		ax
	pop		di
	iret


;--------------------------------------------------------------------
; AcknowledgeIdeInterruptAndSetTaskFlag
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AcknowledgeIdeInterruptAndSetTaskFlag:
	push	ds
	push	si
	push	dx
	push	bx

	; Reading Status Register acknowledges IDE interrupt
	call	RamVars_GetSegmentToDS
	mov		bl, FLGH_DPT_INTERRUPT_IN_SERVICE
	call	FindDPT_ToDSDIforFlagsHighInBL
	INPUT_TO_AL_FROM_IDE_REGISTER STATUS_REGISTER_in

	; Clear Interrupt In-Service Flag from DPT
	and		BYTE [di+DPT.bFlagsHigh], ~FLGH_DPT_INTERRUPT_IN_SERVICE

	; Set Task Flag
	LOAD_BDA_SEGMENT_TO	ds, ax
	mov		BYTE [BDA.bHDTaskFlg], 0FFh		; Set task flag

	pop		bx
	pop		dx
	pop		si
	pop		ds
	ret
