; Project name	:	XTIDE Universal BIOS
; Description	:	Command and port direction functions for different device types.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Device_FinalizeDPT
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
Device_FinalizeDPT:
	test	WORD [di+DPT.wFlags], FLG_DPT_SERIAL_DEVICE
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
	test	WORD [di+DPT.wFlags], FLG_DPT_SERIAL_DEVICE
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
	test	WORD [di+DPT.wFlags], FLG_DPT_SERIAL_DEVICE
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
	test	WORD [di+DPT.wFlags], FLG_DPT_SERIAL_DEVICE
	jnz		SHORT ReturnSuccessForSerialPort
	jmp		IdeCommand_SelectDrive
ReturnSuccessForSerialPort:
	xor		ax, ax
	ret


;--------------------------------------------------------------------
; Device_OutputALtoIdeRegisterInDL
;	Parameters:
;		AL:		Byte to output
;		DL:		IDE Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Device_OutputALtoIdeRegisterInDL:
	mov		bx, IdeIO_OutputALtoIdeRegisterInDX
	jmp		SHORT TranslateRegisterAddressInDLifNecessaryThenJumpToBX


;--------------------------------------------------------------------
; Device_OutputALtoIdeControlBlockRegisterInDL
;	Parameters:
;		AL:		Byte to output
;		DL:		IDE Control Block Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Device_OutputALtoIdeControlBlockRegisterInDL:
	mov		bx, IdeIO_OutputALtoIdeControlBlockRegisterInDX
	jmp		SHORT TranslateRegisterAddressInDLifNecessaryThenJumpToBX


;--------------------------------------------------------------------
; Device_InputToALfromIdeRegisterInDL
;	Parameters:
;		DL:		IDE Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AL:		Inputted byte
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Device_InputToALfromIdeRegisterInDL:
	mov		bx, IdeIO_InputToALfromIdeRegisterInDX
	; Fall to TranslateRegisterAddressInDLifNecessaryThenJumpToBX


;--------------------------------------------------------------------
; TranslateRegisterAddressInDLifNecessaryThenJumpToBX
;	Parameters:
;		AL:		Byte to output (if output function in BX)
;		DL:		IDE Register
;		BX:		I/O function to jump to
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AL:		Inputted byte (if input function in BX)
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
TranslateRegisterAddressInDLifNecessaryThenJumpToBX:
	test	WORD [di+DPT.wFlags], FLG_DPT_REVERSED_A0_AND_A3
	jz		SHORT .JumpToIoFunctionInSI

	; Exchange address lines A0 and A3 from DL
	mov		dh, MASK_A3_AND_A0_ADDRESS_LINES
	and		dh, dl							; DH = 0, 1, 8 or 9, we can ignore 0 and 9
	jz		SHORT .JumpToIoFunctionInSI		; Jump out since DH is 0
	xor		dh, MASK_A3_AND_A0_ADDRESS_LINES
	jz		SHORT .JumpToIoFunctionInSI		; Jump out since DH was 9
	and		dl, ~MASK_A3_AND_A0_ADDRESS_LINES
	or		dl, dh							; Address lines now reversed

ALIGN JUMP_ALIGN
.JumpToIoFunctionInSI:
	push	bx
	xor		dh, dh
	eMOVZX	bx, BYTE [di+DPT.bIdevarsOffset]; CS:BX now points to IDEVARS
	ret
