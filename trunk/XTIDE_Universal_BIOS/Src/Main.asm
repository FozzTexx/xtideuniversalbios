; Project name	:	XTIDE Universal BIOS
; Authors		:	Tomi Tilli
;				:	aitotat@gmail.com
;				:
;				:	Greg Lindhorst
;				:	gregli@hotmail.com
;				;
;				:	Krister Nordvall
;				:	krille_n_@hotmail.com
;				:
; Description	:	Main file for BIOS. This is the only file that needs
;					to be compiled since other files are included to this
;					file (so no linker needed, Nasm does it all).

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

	ORG 0							; Code start offset 0000h

	; We must define included libraries before including "AssemblyLibrary.inc".
%define	EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS	; Exclude unused library functions
%ifdef MODULE_BOOT_MENU
	%define MENUEVENT_INLINE_OFFSETS    	; Only one menu required, save space and inline offsets
	%define INCLUDE_MENU_LIBRARY
	%define MENU_NO_ESC					    ; User cannot 'esc' out of the menu
%else	; If no boot menu included
	%define	INCLUDE_DISPLAY_LIBRARY
	%define INCLUDE_KEYBOARD_LIBRARY
	%define INCLUDE_TIME_LIBRARY
%endif


	; Included .inc files
	%include "AssemblyLibrary.inc"	; Assembly Library. Must be included first!
	%include "ModuleDependency.inc"	; Dependency checks for optional modules
	%include "Version.inc"
	%include "ATA_ID.inc"			; For ATA Drive Information structs
	%include "IdeRegisters.inc"		; For ATA Registers, flags and commands
	%include "Int13h.inc"			; Equates for INT 13h functions
	%include "CustomDPT.inc"		; For Disk Parameter Table
	%include "RomVars.inc"			; For ROMVARS and IDEVARS structs
	%include "RamVars.inc"			; For RAMVARS struct
	%include "BootVars.inc"			; For BOOTVARS struct
	%include "IdeIO.inc"			; Macros for IDE port I/O
	%include "DeviceIDE.inc"		; For IDE device equates



; Section containing code
SECTION .text

; ROM variables (must start at offset 0)
CNT_ROM_BLOCKS		EQU		BIOS_SIZE / 512		; number of 512B blocks, 16 = 8kB BIOS
istruc ROMVARS
	at	ROMVARS.wRomSign,	dw	0AA55h			; PC ROM signature
	at	ROMVARS.bRomSize,	db	CNT_ROM_BLOCKS	; ROM size in 512B blocks
	at	ROMVARS.rgbJump,	jmp	Initialize_FromMainBiosRomSearch
	at	ROMVARS.rgbSign,	db	FLASH_SIGNATURE
	at	ROMVARS.szTitle,	db	TITLE_STRING
	at	ROMVARS.szVersion,	db	ROM_VERSION_STRING

;---------------------------;
; AT Build default settings ;
;---------------------------;
%ifdef USE_AT
	at	ROMVARS.wFlags,			dw	FLG_ROMVARS_FULLMODE | MASK_ROMVARS_INCLUDED_MODULES
	at	ROMVARS.wDisplayMode,	dw	DEFAULT_TEXT_MODE
%ifdef MODULE_BOOT_MENU
	at	ROMVARS.wBootTimeout,	dw	BOOT_MENU_DEFAULT_TIMEOUT
%endif
	at	ROMVARS.bIdeCnt,		db	2						; Number of supported controllers
	at	ROMVARS.bBootDrv,		db	80h						; Boot Menu default drive
	at	ROMVARS.bMinFddCnt, 	db	0						; Do not force minimum number of floppy drives
	at	ROMVARS.bStealSize,		db	1						; Steal 1kB from base memory
	at	ROMVARS.bIdleTimeout,	db	0						; Standby timer disabled by default

	at	ROMVARS.ideVars0+IDEVARS.wBasePort,			dw	DEVICE_ATA_PRIMARY_PORT 		; Controller Command Block base port
	at	ROMVARS.ideVars0+IDEVARS.wControlBlockPort,	dw	DEVICE_ATA_PRIMARY_PORTCTRL 	; Controller Control Block base port
	at	ROMVARS.ideVars0+IDEVARS.bDevice,			db	DEVICE_16BIT_ATA
	at	ROMVARS.ideVars0+IDEVARS.bIRQ,				db	0
	at	ROMVARS.ideVars0+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	dw	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
	at	ROMVARS.ideVars0+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	dw	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)

	at	ROMVARS.ideVars1+IDEVARS.wBasePort,			dw	DEVICE_ATA_SECONDARY_PORT
	at	ROMVARS.ideVars1+IDEVARS.wControlBlockPort,	dw	DEVICE_ATA_SECONDARY_PORTCTRL
	at	ROMVARS.ideVars1+IDEVARS.bDevice,			db	DEVICE_16BIT_ATA
	at	ROMVARS.ideVars1+IDEVARS.bIRQ,				db	0
	at	ROMVARS.ideVars1+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	dw	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
	at	ROMVARS.ideVars1+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	dw	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)

	at	ROMVARS.ideVars2+IDEVARS.wBasePort,			dw	DEVICE_ATA_TERTIARY_PORT
	at	ROMVARS.ideVars2+IDEVARS.wControlBlockPort,	dw	DEVICE_ATA_TERTIARY_PORTCTRL
	at	ROMVARS.ideVars2+IDEVARS.bDevice,			db	DEVICE_16BIT_ATA
	at	ROMVARS.ideVars2+IDEVARS.bIRQ,				db	0
	at	ROMVARS.ideVars2+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	dw	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
	at	ROMVARS.ideVars2+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	dw	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)

	at	ROMVARS.ideVars3+IDEVARS.wBasePort,			dw	DEVICE_ATA_QUATERNARY_PORT
	at	ROMVARS.ideVars3+IDEVARS.wControlBlockPort,	dw	DEVICE_ATA_QUATERNARY_PORTCTRL
	at	ROMVARS.ideVars3+IDEVARS.bDevice,			db	DEVICE_16BIT_ATA
	at	ROMVARS.ideVars3+IDEVARS.bIRQ,				db	0
	at	ROMVARS.ideVars3+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	dw	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
	at	ROMVARS.ideVars3+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	dw	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)

