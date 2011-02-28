; Project name	:	XTIDE Universal BIOS Configurator v2
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
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemFlashEepromType
	at	MENUITEM.szQuickInfo,		dw	g_szNfoFlashEepromType
	at	MENUITEM.szHelp,			dw	g_szNfoFlashEepromType
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_PROGRAMVAR | FLG_MENUITEM_BYTEVALUE | FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	CFGVARS.bEepromType
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgFlashEepromType
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceEepromType
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	g_rgwChoiceToValueLookupForEepromType
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForEepromType
iend

g_MenuitemFlashSdpCommand:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemFlashSDP
	at	MENUITEM.szQuickInfo,		dw	g_szNfoFlashSDP
	at	MENUITEM.szHelp,			dw	g_szHelpFlashSDP
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_PROGRAMVAR | FLG_MENUITEM_BYTEVALUE | FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	CFGVARS.bSdpCommand
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgFlashSDP
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceSdpCommand
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	g_rgwChoiceToValueLookupForSdpCommand
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForSdpCommand
iend

g_MenuitemFlashPageSize:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemFlashPageSize
	at	MENUITEM.szQuickInfo,		dw	g_szNfoFlashPageSize
	at	MENUITEM.szHelp,			dw	g_szHelpFlashPageSize
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_PROGRAMVAR | FLG_MENUITEM_BYTEVALUE | FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	CFGVARS.bEepromPage
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgFlashPageSize
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoicePageSize
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiceToValueLookup,		dw	g_rgwChoiceToValueLookupForPageSize
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
	at	MENUITEM.fnActivate,		dw	Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
	at	MENUITEM.fnFormatValue,		dw	MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
	at	MENUITEM.szName,			dw	g_szItemFlashChecksum
	at	MENUITEM.szQuickInfo,		dw	g_szNfoFlashChecksum
	at	MENUITEM.szHelp,			dw	g_szHelpFlashChecksum
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_PROGRAMVAR | FLG_MENUITEM_VISIBLE | FLG_MENUITEM_FLAGVALUE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_MULTICHOICE
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	CFGVARS.wFlags
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	g_szDlgFlashChecksum
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoice,				dw	g_szMultichoiceBooleanFlag
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	g_rgszValueToStringLookupForFlagBooleans
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	FLG_CFGVARS_CHECKSUM
iend

g_rgwChoiceToValueLookupForEepromType:
	dw	EEPROM_TYPE.2816_2kiB
	dw	EEPROM_TYPE.2864_8kiB
	dw	EEPROM_TYPE.28256_32kiB
	dw	EEPROM_TYPE.28512_64kiB
g_rgszValueToStringLookupForEepromType:
	dw	g_szValueFlash2816
	dw	g_szValueFlash2864
	dw	g_szValueFlash28256
	dw	g_szValueFlash28512

g_rgwChoiceToValueLookupForSdpCommand:
	dw	SDP_COMMAND.none
	dw	SDP_COMMAND.enable
	dw	SDP_COMMAND.disable
g_rgszValueToStringLookupForSdpCommand:
	dw	g_szValueFlashNone
	dw	g_szValueFlashEnable
	dw	g_szValueFlashDisable

g_rgwChoiceToValueLookupForPageSize:
	dw	EEPROM_PAGE.1_byte
	dw	EEPROM_PAGE.2_bytes
	dw	EEPROM_PAGE.4_bytes
	dw	EEPROM_PAGE.8_bytes
	dw	EEPROM_PAGE.16_bytes
	dw	EEPROM_PAGE.32_bytes
	dw	EEPROM_PAGE.64_bytes
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
	call	.MakeSureThatImageFitsInEeprom
	jc		SHORT .InvalidFlashingParameters
	push	es
	push	ds

	call	.PrepareBuffersForFlashing
	mov		cx, FLASHVARS_size + PROGRESS_DIALOG_IO_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	.InitializeFlashvarsFromDSSI
	mov		bx, si							; DS:BX now points to FLASHVARS
	add		si, BYTE FLASHVARS_size			; DS:SI now points to PROGRESS_DIALOG_IO
	call	Dialogs_DisplayProgressDialogForFlashingWithDialogIoInDSSIandFlashvarsInDSBX
	call	.DisplayFlashingResultsFromFlashvarsInDSBX

	add		sp, BYTE FLASHVARS_size + PROGRESS_DIALOG_IO_size
	pop		ds
	pop		es
.InvalidFlashingParameters:
	ret

;--------------------------------------------------------------------
; .MakeSureThatImageFitsInEeprom
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		CF:		Set if EEPROM too small
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.MakeSureThatImageFitsInEeprom:
	call	.GetSelectedEepromSizeInWordsToAX
	cmp		ax, [cs:g_cfgVars+CFGVARS.wImageSizeInWords]
	jae		SHORT .ImageFitsInSelectedEeprom
	mov		dx, g_szErrEepromTooSmall
	call	Dialogs_DisplayErrorFromCSDX
	stc
	ret
ALIGN JUMP_ALIGN
.ImageFitsInSelectedEeprom:
	clc
	ret

