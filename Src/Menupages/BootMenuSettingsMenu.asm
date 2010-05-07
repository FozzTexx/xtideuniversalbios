; File name		:	BootMenuSettingsMenu.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	27.4.2010
; Last update	:	27.4.2010
; Author		:	Tomi Tilli
; Description	:	Menu for configuring boot menu settings.

; Section containing initialized data
SECTION .data

; -Back to previous menu
; Default boot drive (80h)
; Display drive information (Y)
; Display ROM boot selection (N)
; Maximum height (20)
; Minimum number of floppy drives (0)
; Seconds for selection timeout (20)
; Swap boot drive numbers (Y)


ALIGN WORD_ALIGN
g_MenuPageBootMenu:
istruc MENUPAGE
	at	MENUPAGE.bItemCnt,			db	8
iend
istruc MENUPAGEITEM	; Back to previous menu
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szPreviousMenu
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoIdeBack
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoIdeBack
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
istruc MENUPAGEITEM	; Default boot drive
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetHexByteFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.bBootDrv
	at	MENUPAGEITEM.wValueMin,		dw	0
	at	MENUPAGEITEM.wValueMax,		dw	60
	at	MENUPAGEITEM.szName,		dw	g_szItemBootDrive
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBootDrive
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpBootDrive
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgBootDrive
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_HEX_BYTE
iend
istruc MENUPAGEITEM	; Display drive information
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetBoolFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.wFlags
	at	MENUPAGEITEM.wValueMask,	dw	FLG_ROMVARS_DRVNFO
	at	MENUPAGEITEM.szName,		dw	g_szItemBootInfo
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBootInfo
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpBootInfo
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgBootInfo
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_FLAG
iend
istruc MENUPAGEITEM	; Display ROM boot selection
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetBoolFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.wFlags
	at	MENUPAGEITEM.wValueMask,	dw	FLG_ROMVARS_ROMBOOT
	at	MENUPAGEITEM.szName,		dw	g_szItemBootRomBoot
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBootRomBoot
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpBootRomBoot
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgBootRomBoot
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_FLAG
iend
istruc MENUPAGEITEM	; Maximum height
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetByteFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.bBootMnuH
	at	MENUPAGEITEM.wValueMin,		dw	8
	at	MENUPAGEITEM.wValueMax,		dw	25
	at	MENUPAGEITEM.szName,		dw	g_szItemBootHeight
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBootHeight
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoBootHeight
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgBootHeight
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_UNSIGNED_BYTE
iend
istruc MENUPAGEITEM	; Minimum number of floppy drives
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetByteFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.bMinFddCnt
	at	MENUPAGEITEM.wValueMin,		dw	0
	at	MENUPAGEITEM.wValueMax,		dw	127
	at	MENUPAGEITEM.szName,		dw	g_szItemBootMinFDD
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBootMinFDD
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpBootMinFDD
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgBootMinFDD
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_UNSIGNED_BYTE
iend
istruc MENUPAGEITEM	; Seconds for selection timeout
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetByteFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.bBootDelay
	at	MENUPAGEITEM.wValueMin,		dw	0
	at	MENUPAGEITEM.wValueMax,		dw	60
	at	MENUPAGEITEM.szName,		dw	g_szItemBootTimeout
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBootTimeout
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpBootTimeout
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgBootTimeout
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_UNSIGNED_BYTE
iend
istruc MENUPAGEITEM	; Swap boot drive numbers
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetBoolFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.wFlags
	at	MENUPAGEITEM.wValueMask,	dw	FLG_ROMVARS_DRVXLAT
	at	MENUPAGEITEM.szName,		dw	g_szItemBootSwap
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoBootSwap
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpBootSwap
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgBootSwap
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_FLAG
iend