%ifdef MODULE_SERIAL
	at	ROMVARS.ideVarsSerialAuto+IDEVARS.bDevice,		db	DEVICE_SERIAL_PORT
%endif
%else
;-----------------------------------;
; XT and XT+ Build default settings ;
;-----------------------------------;
	at	ROMVARS.wFlags,			dw	MASK_ROMVARS_INCLUDED_MODULES
	at	ROMVARS.wDisplayMode,	dw	DEFAULT_TEXT_MODE
%ifdef MODULE_BOOT_MENU
	at	ROMVARS.wBootTimeout,	dw	BOOT_MENU_DEFAULT_TIMEOUT
%endif
%ifdef MODULE_8BIT_IDE_ADVANCED		
	at	ROMVARS.bIdeCnt,		db	2						; Number of supported controllers
%else
	at  ROMVARS.bIdeCnt,		db	1
%endif
	at	ROMVARS.bBootDrv,		db	80h						; Boot Menu default drive
	at	ROMVARS.bMinFddCnt, 	db	0						; Do not force minimum number of floppy drives
	at	ROMVARS.bStealSize,		db	1						; Steal 1kB from base memory in full mode
	at	ROMVARS.bIdleTimeout,	db	0						; Standby timer disabled by default

	at	ROMVARS.ideVars0+IDEVARS.wBasePort,			dw	DEVICE_XTIDE_DEFAULT_PORT			; Controller Command Block base port
	at	ROMVARS.ideVars0+IDEVARS.wControlBlockPort,	dw	DEVICE_XTIDE_DEFAULT_PORTCTRL		; Controller Control Block base port
	at	ROMVARS.ideVars0+IDEVARS.bDevice,			db	DEVICE_8BIT_XTIDE_REV1
	at	ROMVARS.ideVars0+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
	at	ROMVARS.ideVars0+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)

%ifdef MODULE_8BIT_IDE_ADVANCED
	at	ROMVARS.ideVars1+IDEVARS.bXTCFcontrolRegister,	db	XTCF_8BIT_PIO_MODE
	at	ROMVARS.ideVars1+IDEVARS.bDevice,				db	DEVICE_8BIT_XTCF_PIO8
	at	ROMVARS.ideVars1+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
	at	ROMVARS.ideVars1+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
%else
	at	ROMVARS.ideVars1+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
	at	ROMVARS.ideVars1+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
%endif		

	at	ROMVARS.ideVars2+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
	at	ROMVARS.ideVars2+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)

	at	ROMVARS.ideVars3+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)
	at	ROMVARS.ideVars3+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	DISABLE_WRITE_CACHE | FLG_DRVPARAMS_BLOCKMODE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION)

%ifdef MODULE_SERIAL
	at	ROMVARS.ideVarsSerialAuto+IDEVARS.bDevice,		db	DEVICE_SERIAL_PORT
%endif
%endif
iend

	; Strings are first to avoid them moving unnecessarily when code is turned on and off with %ifdef's
	; since some groups of strings need to be on the same 256-byte page.
	;
%ifdef MODULE_STRINGS_COMPRESSED
	%define STRINGSCOMPRESSED_STRINGS
	%include "StringsCompressed.asm"
%else
	%include "Strings.asm"			; For BIOS message strings
%endif

	; Libraries, data, Initialization and drive detection

	%include "AssemblyLibrary.asm"

	; String compression tables need to come after the AssemblyLibrary (since they depend on addresses
	; established in the assembly library), and are unnecessary if strings are not compressed.
	;
%ifdef MODULE_STRINGS_COMPRESSED
	%undef  STRINGSCOMPRESSED_STRINGS
	%define STRINGSCOMPRESSED_TABLES
	%include "StringsCompressed.asm"
