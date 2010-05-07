; File name		:	Variables.inc
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	16.4.2010
; Last update	:	2.5.2010
; Author		:	Tomi Tilli
; Description	:	Global variables for configuration program.
%ifndef VARIABLES_INC
%define VARIABLES_INC

; Equates and defines
WIDTH_MENU				EQU		38		; Menu width in characters
WIDTH_DLG				EQU		34		; Dialog width in characters
CNT_TITLE_LINES			EQU		4		; Number of title lines at the top of menu
CNT_INFO_LINES			EQU		6		; Number of information lines at the bottom of menu
CNT_TMEOUT_POLL			EQU		3		; EEPROM polling timeout (3 = 110...165ms)
CNT_MAX_CTRLS			EQU		5		; Maximum number of IDE controllers
HEIGHT_MIN_BOOTMNU		EQU		8		; Boot menu minimum height
HEIGHT_MAX_BOOTMNU		EQU		25		; Boot menu maximum height
LEN_SIGNATURE			EQU		8		; XTIDE Universal BIOS signature string length
MAX_EEPROM_SIZE			EQU		16384


; Program global variables
struc CFGVARS
	.wFlags				resb	2			; Program flags
	.wEepromSize		resb	2			; Size in bytes for EEPROM to be flashed
	.wEepromSegment		resb	2			; Segment where EEPROM is located
	.bPageSize			resb	1			; EEPROM page size in bytes
	.bSdpCommand		resb	1			; Command for Software Data Protection
	.bMenuCnt			resb	1			; Number of opened menus
						resb	1
	.flashVars			resb	FLASHVARS_size

	; EEPROM buffers
	.rgbEepromBuffers	resb	MAX_EEPROM_SIZE * 2
endstruc

; Bit defines for CFGVARS.wFlags
FLG_CFGVARS_FILELOADED	EQU	(1<<0)	; BIOS is loaded from file
FLG_CFGVARS_ROMLOADED	EQU	(1<<1)	; BIOS is loaded from EEPROM
FLG_CFGVARS_HIDEINFO	EQU	(1<<2)	; Hide menu information (FLG_MNU_HIDENFO)
FLG_CFGVARS_UNSAVED		EQU	(1<<3)	; BIOS has unsaved changes
FLG_CFGVARS_CHECKSUM	EQU	(1<<4)	; Generate checksum byte

; SDP command for CFGVARS.bSdpCommand
CMD_SDP_NONE			EQU	(0<<1)	; Do not use any SDP command
CMD_SDP_ENABLE			EQU	(1<<1)	; Flash with SDP enable command
CMD_SDP_DISABLE			EQU	(2<<1)	; Flash with SDP disable command


; Variables required for flashing
struc FLASHVARS
	.wTotalPages		resb	2		; Total number of pages to write
	.wPagesLeft			resb	2		; Pages left to write
	.wPagesBeforeDraw	resb	2		; Number of pages to write before updating progress bar
	.wByteOffset		resb	2		; Offset to byte to write next
endstruc


; Shortcuts to structs
%define G_ROMVARS	g_cfgVars+CFGVARS.rgbNewROM


%endif ; VARIABLES_INC
