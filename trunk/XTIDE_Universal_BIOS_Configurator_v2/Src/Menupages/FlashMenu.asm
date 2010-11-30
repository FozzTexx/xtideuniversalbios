; File name		:	FlashMenu.asm
; Project name	:	XTIDE Universal BIOS Configurator v2
; Created date	:	19.11.2010
; Last update	:	19.11.2010
; Author		:	Tomi Tilli
; Description	:	"Flash EEPROM" menu structs and functions.

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_MenupageForFlashMenu:
istruc MENUPAGE
	at	MENUPAGE.fnEnter,			dw	FlashMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.fnBack,			dw	MainMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.wMenuitems,		dw	7
iend

g_MenuitemFlashBackToMainMenu:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	MainMenu_EnterMenuOrModifyItemVisibility
	at	MENUITEM.szName,			dw	g_szItemCfgBackToMain
	at	MENUITEM.szQuickInfo,		dw	g_szItemCfgBackToMain
	at	MENUITEM.szHelp,			dw	g_szItemCfgBackToMain
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGEBACK
iend

g_MenuitemFlashStartFlashing:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	StartFlashing
	at	MENUITEM.szName,			dw	g_szItemFlashStart
	at	MENUITEM.szQuickInfo,		dw	g_szNfoFlashStart
	at	MENUITEM.szHelp,			dw	g_szNfoFlashStart
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_ACTION
iend

g_MenuitemFlashEepromType:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiseSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemFlashEepromType
	at	MENUITEM.szQuickInfo,		dw	g_szNfoFlashEepromType
	at	MENUITEM.szHelp,			dw	g_szNfoFlashEepromType
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_PROGRAMVAR | FLG_MENUITEM_BYTEVALUE | FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOISE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	CFGVARS.bEepromType
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgFlashEepromType
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoise,				dw	g_szMultichoiseEepromType
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiseToValueLookup,		dw	g_rgwChoiseToValueLookupForEepromType
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForEepromType
iend

g_MenuitemFlashSdpCommand:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiseSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemFlashSDP
	at	MENUITEM.szQuickInfo,		dw	g_szNfoFlashSDP
	at	MENUITEM.szHelp,			dw	g_szHelpFlashSDP
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_PROGRAMVAR | FLG_MENUITEM_BYTEVALUE | FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOISE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	CFGVARS.bSdpCommand
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgFlashSDP
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoise,				dw	g_szMultichoiseSdpCommand
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiseToValueLookup,		dw	g_rgwChoiseToValueLookupForSdpCommand
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForSdpCommand
iend

g_MenuitemFlashPageSize:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiseSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemFlashPageSize
	at	MENUITEM.szQuickInfo,		dw	g_szNfoFlashPageSize
	at	MENUITEM.szHelp,			dw	g_szHelpFlashPageSize
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_PROGRAMVAR | FLG_MENUITEM_BYTEVALUE | FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOISE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	CFGVARS.bEepromPageSize
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgFlashPageSize
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoise,				dw	g_szMultichoisePageSize
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiseToValueLookup,		dw	g_rgwChoiseToValueLookupForPageSize
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForPageSize
iend

g_MenuitemFlashEepromAddress:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateHexInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteHexValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemFlashAddr
	at	MENUITEM.szQuickInfo,		dw	g_szNfoFlashAddr
	at	MENUITEM.szHelp,			dw	g_szNfoFlashAddr
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_PROGRAMVAR | FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_HEX
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	CFGVARS.wEepromSegment
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgFlashAddr
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	0C000h
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	0F800h
iend

g_MenuitemFlashGenerateChecksum:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiseSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemFlashChecksum
	at	MENUITEM.szQuickInfo,		dw	g_szNfoFlashChecksum
	at	MENUITEM.szHelp,			dw	g_szHelpFlashChecksum
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_PROGRAMVAR | FLG_MENUITEM_VISIBLE | FLG_MENUITEM_FLAGVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOISE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	CFGVARS.wFlags
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgFlashChecksum
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoise,				dw	g_szMultichoiseBooleanFlag
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForFlagBooleans
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	FLG_CFGVARS_CHECKSUM
iend

g_rgwChoiseToValueLookupForEepromType:
	dw	EEPROM_TYPE.2816_2kiB
	dw	EEPROM_TYPE.2864_8kiB
	dw	EEPROM_TYPE.28256_32kiB
	dw	EEPROM_TYPE.28512_64kiB
g_rgszValueToStringLookupForEepromType:
	dw	g_szValueFlash2816
	dw	g_szValueFlash2864
	dw	g_szValueFlash28256
	dw	g_szValueFlash28512

g_rgwChoiseToValueLookupForSdpCommand:
	dw	SDP_COMMAND.none
	dw	SDP_COMMAND.enable
	dw	SDP_COMMAND.disable
g_rgszValueToStringLookupForSdpCommand:
	dw	g_szValueFlashNone
	dw	g_szValueFlashEnable
	dw	g_szValueFlashDisable

g_rgwChoiseToValueLookupForPageSize:
	dw	EEPROM_PAGE_SIZE.1_byte
	dw	EEPROM_PAGE_SIZE.2_bytes
	dw	EEPROM_PAGE_SIZE.4_bytes
	dw	EEPROM_PAGE_SIZE.8_bytes
	dw	EEPROM_PAGE_SIZE.16_bytes
	dw	EEPROM_PAGE_SIZE.32_bytes
	dw	EEPROM_PAGE_SIZE.64_bytes
g_rgszValueToStringLookupForPageSize:
	dw	g_szValueFlash1byte
	dw	g_szValueFlash2bytes
	dw	g_szValueFlash4bytes
	dw	g_szValueFlash8bytes
	dw	g_szValueFlash16bytes
	dw	g_szValueFlash32bytes
	dw	g_szValueFlash64bytes


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MainMenu_EnterMenuOrModifyItemVisibility
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FlashMenu_EnterMenuOrModifyItemVisibility:
	push	cs
	pop		ds
	mov		si, g_MenupageForFlashMenu
	jmp		Menupage_ChangeToNewMenupageInDSSI


;--------------------------------------------------------------------
; MENUITEM activation functions (.fnActivate)
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except segments
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
StartFlashing:
	ret
