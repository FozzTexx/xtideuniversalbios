; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	"IDE Controller" menu structs and functions.

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
g_MenupageForIdeControllerMenu:
istruc MENUPAGE
	at	MENUPAGE.fnEnter,			dw	IdeControllerMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.fnBack,			dw	ConfigurationMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.wMenuitems,		dw	11
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

g_MenuitemIdeControllerDevice:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromRawItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemIdeDevice
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeDevice
	at	MENUITEM.szHelp,			dw	g_szNfoIdeDevice
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE | FLG_MENUITEM_BYTEVALUE | FLG_MENUITEM_MODIFY_MENU
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDevice
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceCfgDevice
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	g_rgwChoiceToValueLookupForDevice
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForDevice
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueWriter,				dw	IdeControllerMenu_WriteDevice
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
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_HEX
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgIdeCtrlPort
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	0
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	-1
iend

g_MenuitemIdeControllerSerialCOM:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromRawItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemSerialCOM
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeSerialCOM
	at	MENUITEM.szHelp,			dw	g_szHelpIdeSerialCOM
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_MODIFY_MENU | FLG_MENUITEM_BYTEVALUE | FLG_MENUITEM_CHOICESTRINGS
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDevice
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szSerialCOMChoice
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	g_rgbChoiceToValueLookupForCOM
	at	MENUITEM.itemValue + ITEM_VALUE.rgszChoiceToStringLookup,	dw	g_rgszChoiceToStringLookupForCOM
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueWriter,				dw	IdeControllerMenu_SerialWriteCOM
iend

g_MenuitemIdeControllerSerialPort:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateHexInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteHexValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemSerialPort
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeSerialPort
	at	MENUITEM.szHelp,			dw	g_szHelpIdeSerialPort
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_MODIFY_MENU | FLG_MENUITEM_BYTEVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_HEX
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgIdeCmdPort
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	8h
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	3f8h
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueReader,				dw	IdeControllerMenu_SerialReadPort
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueWriter,				dw	IdeControllerMenu_SerialWritePort
iend

g_MenuitemIdeControllerSerialBaud:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromRawItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemSerialBaud
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeSerialBaud
	at	MENUITEM.szHelp,			dw	g_szHelpIdeSerialBaud
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_BYTEVALUE | FLG_MENUITEM_CHOICESTRINGS
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDevice
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szSerialBaudChoice
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	g_rgbChoiceToValueLookupForBaud
	at	MENUITEM.itemValue + ITEM_VALUE.rgszChoiceToStringLookup,	dw	g_rgszChoiceToStringLookupForBaud
iend

g_MenuitemIdeControllerEnableInterrupt:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemIdeEnIRQ
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeEnIRQ
	at	MENUITEM.szHelp,			dw	g_szHelpIdeEnIRQ
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_MODIFY_MENU | FLG_MENUITEM_FLAGVALUE
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

g_rgwChoiceToValueLookupForDevice:
	dw	DEVICE_16BIT_ATA
	dw	DEVICE_32BIT_ATA
	dw	DEVICE_8BIT_ATA
	dw	DEVICE_8BIT_XTIDE_REV1
	dw	DEVICE_8BIT_XTIDE_REV2
	dw	DEVICE_8BIT_XTCF_PIO8
	dw	DEVICE_8BIT_XTCF_PIO8_WITH_BIU_OFFLOAD
	dw	DEVICE_8BIT_XTCF_PIO16_WITH_BIU_OFFLOAD
	dw	DEVICE_8BIT_XTCF_DMA
	dw	DEVICE_8BIT_JRIDE_ISA
	dw	DEVICE_8BIT_ADP50L
	dw	DEVICE_SERIAL_PORT
g_rgszValueToStringLookupForDevice:
	dw	g_szValueCfgDevice16b
	dw	g_szValueCfgDevice32b
	dw	g_szValueCfgDevice8b
	dw	g_szValueCfgDeviceRev1
	dw	g_szValueCfgDeviceRev2
	dw	g_szValueCfgDeviceXTCFPio8
	dw	g_szValueCfgDeviceXTCFPio8WithBIUOffload
	dw	g_szValueCfgDeviceXTCFPio16WithBIUOffload
	dw	g_szValueCfgDeviceXTCFDMA
	dw	g_szValueCfgDeviceJrIdeIsa
	dw	g_szValueCfgDeviceADP50L
	dw	g_szValueCfgDeviceSerial

g_rgbChoiceToValueLookupForCOM:
	dw	'1'
	dw	'2'
	dw	'3'
	dw	'4'
	dw	'5'
	dw	'6'
	dw	'7'
	dw	'8'
	dw	'9'
	dw	'A'
	dw	'B'
	dw	'C'
	dw	'x'				; must be last entry (see reader/write routines)
