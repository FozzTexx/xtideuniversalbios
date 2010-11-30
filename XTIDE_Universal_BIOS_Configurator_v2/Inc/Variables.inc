; File name		:	Variables.inc
; Project name	:	XTIDE Univeral BIOS Configurator v2
; Created date	:	5.10.2010
; Last update	:	19.11.2010
; Author		:	Tomi Tilli
; Description	:	Global variables for configuration program.
%ifndef VARIABLES_INC
%define VARIABLES_INC

; Equates and defines
MAX_ALLOWED_IDE_CONTROLLERS			EQU		5	; Maximum number of IDE controllers
EEPROM_POLLING_TIMEOUT_TICKS		EQU		3	; 1 tick = 54.9 ms
XTIDE_SIGNATURE_LENGTH				EQU		8	; XTIDE Universal BIOS signature string length
NUMBER_OF_SUPPORTED_EEPROM_SIZES	EQU		5
MAX_EEPROM_SIZE						EQU	65536


; Program global variables
struc CFGVARS
	.pMenupage			resb	2			; Offset to MENUPAGE to display
	.wFlags				resb	2			; Program flags
	.wImageSize			resb	2			; Size in bytes for BIOS image to be flashed (0=65536)
	.wEepromSegment		resb	2			; Segment where EEPROM is located
	.bEepromType		resb	1			; EEPROM type
	.bEepromPageSize	resb	1			; EEPROM page size in bytes
	.bSdpCommand		resb	1			; Command for Software Data Protection
						resb	1
	.szOpenedFile		resb	FILENAME_BUFFER_SIZE
	.flashVars			resb	FLASHVARS_size
endstruc

; Bit defines for CFGVARS.wFlags
FLG_CFGVARS_FILELOADED	EQU		(1<<0)	; BIOS is loaded from file
FLG_CFGVARS_ROMLOADED	EQU		(1<<1)	; BIOS is loaded from EEPROM
FLG_CFGVARS_UNSAVED		EQU		(1<<2)	; BIOS has unsaved changes
FLG_CFGVARS_CHECKSUM	EQU		(1<<3)	; Generate checksum byte

; EEPROM types
struc EEPROM_TYPE
	.2816_2kiB			resb	2
	.2864_8kiB			resb	2
	.28256_32kiB		resb	2
	.28512_64kiB		resb	2
endstruc

; Software Data Protection commands
struc SDP_COMMAND
	.none				resb	2	; Do not use any SDP command
	.enable				resb	2	; Flash with SDP enable command
	.disable			resb	2	; Flash with SDP disable command
endstruc

; Page sizes
struc EEPROM_PAGE_SIZE
	.1_byte				resb	2
	.2_bytes			resb	2
	.4_bytes			resb	2
	.8_bytes			resb	2
	.16_bytes			resb	2
	.32_bytes			resb	2
	.64_bytes			resb	2
endstruc

; Default CFGVARS settings
DEFAULT_CFGVARS_FLAGS	EQU		FLG_CFGVARS_CHECKSUM
DEFAULT_EEPROM_SEGMENT	EQU		0D000h
DEFAULT_EEPROM_TYPE		EQU		EEPROM_TYPE.2864_8kiB
DEFAULT_PAGE_SIZE		EQU		EEPROM_PAGE_SIZE.1_byte
DEFAULT_SDP_COMMAND		EQU		SDP_COMMAND.enable


; Variables required for flashing
struc FLASHVARS
	.wTotalPages		resb	2		; Total number of pages to write
	.wPagesLeft			resb	2		; Pages left to write
	.wByteOffset		resb	2		; Offset to byte to write next
endstruc


%endif ; VARIABLES_INC
