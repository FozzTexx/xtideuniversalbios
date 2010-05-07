; File name		:	HStatus.asm
; Project name	:	IDE BIOS
; Created date	:	15.12.2009
; Last update	:	13.4.2010
; Author		:	Tomi Tilli
; Description	:	IDE Status Register polling functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Waits Hard Disk IRQ when not transferring data.
; If interrupts are disabled, RDY flag is polled.
;
; HStatus_WaitIrqOrRdy
;	Parameters:
;		DS:BX:	Ptr to DPT
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if wait succesfull
;				1 if any error
;	Corrupts registers:
;		AL, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HStatus_WaitIrqOrRdy:
	test	BYTE [di+DPT.bDrvCtrl], FLG_IDE_CTRL_nIEN
	jz		HIRQ_WaitIRQ					; Wait for IRQ if enabled
	call	HStatus_ReadAndIgnoreAlternateStatus
	mov		cl, B_TIMEOUT_DRQ				; Load DRQ (not RDY) timeout
	jmp		SHORT HStatus_WaitRdy			; Jump to poll RDY


;--------------------------------------------------------------------
; Reads Alternate Status Register and ignores result.
; Alternate Status Register is read to prevent polling host from
; reading status before it is valid.
;
; HStatus_ReadAndIgnoreAlternateStatus
;	Parameters:
;		DS:BX:	Ptr to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HStatus_ReadAndIgnoreAlternateStatus:
	mov		cx, bx							; Backup BX
	eMOVZX	bx, BYTE [bx+DPT.bIdeOff]		; CS:BX now points to IDEVARS
	mov		dx, [cs:bx+IDEVARS.wPortCtrl]	; DX = Control Block base port
	add		dx, BYTE REGR_IDEC_AST			; DX = Alternate Status Register address
	in		al, dx							; Read Alternate Status Register
	mov		bx, cx							; Restore BX
	ret


;--------------------------------------------------------------------
; Waits until Hard Disk is ready to transfer data.
;
; HStatus_WaitIrqOrDrq
;	Parameters:
;		DS:BX:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if wait succesfull
;				1 if any error
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HStatus_WaitIrqOrDrq:
	push	dx
	push	cx

	; Check if interrupts are enabled
	test	BYTE [bx+DPT.bDrvCtrl], FLG_IDE_CTRL_nIEN
	jnz		SHORT .PollDRQ					; Poll DRQ if IRQ disabled
	call	HIRQ_WaitIRQ					; Wait for IRQ
	jmp		SHORT .Return

ALIGN JUMP_ALIGN
.PollDRQ:
	call	HStatus_ReadAndIgnoreAlternateStatus
	call	HStatus_WaitDrqDefTime
ALIGN JUMP_ALIGN
.Return:
	pop		cx
	pop		dx
	ret


;--------------------------------------------------------------------
; Waits until busy flag is cleared from selected Hard Disk drive.
;
; HStatus_WaitBsyDefTime	Uses default timeout
; HStatus_WaitBsy			Uses user defined timeout
; HStatus_WaitBsyBase		Uses user base port address and timeout
;	Parameters:
;		CL:		Timeout value in system timer ticks (not HStatus_WaitBsyDefTime)
;		DX:		IDE Base port address (HUtil_WaitBsyBase only)
;		DS:		Segment to RAMVARS
;	Returns:
;		AH:		BIOS Error code
;		DX:		IDE Status Register Address
;		CF:		0 if wait succesfull
;				1 if any error
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HStatus_WaitBsyDefTime:
	mov		cl, B_TIMEOUT_BSY			; Load timeout value
ALIGN JUMP_ALIGN
HStatus_WaitBsy:
	mov		dx, [RAMVARS.wIdeBase]		; Load offset to base port
ALIGN JUMP_ALIGN
HStatus_WaitBsyBase:
	add		dx, BYTE REGR_IDE_ST		; Add offset to status reg
	jmp		SHORT HStatus_PollBsy		; Wait until not busy


;--------------------------------------------------------------------
; Waits until Hard Disk is ready to accept commands.
;
; HStatus_WaitRdyDefTime	Uses default timeout
; HStatus_WaitRdy			Uses user defined timeout
; HStatus_WaitRdyBase		Uses user base port address and timeout
;	Parameters:
;		CL:		Timeout value in system timer ticks (not HStatus_WaitRdyDefTime)
;		DX:		IDE Base port address (HStatus_WaitRdyBase only)
;		DS:		Segment to RAMVARS
;	Returns:
;		AH:		BIOS Error code
;		DX:		IDE Status Register Address
;		CF:		0 if wait succesfull
;				1 if any error
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HStatus_WaitRdyDefTime:
	mov		cl, B_TIMEOUT_RDY			; Load timeout value
