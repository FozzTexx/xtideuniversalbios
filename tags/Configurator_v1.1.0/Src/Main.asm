; File name		:	main.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	16.4.2010
; Last update	:	30.4.2010
; Author		:	Tomi Tilli
; Description	:	Program start and exit.			

; Include .inc files
%include "emulate.inc"			; Emulation library. Must be first!
%include "BiosData.inc"			; For BIOS Data Area variables
%include "Variables.inc"		; Global variables for this program
%include "MenuPage.inc"			; Menu page and item structs
%include "RomVars.inc"			; XTIDE Universal BIOS ROMVARS


; Section containing code
SECTION .text

; Program first instruction.
ORG	100h						; Code starts at offset 100h (DOS .COM)
Start:
	jmp		Main_Start

; Include library sources
%include "math.asm"
%include "print.asm"
%include "string.asm"
%include "keys.asm"
%include "file.asm"
%include "menu.asm"

; Include sources for this program
%include "Strings.asm"				; For program strings
%include "MenuEvent.asm"			; For handling menu library events
%include "MenuEventHotkey.asm"		; For handling menu hotkeys
%include "MenuPage.asm"				; For accessing MENUPAGE structs
%include "MenuPageItem.asm"			; For accessing MENUPAGEITEM structs
%include "MenuPageItemFormat.asm"	; For printing menuitem names
%include "FormatTitle.asm"			; For printing menu title
%include "BiosFile.asm"				; For loading and saving BIOS file
%include "EEPROM.asm"				; For handling EEPROM contents
%include "Flash.asm"				; For flashing EEPROM

%include "MainMenu.asm"				; For main menu
%include "ConfigurationMenu.asm"	; For XTIDE Universal BIOS configuration menu
%include "BootLoaderValueMenu.asm"	; For selecting boot loader type
%include "IdeControllerMenu.asm"	; For configuring IDEVARS
%include "BusTypeValueMenu.asm"		; For selecting bus type
%include "DrvParamsMenu.asm"		; For configuring DRVPARAMS
%include "BootMenuSettingsMenu.asm"	; For configuring boot menu
%include "FlashMenu.asm"			; For flash settings
%include "SdpCommandValueMenu.asm"	; For selecting SDP command


;--------------------------------------------------------------------
; Program start
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Main_Start:
	call	MenuDraw_ClrScr		; Clear screen
	call	Main_InitializeVariables

	; Create main menu
	mov		si, g_MenuPageMain	; DS:SI points to MENUPAGE for main menu
	call	MainMenu_SetMenuitemVisibility
	call	Main_EnterMenu		; Enter menu
	call	MenuDraw_ClrScr		; Clear screen

	; Exit to DOS
	mov 	ax, 4C00h			; Exit to DOS
	int 	21h


;--------------------------------------------------------------------
; Initializes global variables used in this program.
;
; Main_InitializeVariables
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Main_InitializeVariables:
	; Zero all global variables
	mov		di, g_cfgVars		; ES:DI points to global variables
	mov		cx, (CFGVARS_size+ROMVARS_size)/2	; Size in words
	xor		ax, ax				; To store zero
	cld							; STOSW to increment DI
	rep stosw					; Zero all variables

	; Find Xtide Universal BIOS segment
	mov		dx, 0D000h			; XTIDE default segment
	call	EEPROM_FindXtideUniversalBiosROM
	jnc		SHORT .InitializeVariables
	mov		dx, es				; XTIDE segment to DX

ALIGN JUMP_ALIGN
.InitializeVariables:
	mov		WORD [g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_CHECKSUM
	mov		WORD [g_cfgVars+CFGVARS.wEepromSegment], dx
	mov		BYTE [g_cfgVars+CFGVARS.bPageSize], 1
	mov		BYTE [g_cfgVars+CFGVARS.bSdpCommand], CMD_SDP_ENABLE
	ret


;--------------------------------------------------------------------
; Enters main or submenu.
;
; Main_EnterMenu
;	Parameters:
;		DS:SI:	Ptr to MENUPAGE (also menu user far pointer for MENUVARS.user)
;	Returns:
;		CX:		Index of last pointed Menuitem (not necessary selected with ENTER)
;				FFFFh if cancelled with ESC
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Main_EnterMenu:
	call	MenuPage_GetNumberOfVisibleItems
	mov		cl, al								; Number of visible menuitems to CL
	mov		ax, (CNT_SCRN_ROW<<8) | WIDTH_MENU
	mov		bx, (CNT_INFO_LINES<<8) | CNT_TITLE_LINES
	mov		ch, [cs:g_cfgVars+CFGVARS.wFlags]	; Load program flags to CH
	and		ch, FLG_MNU_HIDENFO					; Clear all but info flag
	xor		dx, dx								; No selection timeout
	mov		di, MenuEvent_Handler				; CS:DI points to menu event handler
	inc		BYTE [cs:g_cfgVars+CFGVARS.bMenuCnt]
	call	Menu_Enter
	dec		BYTE [cs:g_cfgVars+CFGVARS.bMenuCnt]
	jz		SHORT .Return

	; Update info visibility for previous menu where to resume
	test	BYTE [cs:g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_HIDEINFO
	jnz		SHORT .HideInfo
	call	Menu_ShowInfo
	ret
ALIGN JUMP_ALIGN
.HideInfo:
	call	Menu_HideInfo
.Return:
	ret


; Section containing uninitialized data
SECTION .bss

ALIGN WORD_ALIGN	; All global variables
g_cfgVars:		resb	CFGVARS_size
