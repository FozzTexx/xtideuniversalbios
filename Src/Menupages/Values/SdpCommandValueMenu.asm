; File name		:	SdpCommandValueMenu.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	30.4.2010
; Last update	:	30.4.2010
; Author		:	Tomi Tilli
; Description	:	Menu for selecting SDP command for flashing.

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_MenuPageSdpCommand:
istruc MENUPAGE
	at	MENUPAGE.bItemCnt,			db	3
	at	MENUPAGE.prgbItemToVal,		dw	g_rgbSDPMenuitemToValue
iend
istruc MENUPAGEITEM	; None
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemSdpNone
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoSdpNone
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoSdpNone
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
istruc MENUPAGEITEM	; Enable
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemSdpEnable
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoSdpEnable
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoSdpEnable
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
istruc MENUPAGEITEM	; Disable
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemSdpDisable
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoSdpDisable
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoSdpDisable
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend

; Lookup table for SDP command value strings
g_rgszSdpValueToString:
	dw	g_szValueSdpNone
	dw	g_szValueSdpEnable
	dw	g_szValueSdpDisable

; Lookup table for translating menuitem index to value
g_rgbSDPMenuitemToValue:
	db	CMD_SDP_NONE
	db	CMD_SDP_ENABLE
	db	CMD_SDP_DISABLE
