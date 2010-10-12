; File name		:	StringProcess.asm
; Project name	:	Assembly Library
; Created date	:	12.10.2010
; Last update	:	12.10.2010
; Author		:	Tomi Tilli
; Description	:	Functions for processing characters in a string.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Character processing callback function prototype for StringProcess_DSSIwithFunctionInBX.
;	Parameters:
;		AL:			Character to process
;		CX:			Number of characters processed
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
ALIGN JUMP_ALIGN
StringProcess_DSSIwithFunctionInDX:
	push	si
	push	ax

	xor		cx, cx
ALIGN JUMP_ALIGN
.ProcessNextCharacter:
	lodsb
	test	al, al				; NULL to end string
	jz		SHORT .EndOfString	; Return with CF cleared
	inc		cx
	call	dx
	jnc		SHORT .ProcessNextCharacter

ALIGN JUMP_ALIGN
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
ALIGN JUMP_ALIGN
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
ALIGN JUMP_ALIGN
StringProcess_ConvertToWordInDIWithBaseInBX:
	call	Char_ConvertIntegerToALfromDigitInALwithBaseInBX
	jnc		SHORT .InvalidCharacter
	push	dx

	xor		ah, ah		; Digit converted to integer now in AX
	xchg	ax, di
	mul		bx			; Old WORD *= base
	jc		SHORT .Overflow
	add		di, ax		; Add old WORD to new integer
	jc		SHORT .Overflow

	pop		dx
	ret
.Overflow:
	pop		dx
.InvalidCharacter:
	stc					; Set CF to stop processing
	ret
