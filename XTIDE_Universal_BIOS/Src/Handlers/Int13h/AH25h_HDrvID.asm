; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=25h, Get Drive Information.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=25h, Get Drive Information.
;
; AH25h_HandlerForGetDriveInformation
;	Parameters:
;		ES:		Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Parameters on INTPACK in SS:BP:
;		ES:BX:	Ptr to buffer to receive 512-byte drive information
;	Returns with INTPACK in SS:BP:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH25h_HandlerForGetDriveInformation:
	; Wait until previously selected drive is ready
	call	HDrvSel_SelectDriveAndDisableIRQ
	jc		SHORT .ReturnWithErrorCodeInAH		; Return if error

	; Get drive information
	mov		bx, [bp+INTPACK.bx]
	call	HPIO_NormalizeDataPointer
	push	bx
	mov		dx, [RAMVARS.wIdeBase]		; Load base port address
	eMOVZX	bx, BYTE [di+DPT.bIdeOff]	; Load offset to IDEVARS
	mov		bl, [cs:bx+IDEVARS.bBusType]; Load bus type to BL
	mov		bh, [di+DPT.bDrvSel]		; Load drive sel byte to BH
	pop		di							; Pop buffer offset to DI
	call	AH25h_GetDriveInfo			; Get drive information
.ReturnWithErrorCodeInAH:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH


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

	; Wait until ready to accept commands
	xor		bh, bh						; BX now contains bus type
	mov		cl, B_TIMEOUT_DRVINFO		; Load short timeout
	cmp		[RAMVARS.bDrvCnt], bh		; Detecting first drive?
	eCMOVE	cl, B_TIMEOUT_RESET			;  If so, load long timeout
	call	HStatus_WaitRdy				; Wait until ready to accept commands
	jc		SHORT .ReturnWithErrorCodeInAH

	; Output command
	mov		al, HCMD_ID_DEV				; Load Identify Device command to AL
	out		dx, al						; Output command
	call	HStatus_WaitDrqDefTime		; Wait until ready to transfer (no IRQ!)
	jc		SHORT .ReturnWithErrorCodeInAH

	; Transfer data
	sub		dx, BYTE REGR_IDE_ST		; DX to IDE Data Reg
	mov		cx, 256						; Transfer 256 words (single sector)
	cld									; INSW to increment DI
	call	[cs:bx+g_rgfnPioRead]		; Read ID sector
	call	HStatus_WaitRdyDefTime		; Wait until drive ready

.ReturnWithErrorCodeInAH:
	pop		bx
	pop		dx
	pop		di
	ret
