; File name		:	HStatus.asm
; Project name	:	IDE BIOS
; Created date	:	15.12.2009
; Last update	:	1.8.2010
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
	test	BYTE [bx+DPT.bDrvCtrl], FLG_IDE_CTRL_nIEN
	jnz		SHORT .PollRdySinceInterruptsAreDisabled
	jmp		HIRQ_WaitIRQ

ALIGN JUMP_ALIGN
.PollRdySinceInterruptsAreDisabled:
	mov		cl, B_TIMEOUT_DRQ				; Load DRQ (not RDY) timeout
	jmp		SHORT HStatus_WaitRdy			; Jump to poll RDY


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
	test	BYTE [bx+DPT.bDrvCtrl], FLG_IDE_CTRL_nIEN
	jnz		SHORT .PollDrqSinceInterruptsAreDisabled
	jmp		HIRQ_WaitIRQ

ALIGN JUMP_ALIGN
.PollDrqSinceInterruptsAreDisabled:
	push	dx
	push	cx
	call	HStatus_WaitDrqDefTime
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
; When not busy, IDE Status Register is polled until wanted flag is set.
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
	call	SoftDelay_InitTimeout				; Initialize timeout counter
	in		al, dx								; Discard contents for first read
												; (should read Alternate Status Register)
ALIGN JUMP_ALIGN
.PollLoop:
	in		al, dx								; Load IDE Status Register
	test	al, FLG_IDE_ST_BSY					; Controller busy?
	jnz		SHORT .UpdateTimeout				;  If so, jump to timeout update
	test	al, ah								; Test secondary flag
	jnz		SHORT GetErrorCodeFromPollingToAH	; If set, break loop
ALIGN JUMP_ALIGN
.UpdateTimeout:
	call	SoftDelay_UpdTimeout				; Update timeout counter
	jnc		SHORT .PollLoop						; Loop if time left (sets CF on timeout)
	jmp		HError_ProcessTimeoutAfterPollingBSYandSomeOtherStatusBit

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
	call	SoftDelay_InitTimeout				; Initialize timeout counter
	in		al, dx								; Discard contents for first read
												; (should read Alternate Status Register)
ALIGN JUMP_ALIGN
.PollLoop:
	in		al, dx								; Load IDE Status Reg
	test	al, FLG_IDE_ST_BSY					; Controller busy?
	jz		SHORT GetErrorCodeFromPollingToAH	;  If not, jump to check errors
	call	SoftDelay_UpdTimeout				; Update timeout counter
	jnc		SHORT .PollLoop						; Loop if time left (sets CF on timeout)
ALIGN JUMP_ALIGN
GetErrorCodeFromPollingToAH:
	jmp		HError_ProcessErrorsAfterPollingBSY