g_rgszChoiceToStringLookupForCOM:
	dw	g_szValueCfgCOM1
	dw	g_szValueCfgCOM2
	dw	g_szValueCfgCOM3
	dw	g_szValueCfgCOM4
	dw	g_szValueCfgCOM5
	dw	g_szValueCfgCOM6
	dw	g_szValueCfgCOM7
	dw	g_szValueCfgCOM8
	dw	g_szValueCfgCOM9
	dw	g_szValueCfgCOMA
	dw	g_szValueCfgCOMB
	dw	g_szValueCfgCOMC
	dw	g_szValueCfgCOMx
	dw	NULL

SERIAL_DEFAULT_CUSTOM_PORT		EQU		300h		; can't be any of the pre-defined COM values
SERIAL_DEFAULT_COM				EQU		'1'
SERIAL_DEFAULT_BAUD				EQU		((115200 / 9600)	& 0xff)

PackedCOMPortAddresses:								; COM1 - COMC (or COM12)
	db		SERIAL_COM1_IOADDRESS >> 2
	db		SERIAL_COM2_IOADDRESS >> 2
	db		SERIAL_COM3_IOADDRESS >> 2
	db		SERIAL_COM4_IOADDRESS >> 2
	db		SERIAL_COM5_IOADDRESS >> 2
	db		SERIAL_COM6_IOADDRESS >> 2
	db		SERIAL_COM7_IOADDRESS >> 2
	db		SERIAL_COM8_IOADDRESS >> 2
	db		SERIAL_COM9_IOADDRESS >> 2
	db		SERIAL_COMA_IOADDRESS >> 2
	db		SERIAL_COMB_IOADDRESS >> 2
	db		SERIAL_COMC_IOADDRESS >> 2
	db		SERIAL_DEFAULT_CUSTOM_PORT >> 2			; must be last entry (see reader/writer routines)

g_rgbChoiceToValueLookupForBaud:
	dw		(115200 / 115200) & 0xff
	dw		(115200 /  57600) & 0xff
	dw		(115200 /  38400) & 0xff
	dw		(115200 /  28800) & 0xff
	dw		(115200 /  19200) & 0xff
	dw		(115200 /   9600) & 0xff
	dw		(115200 /   4800) & 0xff
	dw		(115200 /   2400) & 0xff
