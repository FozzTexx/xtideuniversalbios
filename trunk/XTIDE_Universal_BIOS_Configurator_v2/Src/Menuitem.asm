; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	Functions for accessing MENUITEM structs.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Menuitem_DisplayHelpMessageFromDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menuitem_DisplayHelpMessageFromDSSI:
	mov		di, [si+MENUITEM.szName]
	mov		dx, [si+MENUITEM.szHelp]
	jmp		Dialogs_DisplayHelpFromCSDXwithTitleInCSDI


;--------------------------------------------------------------------
; Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menuitem_ActivateMultichoiceSelectionForMenuitemInDSSI:
	call	Registers_CopyDSSItoESDI

	mov		cx, DIALOG_INPUT_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	InitializeDialogInputInDSSIfromMenuitemInESDI
	mov		ax, [es:di+MENUITEM.itemValue + ITEM_VALUE.szMultichoice]
	mov		[si+DIALOG_INPUT.fszItems], ax
	push	di
	CALL_MENU_LIBRARY GetSelectionToAXwithInputInDSSI
	pop		di

	cmp		ax, BYTE NO_ITEM_SELECTED
	je		SHORT .NothingToChange
	call	Registers_CopyESDItoDSSI
	call	Menuitem_StoreValueFromAXtoMenuitemInDSSI
.NothingToChange:
	add		sp, BYTE DIALOG_INPUT_size
	ret


;--------------------------------------------------------------------
; Menuitem_ActivateHexInputForMenuitemInDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menuitem_ActivateHexInputForMenuitemInDSSI:
	call	Registers_CopyDSSItoESDI

	mov		cx, WORD_DIALOG_IO_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	InitializeDialogInputInDSSIfromMenuitemInESDI
	mov		BYTE [si+WORD_DIALOG_IO.bNumericBase], 16
	jmp		SHORT ContinueWordInput

;--------------------------------------------------------------------
; Menuitem_ActivateUnsignedInputForMenuitemInDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;	Returns:
;		CF:		Cleared if value inputted
;				Set if user cancellation
;	Corrupts registers:
;		AX, BX, CX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menuitem_ActivateUnsignedInputForMenuitemInDSSI:
	call	Registers_CopyDSSItoESDI

	mov		cx, WORD_DIALOG_IO_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	InitializeDialogInputInDSSIfromMenuitemInESDI
	mov		BYTE [si+WORD_DIALOG_IO.bNumericBase], 10
ContinueWordInput:
	mov		ax, [es:di+MENUITEM.itemValue + ITEM_VALUE.wMinValue]
	mov		[si+WORD_DIALOG_IO.wMin], ax
	mov		ax, [es:di+MENUITEM.itemValue + ITEM_VALUE.wMaxValue]
	mov		[si+WORD_DIALOG_IO.wMax], ax
	push	di
	CALL_MENU_LIBRARY GetWordWithIoInDSSI
	pop		di

	mov		cl, [si+WORD_DIALOG_IO.bUserCancellation]
	cmp		cl, TRUE
	je		SHORT .NothingToChange
	mov		ax, [si+WORD_DIALOG_IO.wReturnWord]
	call	Registers_CopyESDItoDSSI
	call	Menuitem_StoreValueFromAXtoMenuitemInDSSI
.NothingToChange:
	add		sp, BYTE WORD_DIALOG_IO_size
	shr		cl, 1
	ret


;--------------------------------------------------------------------
; InitializeDialogInputInDSSIfromMenuitemInESDI
;	Parameters:
;		DS:SI:	Ptr to DIALOG_INPUT
;		ES:DI:	Ptr to MENUITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
InitializeDialogInputInDSSIfromMenuitemInESDI:
	mov		ax, [es:di+MENUITEM.itemValue + ITEM_VALUE.szDialogTitle]
	mov		[si+DIALOG_INPUT.fszTitle], ax
	mov		[si+DIALOG_INPUT.fszTitle+2], cs

	mov		[si+DIALOG_INPUT.fszItems+2], cs

	mov		ax, [es:di+MENUITEM.szQuickInfo]
	mov		[si+DIALOG_INPUT.fszInfo], ax
	mov		[si+DIALOG_INPUT.fszInfo+2], cs
	ret

