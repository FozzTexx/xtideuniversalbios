; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	Functions for printing MENUITEM name and value.

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

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuitemPrint_PrintQuickInfoFromDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuitemPrint_PrintQuickInfoFromDSSI:
	push	si

	mov		si, [si+MENUITEM.szQuickInfo]
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromCSSI

	pop		si
	ret


;--------------------------------------------------------------------
; MenuitemPrint_NameWithPossibleValueFromDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuitemPrint_NameWithPossibleValueFromDSSI:
	eMOVZX	bx, [si+MENUITEM.bType]
	cmp		bl, TYPE_MENUITEM_ACTION
	ja		SHORT .PrintNameAndValueFromDSSI
	; Fall to .PrintNameWithoutValueFromDSSI

;--------------------------------------------------------------------
; .PrintNameWithoutValueFromDSSI
;	Parameters:
;		BX:		Menuitem type (MENUITEM.bType)
;		DS:SI:	Ptr to MENUITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
.PrintNameWithoutValueFromDSSI:
	push	bp
	push	si

	mov		bp, sp				; BP = SP before pushing parameters
	push	WORD [cs:bx+.rgwMenuitemTypeCharacter]
	push	WORD [si+MENUITEM.szName]
	mov		si, g_szFormatItemWithoutValue
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI

	pop		si
	pop		bp
	ret
.rgwMenuitemTypeCharacter:
	dw		'-'		; TYPE_MENUITEM_PAGEBACK
	dw		'+'		; TYPE_MENUITEM_PAGENEXT
	dw		'*'		; TYPE_MENUITEM_ACTION


;--------------------------------------------------------------------
; .PrintNameAndValueFromDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;		SS:BP:	Ptr to buffer for item value
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.PrintNameAndValueFromDSSI:
	eENTER_STRUCT	MAX_VALUE_STRING_LENGTH+2	; +2 for NULL and alignment
	call	.FormatValueStringFromItemInDSSItoBufferInSSBP
	call	.FormatNameFromItemInDSSIandValueFromSSBP
	eLEAVE_STRUCT	MAX_VALUE_STRING_LENGTH+2
	ret

;--------------------------------------------------------------------
; .FormatValueStringFromItemInDSSItoBufferInSSBP
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;		SS:BP:	Ptr to buffer for item value
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.FormatValueStringFromItemInDSSItoBufferInSSBP:
	push	es
	call	Registers_CopySSBPtoESDI
	mov		al, '['
	stosb
	call	[si+MENUITEM.fnFormatValue]
	mov		ax, ']'
	stosw	; Also terminate with NULL
	pop		es
	ret

;--------------------------------------------------------------------
; .FormatNameFromItemInDSSIandValueFromSSBP
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;		SS:BP:	Ptr to value string
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.FormatNameFromItemInDSSIandValueFromSSBP:
	push	si

	mov		bx, bp
	mov		bp, sp				; BP = SP before pushing parameters
	push	WORD [si+MENUITEM.szName]
	push	bx
	push	ss
	mov		si, g_szFormatItemNameWithValue
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI

	mov		bp, bx
	pop		si
	ret


;--------------------------------------------------------------------
; MenuitemPrint_WriteLookupValueStringToBufferInESDIfromUnshiftedItemInDSSI
; MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		DI:		Updated
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuitemPrint_WriteLookupValueStringToBufferInESDIfromUnshiftedItemInDSSI:
	call	Menuitem_GetValueToAXfromMenuitemInDSSI
	shl		ax, 1
	jmp		SHORT PrintLookupValueFromAXtoBufferInESDI

ALIGN JUMP_ALIGN
MenuitemPrint_WriteLookupValueStringToBufferInESDIfromShiftedItemInDSSI:
MenuitemPrint_WriteLookupValueStringToBufferInESDIfromRawItemInDSSI:
	call	Menuitem_GetValueToAXfromMenuitemInDSSI
	; Fall to PrintLookupValueFromAXtoBufferInESDI