;--------------------------------------------------------------------
; .PrepareBuffersForFlashing
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.PrepareBuffersForFlashing:
	call	EEPROM_LoadFromRomToRamComparisonBuffer
	call	Buffers_AppendZeroesIfNeeded
	test	WORD [cs:g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_CHECKSUM
	jz		SHORT .DoNotGenerateChecksumByte
	jmp		Buffers_GenerateChecksum
.DoNotGenerateChecksumByte:
	ret

;--------------------------------------------------------------------
; .InitializeFlashvarsFromDSSI
;	Parameters:
;		DS:SI:	Ptr to FLASHVARS to initialize
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.InitializeFlashvarsFromDSSI:
	call	Buffers_GetFileBufferToESDI
	mov		[si+FLASHVARS.fpNextSourcePage], di
	mov		[si+FLASHVARS.fpNextSourcePage+2], es

	call	Buffers_GetFlashComparisonBufferToESDI
	mov		[si+FLASHVARS.fpNextComparisonPage], di
	mov		[si+FLASHVARS.fpNextComparisonPage+2], es

	mov		ax, [cs:g_cfgVars+CFGVARS.wEepromSegment]
	mov		WORD [si+FLASHVARS.fpNextDestinationPage], 0
	mov		[si+FLASHVARS.fpNextDestinationPage+2], ax

	mov		al, [cs:g_cfgVars+CFGVARS.bEepromType]
	mov		[si+FLASHVARS.bEepromType], al

	mov		al, [cs:g_cfgVars+CFGVARS.bSdpCommand]
	mov		[si+FLASHVARS.bEepromSdpCommand], al

	eMOVZX	bx, BYTE [cs:g_cfgVars+CFGVARS.bEepromPage]
	mov		ax, [cs:bx+g_rgwEepromPageToSizeInBytes]
	mov		[si+FLASHVARS.wEepromPageSize], ax

	call	.GetNumberOfPagesToFlashToAX
	mov		[si+FLASHVARS.wPagesToFlash], ax
	ret

;--------------------------------------------------------------------
; .GetNumberOfPagesToFlashToAX
;	Parameters:
;		DS:SI:	Ptr to FLASHVARS to initialize
;	Returns:
;		AX:		Number of pages to flash (0 = 65536)
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetNumberOfPagesToFlashToAX:
	call	.GetSelectedEepromSizeInWordsToAX
	xor		dx, dx
	shl		ax, 1		; Size in bytes to...
	rcl		dx, 1		; ...DX:AX

	cmp		WORD [si+FLASHVARS.wEepromPageSize], BYTE 1
	jbe		SHORT .PreventDivideException
	div		WORD [si+FLASHVARS.wEepromPageSize]
.PreventDivideException:
	ret

;--------------------------------------------------------------------
; .GetSelectedEepromSizeInWordsToAX
;	Parameters:
;		Nothing
;	Returns:
;		AX:		Selected EEPROM size in WORDs
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetSelectedEepromSizeInWordsToAX:
	eMOVZX	bx, BYTE [cs:g_cfgVars+CFGVARS.bEepromType]
	mov		ax, [cs:bx+g_rgwEepromTypeToSizeInWords]
	ret

;--------------------------------------------------------------------
; .DisplayFlashingResultsFromFlashvarsInDSBX
;	Parameters:
;		DS:BX:	Ptr to FLASHVARS
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.DisplayFlashingResultsFromFlashvarsInDSBX:
	eMOVZX	bx, BYTE [bx+FLASHVARS.flashResult]
	jmp		[cs:bx+.rgfnFlashResultMessage]

ALIGN WORD_ALIGN
.rgfnFlashResultMessage:
	dw		.DisplayFlashSuccessful
	dw		.DisplayPollingError
	dw		.DisplayDataVerifyError


;--------------------------------------------------------------------
; .DisplayPollingError
; .DisplayDataVerifyError
; .DisplayFlashSuccessful
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.DisplayPollingError:
	mov		dx, g_szErrEepromPolling
	jmp		Dialogs_DisplayErrorFromCSDX

ALIGN JUMP_ALIGN
.DisplayDataVerifyError:
	mov		dx, g_szErrEepromVerify
	jmp		Dialogs_DisplayErrorFromCSDX

ALIGN JUMP_ALIGN
.DisplayFlashSuccessful:
	call	Buffers_GetFileBufferToESDI
	cmp		WORD [es:di+ROMVARS.wRomSign], 0AA55h	; PC ROM?
	je		SHORT .DisplayRebootMessageAndReboot
	mov		dx, g_szForeignFlash
	jmp		Dialogs_DisplayNotificationFromCSDX
ALIGN JUMP_ALIGN
.DisplayRebootMessageAndReboot:
	mov		dx, g_szPCFlashSuccessfull
	call	Dialogs_DisplayNotificationFromCSDX
	; Fall to .RebootComputer


;--------------------------------------------------------------------
; .RebootComputer
;	Parameters:
; 		Nothing
;	Returns:
;		Nothing, function never returns
;	Corrupts registers:
;		Doesn't matter
;--------------------------------------------------------------------
.RebootComputer:
.ResetAT:
	LOAD_BDA_SEGMENT_TO ds, ax
	mov		[BDA.wBoot], ax			; Make sure soft reset flag is not set
	mov		al, 0FEh				; System reset (AT+ keyboard controller)
	out		64h, al					; Reset computer (AT+)
	mov		ax, 10
	call	Delay_MicrosecondsFromAX
.ResetXT:
	xor		ax, ax
	push	ax
	popf							; Clear FLAGS (disables interrupt)
	mov		ds, ax
	mov		es, ax
	mov		ss, ax
	jmp		WORD 0FFFFh:0h			; XT reset
