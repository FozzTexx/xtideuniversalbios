; File name		:	main.asm
; Project name	:	XTIDE Univeral BIOS Configurator v2
; Created date	:	5.10.2010
; Last update	:	19.11.2010
; Author		:	Tomi Tilli
; Description	:	Program start and exit.			

; Include .inc files
%define INCLUDE_MENU_DIALOGS
%include "AssemblyLibrary.inc"	; Assembly Library. Must be included first!
%include "Romvars.inc"			; XTIDE Universal BIOS variables

%include "MenuCfg.inc"
%include "MenuStructs.inc"
%include "Variables.inc"


; Section containing code
SECTION .text


; Program first instruction.
ORG	100h						; Code starts at offset 100h (DOS .COM)
Start:
	jmp		Main_Start

; Include library sources
%include "AssemblyLibrary.asm"

; Include sources for this program
%include "BiosFile.asm"
%include "Buffers.asm"
%include "Dialogs.asm"
%include "EEPROM.asm"
%include "MenuEvents.asm"
%include "Menuitem.asm"
%include "MenuitemPrint.asm"
%include "Menupage.asm"
%include "Strings.asm"

%include "BootMenuSettingsMenu.asm"
%include "ConfigurationMenu.asm"
%include "FlashMenu.asm"
%include "IdeControllerMenu.asm"
%include "MainMenu.asm"
%include "MasterSlaveMenu.asm"



;--------------------------------------------------------------------
; Program start
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Main_Start:
	CALL_DISPLAY_LIBRARY InitializeDisplayContext
	CALL_DISPLAY_LIBRARY ClearScreen

	call	Main_InitializeCfgVars
	call	MenuEvents_DisplayMenu

	; Exit to DOS
	CALL_DISPLAY_LIBRARY SynchronizeDisplayContextToHardware
	mov 	ax, 4C00h			; Exit to DOS
	int 	21h


;--------------------------------------------------------------------
; Main_InitializeCfgVars
;	Parameters:
;		DS:		Segment to CFGVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Main_InitializeCfgVars:
	push	es

	call	Buffers_Clear
	call	EEPROM_FindXtideUniversalBiosROMtoESDI
	jnc		SHORT .InitializationCompleted
	mov		[CFGVARS.wEepromSegment], es
.InitializationCompleted:
	pop		es
	ret


; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_cfgVars:
istruc CFGVARS
	at	CFGVARS.pMenupage,			dw	g_MenupageForMainMenu
	at	CFGVARS.wFlags,				dw	DEFAULT_CFGVARS_FLAGS
	at	CFGVARS.wEepromSegment,		dw	DEFAULT_EEPROM_SEGMENT
	at	CFGVARS.bEepromType,		db	DEFAULT_EEPROM_TYPE
	at	CFGVARS.bEepromPageSize,	db	DEFAULT_PAGE_SIZE
	at	CFGVARS.bSdpCommand,		db	DEFAULT_SDP_COMMAND
iend


; Section containing uninitialized data
SECTION .bss
