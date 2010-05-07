; File name		:	BusTypeValueMenu.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	25.4.2010
; Last update	:	25.4.2010
; Author		:	Tomi Tilli
; Description	:	Menu for selecting bus type.

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_MenuPageBusType:
istruc MENUPAGE
	at	MENUPAGE.bItemCnt,			db	4
	at	MENUPAGE.prgbItemToVal,		dw	g_rgbBusTypeMenuitemToValue
iend
istruc MENUPAGEITEM	; 8-bit dual port (XTIDE)
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemBus8Dual
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBus8Dual
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoBus8Dual
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
istruc MENUPAGEITEM	; 8-bit single port
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemBus8Single
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBus8Single
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoBus8Single
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
istruc MENUPAGEITEM	; 16-bit
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemBus16
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBus16
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoBus16
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
istruc MENUPAGEITEM	; 32-bit generic
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemBus32Generic
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBus32Generic
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoBus32Generic
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend

; Lookup table for Bus type value strings
g_rgszBusTypeValueToString:
	dw	g_szValueDual8b
	dw	g_szValue16b
	dw	g_szValue32b
	dw	g_szValueSingle8b

; Lookup table for translating menuitem index to value
g_rgbBusTypeMenuitemToValue:
	db	BUS_TYPE_8_DUAL
	db	BUS_TYPE_8_SINGLE
	db	BUS_TYPE_16
	db	BUS_TYPE_32
