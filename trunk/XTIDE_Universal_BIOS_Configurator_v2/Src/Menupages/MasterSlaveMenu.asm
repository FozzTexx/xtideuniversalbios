; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	"Master/Slave Drive" menu structs and functions.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
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
g_MenupageForMasterSlaveMenu:
istruc MENUPAGE
	at	MENUPAGE.fnEnter,			dw	MasterSlaveMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.fnBack,			dw	IdeControllerMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.wMenuitems,		dw	10
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

g_MenuitemMasterSlaveChsTranslateMode:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromUnshiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemDrvXlateMode
	at	MENUITEM.szQuickInfo,		dw	g_szNfoDrvXlateMode
	at	MENUITEM.szHelp,			dw	g_szNfoDrvXlateMode
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_MASKVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDrvXlateMode
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiseXlateMode
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	g_rgwChoiceToValueLookupForXlateMode
	at	MENUITEM.itemValue + ITEM_VALUE.rgszChoiceToStringLookup,	dw	g_rgszChoiceToStringLookupForXlateMode
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	MASK_DRVPARAMS_TRANSLATEMODE
	at	MENUITEM.itemValue + ITEM_VALUE.bFieldPosition,				db	TRANSLATEMODE_FIELD_POSITION
iend

g_MenuitemMasterSlaveWriteCache:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromUnshiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemDrvWriteCache
	at	MENUITEM.szQuickInfo,		dw	g_szNfoDrvWriteCache
	at	MENUITEM.szHelp,			dw	g_szHelpDrvWriteCache
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_MASKVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDrvWriteCache
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiseWrCache
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	g_rgwChoiceToValueLookupForWriteCache
	at	MENUITEM.itemValue + ITEM_VALUE.rgszChoiceToStringLookup,	dw	g_rgszChoiceToStringLookupForWriteCache
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	MASK_DRVPARAMS_WRITECACHE
	at	MENUITEM.itemValue + ITEM_VALUE.bFieldPosition,				db	0
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
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueWriter,				dw	MasterSlaveMenu_WriteCHSFlag
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
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	MAX_PCHS_CYLINDERS
%define					MASTERSLAVE_CYLINDERS_DEFAULT					1024		; Max L-CHS Cylinders
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
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	MAX_PCHS_HEADS
%define					MASTERSLAVE_HEADS_DEFAULT						MAX_PCHS_HEADS
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
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	MAX_PCHS_SECTORS_PER_TRACK
%define					MASTERSLAVE_SECTORS_DEFAULT						MAX_PCHS_SECTORS_PER_TRACK
iend

g_MenuitemMasterSlaveUserLBA:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemDrvUserLBA
	at	MENUITEM.szQuickInfo,		dw	g_szNfoDrvUserLBA
	at	MENUITEM.szHelp,			dw	g_szHelpDrvUserLBA
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_MODIFY_MENU | FLG_MENUITEM_FLAGVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDrvUserLBA
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceBooleanFlag
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForFlagBooleans
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	FLG_DRVPARAMS_USERLBA
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueWriter,				dw	MasterSlaveMenu_WriteLBAFlag
iend

g_MenuitemMasterSlaveUserLbaValue:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateUnsignedInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteUnsignedValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemDrvLbaSectors
	at	MENUITEM.szQuickInfo,		dw	g_szNfoDrvLbaSectors
	at	MENUITEM.szHelp,			dw	g_szNfoDrvLbaSectors
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_UNSIGNED
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDrvLbaSectors
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	16							; 8 GiB (but a little more than L-CHS limit)
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	10000000h / (1024 * 1024)	; Limit to 28-bit LBA
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueReader,				dw	ValueReaderForUserLbaValue
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueWriter,				dw	ValueWriterForUserLbaValue
%define				MASTERSLAVE_USERLBA_DEFAULT						64								; 32 GiB (max supported by Win95)
iend


g_rgwChoiceToValueLookupForWriteCache:
	dw	DEFAULT_WRITE_CACHE
	dw	DISABLE_WRITE_CACHE
	dw	ENABLE_WRITE_CACHE

g_rgszChoiceToStringLookupForWriteCache:
	dw	g_szValueBootDispModeDefault
	dw	g_szValueDrvWrCaDis
	dw	g_szValueDrvWrCaEn

g_rgwChoiceToValueLookupForXlateMode:
	dw	TRANSLATEMODE_NORMAL
	dw	TRANSLATEMODE_LARGE
	dw	TRANSLATEMODE_ASSISTED_LBA
	dw	TRANSLATEMODE_AUTO

