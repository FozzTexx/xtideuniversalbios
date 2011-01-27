; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for selecting Master or Slave drive.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Selects Master or Slave drive for transferring data.
; This means that interrupts will be enabled if so configured in
; IDEVARS. This function returns after drive is ready to accept commands.
;
; HDrvSel_SelectDriveForDataTransfer
;	Parameters:
;		DS:DI:	Ptr to DPT
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if drive selected successfully
;				1 if any error
;	Corrupts registers:
;		AL, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HDrvSel_SelectDriveForDataTransfer:
	mov		al, [di+DPT.bDrvCtrl]			; Load Device Control Byte
	; Fall to HDrvSel_SelectDriveAndSetControlByte

;--------------------------------------------------------------------
; Selects Master or Slave drive.
; Device Control Byte can be used to enable or disable interrupts.
; This function returns only after drive is ready to accept commands.
;
; HDrvSel_SelectDriveAndSetControlByte
;	Parameters:
;		AL:		Device Control Byte (to enable/disable interrupts)
;		DS:DI:	Ptr to DPT
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if drive selected successfully
;				1 if any error
;	Corrupts registers:
;		AL, BX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
HDrvSel_SelectDriveAndSetControlByte:
	push	dx
	push	cx

	; Output Device Control Register to enable/disable interrupts
	call	HDrvSel_OutputDeviceControlByte

	; Select Master or Slave drive
	mov		dx, [RAMVARS.wIdeBase]
	add		dx, BYTE REG_IDE_DRVHD
	mov		al, [di+DPT.bDrvSel]			; Load Master/Slave selection byte
	out		dx, al							; Select drive

	; Wait until drive is ready to accept commands
	call	HStatus_WaitRdyDefTime
	pop		cx
	pop		dx
	ret


;--------------------------------------------------------------------
; Outputs Device Control Byte to Device Control Register.
;
; HDrvSel_OutputDeviceControlByte
;	Parameters:
;		AL:		Device Control Byte
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		DX:		Device Control Register address
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HDrvSel_OutputDeviceControlByte:
	eMOVZX	bx, BYTE [di+DPT.bIdeOff]		; CS:BX now points to IDEVARS
	mov		dx, [cs:bx+IDEVARS.wPortCtrl]	; Load Control Block base address
	add		dx, BYTE REGW_IDEC_CTRL			; Add offset to Device Control Register
	out		dx, al							; Output Device Control byte
	ret


;--------------------------------------------------------------------
; Selects Master or Slave drive and disables interrupts. Interrupts should
; be disabled for commands that do not transfer data.
; This function returns after drive is ready to accept commands.
;
; HDrvSel_SelectDriveAndDisableIRQ
;	Parameters:
;		DS:DI:	Ptr to DPT
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if drive selected successfully
;				1 if any error
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HDrvSel_SelectDriveAndDisableIRQ:
	push	bx
	mov		al, [di+DPT.bDrvCtrl]	; Load Device Control Byte
	or		al, FLG_IDE_CTRL_nIEN	; Disable interrupts
	call	HDrvSel_SelectDriveAndSetControlByte
	pop		bx
	ret
