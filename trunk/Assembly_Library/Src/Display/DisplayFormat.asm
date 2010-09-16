; File name		:	DisplayFormat.asm
; Project name	:	Assembly Library
; Created date	:	29.6.2010
; Last update	:	10.8.2010
; Author		:	Tomi Tilli
; Description	:	Functions for displaying formatted strings.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DisplayFormat_ParseCharacters
;	Parameters:
;		DS:		BDA segment (zero)
;		SS:BP:	Pointer to first format parameter (-=2 for next parameter)
;		CS:SI:	Pointer to string to format
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, BX, CX, DX, SI, BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayFormat_ParseCharacters:
	call	.ReadCharacterAndTestForNull
	jz		SHORT .Return
	xor		cx, cx							; Zero CX for parsing number parameter
	cmp		al, '%'
	je		SHORT .FormatParameterEncountered
	call	DisplayPrint_CharacterFromAL	; Control or printable character
	jmp		SHORT DisplayFormat_ParseCharacters
ALIGN JUMP_ALIGN
.Return:
	ret

;--------------------------------------------------------------------
; .ReadCharacterAndTestForNull
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
.ReadCharacterAndTestForNull:
	eSEG	cs
	lodsb									; Load from CS:SI to AL
	test	al, al							; NULL to end string?
	ret


;--------------------------------------------------------------------
; .FormatParameterEncountered
;	Parameters:
;		CX:		Zero or previous number parameter
;		DS:		BDA segment (zero)
;		SS:BP:	Pointer to next format parameter
;		CS:SI:	Pointer to next format string character
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		SI:		Incremented to next character
;		BP:		Offset to next format parameter
;		Eventually jumps to DisplayFormat_ParseCharacters
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.FormatParameterEncountered:
	call	.ReadCharacterAndTestForNull
	jz		SHORT .Return
	call	Char_IsDecimalDigitInAL
	jnc		SHORT .FormatWithCorrectFormatFunction
	; Fall to .ParseNumberParameterToCX

;--------------------------------------------------------------------
; .ParseNumberParameterToCX
;	Parameters:
;		AL:		Number digit from format string
;		CX:		Zero or previous number parameter
;	Returns:
;		CX:		Updated number parameter
;		Jumps to .FormatParameterEncountered
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.ParseNumberParameterToCX:
	sub		al, '0'				; Digit '0'...'9' to integer 0...9
	mov		ah, cl				; Previous number parameter to AH
	aad							; AL += (AH * 10)
	mov		cl, al				; Updated number parameter now in CX
	jmp		SHORT .FormatParameterEncountered

;--------------------------------------------------------------------
; .FormatWithCorrectFormatFunction
;	Parameters:
;		AL:		Format placeholder character (non digit character after '%')
;		CX:		Number parameter (zero if no number parameter present)
;		DS:		BDA segment (zero)
;		SS:BP:	Pointer to format parameter
;		CS:SI:	Pointer to next format string character
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		Eventually jumps to DisplayFormat_ParseCharacters
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.FormatWithCorrectFormatFunction:
	xor		bx, bx								; Zero lookup index
ALIGN JUMP_ALIGN
.PlaceholderComparisonLoop:
	cmp		al, [cs:bx+.rgcFormatCharToLookupIndex]
	je		SHORT .JumpToFormatPlaceholder
	inc		bx
	cmp		bl, .EndOFrgcFormatCharToLookupIndex - .rgcFormatCharToLookupIndex
	jb		SHORT .PlaceholderComparisonLoop	; Loop
	call	DisplayPrint_CharacterFromAL		; Display unsupported format character
	; Fall to .UpdateSpacesToAppendAfterPrintingSingleCharacter

;--------------------------------------------------------------------
; .UpdateSpacesToAppendAfterPrintingSingleCharacter
; .UpdateSpacesToAppend
;	Parameters:
;		BX:		Number of characters printed (.UpdateSpacesToAppend only)
;		CX:		Number parameter (zero if no number parameter present)
;		DS:		BDA segment (zero)
;		SS:BP:	Pointer to format parameter
;		CS:SI:	Pointer to next format string character
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		CX:		Number of spaces to append
;		Jumps to .PrepareToFormatNextParameter
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.UpdateSpacesToAppendAfterPrintingSingleCharacter:
	mov		bx, 1
ALIGN JUMP_ALIGN
.UpdateSpacesToAppend:
	jcxz	.PrepareToFormatNextParameter
	sub		cx, bx				; Number of spaces to append
	jle		SHORT .PrepareToFormatNextParameter
	mov		al, ' '
	call	DisplayPrint_RepeatCharacterFromALwithCountInCX
	; Fall to .PrepareToFormatNextParameter

