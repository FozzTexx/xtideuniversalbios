; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device Command functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeCommand_ResetMasterAndSlaveController
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
IdeCommand_ResetMasterAndSlaveController:
	; HSR0: Set_SRST
	call	AccessDPT_GetDeviceControlByteToAL
	or		al, FLG_DEVCONTROL_SRST | FLG_DEVCONTROL_nIEN	; Set Reset bit
	mov		dl, DEVICE_CONTROL_REGISTER_out
	call	Device_OutputALtoIdeControlBlockRegisterInDL
	mov		ax, HSR0_RESET_WAIT_US
	call	Timer_DelayMicrosecondsFromAX

	; HSR1: Clear_wait
	call	AccessDPT_GetDeviceControlByteToAL
	or		al, FLG_DEVCONTROL_nIEN
	and		al, ~FLG_DEVCONTROL_SRST						; Clear reset bit
	mov		dl, DEVICE_CONTROL_REGISTER_out
	call	Device_OutputALtoIdeControlBlockRegisterInDL
	mov		ax, HSR1_RESET_WAIT_US
	call	Timer_DelayMicrosecondsFromAX

	; HSR2: Check_status
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_MOTOR_STARTUP, FLG_STATUS_BSY)
	jmp		IdeWait_PollStatusFlagInBLwithTimeoutInBH


;--------------------------------------------------------------------
; IdeCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Select Register
;		DS:		Segment to RAMVARS
;		ES:SI:	Ptr to buffer to receive 512-byte IDE Information
;		CS:BP:	Ptr to IDEVARS
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BL, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
IdeCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH:
	; Create fake DPT to be able to use Device.asm functions
	call	FindDPT_ForNewDriveToDSDI
	eMOVZX	ax, bh
	cmp		BYTE [cs:bp+IDEVARS.bDevice], DEVICE_XTIDE_WITH_REVERSED_A3_AND_A0
	eCMOVE	ah, FLGH_DPT_REVERSED_A0_AND_A3
	mov		[di+DPT.wFlags], ax
	mov		[di+DPT.bIdevarsOffset], bp
	mov		BYTE [di+DPT_ATA.bSetBlock], 1	; Block = 1 sector

	; Wait until drive motors have reached max speed
	cmp		bp, BYTE ROMVARS.ideVars0
	jne		SHORT .SkipLongWaitSinceDriveIsNotPrimaryMaster
	test	al, FLG_DRVNHEAD_DRV
	jnz		SHORT .SkipLongWaitSinceDriveIsNotPrimaryMaster
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_MOTOR_STARTUP, FLG_STATUS_BSY)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
.SkipLongWaitSinceDriveIsNotPrimaryMaster:

	; Create IDEPACK without INTPACK
	push	bp
	call	Idepack_FakeToSSBP

	; Prepare to output Identify Device command
	mov		dl, 1						; Sector count (required by IdeTransfer.asm)
	mov		al, COMMAND_IDENTIFY_DEVICE
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_IDENTIFY_DEVICE, FLG_STATUS_DRQ)
	call	Idepack_StoreNonExtParametersAndIssueCommandFromAL

	; Clean stack and return
	lea		sp, [bp+EXTRA_BYTES_FOR_INTPACK]	; This assumes BP hasn't changed between Idepack_FakeToSSBP and here
	pop		bp
	ret


;--------------------------------------------------------------------
; IdeCommand_OutputWithParameters
;	Parameters:
;		BH:		System timer ticks for timeout
;		BL:		IDE Status Register bit to poll after command
;		ES:SI:	Ptr to buffer (for data transfer commands)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX, (ES:SI for data transfer commands)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeCommand_OutputWithParameters:
	push	bx						; Store status register bits to poll

	; Select Master or Slave drive and output head number or LBA28 top bits
	call	IdeCommand_SelectDrive
	jc		SHORT .DriveNotReady

	; Output Device Control Byte to enable or disable interrupts
	mov		al, [bp+IDEPACK.bDeviceControl]
	test	al, FLG_DEVCONTROL_nIEN	; Interrupts disabled?
	jnz		SHORT .DoNotSetInterruptInServiceFlag

	; Clear Task Flag and set Interrupt In-Service Flag
	or		BYTE [di+DPT.bFlagsHigh], FLGH_DPT_INTERRUPT_IN_SERVICE
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, dx, !	; Also zero DX
	mov		[BDA.bHDTaskFlg], dl
	pop		ds
