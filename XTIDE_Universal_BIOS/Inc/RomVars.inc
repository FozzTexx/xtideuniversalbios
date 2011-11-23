; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for ROMVARS struct containing variables stored
;					in BIOS ROM.
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
	.wBootTimeout		resb	2	; Boot Menu selection timeout in system timer ticks
	.bIdeCnt			resb	1	; Number of available IDE controllers
	.bBootDrv			resb	1	; Boot Menu default drive
	.bMinFddCnt			resb	1	; Minimum number of Floppy Drives
	.bStealSize			resb	1	; Number of 1kB blocks stolen from 640kB base RAM

	.ideVars0			resb	IDEVARS_size
	.ideVars1			resb	IDEVARS_size
	.ideVars2			resb	IDEVARS_size
	.ideVars3			resb	IDEVARS_size

%ifdef MODULE_SERIAL
	.ideVarsSerialAuto	resb	IDEVARS_size
%endif
endstruc

; Bit defines for ROMVARS.wFlags
FLG_ROMVARS_FULLMODE				EQU	(1<<0)	; Full operating mode (steals base RAM, supports EBIOS etc.)
FLG_ROMVARS_DRVXLAT					EQU	(1<<2)	; Enable drive number translation
FLG_ROMVARS_SERIAL_SCANDETECT 		EQU	(1<<3)	; Scan COM ports at the end of drive detection.  Can also be invoked
												; by holding down the ALT key at the end of drive detection.
												; (Conveniently, this is 8, a fact we exploit when testing the bit)
FLG_ROMVARS_MODULE_SERIAL			EQU (1<<6)	; Here in case the configuration needs to know functionality is present
FLG_ROMVARS_MODULE_EBIOS			EQU (1<<7)	; Here in case the configuration needs to know functionality is present

; Boot Menu Display Modes (see Assembly Library Display.inc for standard modes)
DEFAULT_TEXT_MODE		EQU	4


; Controller specific variables
struc IDEVARS
	.wPort:									; IDE Base Port for Command Block (usual) Registers
	.bSerialCOMDigit			resb	1	; Serial Device COM Port digit 
	.bSerialPackedPortAndBaud 	resb	1	; Serial Device packed port and baud

	.wPortCtrl:								; IDE Base Port for Control Block Registers
	.wSerialPackedPrintBaud		resb	2	; Serial Device packed baud rate for printing

	.bDevice					resb	1	; Device type
	.bIRQ						resb	1	; Interrupt Request Number
	.drvParamsMaster			resb	DRVPARAMS_size
	.drvParamsSlave				resb	DRVPARAMS_size
endstruc

; Default values for Port and PortCtrl, shared with the configurator
;
DEVICE_XTIDE_DEFAULT_PORT				EQU		300h
DEVICE_XTIDE_DEFAULT_PORTCTRL			EQU		308h
DEVICE_ATA_DEFAULT_PORT					EQU		1F0h
DEVICE_ATA_DEFAULT_PORTCTRL				EQU		3F0h
DEVICE_SERIAL_DEFAULT_COM				EQU		0		; COM1
DEVICE_SERIAL_DEFAULT_BAUD				EQU		1		; 9600

; Device types for IDEVARS.bDevice
;
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


; Defines for IDEVARS.bSerialPackedPortAndBaud (same format used by DPT.bSerialPortAndBaud)
;
; pppp ppbb
;   i/o port address = p * 2 + 240h
;   baud rate = b, where 00 = 2400, 01 = 9600, 10 = 38.4K, 11 = 115.2K
;
; 240h/2400baud corresponds to 0 for a PackedPortAndBaud value, which triggers auto detect code.
; Which means 240h is not usable, and is why ..._MINPORT is 248h.  A value is reserved at the upper
; end of the spectrum in case it is needed (whcih is why it is 430h instead of 438h).
;
DEVICE_SERIAL_PACKEDPORTANDBAUD_PORTMASK			EQU		0fch
DEVICE_SERIAL_PACKEDPORTANDBAUD_PORTBITS			EQU		03fh
DEVICE_SERIAL_PACKEDPORTANDBAUD_PORT_FIELD_POSITION	EQU		2
DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT		EQU		240h
DEVICE_SERIAL_PACKEDPORTANDBAUD_MINPORT				EQU		248h	; minimum port value that the user can set
DEVICE_SERIAL_PACKEDPORTANDBAUD_MAXPORT				EQU		430h	; or ((..._PORTMASK-1) << 1) + ..._STARTINGPORT

DEVICE_SERIAL_PACKEDPORTANDBAUD_BAUDMASK			EQU		3h
DEVICE_SERIAL_PACKEDPORTANDBAUD_BAUDBITS			EQU		3h
DEVICE_SERIAL_PACKEDPORTANDBAUD_BAUD_FIELD_POSITION	EQU		0

; Defines for IDEVARS.wSerialPrintBaud
;
; pppp ppnn nnnn nnnn
;   unsigned number to output = n
;   postfix character = p + '0' (designed for '0' and 'K', although other values are possible)
;
; Note that the contents of this word is only used for printing by the BIOS when a drive is detected.  
; It is not used for any other purpose, and so long as it conforms to the structure, any values can be used.
;
DEVICE_SERIAL_PRINTBAUD_NUMBERMASK		EQU		003ffh
DEVICE_SERIAL_PRINTBAUD_POSTCHARMASK	EQU		0fc00h
DEVICE_SERIAL_PRINTBAUD_POSTCHARADD		EQU		'0'
;
; These are defined here (instead of in the configurator) for consistency since they could also be used 
; in main.asm as a default for an IDEVARS structure.
;
DEVICE_SERIAL_PRINTBAUD_2400  EQU ((('0'-DEVICE_SERIAL_PRINTBAUD_POSTCHARADD)<<10) | 240)		; Prints "2400"
DEVICE_SERIAL_PRINTBAUD_9600  EQU ((('0'-DEVICE_SERIAL_PRINTBAUD_POSTCHARADD)<<10) | 960)		; Prints "9600"
DEVICE_SERIAL_PRINTBAUD_38_4  EQU ((('K'-DEVICE_SERIAL_PRINTBAUD_POSTCHARADD)<<10) | 38)		; Prints "38K"
DEVICE_SERIAL_PRINTBAUD_115_2 EQU ((('K'-DEVICE_SERIAL_PRINTBAUD_POSTCHARADD)<<10) | 115)		; Prints "115K"

;
; COM Number to I/O Port Address Mapping
;
; COM Number:                               1,    2,    3,    4,    5,    6,    7,    8,    9,   10,   11,   12		
; Corresponds to I/O port:                3f8,  2f8,  3e8,  2e8,  2f0,  3e0,  2e0,  260,  368,  268,  360,  270
; Corresponds to Packed I/O port (hex):    37,   17,   35,   15,   16,   34,   14,    4,   25,    5,   24,    6
;
DEVICE_SERIAL_COM1	EQU		3f8h
DEVICE_SERIAL_COM2	EQU		2f8h
DEVICE_SERIAL_COM3	EQU		3e8h
DEVICE_SERIAL_COM4	EQU		2e8h
DEVICE_SERIAL_COM5	EQU		2f0h
DEVICE_SERIAL_COM6	EQU		3e0h
DEVICE_SERIAL_COM7	EQU		2e0h
DEVICE_SERIAL_COM8	EQU		260h
DEVICE_SERIAL_COM9	EQU		368h
DEVICE_SERIAL_COMA	EQU		268h
DEVICE_SERIAL_COMB	EQU		360h
DEVICE_SERIAL_COMC	EQU		270h


%endif ; ROMVARS_INC