ALIGN JUMP_ALIGN
HStatus_WaitRdy:
	mov		dx, [RAMVARS.wIdeBase]		; Load offset to base port
ALIGN JUMP_ALIGN
HStatus_WaitRdyBase:
	add		dx, BYTE REGR_IDE_ST		; Add offset to status reg
	mov		ah, FLG_IDE_ST_DRDY			; Flag to poll
	jmp		SHORT HStatus_PollBsyAndFlg	; Wait until flag set


;--------------------------------------------------------------------
; Waits until Hard Disk is ready to transfer data.
; Note! This function polls DRQ even if interrupts are enabled!
;
; HStatus_WaitDrqDefTime	Uses default timeout
; HStatus_WaitDrq			Uses user defined timeout
; HStatus_WaitDrqBase		Uses user base port address and timeout
;	Parameters:
;		CL:		Timeout value in system timer ticks (not HStatus_WaitDrqDefTime)
;		DX:		IDE Base port address (HStatus_WaitDrqBase only)
;		DS:		Segment to RAMVARS
;	Returns:
;		AH:		BIOS Error code
;		DX:		IDE Status Register Address
;		CF:		0 if wait succesfull
;				1 if any error
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HStatus_WaitDrqDefTime:
	mov		cl, B_TIMEOUT_DRQ			; Load timeout value
ALIGN JUMP_ALIGN
HStatus_WaitDrq:
	mov		dx, [RAMVARS.wIdeBase]		; Load offset to base port
ALIGN JUMP_ALIGN
HStatus_WaitDrqBase:
	add		dx, BYTE REGR_IDE_ST		; Add offset to status reg
	mov		ah, FLG_IDE_ST_DRQ			; Flag to poll
	; Fall to HStatus_PollBsyAndFlg

;--------------------------------------------------------------------
; IDE Status register polling.
; This function first waits until controller is not busy.
; When not busy, IDE Status Register is polled until wanted
; flag (HBIT_ST_DRDY or HBIT_ST_DRQ) is set.
;
; HStatus_PollBusyAndFlg
;	Parameters:
;		AH:		Status Register Flag to poll (until set) when not busy
;		CL:		Timeout value in system timer ticks
;		DX:		IDE Status Register Address
;		DS:		Segment to RAMVARS
;	Returns:
;		AH:		BIOS Error code
;		CF:		Clear if wait completed successfully (no errors)
;				Set if any error
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HStatus_PollBsyAndFlg:
	call	SoftDelay_InitTimeout		; Initialize timeout counter
ALIGN JUMP_ALIGN
.PollLoop:
	in		al, dx						; Load IDE Status Register
	test	al, FLG_IDE_ST_BSY			; Controller busy?
	jnz		SHORT .UpdateTimeout		;  If so, jump to timeout update
	test	al, ah						; Test secondary flag
	jnz		SHORT HStatus_PollCompleted	; If set, break loop
ALIGN JUMP_ALIGN
.UpdateTimeout:
	call	SoftDelay_UpdTimeout		; Update timeout counter
	jnc		SHORT .PollLoop				; Loop if time left (sets CF on timeout)
	mov		ah, RET_HD_TIMEOUT			; Load error code for timeout
	ret


;--------------------------------------------------------------------
; IDE Status register polling.
; This function waits until controller is not busy.
;
; HStatus_PollBsy
;	Parameters:
;		CL:		Timeout value in system timer ticks
;		DX:		IDE Status Register Address
;		DS:		Segment to RAMVARS
;	Returns:
;		AH:		BIOS Error code
;		CF:		Clear if wait completed successfully (no errors)
;				Set if any error
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HStatus_PollBsy:
	call	SoftDelay_InitTimeout		; Initialize timeout counter
ALIGN JUMP_ALIGN
.PollLoop:
	in		al, dx						; Load IDE Status Reg
	test	al, FLG_IDE_ST_BSY			; Controller busy? (clears CF)
	jz		SHORT HStatus_PollCompleted	;  If not, jump to check errors
	call	SoftDelay_UpdTimeout		; Update timeout counter
	jnc		SHORT .PollLoop				; Loop if time left (sets CF on timeout)
	mov		ah, RET_HD_TIMEOUT			; Load error code for timeout
	ret

ALIGN JUMP_ALIGN
HStatus_PollCompleted:
	test	al, FLG_IDE_ST_DF | FLG_IDE_ST_ERR
	jnz		SHORT .GetErrorCode			;  If errors, jump to get error code
	xor		ah, ah						; Zero AH and clear CF
	ret
.GetErrorCode:
	jmp		HError_GetErrorCodeForStatusReg
