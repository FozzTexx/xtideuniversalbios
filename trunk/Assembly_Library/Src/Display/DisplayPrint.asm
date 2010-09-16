; File name		:	Display.asm
; Project name	:	Assembly Library
; Created date	:	26.6.2010
; Last update	:	10.8.2010
; Author		:	Tomi Tilli
; Description	:	Functions for display output.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Supports following formatting types:
;	%a		Specifies attribute for next character
;	%A		Specifies attribute for remaining string (or until next %A)
;	%d		Prints signed 16-bit decimal integer
;	%u		Prints unsigned 16-bit decimal integer
;	%x		Prints 16-bit hexadecimal integer
;	%s		Prints string (from CS segment)
;	%S		Prints string (far pointer)
;	%c		Prints character
;	%t		Prints character number of times (character needs to be pushed first, then repeat times)
;	%%		Prints '%' character (no parameter pushed)
;
;	Any placeholder can be set to minimum length by specifying
;	minimum number of characters. For example %8d would append spaces
;	after integer so that at least 8 characters would be printed.
; 
; DisplayPrint_FormattedNullTerminatedStringFromCSSI
;	Parameters:
;		BP:		SP before pushing parameters
;		DS:		BDA segment (zero)
;		CS:SI:	Pointer to string to format
;		ES:DI:	Ptr to cursor location in video RAM
;		Stack:	Parameters for formatting placeholders.
;				Parameter for first placeholder must be pushed first.
;				Low word must pushed first for placeholders requiring
;				32-bit parameters (two words).
;	Returns:
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_FormattedNullTerminatedStringFromCSSI:
	push	bp
	push	si
	push	cx
	push	bx
	push	WORD [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute]

	dec		bp					; Point BP to...
	dec		bp					; ...first stack parameter
	call	DisplayFormat_ParseCharacters

	; Pop original character attribute
	pop		ax
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute], al

	pop		bx
	pop		cx
	pop		si
	pop		bp
	ret


;--------------------------------------------------------------------
; DisplayPrint_SignedDecimalIntegerFromAX
;	Parameters:
;		AX:		Word to display
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		BX:		Number of characters printed
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_SignedDecimalIntegerFromAX:
	mov		bx, 10
	test	ah, 1<<7			; Sign bit set?
	jz		SHORT DisplayPrint_WordFromAXWithBaseInBX

	push	ax
	mov		al, '-'
	call	DisplayPrint_CharacterFromAL
	pop		ax
	neg		ax
	call	DisplayPrint_WordFromAXWithBaseInBX
	inc		bx					; Increment character count for '-'
	ret


;--------------------------------------------------------------------
; DisplayPrint_WordFromAXWithBaseInBX
;	Parameters:
;		AX:		Word to display
;		BX:		Integer base (binary=2, octal=8, decimal=10, hexadecimal=16)
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		BX:		Number of characters printed
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_WordFromAXWithBaseInBX:
	push	cx

	xor		cx, cx
ALIGN JUMP_ALIGN
.DivideLoop:
	xor		dx, dx				; DX:AX now holds the integer
	div		bx					; Divide DX:AX by base
	push	dx					; Push remainder
	inc		cx					; Increment character count
	test	ax, ax				; All divided?
	jnz		SHORT .DivideLoop	;  If not, loop
	mov		dx, cx				; Character count to DX
ALIGN JUMP_ALIGN
.PrintLoop:
	pop		bx					; Pop digit
	mov		al, [cs:bx+.rgcDigitToCharacter]
	call	DisplayPrint_CharacterFromAL
	loop	.PrintLoop
	mov		bx, dx				; Return characters printed

	pop		cx
	ret
.rgcDigitToCharacter:	db	"0123456789ABCDEF"


;--------------------------------------------------------------------
; DisplayPrint_CharacterBufferFromBXSIwithLengthInCX
;	Parameters:
;		CX:		Buffer length (characters)
;		BX:SI:	Ptr to NULL terminated string
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		BX:		Number of characters printed
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_CharacterBufferFromBXSIwithLengthInCX:
	push	cx

	mov		es, bx					; Buffer now in ES:SI
	xor		bx, bx					; Zero character counter
	jcxz	.BufferPrinted
