; Project name	:	Assembly Library
; Description	:	Functions for handling characters.

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
; This macro can only be used within this source file!!!
; IS_BETWEEN_IMMEDIATES
;	Parameters:
;		%1:		Value to check
;		%2:		First accepted value in range
;		%3:		Last accepted value in range
;	Returns:
;		CF:		Set if character in range
;				(Jumps to Char_CharIsNotValid if before range)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro IS_BETWEEN_IMMEDIATES 3
	cmp		%1, %2
	jb		SHORT Char_CharIsNotValid
	cmp		%1, (%3)+1				; Set CF if %1 is lesser
%endmacro


;--------------------------------------------------------------------
; Char_IsLowerCaseLetterInAL
;	Parameters:
;		AL:		Character to check
;	Returns:
;		CF:		Set if character is lower case letter ('a'...'z')
;				Cleared if character is not lower case letter
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%ifndef MODULE_HOTKEYS
		%define EXCLUDE
	%endif
%endif

%ifndef EXCLUDE
ALIGN STRING_JUMP_ALIGN
Char_IsLowerCaseLetterInAL:
	IS_BETWEEN_IMMEDIATES al, 'a', 'z'
	ret
%endif
%undef EXCLUDE


;--------------------------------------------------------------------
; Char_IsUpperCaseLetterInAL
;	Parameters:
;		AL:		Character to check
;	Returns:
;		CF:		Set if character is upper case letter ('A'...'Z')
;				Cleared if character is not upper case letter
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN STRING_JUMP_ALIGN
Char_IsUpperCaseLetterInAL:
	IS_BETWEEN_IMMEDIATES al, 'A', 'Z'
	ret
%endif


;--------------------------------------------------------------------
; Char_IsHexadecimalDigitInAL
;	Parameters:
;		AL:		Character to check
;	Returns:
;		AL:		Character converted to lower case
;		CF:		Set if character is decimal digit ('0'...'F')
;				Cleared if character is not decimal digit
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN STRING_JUMP_ALIGN
Char_IsHexadecimalDigitInAL:
	call	Char_IsDecimalDigitInAL
	jc		SHORT Char_CharIsValid
	call	Char_ALtoLowerCaseLetter
	IS_BETWEEN_IMMEDIATES al, 'a', 'f'
	ret
%endif


;--------------------------------------------------------------------
; Char_IsDecimalDigitInAL
;	Parameters:
;		AL:		Character to check
;	Returns:
;		CF:		Set if character is decimal digit ('0'...'9')
;				Cleared if character is not decimal digit
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef MODULE_STRINGS_COMPRESSED
ALIGN STRING_JUMP_ALIGN
Char_IsDecimalDigitInAL:
	IS_BETWEEN_IMMEDIATES al, '0', '9'
	ret
%endif


;--------------------------------------------------------------------
; Char_ConvertIntegerToALfromDigitInALwithBaseInBX
;	Parameters:
;		AL:		Character to convert
;		BX:		Numeric base (10 or 16)
;	Returns:
;		AL:		Character converted to integer
;		CF:		Set if character was valid
;				Cleared if character was invalid
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN STRING_JUMP_ALIGN
Char_ConvertIntegerToALfromDigitInALwithBaseInBX:
	push	dx
	call	Char_GetFilterFunctionToDXforNumericBaseInBX
	call	dx						; Converts to lower case
	pop		dx
	jnc		SHORT Char_CharIsNotValid

	cmp		al, '9'					; Decimal digit
	jbe		SHORT .ConvertToDecimalDigit
	sub		al, 'a'-'0'-10			; Convert to hexadecimal integer
ALIGN STRING_JUMP_ALIGN
.ConvertToDecimalDigit:
	sub		al, '0'					; Convert to decimal integer
	; Fall to Char_CharIsValid
%endif


;--------------------------------------------------------------------
; Char_CharIsValid
; Char_CharIsNotValid
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Set for Char_CharIsValid
;				Cleared for Char_CharIsNotValid
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN STRING_JUMP_ALIGN
Char_CharIsValid:
	stc
	ret
%endif


%ifdef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%ifndef MODULE_HOTKEYS
		%define EXCLUDE
	%endif
	%ifndef MODULE_STRINGS_COMPRESSED
		%undef EXCLUDE
	%endif
%endif

%ifndef EXCLUDE
ALIGN STRING_JUMP_ALIGN
Char_CharIsNotValid:
	clc
	ret
%endif
%undef EXCLUDE


;--------------------------------------------------------------------
; Char_ALtoLowerCaseLetter
;	Parameters:
;		AL:		Character to convert
;	Returns:
;		AL:		Character with possible conversion
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN STRING_JUMP_ALIGN
Char_ALtoLowerCaseLetter:
	call	Char_IsUpperCaseLetterInAL	; Is upper case character?
	jmp		SHORT Char_ALtoUpperCaseLetter.CheckCF
%endif


;--------------------------------------------------------------------
; Char_ALtoUpperCaseLetter
;	Parameters:
;		AL:		Character to convert
;	Returns:
;		AL:		Character with possible conversion
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN STRING_JUMP_ALIGN
Char_ALtoUpperCaseLetter:
	call	Char_IsLowerCaseLetterInAL	; Is lower case character?
.CheckCF:
	jnc		SHORT Char_ChangeCaseInAL.Return
	; Fall to Char_ChangeCaseInAL
%endif


;--------------------------------------------------------------------
; Char_ChangeCaseInAL
;	Parameters:
;		AL:		Character to convert (must be A-Z or a-z)
;	Returns:
;		AL:		Character converted
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
Char_ChangeCaseInAL:
	xor		al, 32
.Return:
	ret
%endif


;--------------------------------------------------------------------
; Char_GetFilterFunctionToDXforNumericBaseInBX
;	Parameters
;		BX:		Numeric base (10 or 16)
;	Returns:
;		CS:DX:	Ptr to character filter function
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN STRING_JUMP_ALIGN
Char_GetFilterFunctionToDXforNumericBaseInBX:
	mov		dx, Char_IsDecimalDigitInAL
	cmp		bl, 10
	je		SHORT .Return
	mov		dx, Char_IsHexadecimalDigitInAL
.Return:
	ret
%endif
