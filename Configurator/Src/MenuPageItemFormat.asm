; Project name	:	XTIDE Universal BIOS Configurator
; Description	:	Functions for formatting
;					menuitem names from MENUPAGEITEM.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Prints lookup string for index values.
;
; MenuPageItemFormat_LookupString
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItemFormat_LookupString:
	mov		si, [di+MENUPAGEITEM.rgszLookup]	; Load offset to string lookup table
	mov		bx, [di+MENUPAGEITEM.pValue]		; Ptr to value containing lookup index
	eMOVZX	bx, [bx]							; BX=lookup index (values are already shifted for WORD lookup)
	push	WORD [bx+si]						; Push offset to string to print
	mov		dh, 4								; Total of 4 bytes for formatting params
	mov		si, .szStringName					; Offset to format string
	jmp		MenuPageItemFormat_NameWithParamsPushed
.szStringName:	db	"+%22s[%7s]",STOP


;--------------------------------------------------------------------
; Prints menuitem name for any MENUPAGEITEM.
;
; MenuPageItemFormat_NameForAnyType
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItemFormat_NameForAnyType:
	eMOVZX	bx, [di+MENUPAGEITEM.bType]			; Load menuitem type
	jmp		[cs:bx+.rgfnPrintBasedOnType]
ALIGN WORD_ALIGN
.rgfnPrintBasedOnType:
	dw		MenuPageItemFormat_NameForBackToPreviousSubmenu		; TYPE_MENUPAGEITEM_BACK
	dw		MenuPageItemFormat_NameForNextSubmenu				; TYPE_MENUPAGEITEM_NEXT
	dw		MenuPageItemFormat_NameForSpecialFunction			; TYPE_MENUPAGEITEM_SPECIAL
	dw		MenuPageItemFormat_NameWithUnsignedByteValue		; TYPE_MENUPAGEITEM_UNSIGNED_BYTE
	dw		MenuPageItemFormat_NameWithUnsignedWordValue		; TYPE_MENUPAGEITEM_UNSIGNED_WORD
	dw		MenuPageItemFormat_NameWithByteHexadecimalValue		; TYPE_MENUPAGEITEM_HEX_BYTE
	dw		MenuPageItemFormat_NameWithWordHexadecimalValue		; TYPE_MENUPAGEITEM_HEX_WORD
	dw		MenuPageItemFormat_NameWithFlagValue				; TYPE_MENUPAGEITEM_FLAG


;--------------------------------------------------------------------
; Prints "Back to previous menu" menuitem.
;
; MenuPageItemFormat_NameForBackToPreviousSubmenu
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItemFormat_NameForBackToPreviousSubmenu:
	mov		dh, 2								; Total of 2 bytes for formatting params
	mov		si, .szPrevMenu						; Offset to format string
	jmp		MenuPageItemFormat_NameWithParamsPushed
.szPrevMenu:		db	"-%32s",STOP


;--------------------------------------------------------------------
; Prints menuitem name for menuitem that opens new submenu.
;
; MenuPageItemFormat_NameForNextSubmenu
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItemFormat_NameForNextSubmenu:
	mov		dh, 2								; Total of 2 bytes for formatting params
	mov		si, .szNextMenu						; Offset to format string
	jmp		MenuPageItemFormat_NameWithParamsPushed
.szNextMenu:		db	"+%32s",STOP


;--------------------------------------------------------------------
; Prints menuitem name for menuitem with special function.
;
; MenuPageItemFormat_NameForSpecialFunction
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItemFormat_NameForSpecialFunction:
	mov		dh, 2								; Total of 2 bytes for formatting params
	mov		si, .szSpecial						; Offset to format string
	jmp		MenuPageItemFormat_NameWithParamsPushed
.szSpecial:			db	"*%32s",STOP


;--------------------------------------------------------------------
; Prints menuitem name with unsigned integer value.
;
; MenuPageItemFormat_NameWithUnsignedByteValue
; MenuPageItemFormat_NameWithUnsignedWordValue
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItemFormat_NameWithUnsignedByteValue:
	mov		si, [di+MENUPAGEITEM.pValue]		; DS:SI points to value
	eMOVZX	ax, [si]							; Load byte to AX
	push	ax									; Push byte
	jmp		SHORT MenuPageItemFormat_NameWithUnsignedValuePushed
ALIGN JUMP_ALIGN
MenuPageItemFormat_NameWithUnsignedWordValue:
	mov		si, [di+MENUPAGEITEM.pValue]		; DS:SI points to value
	push	WORD [si]							; Push integer value
MenuPageItemFormat_NameWithUnsignedValuePushed:
	mov		dh, 4								; Total of 4 bytes for formatting params
	mov		si, .szIntegerName					; Offset to format string
	jmp		SHORT MenuPageItemFormat_NameWithParamsPushed
.szIntegerName:	db	"%25s[%5u]",STOP


;--------------------------------------------------------------------
; Prints menuitem name with hexadecimal value.
;
; MenuPageItemFormat_NameWithByteHexadecimalValue
; MenuPageItemFormat_NameWithWordHexadecimalValue
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItemFormat_NameWithByteHexadecimalValue:
	mov		si, [di+MENUPAGEITEM.pValue]		; DS:SI points to value
	eMOVZX	ax, [si]							; Load byte to AX
	push	ax									; Push byte
	jmp		SHORT MenuPageItemFormat_NameWithHexadecimalValuePushed
ALIGN JUMP_ALIGN
MenuPageItemFormat_NameWithWordHexadecimalValue:
	mov		si, [di+MENUPAGEITEM.pValue]		; DS:SI points to value
	push	WORD [si]							; Push hexadecimal value
MenuPageItemFormat_NameWithHexadecimalValuePushed:
	mov		dh, 4								; Total of 4 bytes for formatting params
	mov		si, .szHexName						; Offset to format string
	jmp		SHORT MenuPageItemFormat_NameWithParamsPushed
.szHexName:		db	"%25s[%5x]",STOP


;--------------------------------------------------------------------
; Prints menuitem name with Y/N flag value.
;
; MenuPageItemFormat_NameWithFlagValue
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItemFormat_NameWithFlagValue:
	mov		dx, 044Eh							; DH=4 bytes in stack, DL='N'
	mov		si, [di+MENUPAGEITEM.pValue]		; DS:SI points to value
	mov		ax, [si]							; Load value
	test	ax, [di+MENUPAGEITEM.wValueMask]	; Flag set?
	jz		SHORT .PushFlagValueChar
	mov		dl, 'Y'
.PushFlagValueChar:
	push	dx
	mov		si, .szFlagName						; Offset to format string
	jmp		SHORT MenuPageItemFormat_NameWithParamsPushed
.szFlagName:	db	"%25s[%5c]",STOP


;--------------------------------------------------------------------
; Prints formatted menuitem name.
;
; MenuPageItemFormat_NameWithParamsPushed
;	Parameters:
;		DH:		Number of bytes pushed to stack + 2 for name string
;		SI:		Offset to formatting string
;		DS:DI:	Ptr to MENUPAGEITEM
;		DS:		String segment
;		Stack:	Formatting parameters except menuitem name
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItemFormat_NameWithParamsPushed:
	push	WORD [di+MENUPAGEITEM.szName]
	mov		dl, ' '				; Min length character
	call	Print_Format
	eMOVZX	ax, dh
	add		sp, ax				; Clear format parameters from stack
	ret
