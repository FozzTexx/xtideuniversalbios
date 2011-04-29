; Project name	:	XTIDE Universal BIOS
; Authors		:	Tomi Tilli
;				:	aitotat@gmail.com
;				:
;				:	Krister Nordvall
;				:	krille_n_@hotmail.com
;				:
; Description	:	Main file for BIOS. This is the only file that needs
;					to be compiled since other files are included to this
;					file (so no linker needed, Nasm does it all).

ORG 000h						; Code start offset 0000h


; Included .inc files
%include "AssemblyLibrary.inc"	; Assembly Library. Must be included first!
%include "Interrupts.inc"		; For interrupt equates
%include "ATA_ID.inc"			; For ATA Drive Information structs
%include "IdeRegisters.inc"		; For ATA Registers, flags and commands
%include "Int13h.inc"			; Equates for INT 13h functions
%include "CustomDPT.inc"		; For Disk Parameter Table
%include "RomVars.inc"			; For ROMVARS and IDEVARS structs
%include "RamVars.inc"			; For RAMVARS struct
%include "BootVars.inc"			; For BOOTVARS and BOOTNFO structs
%include "BootMenu.inc"			; For Boot Menu
%include "IDE_8bit.inc"			; For IDE 8-bit data port macros
%include "DeviceIDE.inc"		; For IDE device equates


; Section containing code
SECTION .text

; ROM variables (must start at offset 0)
CNT_ROM_BLOCKS		EQU		16	; 16 * 512B = 8kB BIOS
istruc ROMVARS
	at	ROMVARS.wRomSign,	dw	0AA55h			; PC ROM signature
	at	ROMVARS.bRomSize,	db	CNT_ROM_BLOCKS	; ROM size in 512B blocks
	at	ROMVARS.rgbJump, 	jmp	Initialize_FromMainBiosRomSearch
	at	ROMVARS.rgbSign,	db	"XTIDE120"		; Signature for flash program
	at	ROMVARS.szTitle
		db	"-=XTIDE Universal BIOS"
%ifdef USE_AT
		db	" (AT)=-",NULL
%elifdef USE_186
		db	" (XT+)=-",NULL
%else
		db	" (XT)=-",NULL
%endif
	at	ROMVARS.szVersion,	db	"v1.2.0_wip (",__DATE__,")",NULL

;---------------------------;
; AT Build default settings ;
;---------------------------;
%ifdef USE_AT
	at	ROMVARS.wFlags,			dw	FLG_ROMVARS_FULLMODE | FLG_ROMVARS_DRVXLAT
	at	ROMVARS.wDisplayMode,	dw	DEFAULT_TEXT_MODE
	at	ROMVARS.wBootTimeout,	dw	30 * TICKS_PER_SECOND	; Boot Menu selection timeout
	at	ROMVARS.bIdeCnt,		db	4						; Number of supported controllers
	at	ROMVARS.bBootDrv,		db	80h						; Boot Menu default drive
	at	ROMVARS.bMinFddCnt, 	db	0						; Do not force minimum number of floppy drives
	at	ROMVARS.bStealSize,		db	1						; Steal 1kB from base memory

	at	ROMVARS.ideVars0+IDEVARS.wPort,			dw	1F0h			; Controller Command Block base port
	at	ROMVARS.ideVars0+IDEVARS.wPortCtrl,		dw	3F0h			; Controller Control Block base port
	at	ROMVARS.ideVars0+IDEVARS.bDevice,		db	DEVICE_16BIT_ATA
	at	ROMVARS.ideVars0+IDEVARS.bIRQ,			db	14
	at	ROMVARS.ideVars0+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE
	at	ROMVARS.ideVars0+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE

	at	ROMVARS.ideVars1+IDEVARS.wPort,			dw	170h			; Controller Command Block base port
	at	ROMVARS.ideVars1+IDEVARS.wPortCtrl,		dw	370h			; Controller Control Block base port
	at	ROMVARS.ideVars1+IDEVARS.bDevice,		db	DEVICE_16BIT_ATA
	at	ROMVARS.ideVars1+IDEVARS.bIRQ,			db	15
	at	ROMVARS.ideVars1+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE
	at	ROMVARS.ideVars1+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE

	at	ROMVARS.ideVars2+IDEVARS.wPort,			dw	300h			; Controller Command Block base port
	at	ROMVARS.ideVars2+IDEVARS.wPortCtrl,		dw	308h			; Controller Control Block base port
	at	ROMVARS.ideVars2+IDEVARS.bDevice,		db	DEVICE_8BIT_DUAL_PORT_XTIDE
	at	ROMVARS.ideVars2+IDEVARS.bIRQ,			db	0
	at	ROMVARS.ideVars2+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE
	at	ROMVARS.ideVars2+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE

	at	ROMVARS.ideVars3+IDEVARS.wPort,			dw	168h			; Controller Command Block base port
	at	ROMVARS.ideVars3+IDEVARS.wPortCtrl,		dw	368h			; Controller Control Block base port
	at	ROMVARS.ideVars3+IDEVARS.bDevice,		db	DEVICE_16BIT_ATA
	at	ROMVARS.ideVars3+IDEVARS.bIRQ,			db	0
	at	ROMVARS.ideVars3+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE
	at	ROMVARS.ideVars3+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE
