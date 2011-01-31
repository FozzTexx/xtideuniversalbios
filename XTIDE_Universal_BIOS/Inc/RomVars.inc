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
	.bIdeCnt		resb	1	; Number of available IDE controllers
	.bBootDrv		resb	1	; Boot Menu default drive
	.bBootDelay		resb	1	; Boot Menu selection delay in seconds
	.bMinFddCnt		resb	1	; Minimum number of Floppy Drives
	.bStealSize		resb	1	; Number of 1kB blocks stolen from 640kB base RAM

	.ideVars0		resb	IDEVARS_size
	.ideVars1		resb	IDEVARS_size
	.ideVars2		resb	IDEVARS_size
	.ideVars3		resb	IDEVARS_size
endstruc

; Bit defines for ROMVARS.wFlags
FLG_ROMVARS_FULLMODE	EQU	(1<<0)	; Full operating mode (steals base RAM, supports EBIOS etc.)
FLG_ROMVARS_DRVXLAT		EQU	(1<<2)	; Enable drive number translation


; Controller specific variables
struc IDEVARS
	.wPort				resb	2	; IDE Base Port for Command Block (usual) Registers
	.wPortCtrl			resb	2	; IDE Base Port for Control Block Registers
	.bBusType			resb	1	; Bus type
	.bIRQ				resb	1	; Interrupt Request Number
	.drvParamsMaster	resb	DRVPARAMS_size
	.drvParamsSlave		resb	DRVPARAMS_size
endstruc

; Bus types for IDEVARS.bBusType
BUS_TYPE_8_DUAL			EQU	(0<<1)	; XTIDE transfers with two 8-bit data ports
BUS_TYPE_16				EQU	(1<<1)	; Normal 16-bit AT-IDE transfers
BUS_TYPE_32				EQU	(2<<1)	; 32-bit VLB and PCI transfers
BUS_TYPE_8_SINGLE		EQU	(3<<1)	; 8-bit transfers with single 8-bit data port


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
