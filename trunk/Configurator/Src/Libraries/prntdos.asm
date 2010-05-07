; File name		:	prntdos.asm
; Project name	:	Print library
; Created date	:	7.12.2009
; Last update	:	7.12.2009
; Author		:	Tomi Tilli
; Description	:	ASM library to for character and string
;					printing using DOS.

;--------------- Equates -----------------------------

; Int 21h (DOS) functions
FN_DOS_WR_CHAR_STDOUT	EQU	02h	; Write Character to Standard Output
FN_DOS_WR_STR_STDOUT	EQU	09h	; Write String to Standard Output


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
	mov		ah, FN_DOS_WR_CHAR_STDOUT
	int		21h
%endmacro


;--------------------------------------------------------------------
; Prints string. All string printing functions must
; use this macro to print strings (so printing implementation
; can be easily modified when needed).
; 
; PRINT_STR
;	Parameters:
;		DS:DX:		Ptr to '$' terminated string
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%macro PRINT_STR 0
	mov		ah, FN_DOS_WR_STR_STDOUT
	int		21h
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
	call	Print_DosCharStr
%endmacro

ALIGN JUMP_ALIGN
Print_DosCharStr:
	push	si
	push	cx
	mov		si, dx				; Load offset to string
	xor		cx, cx				; Zero character counter
	cld							; LODSB to increment SI
ALIGN JUMP_ALIGN
.CharLoop:
	lodsb						; Load from [DS:SI] to AL
	cmp		al, STOP			; End of string?
	je		.Return				;  If so, return
	mov		dl, al				; Copy char to DL
	PRINT_CHAR
	inc		cx					; Increment characters printed
	jmp		.CharLoop			; Loop while characters left
ALIGN JUMP_ALIGN
.Return:
	mov		dx, cx				; Copy chars printed to DX
	pop		cx
	pop		si
	ret
