; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for ROMVARS struct containing variables stored
;					in BIOS ROM.

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

%ifndef ROMVARS_INC
%define ROMVARS_INC

; ROM Variables. Written to the ROM image before flashing.
struc ROMVARS
	.wRomSign			resb	2	; ROM Signature (AA55h)
	.bRomSize			resb	1	; ROM size in 512 byte blocks
	.rgbJump			resb	3	; First instruction to ROM init (jmp)

	.rgbSign			resb	8	; Signature for XTIDE Configurator Program
	.szTitle			resb	31	; BIOS title string
	.szVersion			resb	25	; BIOS version string

	.wFlags				resb	2	; Word for ROM flags
	.wDisplayMode		resb	2	; Display mode for boot menu
	.wfDisplayBootMenu:				; Zero = no Boot Menu, non-zero = Boot Menu timeout
	.wBootTimeout		resb	2	; Boot Menu selection timeout in system timer ticks
	.bIdeCnt			resb	1	; Number of available IDE controllers
	.bBootDrv			resb	1	; Boot Menu default drive
	.bMinFddCnt			resb	1	; Minimum number of Floppy Drives
	.bStealSize			resb	1	; Number of 1kB blocks stolen from 640kB base RAM
	.bIdleTimeout		resb	1	; Standby timer value

	.ideVarsBegin:
	.ideVars0			resb	IDEVARS_size
	.ideVars1			resb	IDEVARS_size
	.ideVars2			resb	IDEVARS_size
	.ideVars3			resb	IDEVARS_size

%ifdef MODULE_SERIAL
	.ideVarsSerialAuto	resb	IDEVARS_size
%endif

	.ideVarsEnd:
endstruc

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if ROMVARS.ideVarsEnd & 0xff00 <> 0
		%error ".ideVars structures must fit within the first 256 bytes of the ROM image"
	%endif
	%if (ROMVARS.ideVarsEnd - ROMVARS.ideVarsBegin) = 0
		%error "there must be at least one .ideVars structure, it would be bizarre if this were not true, but it is assumed in the ah0h reset code."
	%endif
%endif

; Bit defines for ROMVARS.wFlags
FLG_ROMVARS_FULLMODE				EQU	(1<<0)	; Full operating mode (steals base RAM, supports EBIOS etc.)
FLG_ROMVARS_DRVXLAT					EQU	(1<<2)	; Enable drive number translation
FLG_ROMVARS_SERIAL_SCANDETECT 		EQU	(1<<3)	; Scan COM ports at the end of drive detection.  Can also be invoked
												; by holding down the ALT key at the end of drive detection.
												; (Conveniently, this is 8, a fact we exploit when testing the bit)
FLG_ROMVARS_MODULE_ADVATA			EQU	(1<<4)	; Here in case the configuration needs to know functionality is present
FLG_ROMVARS_MODULE_JRIDE			EQU	(1<<5)	; Here in case the configuration needs to know functionality is present
FLG_ROMVARS_MODULE_SERIAL			EQU (1<<6)	; Here in case the configuration needs to know functionality is present
FLG_ROMVARS_MODULE_EBIOS			EQU (1<<7)	; Here in case the configuration needs to know functionality is present

; Boot Menu Display Modes (see Assembly Library Display.inc for standard modes)
DEFAULT_TEXT_MODE		EQU	4


; Controller specific variables
struc IDEVARS
;;; Word 0
	.wSerialPortAndBaud:					; Serial connection port (low, divided by 4) and baud rate divisor (high)
	.wPort:									; IDE Base Port for Command Block (usual) Registers
	.bSerialPort				resb	1
	.bSerialBaud				resb	1

;;; Word 1
	.wPortCtrl:
	.bSerialUnused				resb	1	; IDE Base Port for Control Block Registers

	.wSerialCOMPortCharAndDevice:			; In DetectPrint, we grab the COM Port char and Device at the same time
	.bSerialCOMPortChar			resb	1	; Serial connection COM port number/letter

;;; Word 2
	.bDevice					resb	1	; Device type

	.bIRQ						resb	1	; Interrupt Request Number

;;; And more...
	.drvParamsMaster			resb	DRVPARAMS_size
	.drvParamsSlave				resb	DRVPARAMS_size
endstruc

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if IDEVARS.bSerialCOMPortChar+1 != IDEVARS.bDevice
		%error "IDEVARS.bSerialCOMPortChar needs to come immediately before IDEVARS.bDevice so that both bytes can be fetched at the same time inside DetectPrint.asm"
	%endif
%endif

; Default values for Port and PortCtrl, shared with the configurator
;
DEVICE_XTIDE_DEFAULT_PORT				EQU		300h
DEVICE_XTIDE_DEFAULT_PORTCTRL			EQU		308h
DEVICE_ATA_DEFAULT_PORT					EQU		1F0h
DEVICE_ATA_DEFAULT_PORTCTRL				EQU		3F0h
DEVICE_ATA_DEFAULT_SECONDARY_PORT		EQU		170h
DEVICE_ATA_DEFAULT_SECONDARY_PORTCTRL	EQU		370h

; Device types for IDEVARS.bDevice
;
DEVICE_XTIDE_REV1						EQU	(0<<1)
DEVICE_XTIDE_REV2						EQU	(1<<1)	; Or rev 1 with swapped A0 and A3 (chuck mod)
DEVICE_FAST_XTIDE						EQU	(2<<1)	; (CPLD v2 project)
DEVICE_16BIT_ATA						EQU	(3<<1)
DEVICE_32BIT_ATA						EQU	(4<<1)
DEVICE_SERIAL_PORT						EQU	(5<<1)
DEVICE_JRIDE_ISA						EQU	(6<<1)


; Master/Slave drive specific parameters
struc DRVPARAMS
	.wFlags			resb	2	; Drive flags
	.dwMaximumLBA:				; User specified maximum number of sectors
	.wCylinders		resb	2	; User specified cylinders (1...16383)
	.wHeadsAndSectors:
	.bHeads			resb	1	; User specified Heads (1...16)
	.bSect			resb	1	; User specified Sectors per track (1...63)
endstruc

; Bit defines for DRVPARAMS.wFlags
MASK_DRVPARAMS_WRITECACHE	EQU	(3<<0)	; Drive internal write cache settings (must start at bit 0)
FLG_DRVPARAMS_BLOCKMODE		EQU	(1<<2)	; Enable Block mode transfers
FLG_DRVPARAMS_USERCHS		EQU	(1<<3)	; User specified P-CHS values
FLG_DRVPARAMS_USERLBA		EQU	(1<<4)	; User specified LBA values

; Drive Write Cache values for DRVPARAMS.wFlags.MASK_DRVPARAMS_WRITECACHE
DEFAULT_WRITE_CACHE			EQU	0		; Must be 0
DISABLE_WRITE_CACHE			EQU	1
ENABLE_WRITE_CACHE			EQU	2

%endif ; ROMVARS_INC
