; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	"IDE Controller" menu structs and functions.

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
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
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
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_HEX
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgIdeCtrlPort
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	0
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	-1
iend

g_MenuitemIdeControllerSerialCOM:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromUnshiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemSerialCOM
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeSerialCOM
	at	MENUITEM.szHelp,			dw	g_szHelpIdeSerialCOM
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_MODIFY_MENU
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE 
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDevice
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szSerialCOMChoice
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForCOM
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueReader,				dw	IdeControllerMenu_SerialReadCOM  
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueWriter,				dw	IdeControllerMenu_SerialWriteCOM
iend

g_MenuitemIdeControllerSerialPort:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateHexInputForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteHexValueStringToBufferInESDIfromItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemSerialPort
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeSerialPort
	at	MENUITEM.szHelp,			dw	g_szHelpIdeSerialPort
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_MODIFY_MENU		
	at	MENUITEM.bType,				db	TYPE_MENUITEM_HEX
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgIdeCmdPort
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	DEVICE_SERIAL_PACKEDPORTANDBAUD_MINPORT
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	DEVICE_SERIAL_PACKEDPORTANDBAUD_MAXPORT
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueReader,				dw	IdeControllerMenu_SerialReadPort
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueWriter,				dw	IdeControllerMenu_SerialWritePort
iend		

g_MenuitemIdeControllerSerialBaud:		
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromUnshiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemSerialBaud
	at	MENUITEM.szQuickInfo,		dw	g_szNfoIdeSerialBaud
	at	MENUITEM.szHelp,			dw	g_szHelpIdeSerialBaud
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgDevice
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szSerialBaudChoice
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForBaud
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueReader,				dw	IdeControllerMenu_SerialReadBaud
	at	MENUITEM.itemValue + ITEM_VALUE.fnValueWriter,				dw	IdeControllerMenu_SerialWriteBaud
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

g_rgwChoiceToValueLookupForDevice:
	dw	DEVICE_8BIT_DUAL_PORT_XTIDE
	dw	DEVICE_XTIDE_WITH_REVERSED_A3_AND_A0
	dw	DEVICE_8BIT_SINGLE_PORT
	dw	DEVICE_16BIT_ATA
	dw	DEVICE_32BIT_ATA
	dw	DEVICE_SERIAL_PORT
g_rgszValueToStringLookupForDevice:
	dw	g_szValueCfgDeviceDual8b
	dw	g_szValueCfgDeviceMod
	dw	g_szValueCfgDeviceSingle8b
	dw	g_szValueCfgDevice16b
	dw	g_szValueCfgDevice32b
	dw	g_szValueCfgDeviceSerial

g_rgszValueToStringLookupForCOM:		
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

g_rgszValueToStringLookupForBaud:
	dw	g_szValueCfgBaud2400
	dw	g_szValueCfgBaud9600
	dw	g_szValueCfgBaud38_4
	dw	g_szValueCfgBaud115_2

