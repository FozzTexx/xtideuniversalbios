; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Register I/O functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeIO_OutputALtoIdeRegisterInDX
;	Parameters:
;		AL:		Byte to output
;		DX:		IDE Register
;		CS:BX:	Ptr to IDEVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeIO_OutputALtoIdeRegisterInDX:
	add		dx, [cs:bx+IDEVARS.wPort]
	out		dx, al
	ret


;--------------------------------------------------------------------
; IdeIO_OutputALtoIdeControlBlockRegisterInDX
;	Parameters:
;		AL:		Byte to output
;		DX:		IDE Control Block Register
;		CS:BX:	Ptr to IDEVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeIO_OutputALtoIdeControlBlockRegisterInDX:
	add		dx, [cs:bx+IDEVARS.wPortCtrl]
	out		dx, al
	ret


;--------------------------------------------------------------------
; IdeIO_InputToALfromIdeRegisterInDX
;	Parameters:
;		DX:		IDE Register
;		CS:BX:	Ptr to IDEVARS
;	Returns:
;		AL:		Inputted byte
;	Corrupts registers:
;		DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeIO_InputToALfromIdeRegisterInDX:
	add		dx, [cs:bx+IDEVARS.wPort]
	in		al, dx
	ret
