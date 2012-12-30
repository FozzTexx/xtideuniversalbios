; Project name	:	XTIDE Univeral BIOS Configurator v2
; Description	:	Global variables for configuration program.

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

%ifndef VARIABLES_INC
%define VARIABLES_INC

; Equates and defines
BOOT_MENU_DEFAULT_TIMEOUT			EQU	(30 * TICKS_PER_SECOND)
MAX_ALLOWED_IDE_CONTROLLERS			EQU		4	; Maximum number of IDE controllers
MAX_LITE_MODE_CONTROLLERS			EQU		2
EEPROM_POLLING_TIMEOUT_TICKS		EQU		3	; 1 tick = 54.9 ms
XTIDE_SIGNATURE_LENGTH				EQU		8	; XTIDE Universal BIOS signature string length
NUMBER_OF_EEPROM_TYPES				EQU		5
MAX_EEPROM_SIZE_IN_BYTES			EQU		65536
IDE_PORT_TO_START_DETECTION			EQU	00h		; Must be zero (not actual port)
FIRST_MEMORY_SEGMENT_ADDRESS		EQU	0C000h


; Program global variables
struc CFGVARS
	.pMenupage			resb	2			; Offset to MENUPAGE to display
	.wFlags				resb	2			; Program flags
	.wImageSizeInWords	resb	2			; Size in words for loaded ROM or FILE
	.wEepromSegment		resb	2			; Segment where EEPROM is located
	.bEepromType		resb	1			; EEPROM type
	.bEepromPage		resb	1			; EEPROM page size (EEPROM_PAGE)
	.bSdpCommand		resb	1			; Command for Software Data Protection
						resb	1
	.szOpenedFile		resb	FILENAME_BUFFER_SIZE
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
	.2864_8kiB_MOD		resb	2	; Reversed A0 and A3 address lines
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
struc EEPROM_PAGE
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
DEFAULT_PAGE_SIZE		EQU		EEPROM_PAGE.1_byte
DEFAULT_SDP_COMMAND		EQU		SDP_COMMAND.enable


; Variables required for flashing
struc FLASHVARS
	.fpNextSourcePage			resb	4
	.fpNextComparisonPage		resb	4
	.fpNextDestinationPage		resb	4
	.wPagesToFlash				resb	2	; 0 = 65536
	.wEepromPageSize			resb	2	; 1, 2, 4, 8, 16, 32 or 64
	.bEepromSdpCommand			resb	1
	.bEepromType				resb	1

	.wProgressUpdateParam		resb	2
	.wTimeoutCounter			resb	2
	.wLastOffsetWritten			resb	2
	.bLastByteWritten			resb	1
	.flashResult				resb	1
endstruc

; Flashing results
struc FLASH_RESULT
	.success					resb	2
	.PollingTimeoutError		resb	2
	.DataVerifyError			resb	2
endstruc


%endif ; VARIABLES_INC
