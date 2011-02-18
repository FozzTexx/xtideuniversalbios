; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	"IDE Controller" menu structs and functions.

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_MenupageForIdeControllerMenu:
istruc MENUPAGE
	at	MENUPAGE.fnEnter,			dw	IdeControllerMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.fnBack,			dw	ConfigurationMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.wMenuitems,		dw	8
iend

g_MenuitemIdeControllerBackToConfigurationMenu:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	ConfigurationMenu_EnterMenuOrModifyItemVisibility
	at	MENUITEM.szName,			dw	g_szItemBackToCfgMenu
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeBackToCfgMenu
	at	MENUITEM.szHelp,			dw	g_szNfoIdeBackToCfgMenu
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGEBACK
iend

g_MenuitemIdeControllerMasterDrive:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	MasterDrive
	at	MENUITEM.szName,			dw	g_szItemIdeMaster
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeMaster
	at	MENUITEM.szHelp,			dw	g_szNfoIdeMaster
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGENEXT
iend

g_MenuitemIdeControllerSlaveDrive:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	SlaveDrive
	at	MENUITEM.szName,			dw	g_szItemIdeSlave
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeSlave
	at	MENUITEM.szHelp,			dw	g_szNfoIdeSlave
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGENEXT
iend

g_MenuitemIdeControllerBusType:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemIdeBusType
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeBusType
	at	MENUITEM.szHelp,			dw	g_szNfoIdeBusType
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_BYTEVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgBusType
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceCfgBusType
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	g_rgwChoiceToValueLookupForBusType
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForBusType
iend

g_MenuitemIdeControllerCommandBlockAddress:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateHexInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteHexValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemIdeCmdPort
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeCmdPort
	at	MENUITEM.szHelp,			dw	g_szHelpIdeCmdPort
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_HEX
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgIdeCmdPort
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	0
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	-1
iend

g_MenuitemIdeControllerControlBlockAddress:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateHexInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteHexValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemIdeCtrlPort
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeCtrlPort
	at	MENUITEM.szHelp,			dw	g_szHelpIdeCtrlPort
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_HEX
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgIdeCtrlPort
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	0
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	-1
iend

g_MenuitemIdeControllerEnableInterrupt:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemIdeEnIRQ
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeEnIRQ
	at	MENUITEM.szHelp,			dw	g_szHelpIdeEnIRQ
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_MODIFY_MENU | FLG_MENUITEM_FLAGVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgIdeEnIRQ
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceBooleanFlag
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForFlagBooleans
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	15
iend

g_MenuitemIdeControllerIdeIRQ:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateUnsignedInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteUnsignedValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemIdeIRQ
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeIRQ
	at	MENUITEM.szHelp,			dw	g_szHelpIdeIRQ
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_BYTEVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_UNSIGNED
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgIdeIRQ
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	2
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	15
iend

g_rgwChoiceToValueLookupForBusType:
	dw	BUS_TYPE_8_DUAL
	dw	BUS_TYPE_8_SINGLE
	dw	BUS_TYPE_16
	dw	BUS_TYPE_32
g_rgszValueToStringLookupForBusType:
	dw	g_szValueCfgBusTypeDual8b
	dw	g_szValueCfgBusType16b
	dw	g_szValueCfgBusType32b
	dw	g_szValueCfgBusTypeSingle8b


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeControllerMenu_InitializeToIdevarsOffsetInBX
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeControllerMenu_InitializeToIdevarsOffsetInBX:
	lea		ax, [bx+IDEVARS.drvParamsMaster]
	mov		[cs:g_MenuitemIdeControllerMasterDrive+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+IDEVARS.drvParamsSlave]
	mov		[cs:g_MenuitemIdeControllerSlaveDrive+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+IDEVARS.bBusType]
	mov		[cs:g_MenuitemIdeControllerBusType+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+IDEVARS.wPort]
	mov		[cs:g_MenuitemIdeControllerCommandBlockAddress+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+IDEVARS.wPortCtrl]
	mov		[cs:g_MenuitemIdeControllerControlBlockAddress+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+IDEVARS.bIRQ]
	mov		[cs:g_MenuitemIdeControllerEnableInterrupt+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
	mov		[cs:g_MenuitemIdeControllerIdeIRQ+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
	ret


;--------------------------------------------------------------------
; IdeControllerMenu_EnterMenuOrModifyItemVisibility
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeControllerMenu_EnterMenuOrModifyItemVisibility:
	push	cs
	pop		ds
	call	.EnableOrDisableIRQ
	mov		si, g_MenupageForIdeControllerMenu
	jmp		Menupage_ChangeToNewMenupageInDSSI

;--------------------------------------------------------------------
; .EnableOrDisableIRQ
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableIRQ:
	mov		bx, [cs:g_MenuitemIdeControllerEnableInterrupt+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	mov		bx, g_MenuitemIdeControllerIdeIRQ
	test	ax, ax
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
; MENUITEM activation functions (.fnActivate)
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except segments
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MasterDrive:
	mov		bx, [cs:g_MenuitemIdeControllerMasterDrive+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	jmp		SHORT DisplayMasterSlaveMenu

ALIGN JUMP_ALIGN
SlaveDrive:
	mov		bx, [cs:g_MenuitemIdeControllerSlaveDrive+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	; Fall to DisplayMasterSlaveMenu

ALIGN JUMP_ALIGN
DisplayMasterSlaveMenu:
	call	MasterSlaveMenu_InitializeToDrvparamsOffsetInBX
	jmp		MasterSlaveMenu_EnterMenuOrModifyItemVisibility
