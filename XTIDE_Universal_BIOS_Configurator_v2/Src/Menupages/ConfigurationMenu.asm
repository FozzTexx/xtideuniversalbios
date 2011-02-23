; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	"Configure XTIDE Universal BIOS" menu structs and functions.

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_MenupageForConfigurationMenu:
istruc MENUPAGE
	at	MENUPAGE.fnEnter,			dw	ConfigurationMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.fnBack,			dw	MainMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.wMenuitems,		dw	9
iend

g_MenuitemConfigurationBackToMainMenu:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	MainMenu_EnterMenuOrModifyItemVisibility
	at	MENUITEM.szName,			dw	g_szItemCfgBackToMain
	at	MENUITEM.szQuickInfo,		dw	g_szItemCfgBackToMain
	at	MENUITEM.szHelp,			dw	g_szItemCfgBackToMain
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGEBACK
iend

g_MenuitemConfigurationPrimaryIdeController:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	PrimaryIdeController
	at	MENUITEM.szName,			dw	g_szItemCfgIde1
	at	MENUITEM.szQuickInfo,		dw	g_szNfoCfgIde
	at	MENUITEM.szHelp,			dw	g_szNfoCfgIde
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGENEXT
iend

g_MenuitemConfigurationSecondaryIdeController:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	SecondaryIdeController
	at	MENUITEM.szName,			dw	g_szItemCfgIde2
	at	MENUITEM.szQuickInfo,		dw	g_szNfoCfgIde
	at	MENUITEM.szHelp,			dw	g_szNfoCfgIde
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGENEXT
iend

g_MenuitemConfigurationTertiaryIdeController:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	TertiaryIdeController
	at	MENUITEM.szName,			dw	g_szItemCfgIde3
	at	MENUITEM.szQuickInfo,		dw	g_szNfoCfgIde
	at	MENUITEM.szHelp,			dw	g_szNfoCfgIde
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGENEXT
iend

g_MenuitemConfigurationQuaternaryIdeController:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	QuaternaryIdeController
	at	MENUITEM.szName,			dw	g_szItemCfgIde4
	at	MENUITEM.szQuickInfo,		dw	g_szNfoCfgIde
	at	MENUITEM.szHelp,			dw	g_szNfoCfgIde
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGENEXT
iend

g_MenuitemConfigurationBootMenuSettings:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	BootMenuSettingsMenu_EnterMenuOrModifyItemVisibility
	at	MENUITEM.szName,			dw	g_szItemCfgBootMenu
	at	MENUITEM.szQuickInfo,		dw	g_szNfoCfgBootMenu
	at	MENUITEM.szHelp,			dw	g_szNfoCfgBootMenu
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGENEXT
iend

g_MenuitemConfigurationFullOperatingMode:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemCfgFullMode
	at	MENUITEM.szQuickInfo,		dw	g_szNfoCfgFullMode
	at	MENUITEM.szHelp,			dw	g_szHelpCfgFullMode
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_MODIFY_MENU | FLG_MENUITEM_FLAGVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	ROMVARS.wFlags
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgCfgFullMode
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceBooleanFlag
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForFlagBooleans
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	FLG_ROMVARS_FULLMODE
iend

g_MenuitemConfigurationKiBtoStealFromRAM:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateUnsignedInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteUnsignedValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemCfgStealSize
	at	MENUITEM.szQuickInfo,		dw	g_szNfoCfgStealSize
	at	MENUITEM.szHelp,			dw	g_szHelpCfgStealSize
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_BYTEVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_UNSIGNED
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	ROMVARS.bStealSize
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgCfgStealSize
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	1
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	255
iend

g_MenuitemConfigurationIdeControllers:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateUnsignedInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteUnsignedValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemCfgIdeCnt
	at	MENUITEM.szQuickInfo,		dw	g_szNfoCfgIdeCnt
	at	MENUITEM.szHelp,			dw	g_szNfoCfgIdeCnt
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_MODIFY_MENU | FLG_MENUITEM_BYTEVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_UNSIGNED
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	ROMVARS.bIdeCnt
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgCfgIdeCnt
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	1
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	4
iend


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
ConfigurationMenu_EnterMenuOrModifyItemVisibility:
	push	cs
	pop		ds
	call	.DisableAllIdeControllerMenuitems
	call	.EnableIdeControllerMenuitemsBasedOnConfiguration
	call	.EnableOrDisableKiBtoStealFromRAM
	call	.EnableOrDisableIdeControllerCount
	mov		si, g_MenupageForConfigurationMenu
	jmp		Menupage_ChangeToNewMenupageInDSSI

