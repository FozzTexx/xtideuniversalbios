; Project name	:	XTIDE Universal BIOS
; Description	:	Command and port direction functions for different device types.

; Section containing code
SECTION .text


%macro TEST_USIGN_DPT_AND_JUMP_IF_SERIAL_DEVICE 1
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE
	jnz		SHORT %1
%endmacro

%macro CMP_USING_DPT_AND_JUMP_IF_JRIDE_DEVICE 1
	xchg	ax, bx
	eMOVZX	bx, [di+DPT.bIdevarsOffset]
	cmp		BYTE [cs:bx+IDEVARS.bDevice], DEVICE_JRIDE_ISA
	xchg	bx, ax				; Restore BX
	je		SHORT %1
%endmacro

%macro CMP_USING_IDEVARS_IN_CSBP_AND_JUMP_IF 2
	cmp		BYTE [cs:bp+IDEVARS.bDevice], %1
	je		SHORT %2
%endmacro



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
%ifdef MODULE_SERIAL
Device_FinalizeDPT:
	; needs to check IDEVARS vs. checking the DPT as the serial bit in the DPT is set in the Finalize routine
	CMP_USING_IDEVARS_IN_CSBP_AND_JUMP_IF DEVICE_SERIAL_PORT, .FinalizeDptForSerialPortDevice
	jmp		IdeDPT_Finalize
.FinalizeDptForSerialPortDevice: 
	jmp		SerialDPT_Finalize

%else	; IDE or JR-IDE/ISA
	Device_FinalizeDPT EQU IdeDPT_Finalize
%endif


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
%ifdef MODULE_JRIDE
	%ifdef MODULE_SERIAL				; IDE + JR-IDE/ISA + Serial
	Device_ResetMasterAndSlaveController:
		TEST_USIGN_DPT_AND_JUMP_IF_SERIAL_DEVICE ReturnSuccessForSerialPort
		CMP_USING_DPT_AND_JUMP_IF_JRIDE_DEVICE .ResetJrIDE
		jmp		IdeCommand_ResetMasterAndSlaveController

	%else								; IDE + JR-IDE/ISA
	Device_ResetMasterAndSlaveController:
		CMP_USING_DPT_AND_JUMP_IF_JRIDE_DEVICE .ResetJrIDE
		jmp		IdeCommand_ResetMasterAndSlaveController
	%endif

%elifdef MODULE_SERIAL					; IDE + Serial
Device_ResetMasterAndSlaveController:
	TEST_USIGN_DPT_AND_JUMP_IF_SERIAL_DEVICE ReturnSuccessForSerialPort
	jmp		IdeCommand_ResetMasterAndSlaveController

%else									; IDE
	Device_ResetMasterAndSlaveController EQU IdeCommand_ResetMasterAndSlaveController
%endif

%ifdef MODULE_JRIDE
.ResetJrIDE:
	jmp		MemIdeCommand_ResetMasterAndSlaveController
%endif


;--------------------------------------------------------------------
; Device_IdentifyToBufferInESSIwithDriveSelectByteInBH
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Select Register
;		DS:		Segment to RAMVARS
;		ES:SI:	Ptr to normalized buffer to receive 512-byte IDE Information
;		CS:BP:	Ptr to IDEVARS
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BL, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
%ifdef MODULE_JRIDE
	%ifdef MODULE_SERIAL				; IDE + JR-IDE/ISA + Serial
	Device_IdentifyToBufferInESSIwithDriveSelectByteInBH:
		CMP_USING_IDEVARS_IN_CSBP_AND_JUMP_IF DEVICE_SERIAL_PORT, .IdentifyDriveFromSerialPort
		CMP_USING_IDEVARS_IN_CSBP_AND_JUMP_IF DEVICE_JRIDE_ISA, .IdentifyDriveFromJrIde
		jmp		IdeCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH

	%else								; IDE + JR-IDE/ISA
	Device_IdentifyToBufferInESSIwithDriveSelectByteInBH:
		CMP_USING_IDEVARS_IN_CSBP_AND_JUMP_IF DEVICE_JRIDE_ISA, .IdentifyDriveFromJrIde
		jmp		IdeCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
	%endif

