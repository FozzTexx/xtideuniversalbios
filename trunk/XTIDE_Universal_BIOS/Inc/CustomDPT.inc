; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for DPT structs containing custom
;					Disk Parameter Table used by this BIOS.

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

%ifndef CUSTOMDPT_INC
%define CUSTOMDPT_INC

; Base DPT for all device types
struc DPT	; 10 bytes
	; General Disk Parameter Table related
	.wFlags:
	.bFlagsLow				resb	1
	.bFlagsHigh				resb	1
	.bIdevarsOffset			resb	1	; Offset to IDEVARS for this drive

	; IDE Drive related
	; .bLbaHeads and .twLbaSectors are used for LBA addressing only.
	.bLbaHeads:				resb	1	; Number of LBA assisted heads (1...255)
	.twLbaSectors			resb	2	; 48-bit sector count for LBA addressing

	; .wPchsCylinders and .bPchsSectors are used for CHS addressing only.
	.wPchsCylinders			resb	2	; Number of P-CHS Cylinders (1...16383)
	.wPchsHeadsAndSectors:
	.bPchsHeads				resb	1	; Number of P-CHS heads (1...16)
	.bPchsSectors			resb	1	; Number of P-CHS Sectors per Track (1...63)
endstruc

	; Bit definitions for DPT.bFlagsLow
	MASKL_DPT_CHS_SHIFT_COUNT					EQU	(7<<0)	; Bits 0...2, P-CHS to L-CHS bit shift count (0...4)
	FLGL_DPT_SLAVE								EQU	FLG_DRVNHEAD_DRV	; (1<<4), Drive is slave drive
	MASKL_DPT_ADDRESSING_MODE					EQU	(3<<5)	; Bits 5..6, Addressing Mode (bit 6 == FLG_DRVNHEAD_LBA)
	FLGL_DPT_ENABLE_IRQ							EQU	(1<<7)

	; Bit definitions for DPT.bFlagsHigh
	FLGH_DPT_BLOCK_MODE_SUPPORTED				EQU	(1<<1)	; Use block transfer commands (must be bit 1!)
	FLGH_DPT_SERIAL_DEVICE						EQU	(1<<2)	; Serial Port Device
	FLGH_DPT_INTERRUPT_IN_SERVICE				EQU	(1<<3)	; Set when waiting for IRQ
	FLGH_DPT_POWER_MANAGEMENT_SUPPORTED			EQU (1<<5)

	; IDE device only
	FLGH_DPT_IORDY								EQU	(1<<7)	; Controller and Drive supports IORDY

	; Serial device only
	FLGH_DPT_SERIAL_FLOPPY						EQU	(1<<4)
	FLGH_DPT_SERIAL_FLOPPY_TYPE_MASK			EQU	0e0h
	FLGH_DPT_SERIAL_FLOPPY_TYPE_FIELD_POSITION	EQU	5

	; Addressing modes for DPT.wFlags
	ADDRESSING_MODE_FIELD_POSITION				EQU		5
	ADDRESSING_MODE_LCHS						EQU		0	; L-CHS Addressing Mode (NORMAL in many other BIOSes)
	ADDRESSING_MODE_PCHS						EQU		1	; P-CHS Addressing Mode (LARGE in many other BIOSes)
	ADDRESSING_MODE_LBA28						EQU		2	; 28-bit LBA Addressing Mode
	ADDRESSING_MODE_LBA48						EQU		3	; 48-bit LBA Addressing Mode


; DPT for ATA devices
struc DPT_ATA	; 10 + 2 bytes = 12 bytes
	.dpt					resb	DPT_size
	.bBlockSize				resb	1	; Current block size in sectors (do not set to zero!)
	.bDevice				resb	1	; Device Type from IDEVARS (overrided when 32-bit controller detected)
endstruc


; Additional variables needed to initialize and reset Advanced IDE Controllers.
; EBDA must be reserved for DPTs when using these!
%ifdef MODULE_ADVANCED_ATA
struc DPT_ADVANCED_ATA
	.dpt_ata				resb	DPT_ATA_size
	.wControllerID			resb	2	; Controller specific ID WORD (from Advanced Controller detection)
	.wControllerBasePort	resb	2	; Advanced Controller port (not IDE port)
	.wMinPioCycleTime		resb	2	; Minimum PIO Cycle Time in ns
	.bPioMode				resb	1	; Best supported PIO mode
	.bInitError				resb	1	; Flags for initialization errors
endstruc
%endif

	; Flags for DPT_ADVANCED_ATA.bInitError
	FLG_INITERROR_FAILED_TO_SELECT_DRIVE				EQU (1<<0)
	FLG_INITERROR_FAILED_TO_INITIALIZE_CHS_PARAMETERS	EQU (1<<1)
	FLG_INITERROR_FAILED_TO_SET_WRITE_CACHE				EQU (1<<2)
	FLG_INITERROR_FAILED_TO_RECALIBRATE_DRIVE			EQU (1<<3)
	FLG_INITERROR_FAILED_TO_SET_BLOCK_MODE				EQU (1<<4)
	FLG_INITERROR_FAILED_TO_SET_PIO_MODE				EQU (1<<5)
	FLG_INITERROR_FAILED_TO_INITIALIZE_STANDBY_TIMER	EQU	(1<<6)


; DPT for Serial devices
%ifdef MODULE_SERIAL
struc DPT_SERIAL
	.dpt					resb	DPT_size
	.wSerialPortAndBaud:
	.bSerialPort			resb	1	; Serial connection I/O port address, divided by 4
	.bSerialBaud			resb 	1	; Serial connection baud rate divisor
endstruc
%endif


; This is the common size for all DPTs. All DPTs must be equal size.
%ifdef MODULE_ADVANCED_ATA
	LARGEST_DPT_SIZE			EQU		DPT_ADVANCED_ATA_size
%else
	LARGEST_DPT_SIZE			EQU		DPT_ATA_size
%endif


	; Number of Sectors per Track is fixed to 63 for LBA assist calculation.
	; 1024 cylinders, 256 heads, 63 sectors = 8.4 GB limit (but DOS does not support more than 255 heads)
	MAX_LCHS_CYLINDERS			EQU		1024
	LBA_ASSIST_SPT				EQU		63


;--------------------------------------------------------------------
; LIMIT_LBA_CYLINDERS_IN_DXAX_TO_LCHS_CYLINDERS
;	Parameters:
;		DX:AX:	Number of LBA cylinders
;	Returns:
;		AX:		Number of L-CHS cylinders
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro LIMIT_LBA_CYLINDERS_IN_DXAX_TO_LCHS_CYLINDERS 0
	test	dx, dx
	jnz		SHORT %%LoadMaxValueToAX
	cmp		ax, MAX_LCHS_CYLINDERS
	jb		SHORT %%NoNeedToModify
%%LoadMaxValueToAX:
	mov		ax, MAX_LCHS_CYLINDERS
%%NoNeedToModify:
%endmacro


%endif ; CUSTOMDPT_INC