g_rgszChoiceToStringLookupForXlateMode:
	dw	g_szValueDrvXlateNormal
	dw	g_szValueDrvXlateLarge
	dw	g_szValueDrvXlateLBA
	dw	g_szValueDrvXlateAuto


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
	mov		[cs:g_MenuitemMasterSlaveChsTranslateMode+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
	mov		[cs:g_MenuitemMasterSlaveWriteCache+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
	mov		[cs:g_MenuitemMasterSlaveUserCHS+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
	mov		[cs:g_MenuitemMasterSlaveUserLBA+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+DRVPARAMS.wCylinders]
	mov		[cs:g_MenuitemMasterSlaveCylinders+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+DRVPARAMS.bHeads]
	mov		[cs:g_MenuitemMasterSlaveHeads+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+DRVPARAMS.bSect]
	mov		[cs:g_MenuitemMasterSlaveSectors+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+DRVPARAMS.dwMaximumLBA]
	mov		[cs:g_MenuitemMasterSlaveUserLbaValue+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
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
	call	.EnableOrDisableUserCHSandLBA
	call	.EnableOrDisableCHandS
	call	.EnableOrDisableUserLbaValue
	mov		si, g_MenupageForMasterSlaveMenu
	jmp		Menupage_ChangeToNewMenupageInDSSI


;--------------------------------------------------------------------
; .EnableOrDisableUserCHSandLBA
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableUserCHSandLBA:
	mov		bx, [g_MenuitemMasterSlaveUserLBA+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	test	ax, FLG_DRVPARAMS_USERLBA
	jnz		SHORT .DisableCHSandEnableLBA
	test	ax, FLG_DRVPARAMS_USERCHS
	jnz		SHORT .EnableCHSandDisableLBA

	; Enable both
	mov		bx, g_MenuitemMasterSlaveUserCHS
	call	.EnableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveUserLBA
	jmp		.EnableMenuitemFromCSBX

ALIGN JUMP_ALIGN
.EnableCHSandDisableLBA:
	mov		bx, g_MenuitemMasterSlaveUserCHS
	call	.EnableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveUserLBA
	jmp		.DisableMenuitemFromCSBX

ALIGN JUMP_ALIGN
.DisableCHSandEnableLBA:
	mov		bx, g_MenuitemMasterSlaveUserLBA
	call	.EnableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveUserCHS
	jmp		.DisableMenuitemFromCSBX


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
	test	ax, FLG_DRVPARAMS_USERLBA
	jnz		SHORT .DisableCHandS

	mov		bx, g_MenuitemMasterSlaveCylinders
	call	.EnableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveHeads
	call	.EnableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveSectors
	jmp		SHORT .EnableMenuitemFromCSBX

ALIGN JUMP_ALIGN
.DisableCHandS:
	mov		bx, g_MenuitemMasterSlaveCylinders
	call	.DisableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveHeads
	call	.DisableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveSectors
	jmp		SHORT .DisableMenuitemFromCSBX


;--------------------------------------------------------------------
; .EnableOrDisableUserLbaValue
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableUserLbaValue:
	mov		bx, [cs:g_MenuitemMasterSlaveUserLBA+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	mov		bx, g_MenuitemMasterSlaveUserLbaValue
	test	ax, FLG_DRVPARAMS_USERCHS
	jnz		SHORT .DisableMenuitemFromCSBX
	test	ax, FLG_DRVPARAMS_USERLBA
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
ValueReaderForUserLbaValue:
	push	dx

	mov		ax, [es:di]
	mov		dx, [es:di+2]		; DX:AX now holds user defined LBA28 limit
	add		ax, BYTE 1			; Increment by one
	adc		dx, BYTE 0

	xchg	ax, dx				; SHR 16
	eSHIFT_IM ax, 4, shr		; SHR 4 => AX = DX:AX / (1024*1024)

	pop		dx
	ret


;--------------------------------------------------------------------
; MENUITEM value writer functions
;	Parameters:
;		AX:		Value to be written to MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset
;		DS:SI:	Ptr to MENUITEM
;		ES:DI:	Ptr to value variable
;	Returns:
;		AX:		Value to be stored
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ValueWriterForUserLbaValue:
	push	dx

	xor		dx, dx
	eSHIFT_IM ax, 4, shl
	xchg	dx, ax			; DX:AX now holds AX * 1024 * 1024

	sub		ax, BYTE 1		; Decrement DX:AX by one
	sbb		dx, BYTE 0		; (necessary since maximum LBA28 sector count is 0FFF FFFFh)

	mov		[es:di+2], dx	; Store DX by ourselves
	pop		dx
	ret						; AX will be stored by our menu system

;
; No change to CHS flag, but we use this opportunity to change defaults stored in the CHS values if we are
; changing in/out of user CHS settings (since we use these bytes in different ways with the LBA setting).
;
ALIGN JUMP_ALIGN
MasterSlaveMenu_WriteCHSFlag:
		test	word [es:di], FLG_DRVPARAMS_USERCHS
		jnz		.alreadySet

		push	ax
		push	di
		push	si

		mov		ax, MASTERSLAVE_CYLINDERS_DEFAULT
		mov		si, g_MenuitemMasterSlaveCylinders
		call	Menuitem_StoreValueFromAXtoMenuitemInDSSI

		mov		ax, MASTERSLAVE_HEADS_DEFAULT
		mov		si, g_MenuitemMasterSlaveHeads
		call	Menuitem_StoreValueFromAXtoMenuitemInDSSI

		mov		ax, MASTERSLAVE_SECTORS_DEFAULT
		mov		si, g_MenuitemMasterSlaveSectors
		call	Menuitem_StoreValueFromAXtoMenuitemInDSSI

		pop		si
		pop		di
		pop		ax

.alreadySet:
		ret

;
; No change to LBA flag, but we use this opportunity to change defaults stored in the LBA value if we are
; changing in/out of user LBA settings (since we use these bytes in different ways with the CHS setting).
;
ALIGN JUMP_ALIGN
MasterSlaveMenu_WriteLBAFlag:
		test	word [es:di], FLG_DRVPARAMS_USERLBA
		jnz		.alreadySet

		push	ax
		push	di
		push	si

		mov		ax, MASTERSLAVE_USERLBA_DEFAULT
		mov		si, g_MenuitemMasterSlaveUserLbaValue
		call	Menuitem_StoreValueFromAXtoMenuitemInDSSI

		pop		si
		pop		di
		pop		ax

.alreadySet:
		ret
