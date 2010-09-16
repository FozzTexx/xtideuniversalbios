; File name		:	String.asm
; Project name	:	Assembly Library
; Created date	:	12.7.2010
; Last update	:	6.9.2010
; Author		:	Tomi Tilli
; Description	:	Functions for handling characters.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; String_ConvertWordToAXfromStringInDSSIwithBaseInBX
;	Parameters:
;		BX:		Numeric base (10 or 16)
;		DS:SI:	Ptr to string to convert
;	Returns:
;		AX:		Word converted from string
;		DI:		Offset to NULL or first invalid character
;		CF:		Set if conversion successfull
;				Cleared if invalid string
;	Corrupts registers:
;		DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
String_ConvertWordToAXfromStringInDSSIwithBaseInBX:
	xor		dx, dx
	cld

ALIGN JUMP_ALIGN
.ConvertWordToAXfromStringInDSSIwithBaseInBX:
	lodsb						; Load character from DS:SI to AL
	call	Char_ConvertIntegerToALfromDigitInALwithBaseInBX
	jnc		SHORT .InvalidCharacter
	xor		ah, ah
	push	ax					; Push integer
	xchg	ax, dx				; Copy WORD to AX
	mul		bx					; DX:AX = word in AX * base in BX
	pop		dx					; Pop integer
	add		dx, ax				; WORD back to DX
	jmp		SHORT .ConvertWordToAXfromStringInDSSIwithBaseInBX

ALIGN JUMP_ALIGN
.InvalidCharacter:
	sub		al, 1				; Set CF if NULL character, clear CF otherwise
	xchg	ax, dx				; Return WORD in AX
	ret


;--------------------------------------------------------------------
; String_CopyToESDIfromDSSIwithoutTerminatingESDI
;	Parameters:
;		DS:SI:	Ptr to source NULL terminated string
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		CX:		Number of characters copied
;		SI,DI:	Updated by CX characters
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
String_CopyToESDIfromDSSIwithoutTerminatingESDI:
	push	ax
	xor		cx, cx

ALIGN JUMP_ALIGN
.GetAndStoreNewCharacter:
	lodsb						; Load from DS:SI to AL
	test	al, al				; NULL to end string?
	jz		SHORT .EndOfString
	stosb						; Store from AL to ES:DI
	inc		cx					; Increment number of characters written
	jmp		SHORT .GetAndStoreNewCharacter

ALIGN JUMP_ALIGN
.EndOfString:
	pop		ax
	ret