%endif

	%include "Initialize.asm"		; For BIOS initialization
	%include "Interrupts.asm"		; For Interrupt initialization
	%include "RamVars.asm"			; For RAMVARS initialization and access
	%include "BootVars.asm"			; For initializing variables used during init and boot
	%include "FloppyDrive.asm"		; Floppy Drive related functions
	%include "CreateDPT.asm"		; For creating DPTs
	%include "FindDPT.asm"			; For finding DPTs
	%include "AccessDPT.asm"		; For accessing DPTs
	%include "AtaGeometry.asm"		; For generating L-CHS parameters
	%include "DrvDetectInfo.asm"	; For creating DRVDETECTINFO structs
	%include "AtaID.asm"			; For ATA Identify Device information
	%include "DetectDrives.asm"		; For detecting IDE drives
	%include "DetectPrint.asm"		; For printing drive detection strings

	; Hotkey Bar
%ifdef MODULE_HOTKEYS
	%include "HotkeyBar.asm"		; For hotkeys during drive detection and boot menu
%endif		
%ifdef MODULE_DRIVEXLATE
	%include "DriveXlate.asm"		; For swapping drive numbers, must come immediately after HotkeyBar.asm
%endif

	; Boot menu
%ifdef MODULE_BOOT_MENU
	%include "BootMenu.asm"			; For Boot Menu operations
	%include "BootMenuEvent.asm"	; For menu library event handling
									; NOTE: BootMenuPrint needs to come immediately after BootMenuEvent
									;       so that jump table entries in BootMenuEvent stay within 8-bits
	%include "BootMenuPrint.asm"	; For printing Boot Menu strings, also includes "BootMenuPrintCfg.asm"
%endif

	; Boot loader
	%include "Int19h.asm"			; For Int 19h, Boot Loader
	%include "BootSector.asm"		; For loading boot sector
	%include "Int19hReset.asm"		; INT 19h handler for proper system reset

	; For all device types
	%include "Idepack.asm"
	%include "Device.asm"
	%include "Timer.asm"			; For timeout and delay

	; IDE Device support
%ifdef MODULE_ADVANCED_ATA
	%include "AdvAtaInit.asm"		; For initializing VLB and PCI controllers
	%include "Vision.asm"			; QDI Vision QD6500 and QD6580 support
%endif
	%include "IdeCommand.asm"
%ifdef MODULE_8BIT_IDE_ADVANCED
	%include "JrIdeTransfer.asm"	; Must be included after IdeCommand.asm
	%include "IdeDmaBlock.asm"
%endif
	%include "IdeTransfer.asm"
	%include "IdePioBlock.asm"
	%include "IdeWait.asm"
	%include "IdeError.asm"			; Must be included after IdeWait.asm
	%include "IdeDPT.asm"
	%include "IdeIO.asm"
%ifdef MODULE_IRQ
	%include "IdeIrq.asm"
%endif

	; Serial Device support
%ifdef MODULE_SERIAL				; Serial Port Device support
	%include "SerialCommand.asm"
	%include "SerialDPT.asm"
%endif

	; INT 13h Hard Disk BIOS functions
	%include "Int13h.asm"			; For Int 13h, Disk functions
	%include "AH0h_HReset.asm"		; Required by Int13h_Jump.asm
	%include "AH1h_HStatus.asm"		; Required by Int13h_Jump.asm
	%include "AH2h_HRead.asm"		; Required by Int13h_Jump.asm
	%include "AH3h_HWrite.asm"		; Required by Int13h_Jump.asm
	%include "AH4h_HVerify.asm"		; Required by Int13h_Jump.asm
	%include "AH8h_HParams.asm"		; Required by Int13h_Jump.asm
	%include "AH9h_HInit.asm"		; Required by Int13h_Jump.asm
	%include "AHCh_HSeek.asm"		; Required by Int13h_Jump.asm
	%include "AHDh_HReset.asm"		; Required by Int13h_Jump.asm
	%include "AH10h_HReady.asm"		; Required by Int13h_Jump.asm
	%include "AH11h_HRecal.asm"		; Required by Int13h_Jump.asm
	%include "AH15h_HSize.asm"		; Required by Int13h_Jump.asm
%ifdef MODULE_8BIT_IDE_ADVANCED
	%include "AH1Eh_XTCF.asm"
%endif
	%include "AH23h_HFeatures.asm"	; Required by Int13h_Jump.asm
	%include "AH24h_HSetBlocks.asm"	; Required by Int13h_Jump.asm
	%include "AH25h_HDrvID.asm"		; Required by Int13h_Jump.asm
	%include "Address.asm"			; For sector address translations
	%include "Prepare.asm"			; For buffer pointer normalization
%ifdef MODULE_EBIOS
	%include "AH42h_ExtendedReadSectors.asm"
	%include "AH43h_ExtendedWriteSectors.asm"
	%include "AH44h_ExtendedVerifySectors.asm"
	%include "AH47h_ExtendedSeek.asm"
	%include "AH48h_GetExtendedDriveParameters.asm"
	%include "AH41h_CheckIfExtensionsPresent.asm"
%endif