.DoNotSetInterruptInServiceFlag:
	mov		dl, DEVICE_CONTROL_REGISTER_out
	call	Device_OutputALtoIdeControlBlockRegisterInDL

	; Output Feature Number
	mov		dl, FEATURES_REGISTER_out
	mov		al, [bp+IDEPACK.bFeatures]
	call	Device_OutputALtoIdeRegisterInDL

	; Output Sector Address High (only used by LBA48)
	mov		ax, [bp+IDEPACK.wSectorCountHighAndLbaLowExt]
	mov		cx, [bp+IDEPACK.wLbaMiddleAndHighExt]
	call	OutputSectorCountAndAddress

	; Output Sector Address Low
	mov		ax, [bp+IDEPACK.wSectorCountAndLbaLow]
	mov		cx, [bp+IDEPACK.wLbaMiddleAndHigh]
	call	OutputSectorCountAndAddress

	; Output command
	mov		dl, COMMAND_REGISTER_out
	mov		al, [bp+IDEPACK.bCommand]
	call	Device_OutputALtoIdeRegisterInDL

	; Wait until command completed
	pop		bx						; Pop status and timeout for polling
	cmp		bl, FLG_STATUS_DRQ		; Data transfer started?
	je		SHORT IdeTransfer_StartWithCommandInAL
	test	BYTE [bp+IDEPACK.bDeviceControl], FLG_DEVCONTROL_nIEN
	jz		SHORT .WaitForIrqOrRdy
	jmp		IdeWait_PollStatusFlagInBLwithTimeoutInBH

ALIGN JUMP_ALIGN
.WaitForIrqOrRdy:
	jmp		IdeWait_IRQorStatusFlagInBLwithTimeoutInBH

.DriveNotReady:
	pop		bx							; Clean stack
ReturnSinceTimeoutWhenPollingBusy:
	ret


;--------------------------------------------------------------------
; IdeCommand_SelectDrive
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeCommand_SelectDrive:
	; Wait until neither Master or Slave Drive is busy
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_BSY, FLG_STATUS_BSY)
	cmp		BYTE [bp+IDEPACK.bCommand], COMMAND_IDENTIFY_DEVICE
	eCMOVE	bh, TIMEOUT_IDENTIFY_DEVICE
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
	jc		SHORT ReturnSinceTimeoutWhenPollingBusy

	; Select Master or Slave Drive
	mov		dl, DRIVE_AND_HEAD_SELECT_REGISTER
	mov		al, [bp+IDEPACK.bDrvAndHead]
	call	Device_OutputALtoIdeRegisterInDL
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRDY, FLG_STATUS_DRDY)
	cmp		BYTE [bp+IDEPACK.bCommand], COMMAND_IDENTIFY_DEVICE
	eCMOVE	bh, TIMEOUT_IDENTIFY_DEVICE
	jmp		IdeWait_PollStatusFlagInBLwithTimeoutInBH


;--------------------------------------------------------------------
; OutputSectorCountAndAddress
;	Parameters:
;		AH:		LBA low bits (Sector Number)
;		AL:		Sector Count
;		CL:		LBA middle bits (Cylinder Number low)
;		CH:		LBA high bits (Cylinder Number high)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
OutputSectorCountAndAddress:
	mov		dl, SECTOR_COUNT_REGISTER
	call	Device_OutputALtoIdeRegisterInDL

	mov		al, ah
	mov		dl, LBA_LOW_REGISTER
	call	Device_OutputALtoIdeRegisterInDL

	mov		al, cl
	mov		dl, LBA_MIDDLE_REGISTER
	call	Device_OutputALtoIdeRegisterInDL

	mov		al, ch
	mov		dl, LBA_HIGH_REGISTER
	jmp		Device_OutputALtoIdeRegisterInDL
