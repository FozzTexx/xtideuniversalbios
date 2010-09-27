; File name		:	DisplayFormat.asm
; Project name	:	Assembly Library
; Created date	:	29.6.2010
; Last update	:	26.9.2010
; Author		:	Tomi Tilli
; Description	:	Functions for displaying formatted strings.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DisplayFormat_ParseCharacters
;	Parameters:
;		DS:		BDA segment (zero)
;		SS:BP:	Pointer to first format parameter (-=2 updates to next parameter)
;		CS:SI:	Pointer to string to format
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		CS:SI:	Ptr to end of format string (ptr to one past NULL)
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, BX, CX, DX, BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayFormat_ParseCharacters:
	call	ReadCharacterAndTestForNull
	jz		SHORT .QuitCharacterParsing

	ePUSH_T	cx, DisplayFormat_ParseCharacters	; Return address
	xor		cx, cx								; Initial placeholder size
	cmp		al, '%'								; Format specifier?
	je		SHORT ParseFormatSpecifier
	jmp		DisplayPrint_CharacterFromAL

ALIGN JUMP_ALIGN
.QuitCharacterParsing:
	ret


;--------------------------------------------------------------------
; ParseFormatSpecifier
;	Parameters:
;		CX:		Placeholder size
;		DS:		BDA segment (zero)
;		SS:BP:	Pointer to first format parameter (-=2 for next parameter)
;		CS:SI:	Pointer to string to format
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		SI:		Updated to first unparsed character
;		DI:		Updated offset to video RAM
;		BP:		Updated to next format parameter
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ParseFormatSpecifier:
	call	ReadCharacterAndTestForNull
	call	Char_IsDecimalDigitInAL
	jc		SHORT .ParsePlaceholderSizeDigitFromALtoCX
	call	GetFormatSpecifierParserToAX
	call	ax				; Parser function
	dec		bp
	dec		bp				; SS:BP now points to next parameter
	test	cx, cx
	jnz		SHORT PrependOrAppendSpaces
	ret

;--------------------------------------------------------------------
; .ParsePlaceholderSizeDigitFromALtoCX
;	Parameters:
;		AL:		Digit character from format string
;		CX:		Current placeholder size
;		DS:		BDA segment (zero)
;	Returns:
;		CX:		Current placeholder size
;		Jumps back to ParseFormatSpecifier
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ParsePlaceholderSizeDigitFromALtoCX:
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition], di
	sub		al, '0'				; Digit '0'...'9' to integer 0...9
	mov		ah, cl				; Previous number parameter to AH
	aad							; AL += (AH * 10)
	mov		cl, al				; Updated number parameter now in CX
	jmp		SHORT ParseFormatSpecifier


;--------------------------------------------------------------------
; ReadCharacterAndTestForNull
;	Parameters:
;		CS:SI:	Pointer next character from string
;	Returns:
;		AL:		Character from string
;		SI:		Incremented to next character
;		ZF:		Set if NULL, cleared if valid character
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadCharacterAndTestForNull:
	eSEG	cs
	lodsb									; Load from CS:SI to AL
	test	al, al							; NULL to end string?
	ret


;--------------------------------------------------------------------
; GetFormatSpecifierParserToAX
;	Parameters:
;		AL:		Format specifier character
;	Returns:
;		AX:		Offset to parser function
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetFormatSpecifierParserToAX:
	mov		bx, .rgcFormatCharToLookupIndex
ALIGN JUMP_ALIGN
.CheckForNextSpecifierParser:
	cmp		al, [cs:bx]
	je		SHORT .ConvertIndexToFunctionOffset
	inc		bx
	cmp		bx, .rgcFormatCharToLookupIndexEnd
	jb		SHORT .CheckForNextSpecifierParser
	mov		ax, c_FormatCharacter
	ret
ALIGN JUMP_ALIGN
.ConvertIndexToFunctionOffset:
	sub		bx, .rgcFormatCharToLookupIndex
	shl		bx, 1				; Shift for WORD lookup
	mov		ax, [cs:bx+.rgfnFormatSpecifierParser]
	ret

.rgcFormatCharToLookupIndex:
	db		"aAduxsSct-+%"
.rgcFormatCharToLookupIndexEnd:
ALIGN WORD_ALIGN
.rgfnFormatSpecifierParser:
	dw		a_FormatAttributeForNextCharacter
	dw		A_FormatAttributeForRemainingString
	dw		d_FormatSignedDecimalWord
	dw		u_FormatUnsignedDecimalWord
	dw		x_FormatHexadecimalWord
	dw		s_FormatStringFromSegmentCS
	dw		S_FormatStringFromFarPointer
	dw		c_FormatCharacter
	dw		t_FormatRepeatCharacter
	dw		PrepareToPrependParameterWithSpaces
	dw		PrepareToAppendSpacesAfterParameter
	dw		percent_FormatPercent


