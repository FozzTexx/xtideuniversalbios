; File name		:	String.asm
; Project name	:	Assembly Library
; Created date	:	12.7.2010
; Last update	:	13.10.2010
; Author		:	Tomi Tilli
; Description	:	Functions for handling characters.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; String_ConvertDSSItoLowerCase
;	Parameters:
;		DS:SI:	Ptr to string to convert
;	Returns:
;		CX:		Number of characters processed
;		SI:		Updated
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
String_ConvertDSSItoLowerCase:
	push	dx
	push	ax

	mov		dx, StringProcess_ConvertToLowerCase
	call	StringProcess_DSSIwithFunctionInDX

	pop		ax
	pop		dx
	ret


;--------------------------------------------------------------------
; String_ConvertWordToAXfromStringInDSSIwithBaseInBX
;	Parameters:
;		BX:		Numeric base (10 or 16)
;		DS:SI:	Ptr to string to convert
;	Returns:
;		AX:		Word converted from string
;		CX:		Number of characters processed
;		SI:		Updated
;		CF:		Cleared if successfull
;				Set if error during conversion
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
String_ConvertWordToAXfromStringInDSSIwithBaseInBX:
	push	di
	push	dx

	xor		di, di
	mov		dx, StringProcess_ConvertToWordInDIWithBaseInBX
	call	StringProcess_DSSIwithFunctionInDX
	xchg	ax, di

	pop		dx
	pop		di
	ret


;--------------------------------------------------------------------
; String_CopyDSSItoESDIandGetLengthToCX
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
String_CopyDSSItoESDIandGetLengthToCX:
	push	ax

	xor		cx, cx
ALIGN JUMP_ALIGN
.CopyNextCharacter:
	lodsb						; Load from DS:SI to AL
	test	al, al				; NULL to end string?
	jz		SHORT .EndOfString
	stosb						; Store from AL to ES:DI
	inc		cx					; Increment number of characters written
	jmp		SHORT .CopyNextCharacter

ALIGN JUMP_ALIGN
.EndOfString:
	pop		ax
	ret


;--------------------------------------------------------------------
; String_GetLengthFromDSSItoCX
;	Parameters:
;		DS:SI:	Ptr to NULL terminated string
;	Returns:
;		CX:		String length in characters
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
String_GetLengthFromDSSItoCX:
	push	ax
	push	si

	call	Memory_ExchangeDSSIwithESDI
	xor		ax, ax		; Find NULL
	mov		cx, -1		; Full segment if necessary
	repne scasb
	mov		cx, di
	call	Memory_ExchangeDSSIwithESDI

	pop		si
	stc
	sbb		cx, si		; Subtract NULL
	pop		ax
	ret
