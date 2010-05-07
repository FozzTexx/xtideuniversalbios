; File name		:	BootLoaderValueMenu.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	22.4.2010
; Last update	:	25.4.2010
; Author		:	Tomi Tilli
; Description	:	Menu for selecting Boot Loader type.

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_MenuPageBootLoaderType:
istruc MENUPAGE
	at	MENUPAGE.bItemCnt,			db	3
	at	MENUPAGE.prgbItemToVal,		dw	g_rgbBootLoaderMenuitemToValue
iend
istruc MENUPAGEITEM	; Boot menu
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemBootMenu
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBootMenu
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoBootMenu
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
istruc MENUPAGEITEM	; Simple
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemBootSimple
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBootSimple
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoBootSimple
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
istruc MENUPAGEITEM	; None
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemBootNone
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBootNone
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoBootNone
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend

; Boot loader type value strings
g_rgszBootLoaderValueToString:
	dw		g_szValueBootLdrMenu		; BOOTLOADER_TYPE_MENU
	dw		g_szValueBootLdrSimple		; BOOTLOADER_TYPE_SIMPLE
	dw		g_szValueBootLdrSimple		; Undefined
	dw		g_szValueBootLdrNone		; BOOTLOADER_TYPE_NONE

; Lookup table for translating menuitem index to value
g_rgbBootLoaderMenuitemToValue:
	db		BOOTLOADER_TYPE_MENU
	db		BOOTLOADER_TYPE_SIMPLE
	db		BOOTLOADER_TYPE_NONE