;--------------------------------------------------------------------
; MenuitemPrint_WriteLookupValueStringToBufferInESDIfromItemInDSSI
;	Parameters:
;		AX:		Value to print
;		DS:SI:	Ptr to MENUITEM
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		DI:		Updated
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrintLookupValueFromAXtoBufferInESDI:
	push	si
	test	byte [si+MENUITEM.bFlags], FLG_MENUITEM_CHOICESTRINGS
	jnz		.lookupChoice

	add		ax, [si+MENUITEM.itemValue+ITEM_VALUE.rgszValueToStringLookup]
	xchg	bx, ax
.found:
	mov		si, [bx]
.errorReturn:
	call	String_CopyDSSItoESDIandGetLengthToCX
	pop		si
	ret

;
; With FLG_MENUITEM_CHOICESTRINGS, the array at .rgszChoiceToStringLookup is based on the
; Choice number (offset within .rgwChoiceToValueLookup) instead of the value stored.
; Here, we scan the .rgwChoiceToValueLookup array until we find the value there, and then
; use the same offset in .rgszChoiceToStringLookup.  If we don't find the value, we
; return an "Error!" string instead.
;
; Note that the pointer array at .rgszChoiceToStringLookup must be NULL terminated.  Since the
; value could be zero, we don't use the .rgwChoiceToValueLookup array to find the end.
;
.lookupChoice:
	mov		bx,[si+MENUITEM.itemValue+ITEM_VALUE.rgszChoiceToStringLookup]
	mov		si,[si+MENUITEM.itemValue+ITEM_VALUE.rgwChoiceToValueLookup]

.wordLoop:
	cmp		ax,[si]
	jz		.found
	inc		bx
	inc		bx
	inc		si
	inc		si
	cmp		word [bx],0
	jnz		.wordLoop

	mov		si,g_szValueUnknownError
	jmp		.errorReturn

;--------------------------------------------------------------------
; MenuitemPrint_WriteUnsignedValueStringToBufferInESDIfromItemInDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		DI:		Updated
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuitemPrint_WriteUnsignedValueStringToBufferInESDIfromItemInDSSI:
	mov		bx, di
	mov		cx, MAX_VALUE_STRING_LENGTH
	CALL_DISPLAY_LIBRARY PushDisplayContext
	CALL_DISPLAY_LIBRARY PrepareOffScreenBufferInESBXwithLengthInCX

	call	Menuitem_GetValueToAXfromMenuitemInDSSI
	mov		bx, 10
	CALL_DISPLAY_LIBRARY PrintWordFromAXwithBaseInBX
	jmp		SHORT MenuitemPrint_FinishPrintingUnsignedOrHexValue

;--------------------------------------------------------------------
; MenuitemPrint_WriteHexValueStringToBufferInESDIfromItemInDSSI
;	Parameters:
;		DS:SI:	Ptr to MENUITEM
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		DI:		Updated
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuitemPrint_WriteHexValueStringToBufferInESDIfromItemInDSSI:
	mov		bx, di
	mov		cx, MAX_VALUE_STRING_LENGTH
	CALL_DISPLAY_LIBRARY PushDisplayContext
	CALL_DISPLAY_LIBRARY PrepareOffScreenBufferInESBXwithLengthInCX

	call	Menuitem_GetValueToAXfromMenuitemInDSSI
	mov		bx, 16
	CALL_DISPLAY_LIBRARY PrintWordFromAXwithBaseInBX
	mov		al, 'h'
	CALL_DISPLAY_LIBRARY PrintCharacterFromAL
ALIGN JUMP_ALIGN
MenuitemPrint_FinishPrintingUnsignedOrHexValue:
	CALL_DISPLAY_LIBRARY GetCharacterPointerToBXAX
	xchg	bx, ax

	CALL_DISPLAY_LIBRARY PopDisplayContext
	mov		di, bx
	ret


; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_rgszValueToStringLookupForFlagBooleans:
	dw		g_szNo
	dw		g_szYes
