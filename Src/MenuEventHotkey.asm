; File name		:	MenuEventHotkey.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	16.4.2010
; Last update	:	16.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions to handle menu hotkeys.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Handles all menu hotkeys.
;
; MenuEventHotkey_Pressed
;	Parameters:
;		CX:		Index (menu library) of currently selected Menuitem
;		DL:		ASCII character for pressed key
;		DH:		BIOS Scan Code for pressed key
;		DS:SI:	Ptr to MENUPAGE
;		DS:DI:	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEventHotkey_Pressed:
	cmp		dh, KEY_BSC_F1		; Display help?
	je		SHORT MenuEventHotkey_Help
	cmp		dh, KEY_BSC_F2		; Toggle menu information?
	je		SHORT MenuEventHotkey_ToggleInfo
	ret


;--------------------------------------------------------------------
; Displays help dialog for menuitem.
;
; MenuEventHotkey_Help
;	Parameters:
;		DS:SI:	Ptr to MENUPAGE
;		DS:DI:	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEventHotkey_Help:
	jmp		MenuPageItem_DisplayHelpDialog


;--------------------------------------------------------------------
; Hides or sets menu information visible.
;
; MenuEventHotkey_ToggleInfo
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEventHotkey_ToggleInfo:
	xor		WORD [g_cfgVars+CFGVARS.wFlags], BYTE FLG_CFGVARS_HIDEINFO
	jmp		Menu_ToggleInfo