;--------------------------------------------------------------------
; Menuitem_StoreValueFromAXtoMenuitemInDSSI
;	Parameters:
;		AX:		Value or multichoice selection to store
;		DS:SI:	Ptr to MENUITEM
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menuitem_StoreValueFromAXtoMenuitemInDSSI:
	eMOVZX	bx, [si+MENUITEM.bType]
	cmp		bl, TYPE_MENUITEM_HEX
	ja		SHORT .InvalidItemType

	call	GetConfigurationBufferToESDIforMenuitemInDSSI
	add		di, [si+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
		
	push	bx
	mov		bx,[si+MENUITEM.itemValue+ITEM_VALUE.fnValueWriter]
	test	bx,bx
	jz		SHORT .NoWriter
	call	bx
.NoWriter:
	pop		bx
		
	jmp		[cs:bx+.rgfnJumpToStoreValueBasedOnItemType]
.InvalidItemType:
	ret

ALIGN WORD_ALIGN
.rgfnJumpToStoreValueBasedOnItemType:
	dw		.InvalidItemType									; TYPE_MENUITEM_PAGEBACK
	dw		.InvalidItemType									; TYPE_MENUITEM_PAGENEXT
	dw		.InvalidItemType									; TYPE_MENUITEM_ACTION
	dw		.StoreMultichoiceValueFromAXtoESDIwithItemInDSSI	; TYPE_MENUITEM_MULTICHOICE
	dw		.StoreByteOrWordValueFromAXtoESDIwithItemInDSSI		; TYPE_MENUITEM_UNSIGNED
	dw		.StoreByteOrWordValueFromAXtoESDIwithItemInDSSI		; TYPE_MENUITEM_HEX

;--------------------------------------------------------------------
; .StoreMultichoiceValueFromAXtoESDIwithItemInDSSI
;	Parameters:
;		AX:		Multichoice selection (index)
;		DS:SI:	Ptr to MENUITEM
;		ES:DI:	Ptr to value variable
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.StoreMultichoiceValueFromAXtoESDIwithItemInDSSI:
	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_MASKVALUE
	jnz		SHORT .ClearBitsUsingMask
	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_FLAGVALUE
	jz		SHORT .TranslateChoiceToValueUsingLookupTable

	test	ax, ax			; Setting item flag?
	mov		ax, [si+MENUITEM.itemValue+ITEM_VALUE.wValueBitmask]
	jnz		SHORT .SetFlagFromAX
	not		ax
	and		[es:di], ax		; Clear flag
	jmp		SHORT .SetUnsavedChanges
ALIGN JUMP_ALIGN
.SetFlagFromAX:
	or		[es:di], ax
	jmp		SHORT .SetUnsavedChanges

ALIGN JUMP_ALIGN
.ClearBitsUsingMask:
	mov		bx, [si+MENUITEM.itemValue+ITEM_VALUE.wValueBitmask]
	not		bx
	and		[es:di], bx
	; Fall to .TranslateChoiceToValueUsingLookupTable


ALIGN JUMP_ALIGN
.TranslateChoiceToValueUsingLookupTable:
;
; if the lookup pointer is NULL, no translation is needed
;
	mov		bx, [si+MENUITEM.itemValue+ITEM_VALUE.rgwChoiceToValueLookup]
	test	bx, bx
	jz		.StoreByteOrWordValueFromAXtoESDIwithItemInDSSI

	shl		ax, 1			; Shift for WORD lookup
	add		bx, ax
	mov		ax, [bx]		; Lookup complete
	; Fall to .StoreByteOrWordValueFromAXtoESDIwithItemInDSSI

;--------------------------------------------------------------------
; .StoreByteOrWordValueFromAXtoESDIwithItemInDSSI
;	Parameters:
;		AX:		Value to store
;		DS:SI:	Ptr to MENUITEM
;		ES:DI:	Ptr to value variable
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.StoreByteOrWordValueFromAXtoESDIwithItemInDSSI:
	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_MASKVALUE
	jz		SHORT .StoreByteOrWord
	or		[es:di], ax
	jmp		SHORT .SetUnsavedChanges

.StoreByteOrWord:
	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_BYTEVALUE
	jnz		SHORT .StoreByteFromAL

	mov		[es:di+1], ah
ALIGN JUMP_ALIGN
.StoreByteFromAL:
	mov		[es:di], al
	; Fall to .SetUnsavedChanges

;--------------------------------------------------------------------
; .SetUnsavedChanges
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.SetUnsavedChanges:
	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_PROGRAMVAR
	jnz		SHORT .NoUnsavedChangesForProgramVariables
	call	Buffers_SetUnsavedChanges
.NoUnsavedChangesForProgramVariables:
	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_MODIFY_MENU
	jnz		SHORT .ModifyItemVisibility
	CALL_MENU_LIBRARY RefreshTitle
	CALL_MENU_LIBRARY GetHighlightedItemToAX
	CALL_MENU_LIBRARY RefreshItemFromAX
	ret

ALIGN JUMP_ALIGN
.ModifyItemVisibility:
	push	es
	push	ds
	ePUSHA
	call	Menupage_GetActiveMenupageToDSDI
	call	[di+MENUPAGE.fnEnter]
	ePOPA
	pop		ds
	pop		es
	ret


;--------------------------------------------------------------------
; Menuitem_GetValueToAXfromMenuitemInDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;	Returns:
;		AX:		Menuitem value
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menuitem_GetValueToAXfromMenuitemInDSSI:
	push	es
	push	di
	push	bx
	call	GetConfigurationBufferToESDIforMenuitemInDSSI
	add		di, [si+MENUITEM.itemValue+ITEM_VALUE.wRomvarsValueOffset]
	mov		ax, [es:di]

	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_BYTEVALUE
	jz		SHORT .NoConvertWordToByteValue
	xor		ah, ah				; conversion needs to happen before call to the reader,
								; in case the reader unpacks the byte to a word

.NoConvertWordToByteValue:
	mov		bx, [si+MENUITEM.itemValue+ITEM_VALUE.fnValueReader]
	test	bx,bx
	jz		SHORT .NoReader

	call	bx

.NoReader:
	pop		bx
	pop		di
	pop		es

	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_MASKVALUE
	jz		SHORT .TestIfFlagValue
	and		ax, [si+MENUITEM.itemValue+ITEM_VALUE.wValueBitmask]
	ret

.TestIfFlagValue:
	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_FLAGVALUE
	jz		SHORT .Return

	test	ax, [si+MENUITEM.itemValue+ITEM_VALUE.wValueBitmask]
	mov		ax, TRUE<<1		; Shift for lookup
	jnz		SHORT .Return
	xor		ax, ax

ALIGN JUMP_ALIGN, ret
.Return:
	ret


;--------------------------------------------------------------------
; GetConfigurationBufferToESDIforMenuitemInDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;	Returns:
;		ES:DI:	Ptr to configuration buffer
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetConfigurationBufferToESDIforMenuitemInDSSI:
	test	BYTE [si+MENUITEM.bFlags], FLG_MENUITEM_PROGRAMVAR
	jnz		SHORT .ReturnCfgvarsInESDI
	jmp		Buffers_GetFileBufferToESDI
ALIGN JUMP_ALIGN
.ReturnCfgvarsInESDI:
	push	cs
	pop		es
	mov		di, g_cfgVars
	ret
