; Project name	:	Assembly Library
; Description	:	Functions for processing characters in a string.

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
; Character processing callback function prototype for StringProcess_DSSIwithFunctionInDX.
;	Parameters:
;		AL:			Character to process
;		CX:			Character number (index for next character)
;		DS:SI:		Ptr to next character
;		BX,DI,ES:	Free to use by processing function
;	Returns:
;		CF:			Clear to continue with next character
;					Set to stop processing
;		BX,DI,ES:	Free to use by processing function
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------


;--------------------------------------------------------------------
; StringProcess_DSSIwithFunctionInDX
;	Parameters:
;		DX:		Character processing function
;		DS:SI:	Ptr to NULL terminated string to convert
;	Returns:
;		CX:		Number of characters processed
;		CF:		Clear if all characters processed
;				Set if terminated by processing function
;	Corrupts registers:
;		Nothing (processing function can corrupt BX,DI,ES)
;--------------------------------------------------------------------
ALIGN STRING_JUMP_ALIGN
StringProcess_DSSIwithFunctionInDX:
	push	si
	push	ax

	xor		cx, cx
ALIGN STRING_JUMP_ALIGN
.ProcessNextCharacter:
	lodsb
	test	al, al				; NULL to end string
	jz		SHORT .EndOfString	; Return with CF cleared
	inc		cx
	call	dx
	jnc		SHORT .ProcessNextCharacter

ALIGN STRING_JUMP_ALIGN
.EndOfString:
	pop		ax
	pop		si
	ret


;--------------------------------------------------------------------
; StringProcess_ConvertToLowerCase (callback function for StringProcess_DSSIwithFunctionInDX)
;	Parameters:
;		AL:		Character to convert to lower case
;		DS:SI:	Ptr to next character
;	Returns:
;		CF:		Clear to continue processing
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
ALIGN STRING_JUMP_ALIGN
StringProcess_ConvertToLowerCase:
	call	Char_ALtoLowerCaseLetter
	mov		[si-1], al
	clc
	ret


;--------------------------------------------------------------------
; StringProcess_ConvertToWordInDIWithBaseInBX (callback function for StringProcess_DSSIwithFunctionInDX)
;	Parameters:
;		AL:		Character to convert to lower case
;		BX:		Numeric base (2, 10 or 16)
;	Returns:
;		CF:		Clear to continue processing
;				Set if error
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN STRING_JUMP_ALIGN
StringProcess_ConvertToWordInDIWithBaseInBX:
	call	Char_ConvertIntegerToALfromDigitInALwithBaseInBX
	cmc
	jc		SHORT .InvalidCharacter
	push	dx

	xor		ah, ah		; Digit converted to integer now in AX
	xchg	ax, di
	mul		bx			; Old WORD *= base
	jc		SHORT .Overflow
	add		di, ax		; Add old WORD to new integer

.Overflow:
	pop		dx
.InvalidCharacter:
	ret
