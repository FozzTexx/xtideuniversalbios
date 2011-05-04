; Project name	:	XTIDE Universal BIOS
; Description	:	Command and port direction functions for different device types.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Device_FinalizeDPT
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
Device_FinalizeDPT:
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE
	jnz		SHORT ReturnSuccessForSerialPort
	jmp		IdeDPT_Finalize
.FinalizeDptForSerialPortDevice:
	jmp		SerialDPT_Finalize


;--------------------------------------------------------------------
; Device_ResetMasterAndSlaveController
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
Device_ResetMasterAndSlaveController:
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE
	jnz		SHORT ReturnSuccessForSerialPort
	jmp		IdeCommand_ResetMasterAndSlaveController


;--------------------------------------------------------------------
; Device_IdentifyToBufferInESSIwithDriveSelectByteInBH
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
Device_IdentifyToBufferInESSIwithDriveSelectByteInBH:
	cmp		BYTE [cs:bp+IDEVARS.bDevice], DEVICE_SERIAL_PORT
	je		SHORT .IdentifyDriveFromSerialPort
	jmp		IdeCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
.IdentifyDriveFromSerialPort:
	jmp		SerialCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH


;--------------------------------------------------------------------
; Device_OutputCommandWithParameters
;	Parameters:
;		BH:		Default system timer ticks for timeout (can be ignored)
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
Device_OutputCommandWithParameters:
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE
	jnz		SHORT .OutputCommandToSerialPort
	jmp		IdeCommand_OutputWithParameters
ALIGN JUMP_ALIGN
.OutputCommandToSerialPort:
	jmp		SerialCommand_OutputWithParameters


;--------------------------------------------------------------------
; Device_SelectDrive
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
Device_SelectDrive:
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE
	jnz		SHORT ReturnSuccessForSerialPort
	jmp		IdeCommand_SelectDrive
ReturnSuccessForSerialPort:
	xor		ax, ax
	ret
