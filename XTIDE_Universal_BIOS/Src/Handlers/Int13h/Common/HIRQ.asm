; File name		:	HIRQ.asm
; Project name	:	IDE BIOS
; Created date	:	11.12.2009
; Last update	:	23.8.2010
; Author		:	Tomi Tilli
; Description	:	Interrupt handling related functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; HIRQ_WaitForIRQ
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set if wait done by operating system
;				Cleared if BIOS must perform task flag polling
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HIRQ_WaitForIRQ:
	test	BYTE [bx+DPT.bDrvCtrl], FLG_IDE_CTRL_nIEN	; Clears CF
	jz		SHORT .NotifyOperatingSystemAboutWaitingForIRQ
	ret		; Go to poll status register

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
ALIGN JUMP_ALIGN
.NotifyOperatingSystemAboutWaitingForIRQ:
	push	ds

	LOAD_BDA_SEGMENT_TO	ds, ax			; Zero AX
	cli									; Disable interrupts
	cmp		al, [ds:BDA.bHDTaskFlg]		; Task flag already set?
	jc		SHORT .ReturnFromWaitNotify	;  If so, skip OS notification

	mov		ah, 90h						; Hard disk busy (AX=9000h)
	int		INTV_SYSTEM_SERVICES		; OS hook, device busy
	jnc		SHORT .ReturnFromWaitNotify	; CF cleared, BIOS handles waiting

	; Make sure that OS hooks are supported, otherwise the CF means unsupported function
	test	ah, ah						; OS hook supported? (clears CF)
	jnz		SHORT .ReturnFromWaitNotify	; AH has error, BIOS must do the wait
	stc									; Set CF since wait done by OS
.ReturnFromWaitNotify:
	pop		ds
	sti									; Enable interrupts
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

	; Issue Int 15h, function AX=9100h (Interrupt ready)
	mov		ax, 9100h					; Interrupt ready, device 0 (HD)
	int		INTV_SYSTEM_SERVICES

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
	call	RamVars_GetSegmentToDS
	call	HError_GetStatusAndErrorRegistersToAXandStoreThemToBDA
	mov		BYTE [BDA.bHDTaskFlg], 0FFh		; Set task flag

	pop		dx
	pop		di
	pop		ds
	ret
