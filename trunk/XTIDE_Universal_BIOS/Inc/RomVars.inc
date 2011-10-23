; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for ROMVARS struct containing variables stored
;					in BIOS ROM.
%ifndef ROMVARS_INC
%define ROMVARS_INC

; ROM Variables. There are written to ROM image before flashing.
struc ROMVARS
	.wRomSign		resb	2	; ROM Signature (AA55h)
	.bRomSize		resb	1	; ROM size in 512 byte blocks
	.rgbJump		resb	3	; First instruction to ROM init (jmp)

	.rgbSign		resb	8	; Signature for XTIDE Configurator Program
	.szTitle		resb	31	; BIOS title string
	.szVersion		resb	25	; BIOS version string

	.wFlags			resb	2	; Word for ROM flags
	.wDisplayMode	resb	2	; Display mode for boot menu
	.wBootTimeout	resb	2	; Boot Menu selection timeout in system timer ticks
	.bIdeCnt		resb	1	; Number of available IDE controllers
	.bBootDrv		resb	1	; Boot Menu default drive
	.bMinFddCnt		resb	1	; Minimum number of Floppy Drives
	.bStealSize		resb	1	; Number of 1kB blocks stolen from 640kB base RAM

	.ideVars0		resb	IDEVARS_size
	.ideVars1		resb	IDEVARS_size
	.ideVars2		resb	IDEVARS_size
	.ideVars3		resb	IDEVARS_size

%ifdef MODULE_SERIAL
	.ideVarsSerialAuto	resb	IDEVARS_size
%endif
endstruc

; Bit defines for ROMVARS.wFlags
FLG_ROMVARS_FULLMODE	EQU	(1<<0)	; Full operating mode (steals base RAM, supports EBIOS etc.)
FLG_ROMVARS_DRVXLAT		EQU	(1<<2)	; Enable drive number translation

%ifdef MODULE_SERIAL
FLG_ROMVARS_MODULE_SERIAL	EQU (1<<3)
%else
FLG_ROMVARS_MODULE_SERIAL   EQU 0
%endif

%ifdef MODULE_EBIOS
FLG_ROMVARS_MODULE_EBIOS	EQU (1<<4)
%else
FLG_ROMVARS_MODULE_EBIOS    EQU 0
%endif

; Boot Menu Display Modes (see Assembly Library Display.inc for standard modes)
DEFAULT_TEXT_MODE		EQU	4


; Controller specific variables
struc IDEVARS
	.wPort				resb	2	; IDE Base Port for Command Block (usual) Registers
	.wPortCtrl			resb	2	; IDE Base Port for Control Block Registers
	.bDevice			resb	1	; Device type
	.bIRQ				resb	1	; Interrupt Request Number
	.drvParamsMaster	resb	DRVPARAMS_size
	.drvParamsSlave		resb	DRVPARAMS_size
endstruc

; Device types for IDEVARS.bDevice
DEVICE_8BIT_DUAL_PORT_XTIDE				EQU	(0<<1)
DEVICE_XTIDE_WITH_REVERSED_A3_AND_A0	EQU	(1<<1)
DEVICE_8BIT_SINGLE_PORT					EQU	(2<<1)
DEVICE_16BIT_ATA						EQU	(3<<1)
DEVICE_32BIT_ATA						EQU	(4<<1)
DEVICE_SERIAL_PORT						EQU	(5<<1)

; Master/Slave drive specific parameters
struc DRVPARAMS
	.wFlags			resb	2	; Drive flags
	.wCylinders		resb	2	; User specified cylinders (1...16383)
	.wHeadsAndSectors:
	.bHeads			resb	1	; User specified Heads (1...16)
	.bSect			resb	1	; User specified Sectors per track (1...63)
endstruc

; Bit defines for DRVPARAMS.wFlags
FLG_DRVPARAMS_USERCHS	EQU	(1<<0)	; User specified P-CHS values
FLG_DRVPARAMS_BLOCKMODE	EQU	(1<<1)	; Enable Block mode transfers


%endif ; ROMVARS_INC