g_wPrintBaud:
	dw	DEVICE_SERIAL_PRINTBAUD_2400
	dw	DEVICE_SERIAL_PRINTBAUD_9600
	dw	DEVICE_SERIAL_PRINTBAUD_38_4
	dw	DEVICE_SERIAL_PRINTBAUD_115_2

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

	lea		ax, [bx+IDEVARS.wPort]
	mov		[cs:g_MenuitemIdeControllerCommandBlockAddress+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
	mov		[cs:g_MenuitemIdeControllerSerialPort+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
	mov		[cs:g_MenuitemIdeControllerSerialCOM+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax		
	mov		[cs:g_MenuitemIdeControllerSerialBaud+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset], ax
				;; baud also modifies the next two bytes (print chars in wPortCtrl), but it never reads them
		
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
	call	.EnableOrDisableSerial
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
	test	al, al
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

.EnableOrDisableSerial:
	mov		bx, g_MenuitemIdeControllerCommandBlockAddress
	call	.DisableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerControlBlockAddress
	call	.DisableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerEnableInterrupt
	call	.DisableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerSerialBaud
	call	.DisableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerSerialCOM
	call	.DisableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerSerialPort
	call	.DisableMenuitemFromCSBX
				
	mov		bx, [cs:g_MenuitemIdeControllerDevice+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]		
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	cmp		al,DEVICE_SERIAL_PORT
	jnz		.DisableAllSerial

	mov		bx, g_MenuitemIdeControllerSerialCOM
	call	.EnableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerSerialBaud
	call	.EnableMenuitemFromCSBX

	mov		bx, [cs:g_MenuitemIdeControllerSerialCOM+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]			
	call	Buffers_GetRomvarsValueToAXfromOffsetInBX
	mov		bx, g_MenuitemIdeControllerSerialPort
	cmp		al,'x'
	jz		.EnableMenuitemFromCSBX
	jmp		.DisableMenuitemFromCSBX

.DisableAllSerial:

	mov		bx, g_MenuitemIdeControllerCommandBlockAddress
	call	.EnableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerControlBlockAddress
	call	.EnableMenuitemFromCSBX

	mov		bx, g_MenuitemIdeControllerEnableInterrupt
	call	.EnableMenuitemFromCSBX				

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

PackedCOMPortAddresses:				; COM1 - COMC (or COM12)
	db      (DEVICE_SERIAL_COM1 - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1
	db		(DEVICE_SERIAL_COM2 - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1
	db		(DEVICE_SERIAL_COM3 - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1
	db		(DEVICE_SERIAL_COM4 - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1   
	db		(DEVICE_SERIAL_COM5 - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1
	db		(DEVICE_SERIAL_COM6 - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1
	db		(DEVICE_SERIAL_COM7 - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1   
	db		(DEVICE_SERIAL_COM8 - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1   
	db		(DEVICE_SERIAL_COM9 - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1
	db		(DEVICE_SERIAL_COMA - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1   
	db		(DEVICE_SERIAL_COMB - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1
	db		(DEVICE_SERIAL_COMC - DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT) >> 1  
	db		0						; null terminated

;------------------------------------------------------------------------------------------
;
; Reader/Writer Routines
;
; For serial drives, we pack the port number and baud rate into a single byte, and thus
; we need to take care to properly read/write just the bits we need.  In addition, since
; we use the Port/PortCtrl bytes in a special way for serial drives, we need to properly
; default the values stored in both these words  when switching in and out of the Serial 
; device choice.
;
; Writers:
;	Parameters:
;       AX:     Value that the MENUITEM system was interacting with
;		ES:DI:  ROMVARS location where the value is to be stored
;	    DS:SI:  MENUITEM pointer
;	Returns:
;		AX:		Value to actually write to ROMVARS
;	Corrupts registers:
;		AX
;
; Readers:
;	Parameters:
;       AX:     Value read from the ROMVARS location
;		ES:DI:  ROMVARS location where the value was just read from
;	    DS:SI:  MENUITEM pointer
;	Returns:
;		AX:		Value that the MENUITEM system will interact with and display
;	Corrupts registers:
;		AX
;

;
; No change to Device byte, but use this opportunity to change defaults stored in wPort and wPortCtrl if we are
; changing in/out of a Serial device (since we use these bytes in radically different ways).  Also clear the
; interrupt informtion is we are moving into Serial (since the serial device does not use interrupts).
;
ALIGN JUMP_ALIGN
IdeControllerMenu_WriteDevice:
		push	ax
		push	bx
		push	di

		mov		bl,[es:di]							; what is the current Device?
		
		add		di,IDEVARS.wPort - IDEVARS.bDevice	; Get ready to set the Port addresses
		
		cmp		al,DEVICE_SERIAL_PORT
		jz		.changingToSerial

		cmp		bl,DEVICE_SERIAL_PORT
		jnz		.done								; if we weren't Serial before, nothing to do

.changingFromSerial:
		cmp		al,DEVICE_16BIT_ATA
		jl		.xtide

		mov		ax,DEVICE_ATA_DEFAULT_PORT			; Defaults for 16-bit and better ATA devices
		mov		bx,DEVICE_ATA_DEFAULT_PORTCTRL
		jmp		.writeNonSerial

.xtide:	
		mov		ax,DEVICE_XTIDE_DEFAULT_PORT		; Defaults for 8-bit XTIDE devices
		mov		bx,DEVICE_XTIDE_DEFAULT_PORTCTRL		

.writeNonSerial:		
		mov		[es:di],ax							; Store defaults in IDEVARS.wPort and IDEVARS.wPortCtrl
		mov		[es:di+2],bx

		jmp		.done

.changingToSerial:		
		cmp		bl,DEVICE_SERIAL_PORT
		jz		.done								; if we were already serial, nothing to do

		mov		ax,DEVICE_SERIAL_DEFAULT_COM
		call	IdeControllerMenu_SerialWriteCOM
		mov		[es:di],ax
		
		mov		ax,DEVICE_SERIAL_DEFAULT_BAUD
		call	IdeControllerMenu_SerialWriteBaud
		mov		[es:di],ax
				
		add		di,IDEVARS.bIRQ - IDEVARS.wPort		; clear out the interrupt information, we don't use interrupts
		mov		al,0
		mov		[es:di],al

.done:	
		pop		di
		pop		bx
		pop		ax

		ret

;
; "COMn" ASCII characer -> Numeric COM number
;
ALIGN JUMP_ALIGN
IdeControllerMenu_SerialReadCOM:
		xor		ah,ah								; clear out packedportbaud value

		cmp		al,'x'								; base this on the ASCII character used to print
		jz		.custom

		cmp		al,'A'
		jae		.over10

		sub		al, '0'+1							; convert ASCII value '0'-'9' to numeric
		ret

.over10:
		sub		al, 'A'-10+1						; convert ASCII value 'A'-'C' to numeric
		ret

.custom:
		mov		al, 12								; convert ASCII value 'x' (for custom) to numeric
		ret

;
; Numeric COM number -> Packed port address, and update ASCII character for printing "COMn"
;				
ALIGN JUMP_ALIGN
IdeControllerMenu_SerialWriteCOM:
		push	bx

		cmp		al,12								; custom?
		jge		.custom

		mov		bx,ax								; lookup packed port address based on COM address
		mov		ah,[cs:bx+PackedCOMPortAddresses]

		cmp		al,9								; COMA or higher, but not custom
		jge		.atorabove10

		add		al, '0'+1							; convert numeric to ASCII '1' to '9'
		jmp		IdeControllerMenu_SerialWriteCOM_PackAndRet

.custom:
		mov		al,'x'								; ASCII value 'x' for custom
		mov		ah,1 << DEVICE_SERIAL_PACKEDPORTANDBAUD_PORT_FIELD_POSITION	; 248h 
		jmp		IdeControllerMenu_SerialWriteCOM_PackAndRet

.atorabove10:
		add		al, 'A'-10+1						; convert numeric to ASCII 'A' to 'C'

IdeControllerMenu_SerialWriteCOM_PackAndRet:
		mov		bl,[es:di+1]						; read baud rate bits
		and		bl,DEVICE_SERIAL_PACKEDPORTANDBAUD_BAUDMASK  	
		or		ah,bl

		pop		bx
		ret		

;
; Packed Baud -> Numeric Baud
;				
ALIGN JUMP_ALIGN
IdeControllerMenu_SerialReadBaud:
		xchg	al,ah
		and		ax,DEVICE_SERIAL_PACKEDPORTANDBAUD_BAUDMASK			; also clears high order byte
		ret

;
; Numeric Baud -> Packed Baud, also update ASCII printing characters for baud rate
;				
ALIGN JUMP_ALIGN
IdeControllerMenu_SerialWriteBaud:
		and		ax,DEVICE_SERIAL_PACKEDPORTANDBAUD_BAUDBITS 		; ensure we only have the bits we want
		
		push	bx

		mov		bx,ax												; lookup printing word for wPortCtrl
		shl		bx,1
		mov		bx,[cs:bx+g_wPrintBaud]
		mov		[es:di+2],bx

		xchg	al,ah												; or in port bits
		mov		bx,[es:di]
		and		bh,DEVICE_SERIAL_PACKEDPORTANDBAUD_PORTMASK 
		or		ax,bx

		pop		bx
		ret

;
; Packed Port -> Numeric Port
;				
ALIGN JUMP_ALIGN
IdeControllerMenu_SerialReadPort:		
		mov		al,ah
		and		ax,DEVICE_SERIAL_PACKEDPORTANDBAUD_PORTMASK    		; note that this clears AH
		shl		ax,1
		add		ax,DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT
		ret

;
; Numeric Port -> Packed Port, convert from Custom to a defined COM port if we match one
;
ALIGN JUMP_ALIGN
IdeControllerMenu_SerialWritePort:		
		push	bx

		sub		ax,DEVICE_SERIAL_PACKEDPORTANDBAUD_STARTINGPORT		; convert from numeric to packed port number
		shr		ax,1
		and		al,DEVICE_SERIAL_PACKEDPORTANDBAUD_PORTMASK

		mov		bx,PackedCOMPortAddresses							; loop, looking for port address in known COM address list
.next:	
		mov		ah,[cs:bx]
		inc		bx
		test	ah,ah
		jz		.notfound
		cmp		al,ah
		jnz		.next

		sub		bx,PackedCOMPortAddresses + 1						; FOUND!, +1 since we already incremented
		mov		ax,bx
		pop		bx
		jmp		IdeControllerMenu_SerialWriteCOM					; if found, use that logic to get ASCII character

.notfound:
		xchg	ah,al												
		mov		al,'x'
		jmp		IdeControllerMenu_SerialWriteCOM_PackAndRet


