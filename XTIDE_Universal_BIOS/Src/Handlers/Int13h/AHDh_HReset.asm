; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=Dh, Reset Hard Disk (Alternate reset).

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=Dh, Reset Hard Disk (Alternate reset).
;
; AHDh_HandlerForResetHardDisk
;	Parameters:
;		AH:		Bios function Dh
;		DL:		Drive number
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AHDh_HandlerForResetHardDisk:
%ifndef USE_186
	call	AHDh_ResetDrive
	jmp		Int13h_PopDiDsAndReturn
%else
	push	Int13h_PopDiDsAndReturn
	; Fall through to AHDh_ResetDrive
%endif


;--------------------------------------------------------------------
; Resets hard disk.
;
; AHDh_ResetDrive
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AHDh_ResetDrive:
	push	dx
	push	cx
	push	bx
	push	ax

	call	FindDPT_ForDriveNumber		; DS:DI now points to DPT
	call	Interrupts_UnmaskInterruptControllerForDriveInDSDI
	call	AHDh_ResetMasterAndSlave
	;jc		SHORT .ReturnError			; CF would be set if slave drive present without master
										; (error register has special values after reset)

	; Initialize Master and Slave drives
	mov		dx, [RAMVARS.wIdeBase]		; Load base port address
	call	AHDh_InitializeMasterAndSlave

	pop		bx							; Pop old AX
	mov		al, bl						; Restore AL
	pop		bx
	pop		cx
	pop		dx
	ret


;--------------------------------------------------------------------
; Resets Master and Slave drives at wanted port.
; Both IDE drives will be reset. It is not possible to reset
; Master or Slave only.
;
; AHDh_ResetMasterAndSlave
;	Parameters:
;		DS:DI:	Ptr to DPT for Master or Slave drive
;	Returns:
;		CF:		0 if reset succesfull
;				1 if any error
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AHDh_ResetMasterAndSlave:
	; Reset controller
	; HSR0: Set_SRST
	mov		al, [di+DPT.bDrvCtrl]		; Load value for ACR
	or		al, FLG_IDE_CTRL_SRST		; Set Reset bit
	call	HDrvSel_OutputDeviceControlByte
	mov		ax, 5						; Delay at least 5us
	call	Delay_MicrosecondsFromAX

	; HSR1: Clear_wait
	mov		al, [di+DPT.bDrvCtrl]		; Load value for ACR
	out		dx, al						; End Reset
	mov		ax, 2000					; Delay at least 2ms
	call	Delay_MicrosecondsFromAX

	; HSR2: Check_status
	mov		cl, B_TIMEOUT_RESET			; Reset timeout delay
	jmp		HStatus_WaitBsy


;--------------------------------------------------------------------
; Initializes Master and Slave drive.
;
; AHDh_InitializeMasterAndSlave
;	Parameters:
;		DX:		IDE Base Port address
;	Returns:
;		AH:		Error code
;		CF:		0 if initialization succesfull
;				1 if any error
;	Corrupts registers:
;		AL, BX, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AHDh_InitializeMasterAndSlave:
	push	dx							; Store base port address
	xor		cx, cx						; Assume no errors
	call	FindDPT_ForIdeMasterAtPort
	jnc		SHORT .InitializeSlave		; Master drive not present
	call	AH9h_InitializeDriveForUse
	mov		cl, ah						; Copy error code to CL
.InitializeSlave:
	pop		dx							; Restore base port address
	call	FindDPT_ForIdeSlaveAtPort
	jnc		SHORT .CombineErrors		; Slave drive not present
	call	AH9h_InitializeDriveForUse
	mov		ch, ah						; Copy error code to CH
.CombineErrors:
	or		cl, ch						; OR error codes, clear CF
	jz		SHORT .Return
	mov		ah, RET_HD_RESETFAIL		; Load Reset Failed error code
	stc
.Return:
	ret