g_rgszChoiceToStringLookupForBaud:
	dw		g_szValueCfgBaud115_2
	dw		g_szValueCfgBaud57_6
	dw		g_szValueCfgBaud38_4
	dw		g_szValueCfgBaud28_8
	dw		g_szValueCfgBaud19_2
	dw		g_szValueCfgBaud9600
	dw		g_szValueCfgBaud4800
	dw		g_szValueCfgBaud2400
	dw		NULL

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

	lea		ax, [bx+IDEVARS.bDevice]
	mov		[cs:g_MenuitemIdeControllerDevice+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+IDEVARS.wBasePort]
	mov		[cs:g_MenuitemIdeControllerCommandBlockAddress+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+IDEVARS.bSerialPort]
	mov		[cs:g_MenuitemIdeControllerSerialPort+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+IDEVARS.bSerialBaud]
	mov		[cs:g_MenuitemIdeControllerSerialBaud+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+IDEVARS.wControlBlockPort]
	mov		[cs:g_MenuitemIdeControllerControlBlockAddress+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

	lea		ax, [bx+IDEVARS.bSerialCOMPortChar]
	mov		[cs:g_MenuitemIdeControllerSerialCOM+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax

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
	call	.EnableOrDisableCommandBlockPort
	call	.EnableOrDisableControlBlockPort
	call	.DisableIRQchannelSelection
	call	.EnableOrDisableEnableInterrupt
	call	.EnableOrDisableSerial
	mov		si, g_MenupageForIdeControllerMenu
	jmp		Menupage_ChangeToNewMenupageInDSSI


;--------------------------------------------------------------------
; .EnableOrDisableCommandBlockPort
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableCommandBlockPort:
	mov		bx, [cs:g_MenuitemIdeControllerDevice+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	mov		bx, g_MenuitemIdeControllerCommandBlockAddress
	cmp		al, DEVICE_SERIAL_PORT
	je		SHORT .DisableMenuitemFromCSBX
	jmp		SHORT .EnableMenuitemFromCSBX


;--------------------------------------------------------------------
; .EnableOrDisableControlBlockPort
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableControlBlockPort:
	mov		bx, [cs:g_MenuitemIdeControllerDevice+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	mov		bx, g_MenuitemIdeControllerControlBlockAddress
	cmp		al, DEVICE_8BIT_XTCF_PIO8
	jb		SHORT .EnableMenuitemFromCSBX	; Not needed for XT-CF, JR-IDE/ISA and ADP50L
	jmp		SHORT .DisableMenuitemFromCSBX


;--------------------------------------------------------------------
; .EnableOrDisableEnableInterrupt
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableEnableInterrupt:
	call	Buffers_GetRomvarsFlagsToAX
	mov		bx, g_MenuitemIdeControllerEnableInterrupt
	test	ax, FLG_ROMVARS_MODULE_IRQ
	jz		SHORT .DisableMenuitemFromCSBX

	mov		bx, [cs:g_MenuitemIdeControllerDevice+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	mov		bx, g_MenuitemIdeControllerEnableInterrupt
	cmp		al, DEVICE_8BIT_XTCF_PIO8
	jae		SHORT .DisableMenuitemFromCSBX

	call	EnableMenuitemFromCSBX
	; Fall to .EnableOrDisableIRQchannelSelection

;--------------------------------------------------------------------
; .EnableOrDisableIRQchannelSelection
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableIRQchannelSelection:
	mov		bx, [cs:g_MenuitemIdeControllerEnableInterrupt+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	mov		bx, g_MenuitemIdeControllerIdeIRQ
	test	al, al
	jnz		SHORT .EnableMenuitemFromCSBX
.DisableIRQchannelSelection:
	mov		bx, g_MenuitemIdeControllerIdeIRQ
	; Fall to .DisableMenuitemFromCSBX


;--------------------------------------------------------------------
; .DisableMenuitemFromCSBX
; .EnableMenuitemFromCSBX
;	Parameters:
;		CS:BX:	Ptr to MENUITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.DisableMenuitemFromCSBX:
	jmp		DisableMenuitemFromCSBX

ALIGN JUMP_ALIGN
.EnableMenuitemFromCSBX:
	jmp		EnableMenuitemFromCSBX


.EnableOrDisableSerial:
	mov		bx, g_MenuitemIdeControllerSerialBaud
	call	DisableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerSerialCOM
	call	DisableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerSerialPort
	call	DisableMenuitemFromCSBX

	mov		bx, [cs:g_MenuitemIdeControllerDevice+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	cmp		al, DEVICE_SERIAL_PORT
	jne		.DisableAllSerial

	mov		bx, g_MenuitemIdeControllerSerialCOM
	call	EnableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerSerialBaud
	call	EnableMenuitemFromCSBX

	mov		bx, [cs:g_MenuitemIdeControllerSerialCOM+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	mov		bx, g_MenuitemIdeControllerSerialPort
	cmp		al, 'x'
	je		SHORT .EnableMenuitemFromCSBX
	jmp		SHORT .DisableMenuitemFromCSBX
.DisableAllSerial:
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
;
; "Block Mode Transfers" and "Internal Write Cache" are not supported on serial drives, disable/enable the options as appropriate
;
	push	bx
	mov		bx, [cs:g_MenuitemIdeControllerDevice+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	mov		bx, g_MenuitemMasterSlaveBlockModeTransfers

	cmp		al, DEVICE_SERIAL_PORT
	je		.isSerial

	call	EnableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveWriteCache
	call	EnableMenuitemFromCSBX
	jmp		.isDone

.isSerial:
	call	DisableMenuitemFromCSBX
	mov		bx, g_MenuitemMasterSlaveWriteCache
	call	DisableMenuitemFromCSBX

.isDone:
	pop		bx

	call	MasterSlaveMenu_InitializeToDrvparamsOffsetInBX
	jmp		MasterSlaveMenu_EnterMenuOrModifyItemVisibility

;------------------------------------------------------------------------------------------
;
; Reader/Writer Routines
;
; For serial drives, we pack the port number and baud rate into a single byte, and thus
; we need to take care to properly read/write just the bits we need.  In addition, since
; we use the Port/PortCtrl bytes in a special way for serial drives, we need to properly
; default the values stored in both these words when switching in and out of the Serial
; device choice.
;
; Writers:
;	Parameters:
;		AX:		Value that the MENUITEM system was interacting with
;		ES:DI:	ROMVARS location where the value is to be stored
;		DS:SI:	MENUITEM pointer
;	Returns:
;		AX:		Value to actually write to ROMVARS
;	Corrupts registers:
;		AX
;
; Readers:
;	Parameters:
;		AX:		Value read from the ROMVARS location
;		ES:DI:	ROMVARS location where the value was just read from
;		DS:SI:	MENUITEM pointer
;	Returns:
;		AX:		Value that the MENUITEM system will interact with and display
;	Corrupts registers:
;		AX
;
ALIGN JUMP_ALIGN
WriterForXTCFwindow:
	xor		al, al
	SKIP2B	f
ReaderForXTCFwindow:
	xor		ah, ah
	xchg	al, ah
	ret


;
; No change to Device byte, but use this opportunity to change defaults stored in wPort and wPortCtrl if we are
; changing in/out of a Serial device (since we use these bytes in radically different ways).
;
ALIGN JUMP_ALIGN
IdeControllerMenu_WriteDevice:
	push	bx
	push	di
	push	ax

	; Note! AL is the choice index, not device code
	shl		ax, 1								; Selection to device code
	mov		bl, [es:di]							; what is the current Device we are changing from?
	sub		di, BYTE IDEVARS.bDevice - IDEVARS.wBasePort	; Get ready to set the Port addresses
	cmp		al, DEVICE_SERIAL_PORT
	je		SHORT .ChangingToSerial
	cmp		al, DEVICE_8BIT_JRIDE_ISA
	je		SHORT .ChangingToJrIdeIsa
	cmp		al, DEVICE_8BIT_ADP50L
	je		SHORT .ChangingToADP50L

	; Restore ports to default values
	cmp		al, DEVICE_8BIT_ATA					; Standard ATA controllers, including 8-bit mode
	mov		ax, DEVICE_ATA_PRIMARY_PORT			; Defaults for 16-bit and better ATA devices
	mov		bx, DEVICE_ATA_PRIMARY_PORTCTRL
	jbe		SHORT .WriteNonSerial

	mov		ax, DEVICE_XTIDE_DEFAULT_PORT		; Defaults for 8-bit XTIDE and XT-CF devices
	mov		bx, DEVICE_XTIDE_DEFAULT_PORTCTRL

.WriteNonSerial:
	stosw										; Store defaults in IDEVARS.wBasePort and IDEVARS.wBasePortCtrl
	xchg	bx, ax
	stosw
	jmp		SHORT .Done

.ChangingToJrIdeIsa:
	mov		ah, JRIDE_DEFAULT_SEGMENT_ADDRESS >> 8
	SKIP2B	bx

.ChangingToADP50L:
	mov		ah, ADP50L_DEFAULT_BIOS_SEGMENT_ADDRESS >> 8
	xor		al, al
	xor		bx, bx
	jmp		SHORT .WriteNonSerial

.ChangingToSerial:
	cmp		bl, DEVICE_SERIAL_PORT
	je		SHORT .Done							; if we were already serial, nothing to do

	mov		BYTE [es:di+IDEVARS.bSerialBaud-IDEVARS.wBasePort], SERIAL_DEFAULT_BAUD
	mov		BYTE [es:di+IDEVARS.bIRQ-IDEVARS.wBasePort], 0	; Clear .bIRQ to keep the boot menu from printing it

	mov		al, SERIAL_DEFAULT_COM
	sub		di, IDEVARS.wBasePort - IDEVARS.bSerialCOMPortChar
	call	IdeControllerMenu_SerialWriteCOM
	stosb

.Done:
	pop		ax
	pop		di			; IDEVARS.bDevice
	pop		bx
	ret

;
; Doesn't modify COM character (unless it is not recognized, which would be an error case),
; But does update the port address based on COM port selection
;
ALIGN JUMP_ALIGN
IdeControllerMenu_SerialWriteCOM:
	push	ax
	push	bx
	push	si

	mov		si, g_rgbChoiceToValueLookupForCOM
	mov		bx, PackedCOMPortAddresses

.loop:
	mov		ah, [bx]

	cmp		ah, (SERIAL_DEFAULT_CUSTOM_PORT >> 2)
	je		.notFound

	cmp		al, [si]
	je		.found

	inc		si
	inc		si
	inc		bx

	jmp		.loop

.notFound:
	mov		al, 'x'

.found:
	mov		[es:di+IDEVARS.bSerialPort-IDEVARS.bSerialCOMPortChar], ah

	pop		si
	pop		bx
	pop		ax

	ret


;
; Packed Port (byte) -> Numeric Port (word)
;
ALIGN JUMP_ALIGN
IdeControllerMenu_SerialReadPort:
	xor		ah, ah
	eSHL_IM	ax, 2
	ret

;
; Numeric Port (word) -> Packed Port (byte)
; And convert from Custom to a defined COM port if we match one of the pre-defined COM port numbers
;
ALIGN JUMP_ALIGN
IdeControllerMenu_SerialWritePort:
	push	bx
	push	si

	eSHR_IM	ax, 2
	and		al, 0feh			; force 8-byte boundary

	mov		si, g_rgbChoiceToValueLookupForCOM
	mov		bx, PackedCOMPortAddresses			; loop, looking for port address in known COM address list

.loop:
	mov		ah, [si]
	cmp		ah, 'x'
	je		.found

	cmp		al, [bx]
	je		.found

	inc		si
	inc		si
	inc		bx

	jmp		.loop

.found:
	mov		[es:di+IDEVARS.bSerialCOMPortChar-IDEVARS.bSerialPort], ah

	pop		si
	pop		bx

	ret