;--------------------------------------------------------------------
; PrependOrAppendSpaces
;	Parameters:
;		CX:		Minimum length for format specifier in characters
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrependOrAppendSpaces:
	mov		ax, di
	sub		ax, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition]
	test	cx, cx
	js		SHORT .PrependWithSpaces
	; Fall to .AppendSpaces

;--------------------------------------------------------------------
; .AppendSpaces
;	Parameters:
;		AX:		Number of format parameter BYTEs printed
;		CX:		Minimum length for format specifier in characters
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
.AppendSpaces:
	call	DisplayContext_GetCharacterOffsetToAXfromByteOffsetInAX
	sub		cx, ax
	jle		SHORT .NothingToAppendOrPrepend
	mov		al, ' '
	jmp		DisplayPrint_RepeatCharacterFromALwithCountInCX

;--------------------------------------------------------------------
; .PrependWithSpaces
;	Parameters:
;		AX:		Number of format parameter BYTEs printed
;		CX:		Negative minimum length for format specifier in characters
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.PrependWithSpaces:
	xchg	ax, cx
	neg		ax
	call	DisplayContext_GetByteOffsetToAXfromCharacterOffsetInAX
	sub		ax, cx				; AX = BYTEs to prepend, CX = BYTEs to move
	jle		SHORT .NothingToAppendOrPrepend

	mov		bx, di
	add		bx, ax				; BX = DI after prepending

	push	si
	dec		di					; DI = Offset to last byte formatted
	mov		si, di
	add		di, ax				; DI = Offset to new location for last byte
	std
	eSEG_STR rep, es, movsb

	mov		dl, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags]
	and		dx, BYTE FLG_CONTEXT_ATTRIBUTES
	not		dx
	and		di, dx				; WORD alignment when using attributes

	call	DisplayContext_GetCharacterOffsetToAXfromByteOffsetInAX
	xchg	cx, ax				; CX = Spaces to prepend
	mov		al, ' '
	call	DisplayPrint_RepeatCharacterFromALwithCountInCX
	cld							; Restore DF

	mov		di, bx
	pop		si
.NothingToAppendOrPrepend:
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Formatting functions
;	Parameters:
;		DS:		BDA segment (zero)
;		SS:BP:	Pointer to next format parameter (-=2 updates to next parameter)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		SS:BP:	Points to last WORD parameter used
;	Corrupts registers:
;		AX, BX, DX
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ALIGN JUMP_ALIGN
a_FormatAttributeForNextCharacter:
	mov		bl, [bp]
	xchg	bl, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute]
	push	bx
	push	cx
	push	di
	call	DisplayFormat_ParseCharacters	; Recursive call
	pop		WORD [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition]
	pop		cx
	pop		bx
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute], bl
	ret

ALIGN JUMP_ALIGN
A_FormatAttributeForRemainingString:
	mov		al, [bp]
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute], al
	ret

ALIGN JUMP_ALIGN
d_FormatSignedDecimalWord:
	mov		ax, [bp]
	mov		bx, 10
	jmp		DisplayPrint_SignedWordFromAXWithBaseInBX

ALIGN JUMP_ALIGN
u_FormatUnsignedDecimalWord:
	mov		ax, [bp]
	mov		bx, 10
	jmp		DisplayPrint_WordFromAXWithBaseInBX

ALIGN JUMP_ALIGN
x_FormatHexadecimalWord:
	mov		ax, [bp]
	mov		bx, 16
	call	DisplayPrint_WordFromAXWithBaseInBX
	mov		al, 'h'
	jmp		DisplayPrint_CharacterFromAL

ALIGN JUMP_ALIGN
s_FormatStringFromSegmentCS:
	xchg	si, [bp]
	call	DisplayPrint_NullTerminatedStringFromCSSI
	mov		si, [bp]
	ret

ALIGN JUMP_ALIGN
S_FormatStringFromFarPointer:
	mov		bx, [bp-2]
	xchg	si, [bp]
	call	DisplayPrint_NullTerminatedStringFromBXSI
	mov		si, [bp]
	dec		bp
	dec		bp
	ret

ALIGN JUMP_ALIGN
c_FormatCharacter:
	mov		al, [bp]
	jmp		DisplayPrint_CharacterFromAL

ALIGN JUMP_ALIGN
t_FormatRepeatCharacter:
	push	cx
	mov		cx, [bp-2]
	mov		al, [bp]
	call	DisplayPrint_RepeatCharacterFromALwithCountInCX
	pop		cx
	dec		bp
	dec		bp
	ret

ALIGN JUMP_ALIGN
percent_FormatPercent:
	mov		al, '%'
	jmp		DisplayPrint_CharacterFromAL

ALIGN JUMP_ALIGN
PrepareToPrependParameterWithSpaces:
	neg		cx
	; Fall to PrepareToAppendSpacesAfterParameter

ALIGN JUMP_ALIGN
PrepareToAppendSpacesAfterParameter:
	add		sp, BYTE 2				; Remove return offset
	jmp		ParseFormatSpecifier
