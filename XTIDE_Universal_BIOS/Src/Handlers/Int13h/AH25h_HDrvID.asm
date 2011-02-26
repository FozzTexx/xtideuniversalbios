; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=25h, Get Drive Information.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=25h, Get Drive Information.
;
; AH25h_HandlerForGetDriveInformation
;	Parameters:
;		AH:		Bios function 25h
;		DL:		Drive number
;		ES:BX:	Ptr to buffer to receive 512-byte drive information
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		ES:BX:	Ptr to 512-byte buffer to receive drive Information
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH25h_HandlerForGetDriveInformation:
	push	dx
	push	cx
	push	bx
	push	ax
	push	es

	; Wait until previously selected drive is ready
	call	FindDPT_ForDriveNumber		; DS:DI now points to DPT
	call	HDrvSel_SelectDriveAndDisableIRQ
	jc		SHORT .Return				; Return if error

	; Get drive information
	call	HPIO_NormalizeDataPointer
	push	bx
	mov		dx, [RAMVARS.wIdeBase]		; Load base port address
	eMOVZX	bx, BYTE [di+DPT.bIdeOff]	; Load offset to IDEVARS
	mov		bl, [cs:bx+IDEVARS.bBusType]; Load bus type to BL
	mov		bh, [di+DPT.bDrvSel]		; Load drive sel byte to BH
	pop		di							; Pop buffer offset to DI
	call	AH25h_GetDriveInfo			; Get drive information
.Return:
	pop		es
	jmp		Int13h_PopXRegsAndReturn


;--------------------------------------------------------------------
; Gets drive information using Identify Device command.
;
; AH25h_GetDriveInfo
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Select Register
;		BL:		Bus type
;		DX:		IDE Controller base port address
;		DS:		Segment to RAMVARS
;		ES:DI:	Ptr to buffer to receive 512 byte drive information
;	Returns:
;		AH:		Int 13h return status (will be stored to BDA)
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH25h_GetDriveInfo:
	push	di
	push	dx
	push	bx

	; Select Master or Slave drive.
	; DO NOT WAIT UNTIL CURRENTLY SELECTED IS READY!
	; It makes slave drive detection impossible if master is not present.
	mov		[RAMVARS.wIdeBase], dx		; Store IDE Base port to RAMVARS
	add		dx, BYTE REG_IDE_DRVHD		; DX to Drive and Head Sel Register
	mov		al, bh						; Drive Select byte to AL
	out		dx, al						; Select Master or Slave drive
	sub		dx, BYTE REG_IDE_DRVHD		; Back to IDE Base port
	call	AH25h_GetDriveDetectionTimeoutValue
	call	HStatus_WaitRdy				; Wait until ready to accept commands
	jc		SHORT .Return				; Return if error

	; Output command
	mov		al, HCMD_ID_DEV				; Load Identify Device command to AL
	out		dx, al						; Output command
	call	HStatus_WaitDrqDefTime		; Wait until ready to transfer (no IRQ!)
	jc		SHORT .Return				; Return if error

	; Transfer data
	sub		dx, BYTE REGR_IDE_ST		; DX to IDE Data Reg
	xor		bh, bh						; BX now contains bus type
	mov		cx, 256						; Transfer 256 words (single sector)
	cld									; INSW to increment DI
	call	[cs:bx+g_rgfnPioRead]		; Read ID sector
	call	HStatus_WaitRdyDefTime		; Wait until drive ready

	; Return
.Return:
	pop		bx
	pop		dx
	pop		di
	ret


;--------------------------------------------------------------------
; Returns timeout value for drive detection.
; Long timeout is required for detecting first drive to make sure it is
; ready after power-on (ATA specification says up to 31 seconds).
; Short timeout is used for additional drives to prevent long boot time
; when drive has failed or it is not present.
;
; AH25h_GetDriveDetectionTimeoutValue
;	Parameters:
;		DS:		Segment to RAMVARS
;	Returns:
;		CL:		Timeout value
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH25h_GetDriveDetectionTimeoutValue:
	mov		cl, B_TIMEOUT_RESET			; Load long timeout (assume first drive)
	cmp		BYTE [RAMVARS.bDrvCnt], 0	; Detecting first drive?
	je		SHORT .Return
	mov		cl, B_TIMEOUT_DRVINFO		; Load short timeout
ALIGN JUMP_ALIGN, ret	; This speed optimization may be unnecessary
.Return:
	ret
