; File name		:	Char.asm
; Project name	:	Assembly Library
; Created date	:	28.6.2010
; Last update	:	7.9.2010
; Author		:	Tomi Tilli
; Description	:	Functions for handling characters.

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
;		CF:		Set if character is range
;				(Jumps to CharIsNotValid if before range)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro IS_BETWEEN_IMMEDIATES 3
	cmp		%1, %2
	jb		SHORT CharIsNotValid
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
ALIGN JUMP_ALIGN
Char_IsLowerCaseLetterInAL:
	IS_BETWEEN_IMMEDIATES al, 'a', 'z'
	ret

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
ALIGN JUMP_ALIGN
Char_IsUpperCaseLetterInAL:
	IS_BETWEEN_IMMEDIATES al, 'A', 'Z'
	ret

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
ALIGN JUMP_ALIGN
Char_IsHexadecimalDigitInAL:
	call	Char_IsDecimalDigitInAL
	jc		SHORT Char_CharIsValid
	call	Char_ALtoLowerCaseLetter
	IS_BETWEEN_IMMEDIATES al, 'a', 'f'
	ret

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
ALIGN JUMP_ALIGN
Char_IsDecimalDigitInAL:
	IS_BETWEEN_IMMEDIATES al, '0', '9'
	ret


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
ALIGN JUMP_ALIGN
Char_ConvertIntegerToALfromDigitInALwithBaseInBX:
	push	dx
	call	Char_GetFilterFunctionToDXforNumericBaseInBX
	call	dx						; Converts to lower case
	pop		dx
	jnc		SHORT CharIsNotValid

	cmp		al, '9'					; Decimal digit
	jbe		SHORT .ConvertToDecimalDigit
	sub		al, 'a'-'0'-10			; Convert to hexadecimal integer
ALIGN JUMP_ALIGN
.ConvertToDecimalDigit:
	sub		al, '0'					; Convert to decimal integer
	; Fall to CharIsValid

;--------------------------------------------------------------------
; CharIsValid
; CharIsNotValid
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Set for CharIsValid
;				Cleared for CharIsNotValid
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Char_CharIsValid:
	stc
	ret

ALIGN JUMP_ALIGN
CharIsNotValid:
	clc
	ret


;--------------------------------------------------------------------
; Char_ALtoLowerCaseLetter
;	Parameters:
;		AL:		Character to convert
;	Returns:
;		AL:		Character with possible conversion
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Char_ALtoLowerCaseLetter:
	call	Char_IsUpperCaseLetterInAL	; Is upper case character?
	jnc		SHORT .Return				;  If not, return
	add		al, 'a'-'A'					; Convert to lower case
.Return:
	ret

;--------------------------------------------------------------------
; Char_ALtoUpperCaseLetter
;	Parameters:
;		AL:		Character to convert
;	Returns:
;		AL:		Character with possible conversion
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Char_ALtoUpperCaseLetter:
	call	Char_IsLowerCaseLetterInAL	; Is lower case character?
	jnc		SHORT .Return				;  If not, return
	sub		al, 'a'-'A'					; Convert to upper case
.Return:
	ret


;--------------------------------------------------------------------
; Char_GetFilterFunctionToDXforNumericBaseInBX
;	Parameters
;		BX:		Numeric base (10 or 16)
;	Returns:
;		CS:DX:	Ptr to character filter function
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Char_GetFilterFunctionToDXforNumericBaseInBX:
	mov		dx, Char_IsDecimalDigitInAL
	cmp		bl, 10
	je		SHORT .Return
	sub		dx, BYTE Char_IsDecimalDigitInAL - Char_IsHexadecimalDigitInAL
.Return:
	ret