;--------------------------------------------------------------------
; .PrepareToFormatNextParameter
;	Parameters:
;		DS:		BDA segment (zero)
;		SS:BP:	Pointer to format parameter
;		CS:SI:	Pointer to next format string character
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		BP:		Adjusted to point next stack parameter
;		Jumps to DisplayFormat_ParseCharacters
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.PrepareToFormatNextParameter:
	dec		bp
	dec		bp
	jmp		SHORT DisplayFormat_ParseCharacters


;--------------------------------------------------------------------
; .JumpToFormatPlaceholder
;	Parameters:
;		BX:		Lookup index for format function
;		CX:		Number parameter (zero if no number parameter present)
;		DS:		BDA segment (zero)
;		SS:BP:	Pointer to next format parameter
;		CS:SI:	Pointer to next format string character
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		Eventually jumps to DisplayFormat_ParseCharacters
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.JumpToFormatPlaceholder:
	shl		bx, 1					; Shift for WORD lookup
	jmp		[cs:bx+.rgfnFormatParameter]

ALIGN JUMP_ALIGN
.a_FormatAttributeForNextCharacter:
	mov		bl, [bp]
	xchg	bl, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute]
	call	.ReadCharacterAndTestForNull
	jz		SHORT .Return
	call	DisplayPrint_CharacterFromAL
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute], bl
	jmp		SHORT .UpdateSpacesToAppendAfterPrintingSingleCharacter

ALIGN JUMP_ALIGN
.A_FormatAttributeForRemainingString:
	mov		al, [bp]
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute], al
	jmp		SHORT .PrepareToFormatNextParameter

ALIGN JUMP_ALIGN
.d_FormatSignedDecimalWord:
	mov		ax, [bp]
	call	DisplayPrint_SignedDecimalIntegerFromAX
	jmp		SHORT .UpdateSpacesToAppend

ALIGN JUMP_ALIGN
.u_FormatUnsignedDecimalWord:
	mov		ax, [bp]
	mov		bx, 10
	call	DisplayPrint_WordFromAXWithBaseInBX
	jmp		SHORT .UpdateSpacesToAppend

ALIGN JUMP_ALIGN
.x_FormatHexadecimalWord:
	mov		ax, [bp]
	mov		bx, 16
	call	DisplayPrint_WordFromAXWithBaseInBX
	inc		bx					; Increment character count for 'h'
	mov		al, 'h'
	call	DisplayPrint_CharacterFromAL
	jmp		SHORT .UpdateSpacesToAppend

ALIGN JUMP_ALIGN
.s_FormatStringFromSegmentCS:
	xchg	si, [bp]
	call	DisplayPrint_NullTerminatedStringFromCSSI
	mov		si, [bp]			; Restore SI
	jmp		SHORT .UpdateSpacesToAppend

ALIGN JUMP_ALIGN
.S_FormatStringFromFarPointer:
	xchg	si, [bp]
	mov		bx, [bp-2]
	call	DisplayPrint_NullTerminatedStringFromBXSI
	mov		si, [bp]			; Restore SI
	jmp		SHORT .UpdateSpacesToAppendWithDWordParameter

ALIGN JUMP_ALIGN
.c_FormatCharacter:
	mov		al, [bp]
	jmp		SHORT .FormatSingleCharacterFromAL

ALIGN JUMP_ALIGN
.t_FormatRepeatCharacter:
	mov		cx, [bp-2]
	mov		bx, cx
	mov		al, [bp]
	call	DisplayPrint_RepeatCharacterFromALwithCountInCX
	jmp		SHORT .UpdateSpacesToAppendWithDWordParameter

ALIGN JUMP_ALIGN
.percent_FormatPercent:
	mov		al, '%'
	inc		bp					; Adjust here since...
	inc		bp					; ...no parameter on stack
	; Fall to .FormatSingleCharacterFromAL

ALIGN JUMP_ALIGN
.FormatSingleCharacterFromAL:
	call	DisplayPrint_CharacterFromAL
	jmp		.UpdateSpacesToAppendAfterPrintingSingleCharacter

ALIGN JUMP_ALIGN
.UpdateSpacesToAppendWithDWordParameter:
	dec		bp
	dec		bp
	jmp		.UpdateSpacesToAppend


; Table for converting format character to jump table index
.rgcFormatCharToLookupIndex:
	db		"aAduxsSct%"
.EndOFrgcFormatCharToLookupIndex:

; Jump table
ALIGN WORD_ALIGN
.rgfnFormatParameter:
	dw		.a_FormatAttributeForNextCharacter
	dw		.A_FormatAttributeForRemainingString
	dw		.d_FormatSignedDecimalWord
	dw		.u_FormatUnsignedDecimalWord
	dw		.x_FormatHexadecimalWord
	dw		.s_FormatStringFromSegmentCS
	dw		.S_FormatStringFromFarPointer
	dw		.c_FormatCharacter
	dw		.t_FormatRepeatCharacter
	dw		.percent_FormatPercent