%else
;-----------------------------------;
; XT and XT+ Build default settings ;
;-----------------------------------;
	at	ROMVARS.wFlags,			dw	FLG_ROMVARS_DRVXLAT
	at	ROMVARS.wDisplayMode,	dw	DEFAULT_TEXT_MODE
	at	ROMVARS.wBootTimeout,	dw	30 * TICKS_PER_SECOND	; Boot Menu selection timeout
	at	ROMVARS.bIdeCnt,		db	1						; Number of supported controllers
	at	ROMVARS.bBootDrv,		db	80h						; Boot Menu default drive
	at	ROMVARS.bMinFddCnt, 	db	1						; Assume at least 1 floppy drive present if autodetect fails
	at	ROMVARS.bStealSize,		db	1						; Steal 1kB from base memory in full mode

	at	ROMVARS.ideVars0+IDEVARS.wPort,			dw	300h			; Controller Command Block base port
	at	ROMVARS.ideVars0+IDEVARS.wPortCtrl,		dw	308h			; Controller Control Block base port
	at	ROMVARS.ideVars0+IDEVARS.bDevice,		db	DEVICE_8BIT_DUAL_PORT_XTIDE
	at	ROMVARS.ideVars0+IDEVARS.bIRQ,			db	0				; IRQ
	at	ROMVARS.ideVars0+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE
	at	ROMVARS.ideVars0+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE

	at	ROMVARS.ideVars1+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE
	at	ROMVARS.ideVars1+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE

	at	ROMVARS.ideVars2+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE
	at	ROMVARS.ideVars2+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE

	at	ROMVARS.ideVars3+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE
	at	ROMVARS.ideVars3+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags,	db	FLG_DRVPARAMS_BLOCKMODE
%endif
iend


; Include .asm files (static data and libraries)
%include "AssemblyLibrary.asm"
%include "Strings.asm"			; For BIOS message strings

; Include .asm files (Initialization and drive detection)
%include "Initialize.asm"		; For BIOS initialization
%include "Interrupts.asm"		; For Interrupt initialization
%include "RamVars.asm"			; For RAMVARS initialization and access
%include "CreateDPT.asm"		; For creating DPTs
%include "FindDPT.asm"			; For finding DPTs
%include "AccessDPT.asm"		; For accessing DPTs
%include "BootInfo.asm"			; For creating BOOTNFO structs
%include "AtaID.asm"			; For ATA Identify Device information
%include "DetectDrives.asm"		; For detecting IDE drives
%include "DetectPrint.asm"		; For printing drive detection strings

; Include .asm files (boot menu)
%include "BootMenu.asm"			; For Boot Menu operations
%include "BootMenuEvent.asm"	; For menu library event handling
%include "FloppyDrive.asm"		; Floppy Drive related functions
%include "BootSector.asm"		; For loading boot sector
%include "BootPrint.asm"		; For printing boot information
%include "BootMenuPrint.asm"	; For printing Boot Menu strings
%include "BootMenuPrintCfg.asm"	; For printing hard disk configuration

; Include .asm files (general drive accessing)
%include "DriveXlate.asm"		; For swapping drive numbers
%include "HAddress.asm"			; For sector address translations
%include "HTimer.asm"			; For timeout and delay

; Include .asm files (Interrupt handlers)
%include "Int13h.asm"			; For Int 13h, Disk functions
%ifndef USE_AT
	%include "Int19hLate.asm"	; For late initialization
%endif
%include "Int19hMenu.asm"		; For Int 19h, Boot Loader for Boot Menu

; Include .asm files (Hard Disk BIOS functions)
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
%include "AH23h_HFeatures.asm"	; Required by Int13h_Jump.asm
%include "AH24h_HSetBlocks.asm"	; Required by Int13h_Jump.asm
%include "AH25h_HDrvID.asm"		; Required by Int13h_Jump.asm
%include "Device.asm"
%include "Idepack.asm"

; IDE Device support
%include "IdeCommand.asm"
%include "IdeDPT.asm"
%include "IdeIO.asm"
%include "IdeIrq.asm"
%include "IdeTransfer.asm"
%include "IdeWait.asm"
%include "IdeError.asm"			; Must be included after IdeWait.asm

; Serial Port Device support
%include "SerialCommand.asm"
%include "SerialDPT.asm"


; Fill with zeroes until size is what we want
;times (CNT_ROM_BLOCKS*512)-($-$$) db 0
