; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	"Boot Menu Settings" menu structs and functions.

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

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_MenupageForBootMenuSettingsMenu:
istruc MENUPAGE
	at	MENUPAGE.fnEnter,			dw	BootMenuSettingsMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.fnBack,			dw	ConfigurationMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.wMenuitems,		dw	6
iend

g_MenuitemBootMnuStngsBackToConfigurationMenu:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	ConfigurationMenu_EnterMenuOrModifyItemVisibility
	at	MENUITEM.szName,			dw	g_szItemBackToCfgMenu
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeBackToCfgMenu
	at	MENUITEM.szHelp,			dw	g_szNfoIdeBackToCfgMenu
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGEBACK
iend

g_MenuitemBootMnuStngsDisplayMode:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromUnshiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemBootDispMode
	at	MENUITEM.szQuickInfo,		dw	g_szNfoDispMode
	at	MENUITEM.szHelp,			dw	g_szNfoDispMode
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	ROMVARS.wDisplayMode
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgBootDispMode
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceBootDispMode
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	g_rgwChoiceToValueLookupForDisplayModes
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForDisplayModes
iend

g_MenuitemBootMnuStngsFloppyDrives:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromUnshiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemBootFloppyDrvs
	at	MENUITEM.szQuickInfo,		dw	g_szNfoBootFloppyDrvs
	at	MENUITEM.szHelp,			dw	g_szHelpBootFloppyDrvs
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_BYTEVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	ROMVARS.bMinFddCnt
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgBootFloppyDrvs
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceBootFloppyDrvs
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForFloppyDrives
iend

g_MenuitemBootMenuSerialScanDetect:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemSerialDetect
	at	MENUITEM.szQuickInfo,		dw	g_szNfoSerialDetect
	at	MENUITEM.szHelp,			dw	g_szHelpSerialDetect
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_FLAGVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	ROMVARS.wFlags
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgSerialDetect
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceBooleanFlag
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForFlagBooleans
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	FLG_ROMVARS_SERIAL_SCANDETECT
iend

g_MenuitemBootMnuStngsDefaultBootDrive:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateHexInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteHexValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemBootDrive
	at	MENUITEM.szQuickInfo,		dw	g_szNfoBootDrive
	at	MENUITEM.szHelp,			dw	g_szHelpBootDrive
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_BYTEVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_HEX
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	ROMVARS.bBootDrv
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgBootDrive
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	0
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	0FFh
iend

g_MenuitemBootMnuStngsSelectionTimeout:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateUnsignedInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteUnsignedValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemBootTimeout
	at	MENUITEM.szQuickInfo,		dw	g_szNfoBootTimeout
	at	MENUITEM.szHelp,			dw	g_szHelpBootTimeout
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_UNSIGNED
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	ROMVARS.wBootTimeout
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgBootTimeout
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	2
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	1092
iend


g_rgwChoiceToValueLookupForEnableBootMenu:
	dw	FALSE
	dw	BOOT_MENU_DEFAULT_TIMEOUT

g_rgwChoiceToValueLookupForDisplayModes:
	dw	DEFAULT_TEXT_MODE
	dw	CGA_TEXT_MODE_BW40
	dw	CGA_TEXT_MODE_CO40
	dw	CGA_TEXT_MODE_BW80
	dw	CGA_TEXT_MODE_CO80
	dw	MDA_TEXT_MODE
g_rgszValueToStringLookupForDisplayModes:
	dw	g_szValueBootDispModeBW40
	dw	g_szValueBootDispModeCO40
	dw	g_szValueBootDispModeBW80
	dw	g_szValueBootDispModeCO80
	dw	g_szValueBootDispModeDefault
	dw	NULL
	dw	NULL
	dw	g_szValueBootDispModeMono

g_rgszValueToStringLookupForFloppyDrives:
	dw	g_szValueBootFloppyDrvsAuto
	dw	g_szValueBootFloppyDrvs1
	dw	g_szValueBootFloppyDrvs2
	dw	g_szValueBootFloppyDrvs3
	dw	g_szValueBootFloppyDrvs4


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; BootMenuSettingsMenu_EnterMenuOrModifyItemVisibility
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuSettingsMenu_EnterMenuOrModifyItemVisibility:
	push	cs
	pop		ds
	call	.EnableOrDisableScanForSerialDrives
	call	.EnableOrDisableDefaultBootDrive
	call	.EnableOrDisableBootMenuSelectionTimeout
	mov		si, g_MenupageForBootMenuSettingsMenu
	jmp		Menupage_ChangeToNewMenupageInDSSI


;--------------------------------------------------------------------
; .EnableOrDisableScanForSerialDrives
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableScanForSerialDrives:
	call	Buffers_GetRomvarsFlagsToAX
	mov		bx, g_MenuitemBootMenuSerialScanDetect
	test	ax, FLG_ROMVARS_MODULE_SERIAL
	jmp		SHORT .DisableMenuitemFromCSBXifZFset


;--------------------------------------------------------------------
; .EnableOrDisableDefaultBootDrive
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableDefaultBootDrive:
	call	Buffers_GetRomvarsFlagsToAX
	mov		bx, g_MenuitemBootMnuStngsDefaultBootDrive
	test	ax, FLG_ROMVARS_MODULE_HOTKEYS
	jmp		SHORT .DisableMenuitemFromCSBXifZFset


;--------------------------------------------------------------------
; .EnableOrDisableBootMenuSelectionTimeout
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableBootMenuSelectionTimeout:
	call	Buffers_GetRomvarsFlagsToAX
	mov		bx, g_MenuitemBootMnuStngsSelectionTimeout
	test	ax, FLG_ROMVARS_MODULE_BOOT_MENU
.DisableMenuitemFromCSBXifZFset:
	jz		SHORT .DisableMenuitemFromCSBX
	; Fall to .EnableMenuitemFromCSBX


;--------------------------------------------------------------------
; .EnableMenuitemFromCSBX
; .DisableMenuitemFromCSBX
;	Parameters:
;		CS:BX:	Ptr to MENUITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableMenuitemFromCSBX:
	or		BYTE [cs:bx+MENUITEM.bFlags], FLG_MENUITEM_VISIBLE
	ret

ALIGN JUMP_ALIGN
.DisableMenuitemFromCSBX:
	and		BYTE [cs:bx+MENUITEM.bFlags], ~FLG_MENUITEM_VISIBLE
	ret


;--------------------------------------------------------------------
; MENUITEM value reader functions
;	Parameters:
;		AX:		Value from MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset
;		DS:SI:	Ptr to MENUITEM
;		ES:DI:	Ptr to value variable
;	Returns:
;		AX:		Value with possible modifications
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ValueReaderForEnableBootMenu:
	test	ax, ax
	jz		SHORT .NoNeedToModify
	mov		ax, TRUE<<1
.NoNeedToModify:
	ret