ALIGN JUMP_ALIGN
.CharacterOutputLoop:
	mov		al, [es:bx+si]
	inc		bx
	call	LoadDisplaySegmentAndPrintCharacterFromAL
	loop	.CharacterOutputLoop
.BufferPrinted:
	mov		es, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition+2]
	pop		cx
	ret


;--------------------------------------------------------------------
; DisplayPrint_NullTerminatedStringFromCSSI
;	Parameters:
;		CS:SI:	Ptr to NULL terminated string
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		BX:		Number of characters printed
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_NullTerminatedStringFromCSSI:
	mov		bx, cs
	; Fall to DisplayPrint_NullTerminatedStringFromBXSI

;--------------------------------------------------------------------
; DisplayPrint_NullTerminatedStringFromBXSI
;	Parameters:
;		DS:		BDA segment (zero)
;		BX:SI:	Ptr to NULL terminated string
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		BX:		Number of characters printed
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_NullTerminatedStringFromBXSI:
	mov		es, bx					; String now in ES:SI
	xor		bx, bx					; Zero character counter
ALIGN JUMP_ALIGN
.CharacterOutputLoop:
	mov		al, [es:bx+si]
	test	al, al
	jz		SHORT .AllCharacterPrinted
	inc		bx

	call	LoadDisplaySegmentAndPrintCharacterFromAL
	jmp		SHORT .CharacterOutputLoop
ALIGN JUMP_ALIGN
.AllCharacterPrinted:
	mov		es, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition+2]
	ret

;--------------------------------------------------------------------
; LoadDisplaySegmentAndPrintCharacterFromAL
;	Parameters:
;		AL:		Character to print
;		DI:		Offset to cursor location in video RAM
;		DS:		BDA segment (zero)
;	Returns:
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
LoadDisplaySegmentAndPrintCharacterFromAL:
	push	es
	mov		es, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition+2]
	call	DisplayPrint_CharacterFromAL
	pop		es
	ret


;--------------------------------------------------------------------
; DisplayPrint_Newline
;	Parameters:
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_Newline:
	mov		al, CR
	call	DisplayPrint_CharacterFromAL
	mov		al, LF
	jmp		SHORT DisplayPrint_CharacterFromAL


;--------------------------------------------------------------------
; DisplayPrint_RepeatCharacterFromALwithCountInCX
;	Parameters:
;		AL:		Character to display
;		CX:		Repeat count
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_RepeatCharacterFromALwithCountInCX:
	push	ax
	call	DisplayPrint_CharacterFromAL
	pop		ax
	loop	DisplayPrint_RepeatCharacterFromALwithCountInCX
	ret


;--------------------------------------------------------------------
; DisplayPrint_CharacterFromAL
;	Parameters:
;		AL:		Character to display
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_CharacterFromAL:
	mov		ah, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute]
	jmp		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fnCharOut]


;--------------------------------------------------------------------
; DisplayPrint_ClearScreen
;	Parameters:
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_ClearScreen:
	push	di
	xor		ax, ax
	call	DisplayCursor_SetCoordinatesFromAX
	call	DisplayPage_GetColumnsToALandRowsToAH
	call	DisplayPrint_ClearAreaWithHeightInAHandWidthInAL
	pop		di
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition], di
	ret


;--------------------------------------------------------------------
; DisplayPrint_ClearAreaWithHeightInAHandWidthInAL
;	Parameters:
;		AH:		Area height
;		AL:		Area width
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayPrint_ClearAreaWithHeightInAHandWidthInAL:
	push	cx
	push	bx
	push	di

	xchg	bx, ax							; Move parameters to BX
	call	DisplayCursor_GetSoftwareCoordinatesToAX
	xchg	dx, ax							; Coordinates now in DX
	xor		cx, cx							; Zero CX

ALIGN JUMP_ALIGN
.ClearRowFromArea:
	mov		al, ' '							; Clear with space
	mov		ah, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute]
	mov		cl, bl							; Area width = WORDs to clear
	rep stosw
	dec		bh
	jz		SHORT .AreaCleared

	inc		dh								; Increment row
	push	dx
	xchg	ax, dx
	call	DisplayCursor_SetCoordinatesFromAX
	pop		dx
	jmp		SHORT .ClearRowFromArea

ALIGN JUMP_ALIGN
.AreaCleared:
	pop		di
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition], di
	pop		bx
	pop		cx
	ret