;--------------------------------------------------------------------
; .DisableAllIdeControllerMenuitems
; .EnableIdeControllerMenuitemsBasedOnConfiguration
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.DisableAllIdeControllerMenuitems:
	mov		cx, MAX_ALLOWED_IDE_CONTROLLERS-1
	mov		bx, g_MenuitemConfigurationSecondaryIdeController
ALIGN JUMP_ALIGN
.DisableNextIdeControllerMenuitem:
	call	.DisableMenuitemFromCSBX
	add		bx, BYTE MENUITEM_size
	loop	.DisableNextIdeControllerMenuitem
	ret

ALIGN JUMP_ALIGN
.EnableIdeControllerMenuitemsBasedOnConfiguration:
	call	.GetIdeControllerCountToCX
	dec		cx			; Primary always enabled
	jcxz	.PrimaryControllerAlreadyEnabled
	mov		bx, g_MenuitemConfigurationSecondaryIdeController
ALIGN JUMP_ALIGN
.EnableNextIdeControllerMenuitem:
	call	.EnableMenuitemFromCSBX
	add		bx, BYTE MENUITEM_size
	loop	.EnableNextIdeControllerMenuitem
.PrimaryControllerAlreadyEnabled:
	ret

;--------------------------------------------------------------------
; .GetIdeControllerCountToCX
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		CX:		Number of IDE controllers to configure
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetIdeControllerCountToCX:
	call	Buffers_GetRomvarsFlagsToAX
	test	ax, FLG_ROMVARS_FULLMODE
	jz		SHORT .AllowOnlyOneIdeControllerInLiteMode

	mov		bx, ROMVARS.bIdeCnt
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	eMOVZX	cx, al
	ret
ALIGN JUMP_ALIGN
.AllowOnlyOneIdeControllerInLiteMode:
	mov		cx, 1
	ret

;--------------------------------------------------------------------
; .EnableOrDisableKiBtoStealFromRAM
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableKiBtoStealFromRAM:
	call	Buffers_GetRomvarsFlagsToAX
	mov		bx, g_MenuitemConfigurationKiBtoStealFromRAM
	test	ax, FLG_ROMVARS_FULLMODE
	jz		SHORT .DisableMenuitemFromCSBX
	jmp		SHORT .EnableMenuitemFromCSBX

;--------------------------------------------------------------------
; .EnableOrDisableKiBtoStealFromRAM
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableIdeControllerCount:
	call	Buffers_GetRomvarsFlagsToAX
	mov		bx, g_MenuitemConfigurationIdeControllers
	test	ax, FLG_ROMVARS_FULLMODE
	jnz		SHORT .EnableMenuitemFromCSBX
.LimitIdeControllerCountToOneForLiteMode:
	call	Buffers_GetFileBufferToESDI
	mov		BYTE [es:di+ROMVARS.bIdeCnt], 1
	jmp		SHORT .DisableMenuitemFromCSBX

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
PrimaryIdeController:
	mov		bx, ROMVARS.ideVars0
	jmp		SHORT DisplayIdeControllerMenu

ALIGN JUMP_ALIGN
SecondaryIdeController:
	mov		bx, ROMVARS.ideVars1
	jmp		SHORT DisplayIdeControllerMenu

ALIGN JUMP_ALIGN
TertiaryIdeController:
	mov		bx, ROMVARS.ideVars2
	jmp		SHORT DisplayIdeControllerMenu

ALIGN JUMP_ALIGN
QuaternaryIdeController:
	mov		bx, ROMVARS.ideVars3
	; Fall to DisplayIdeControllerMenu

ALIGN JUMP_ALIGN
DisplayIdeControllerMenu:
	call	IdeControllerMenu_InitializeToIdevarsOffsetInBX
	jmp		IdeControllerMenu_EnterMenuOrModifyItemVisibility
