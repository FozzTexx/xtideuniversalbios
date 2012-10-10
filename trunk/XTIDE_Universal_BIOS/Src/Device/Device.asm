; Project name	:	XTIDE Universal BIOS
; Description	:	Command and port direction functions for different device types.
		
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


%macro TEST_USING_DPT_AND_JUMP_IF_SERIAL_DEVICE 1
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE
	jnz		SHORT %1
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
%ifdef MODULE_SERIAL	; IDE + Serial
Device_FinalizeDPT:
	; needs to check IDEVARS vs. checking the DPT as the serial bit in the DPT is set in the Finalize routine
	CMP_USING_IDEVARS_IN_CSBP_AND_JUMP_IF	DEVICE_SERIAL_PORT, .FinalizeDptForSerialPortDevice
	jmp		IdeDPT_Finalize
.FinalizeDptForSerialPortDevice:
	jmp		SerialDPT_Finalize

%else					; IDE
	Device_FinalizeDPT		EQU		IdeDPT_Finalize
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
%ifdef MODULE_SERIAL	; IDE + Serial
Device_ResetMasterAndSlaveController:
	TEST_USING_DPT_AND_JUMP_IF_SERIAL_DEVICE	ReturnSuccessForSerialPort
	jmp		IdeCommand_ResetMasterAndSlaveController

%else					; IDE
	Device_ResetMasterAndSlaveController	EQU		IdeCommand_ResetMasterAndSlaveController
%endif


;--------------------------------------------------------------------
; Device_IdentifyToBufferInESSIwithDriveSelectByteInBH
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Select Register
;		DX:		Autodetected port (for devices that support autodetection)
;		DS:		Segment to RAMVARS
;		ES:SI:	Ptr to normalized buffer to receive 512-byte IDE Information
;		CS:BP:	Ptr to IDEVARS
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
%ifdef MODULE_SERIAL	; IDE + Serial
Device_IdentifyToBufferInESSIwithDriveSelectByteInBH:
	CMP_USING_IDEVARS_IN_CSBP_AND_JUMP_IF	DEVICE_SERIAL_PORT, .IdentifyDriveFromSerialPort
	jmp		IdeCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
.IdentifyDriveFromSerialPort:
	jmp		SerialCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH

%else					; IDE
	Device_IdentifyToBufferInESSIwithDriveSelectByteInBH	EQU		IdeCommand_IdentifyDeviceToBufferInESSIwithDriveSelectByteInBH
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
%ifdef MODULE_SERIAL	; IDE + Serial
ALIGN JUMP_ALIGN
Device_OutputCommandWithParameters:
	TEST_USING_DPT_AND_JUMP_IF_SERIAL_DEVICE .OutputCommandToSerialPort
	jmp		IdeCommand_OutputWithParameters

ALIGN JUMP_ALIGN
.OutputCommandToSerialPort:
	jmp		SerialCommand_OutputWithParameters

%else					; IDE
	Device_OutputCommandWithParameters		EQU		IdeCommand_OutputWithParameters
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
%ifdef MODULE_SERIAL	; IDE + Serial
Device_SelectDrive:
	TEST_USING_DPT_AND_JUMP_IF_SERIAL_DEVICE	ReturnSuccessForSerialPort
	jmp		IdeCommand_SelectDrive

%else					; IDE
	Device_SelectDrive		EQU		IdeCommand_SelectDrive
%endif


%ifdef MODULE_SERIAL
ALIGN JUMP_ALIGN
ReturnSuccessForSerialPort:
	xor		ax, ax
	ret
%endif
