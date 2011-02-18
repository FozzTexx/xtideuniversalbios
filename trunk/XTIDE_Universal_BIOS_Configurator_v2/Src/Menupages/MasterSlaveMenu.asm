; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	"Master/Slave Drive" menu structs and functions.

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_MenupageForMasterSlaveMenu:
istruc MENUPAGE
	at	MENUPAGE.fnEnter,			dw	MasterSlaveMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.fnBack,			dw	IdeControllerMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.wMenuitems,		dw	6
iend

g_MenuitemMasterSlaveBackToIdeControllerMenu:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	IdeControllerMenu_EnterMenuOrModifyItemVisibility
	at	MENUITEM.szName,			dw	g_szItemDrvBackToIde
	at	MENUITEM.szQuickInfo,		dw	g_szItemDrvBackToIde
	at	MENUITEM.szHelp,			dw	g_szItemDrvBackToIde
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGEBACK
iend

g_MenuitemMasterSlaveBlockModeTransfers:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemDrvBlockMode
	at	MENUITEM.szQuickInfo,		dw	g_szNfoDrvBlockMode
	at	MENUITEM.szHelp,			dw	g_szHelpDrvBlockMode
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_FLAGVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDrvBlockMode
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceBooleanFlag
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForFlagBooleans
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	FLG_DRVPARAMS_BLOCKMODE
iend

g_MenuitemMasterSlaveUserCHS:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemDrvUserCHS
	at	MENUITEM.szQuickInfo,		dw	g_szNfoDrvUserCHS
	at	MENUITEM.szHelp,			dw	g_szHelpDrvUserCHS
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_MODIFY_MENU | FLG_MENUITEM_FLAGVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDrvUserCHS
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceBooleanFlag
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForFlagBooleans
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	FLG_DRVPARAMS_USERCHS
iend

g_MenuitemMasterSlaveCylinders:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateUnsignedInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteUnsignedValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemDrvCyls
	at	MENUITEM.szQuickInfo,		dw	g_szNfoDrvCyls
	at	MENUITEM.szHelp,			dw	g_szNfoDrvCyls
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_UNSIGNED
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDrvCyls
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	1
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	16383
iend

g_MenuitemMasterSlaveHeads:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateUnsignedInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteUnsignedValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemDrvHeads
	at	MENUITEM.szQuickInfo,		dw	g_szNfoDrvHeads
	at	MENUITEM.szHelp,			dw	g_szNfoDrvHeads
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_BYTEVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_UNSIGNED
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDrvHeads
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	1
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	16
iend

g_MenuitemMasterSlaveSectors:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateUnsignedInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteUnsignedValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemDrvSect
	at	MENUITEM.szQuickInfo,		dw	g_szNfoDrvSect
	at	MENUITEM.szHelp,			dw	g_szNfoDrvSect
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_BYTEVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_UNSIGNED
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDrvSect
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	1
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	63
iend


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MasterSlaveMenu_InitializeToDrvparamsOffsetInBX
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MasterSlaveMenu_InitializeToDrvparamsOffsetInBX:
	lea		ax, [bx+DRVPARAMS.wFlags]
	mov		[cs:g_MenuitemMasterSlaveBlockModeTransfers+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
	mov		[cs:g_MenuitemMasterSlaveUserCHS+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+DRVPARAMS.wCylinders]
	mov		[cs:g_MenuitemMasterSlaveCylinders+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+DRVPARAMS.bHeads]
	mov		[cs:g_MenuitemMasterSlaveHeads+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+DRVPARAMS.bSect]
	mov		[cs:g_MenuitemMasterSlaveSectors+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
	ret


;--------------------------------------------------------------------
; MasterSlaveMenu_EnterMenuOrModifyItemVisibility
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MasterSlaveMenu_EnterMenuOrModifyItemVisibility:
	push	cs
	pop		ds
	call	.EnableOrDisableCHandS
	mov		si, g_MenupageForMasterSlaveMenu
	jmp		Menupage_ChangeToNewMenupageInDSSI

;--------------------------------------------------------------------
; .EnableOrDisableCHandS
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableCHandS:
	mov		bx, [cs:g_MenuitemMasterSlaveUserCHS+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	test	ax, FLG_DRVPARAMS_USERCHS
	jz		SHORT .DisableCHandS

	mov		bx, g_MenuitemMasterSlaveCylinders
	call	.EnableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveHeads
	call	.EnableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveSectors
	call	.EnableMenuitemFromCSBX
	ret

ALIGN JUMP_ALIGN
.DisableCHandS:
	mov		bx, g_MenuitemMasterSlaveCylinders
	call	.DisableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveHeads
	call	.DisableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveSectors
	call	.DisableMenuitemFromCSBX
	ret

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