%elifdef MODULE_SERIAL					; IDE + Serial
Device_IdentifyToBufferInESSIwithDriveSelectByteInBH:
	CMP_USING_IDEVARS_IN_CSBP_AND_JUMP_IF DEVICE_SERIAL_PORT, .IdentifyDriveFromSerialPort
	jmp		IdeCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH

%else									; IDE
	Device_IdentifyToBufferInESSIwithDriveSelectByteInBH EQU IdeCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
%endif

%ifdef MODULE_JRIDE
.IdentifyDriveFromJrIde:
	jmp		MemIdeCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
%endif

%ifdef MODULE_SERIAL
.IdentifyDriveFromSerialPort:
	jmp		SerialCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
%endif


;--------------------------------------------------------------------
; Device_OutputCommandWithParameters
;	Parameters:
;		BH:		Default system timer ticks for timeout (can be ignored)
;		BL:		IDE Status Register bit to poll after command
;		ES:SI:	Ptr to normalized buffer (for data transfer commands)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CX:		Number of successfully transferred sectors (for transfer commands)
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, (CX), DX, (ES:SI for data transfer commands)
;--------------------------------------------------------------------
%ifdef MODULE_JRIDE
	%ifdef MODULE_SERIAL				; IDE + JR-IDE/ISA + Serial
	Device_OutputCommandWithParameters:
		TEST_USIGN_DPT_AND_JUMP_IF_SERIAL_DEVICE .OutputCommandToSerialPort
		CMP_USING_DPT_AND_JUMP_IF_JRIDE_DEVICE .OutputCommandToJrIDE
		jmp		IdeCommand_OutputWithParameters

	%else								; IDE + JR-IDE/ISA
	Device_OutputCommandWithParameters:
		CMP_USING_DPT_AND_JUMP_IF_JRIDE_DEVICE .OutputCommandToJrIDE
		jmp		IdeCommand_OutputWithParameters
	%endif

%elifdef MODULE_SERIAL					; IDE + Serial
Device_OutputCommandWithParameters:
	TEST_USIGN_DPT_AND_JUMP_IF_SERIAL_DEVICE .OutputCommandToSerialPort
	jmp		IdeCommand_OutputWithParameters

%else									; IDE
	Device_OutputCommandWithParameters EQU IdeCommand_OutputWithParameters
%endif

%ifdef MODULE_JRIDE
ALIGN JUMP_ALIGN
.OutputCommandToJrIDE:
	jmp		MemIdeCommand_OutputWithParameters
%endif

%ifdef MODULE_SERIAL
ALIGN JUMP_ALIGN
.OutputCommandToSerialPort:
	jmp		SerialCommand_OutputWithParameters
%endif


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
%ifdef MODULE_JRIDE
	%ifdef MODULE_SERIAL				; IDE + JR-IDE/ISA + Serial
	Device_SelectDrive:
		TEST_USIGN_DPT_AND_JUMP_IF_SERIAL_DEVICE ReturnSuccessForSerialPort
		CMP_USING_DPT_AND_JUMP_IF_JRIDE_DEVICE .SelectJrIdeDrive
		jmp		IdeCommand_SelectDrive

	%else								; IDE + JR-IDE/ISA
	Device_SelectDrive:
		CMP_USING_DPT_AND_JUMP_IF_JRIDE_DEVICE .SelectJrIdeDrive
		jmp		IdeCommand_SelectDrive
	%endif

%elifdef MODULE_SERIAL					; IDE + Serial
Device_SelectDrive:
	TEST_USIGN_DPT_AND_JUMP_IF_SERIAL_DEVICE ReturnSuccessForSerialPort
	jmp		IdeCommand_SelectDrive

%else									; IDE
	Device_SelectDrive EQU IdeCommand_SelectDrive
%endif

%ifdef MODULE_JRIDE
ALIGN JUMP_ALIGN
.SelectJrIdeDrive:
	jmp		MemIdeCommand_SelectDrive
%endif

%ifdef MODULE_SERIAL
ALIGN JUMP_ALIGN
ReturnSuccessForSerialPort:
	xor		ax, ax
	ret
%endif
