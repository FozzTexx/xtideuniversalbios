; Project name	:	XTIDE Universal BIOS
; Description	:	Equates for IDE registers, flags and commands.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
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

%ifndef IDEREGISTERS_INC
%define IDEREGISTERS_INC

; IDE Register offsets from Command Block base port
DATA_REGISTER					EQU		0
ERROR_REGISTER_in				EQU		1		; Read only
FEATURES_REGISTER_out			EQU		1		; Write only, ATA1+
;WRITE_PRECOMPENSATION_out		EQU		1		; Write only, Obsolete on ATA1+
SECTOR_COUNT_REGISTER			EQU		2
SECTOR_NUMBER_REGISTER			EQU		3		; LBA Low Register
LOW_CYLINDER_REGISTER			EQU		4		; LBA Middle Register
HIGH_CYLINDER_REGISTER			EQU		5		; LBA High Register
LBA_LOW_REGISTER				EQU		3		; LBA 7...0, LBA48 31...24
LBA_MIDDLE_REGISTER				EQU		4		; LBA 15...8, LBA48 39...32
LBA_HIGH_REGISTER				EQU		5		; LBA 23...16, LBA48 47...40
DRIVE_AND_HEAD_SELECT_REGISTER	EQU		6		; LBA28 27...24
STATUS_REGISTER_in				EQU		7		; Read only
COMMAND_REGISTER_out			EQU		7		; Write only
;XTIDE_DATA_HIGH_REGISTER		EQU		8		; Non-standard (actually first Control Block reg)

; IDE Register offsets from Control Block base port
; (usually Command Block base port + 200h)
ALTERNATE_STATUS_REGISTER_in	EQU		6		; Read only
DEVICE_CONTROL_REGISTER_out		EQU		6		; Write only
;DRIVE_ADDRESS_REGISTER			EQU		7		; Obsolete on ATA2+

; Bit mask for XTIDE mod with reversed A0 and A3 address lines
MASK_A3_AND_A0_ADDRESS_LINES	EQU		((1<<3) | (1<<0))

; Bit definitions for IDE Error Register
FLG_ERROR_BBK			EQU		(1<<7)	; Bad Block Detected (reserved on ATA2+, command dependent on ATA4+)
FLG_ERROR_UNC			EQU		(1<<6)	; Uncorrectable Data Error (command dependent on ATA4+)
FLG_ERROR_MC			EQU		(1<<5)	; Media Changed (command dependent on ATA4+)
FLG_ERROR_IDNF			EQU		(1<<4)	; ID Not Found (command dependent on ATA4+)
FLG_ERROR_MCR			EQU		(1<<3)	; Media Change Request (command dependent on ATA4+)
FLG_ERROR_ABRT			EQU		(1<<2)	; Command Aborted
FLG_ERROR_TK0NF			EQU		(1<<1)	; Track 0 Not Found (command dependent on ATA4+)
FLG_ERROR_AMNF			EQU		(1<<0)	; Address Mark Not Found (command dependent on ATA4+)

; Bit definitions for IDE Drive and Head Select Register
FLG_DRVNHEAD_LBA		EQU		(1<<6)	; LBA Addressing enabled (instead of CHS)
FLG_DRVNHEAD_DRV		EQU		(1<<4)	; Drive Select (0=Master, 1=Slave)
MASK_DRVNHEAD_HEAD		EQU		0Fh		; Head select bits (bits 0...3)
MASK_DRVNHEAD_SET		EQU		0A0h	; Bits that must be set to 1 on ATA1 (reserved on ATA2+)

; Bit definitions for IDE Status Register
FLG_STATUS_BSY			EQU		(1<<7)	; Busy (other flags undefined when set)
FLG_STATUS_DRDY			EQU		(1<<6)	; Device Ready
FLG_STATUS_DF			EQU		(1<<5)	; Device Fault (command dependent on ATA4+)
FLG_STATUS_DSC			EQU		(1<<4)	; Device Seek Complete (command dependent on ATA4+)
FLG_STATUS_DRQ			EQU		(1<<3)	; Data Request
FLG_STATUS_CORR			EQU		(1<<2)	; Corrected Data (obsolete on ATA4+)
FLG_STATUS_IDX			EQU		(1<<1)	; Index (vendor specific on ATA2+, obsolete on ATA4+)
FLG_STATUS_ERR			EQU		(1<<0)	; Error

; Bit definitions for IDE Device Control Register
; Bit 0 must be zero, unlisted bits are reserved.
;FLG_DEVCONTROL_HOB		EQU		(1<<7)	; High Order Byte (ATA6+)
FLG_DEVCONTROL_O8H		EQU		(1<<3)	; Drive has more than 8 heads (pre-ATA only, 1 on ATA1, reserved on ATA2+)
FLG_DEVCONTROL_SRST		EQU		(1<<2)	; Software Reset
FLG_DEVCONTROL_nIEN		EQU		(1<<1)	; Negated Interrupt Enable (IRQ disabled when set)

; Commands for IDE Controller
COMMAND_RECALIBRATE						EQU		10h
COMMAND_READ_SECTORS					EQU		20h
COMMAND_READ_SECTORS_EXT				EQU		24h		; LBA48
COMMAND_WRITE_SECTORS					EQU		30h
COMMAND_WRITE_SECTORS_EXT				EQU		34h		; LBA48
COMMAND_VERIFY_SECTORS					EQU		40h
COMMAND_VERIFY_SECTORS_EXT				EQU		42h		; LBA48
COMMAND_SEEK							EQU		70h
COMMAND_INITIALIZE_DEVICE_PARAMETERS	EQU		91h
COMMAND_SET_MULTIPLE_MODE				EQU		0C6h	; Block mode
COMMAND_READ_MULTIPLE					EQU		0C4h	; Block mode
COMMAND_READ_MULTIPLE_EXT				EQU		29h		; LBA48, Block mode
COMMAND_WRITE_MULTIPLE					EQU		0C5h	; Block mode
COMMAND_WRITE_MULTIPLE_EXT				EQU		39h		; LBA48, Block mode
COMMAND_IDENTIFY_DEVICE					EQU		0ECh
COMMAND_SET_FEATURES					EQU		0EFh
COMMAND_IDLE							EQU		0E3h


; Subcommands for COMMAND_SET_FEATURES
FEATURE_ENABLE_8BIT_PIO_TRANSFER_MODE	EQU		01h		; CFA feature set only
FEATURE_ENABLE_WRITE_CACHE				EQU		02h
FEATURE_DISABLE_8BIT_PIO_TRANSFER_MODE	EQU		81h		; CFA feature set only
FEATURE_DISABLE_WRITE_CACHE				EQU		82h		; Can also be used to flush cache
FEATURE_SET_TRANSFER_MODE				EQU		03h		; Transfer mode goes to the Sector Count Register
	PIO_DEFAULT_MODE					EQU		0h
	PIO_DEFAULT_MODE_DISABLE_IORDY		EQU		1h
	PIO_FLOW_CONTROL_MODE_xxx			EQU		(1<<3)	; Bits 2...0 hold the PIO mode


%endif ; IDEREGISTERS_INC
