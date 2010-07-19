; File name		:	prntbios.asm
; Project name	:	Print library
; Created date	:	7.12.2009
; Last update	:	17.1.2010
; Author		:	Tomi Tilli
; Description	:	ASM library to for character and string
;					printing using BIOS.

;--------------- Equates -----------------------------

; Int 10h (BIOS) functions
FN_BIOS_WR_CHAR_TEL		EQU	0Eh	; Teletype Output


;-------------- Public functions ---------------------
; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Prints character. All character printing functions must
; use this macro to print characters (so printing implementation
; can be easily modified when needed).
; 
; PRINT_CHAR
;	Parameters:
;		DL:		Character to print
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%macro PRINT_CHAR 0
	call	Print_BiosTeleChar
%endmacro

ALIGN JUMP_ALIGN
Print_BiosTeleChar:
	push	bp					; Save because of buggy BIOSes
	push	bx
	mov		ah, FN_BIOS_WR_CHAR_TEL
	mov		al, dl				; Copy char to write
	xor		bx, bx				; Page 0
	int		10h
	pop		bx
	pop		bp
	ret


;--------------------------------------------------------------------
; Prints string. All string printing functions must
; use this macro to print strings (so printing implementation
; can be easily modified when needed).
; 
; PRINT_STR
;	Parameters:
;		DS:DX:		Ptr to STOP terminated string
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%macro PRINT_STR 0
	push	dx
	call	Print_BiosTeleStr
	pop		dx
%endmacro


;--------------------------------------------------------------------
; Prints string and returns number of characters printed.
; All string printing functions must use this macro to print strings
; (so printing implementation can be easily modified when needed).
; 
; PRINT_STR_LEN
;	Parameters:
;		DS:DX:		Ptr to STOP terminated string
;	Returns:
;		DX:			Number of characters printed
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%macro PRINT_STR_LEN 0
	call	Print_BiosTeleStr
%endmacro

ALIGN JUMP_ALIGN
Print_BiosTeleStr:
	push	bp						; Save because of buggy BIOSes
	push	si
	push	bx
	mov		si, dx					; Copy offset to string
	xor		dx, dx					; Zero char counter
	xor		bx, bx					; Page 0
	cld								; LODSB to increment SI
ALIGN JUMP_ALIGN
.CharLoop:
	lodsb							; Load char from [DS:SI] to AL
	cmp		al, STOP				; End of string?
	je		.Return					;  If so, return
	mov		ah, FN_BIOS_WR_CHAR_TEL	; Some BIOSes corrupts AX when returning
	int		10h
	inc		dx						; Increment chars printed
	jmp		.CharLoop				; Loop while chars left
ALIGN JUMP_ALIGN
.Return:
	pop		bx
	pop		si
	pop		bp
	ret
