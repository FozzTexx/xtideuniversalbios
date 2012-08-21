; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device Command functions.

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html				
;		

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
	OUTPUT_AL_TO_IDE_CONTROL_BLOCK_REGISTER		DEVICE_CONTROL_REGISTER_out
	mov		ax, HSR0_RESET_WAIT_US
	call	Timer_DelayMicrosecondsFromAX

	; HSR1: Clear_wait
	call	AccessDPT_GetDeviceControlByteToAL
	or		al, FLG_DEVCONTROL_nIEN
	and		al, ~FLG_DEVCONTROL_SRST						; Clear reset bit
	OUTPUT_AL_TO_IDE_CONTROL_BLOCK_REGISTER		DEVICE_CONTROL_REGISTER_out
	mov		ax, HSR1_RESET_WAIT_US
	call	Timer_DelayMicrosecondsFromAX

	; HSR2: Check_status
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_MAXIMUM, FLG_STATUS_BSY)
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
	mov		[di+DPT.wFlags], ax
	mov		[di+DPT.bIdevarsOffset], bp
	mov		BYTE [di+DPT_ATA.bBlockSize], 1	; Block = 1 sector
	call	IdeDPT_StoreDeviceTypeFromIdevarsInCSBPtoDPTinDSDI

	; Wait until drive motors have reached max speed
	cmp		bp, BYTE ROMVARS.ideVars0		; First controller?
	jne		SHORT .SkipLongWaitSinceDriveIsNotPrimaryMaster
	test	bh, FLG_DRVNHEAD_DRV			; Wait already done for Master
	jnz		SHORT .SkipLongWaitSinceDriveIsNotPrimaryMaster
	call	AHDh_WaitUnilDriveMotorHasReachedFullSpeed
.SkipLongWaitSinceDriveIsNotPrimaryMaster:

	; Create IDEPACK without INTPACK
	push	bp
	call	Idepack_FakeToSSBP

%ifdef MODULE_8BIT_IDE
	; Enable 8-bit PIO mode for Lo-tech XT-CF
	call	AH9h_Enable8bitPioModeForXTCF
	jc		SHORT .FailedToSet8bitMode
%endif

	; Prepare to output Identify Device command
	mov		dl, 1						; Sector count (required by IdeTransfer.asm)
	mov		al, COMMAND_IDENTIFY_DEVICE
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
	call	Idepack_StoreNonExtParametersAndIssueCommandFromAL

	; Clean stack and return
.FailedToSet8bitMode:
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
;		CX:		Number of successfully transferred sectors (for transfer commands)
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, (CX), DX, (ES:SI for data transfer commands)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeCommand_OutputWithParameters:
	push	bx						; Store status register bits to poll

	; Select Master or Slave drive and output head number or LBA28 top bits
	call	IdeCommand_SelectDrive
	jc		SHORT .DriveNotReady

	; Output Device Control Byte to enable or disable interrupts
	mov		al, [bp+IDEPACK.bDeviceControl]
%ifdef MODULE_IRQ
	test	al, FLG_DEVCONTROL_nIEN	; Interrupts disabled?
	jnz		SHORT .DoNotSetInterruptInServiceFlag

	; Clear Task Flag and set Interrupt In-Service Flag
	or		BYTE [di+DPT.bFlagsHigh], FLGH_DPT_INTERRUPT_IN_SERVICE
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, dx, !	; Also zero DX
	mov		[BDA.bHDTaskFlg], dl
	pop		ds
.DoNotSetInterruptInServiceFlag:
%endif
	OUTPUT_AL_TO_IDE_CONTROL_BLOCK_REGISTER		DEVICE_CONTROL_REGISTER_out

	; Output Feature Number
	mov		al, [bp+IDEPACK.bFeatures]
	OUTPUT_AL_TO_IDE_REGISTER	FEATURES_REGISTER_out

	; Output Sector Address High (only used by LBA48)
%ifdef MODULE_EBIOS
	eMOVZX	ax, [bp+IDEPACK.bLbaLowExt]		; Zero sector count
	mov		cx, [bp+IDEPACK.wLbaMiddleAndHighExt]
	call	OutputSectorCountAndAddress
%endif

	; Output Sector Address Low
	mov		ax, [bp+IDEPACK.wSectorCountAndLbaLow]
	mov		cx, [bp+IDEPACK.wLbaMiddleAndHigh]
	call	OutputSectorCountAndAddress

	; Output command
	mov		al, [bp+IDEPACK.bCommand]
	OUTPUT_AL_TO_IDE_REGISTER	COMMAND_REGISTER_out

	; Wait until command completed
	pop		bx								; Pop status and timeout for polling
	cmp		bl, FLG_STATUS_DRQ				; Data transfer started?
	jne		SHORT .WaitUntilNonTransferCommandCompletes
%ifdef MODULE_JRIDE
	cmp		BYTE [di+DPT_ATA.bDevice], DEVICE_8BIT_JRIDE_ISA
	je		SHORT JrIdeTransfer_StartWithCommandInAL
%endif
	jmp		IdeTransfer_StartWithCommandInAL

.WaitUntilNonTransferCommandCompletes:
%ifdef MODULE_IRQ
	test	BYTE [bp+IDEPACK.bDeviceControl], FLG_DEVCONTROL_nIEN
	jz		SHORT .PollStatusFlagInsteadOfWaitIrq
	jmp		IdeWait_IRQorStatusFlagInBLwithTimeoutInBH
.PollStatusFlagInsteadOfWaitIrq:
%endif
	jmp		IdeWait_PollStatusFlagInBLwithTimeoutInBH

.DriveNotReady:
	pop		bx							; Clean stack
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
%if 0
	; Wait until neither Master or Slave Drive is busy
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_BSY, FLG_STATUS_BSY)
	cmp		BYTE [bp+IDEPACK.bCommand], COMMAND_IDENTIFY_DEVICE
	eCMOVE	bh, TIMEOUT_IDENTIFY_DEVICE
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
%endif

	; Select Master or Slave Drive
	mov		al, [bp+IDEPACK.bDrvAndHead]
	OUTPUT_AL_TO_IDE_REGISTER	DRIVE_AND_HEAD_SELECT_REGISTER
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRDY, FLG_STATUS_DRDY)
	cmp		BYTE [bp+IDEPACK.bCommand], COMMAND_IDENTIFY_DEVICE
	eCMOVE	bh, TIMEOUT_IDENTIFY_DEVICE
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH

	; Ignore errors from IDE Error Register (set by previous command)
	cmp		ah, RET_HD_TIMEOUT
	je		SHORT .FailedToSelectDrive
	xor		ax, ax					; Always success unless timeout
	ret
.FailedToSelectDrive:
	stc
	ret


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
	OUTPUT_AL_TO_IDE_REGISTER	SECTOR_COUNT_REGISTER

	mov		al, ah
	OUTPUT_AL_TO_IDE_REGISTER	LBA_LOW_REGISTER

	mov		al, cl
	OUTPUT_AL_TO_IDE_REGISTER	LBA_MIDDLE_REGISTER

	mov		al, ch
	JUMP_TO_OUTPUT_AL_TO_IDE_REGISTER	LBA_HIGH_REGISTER
