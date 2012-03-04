; Project name	:	Print library
; Description	:	ASM library for character and string
;					printing using direct access to VRAM.
;
;					NOT WORKING!!!

;--------------- Equates -----------------------------

%include "BDA.inc"						; For BDA variables

; Int 10h (BIOS) functions
FN_BIOS_WR_CHAR_TEL	EQU		0Eh			; Teletype Output

; Color adapter or Mono adapter segments
SEG_COLOR			EQU		0B800h		; CGA+
SEG_MONO			EQU		0B000h		; MDA, Hercules


;-------------- Public functions ---------------------
; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Return pointer to VRAM for current cursor position.
;
; PrntVram_GetPtr
;	Parameters:
;		Nothing
;	Returns:
;		ES:DI:	Pointer to cursor location
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrntVram_GetPtr:
	push	dx
	xor		ax, ax							; Zero AX
	mov		es, ax							; Copy zero to ES (BDA segment)

	; Calculate offset to VRAM
	eMOVZX	di, [es:BDA.bVidPageIdx]		; Load page index
	shl		di, 1							; Shift for word lookup
	mov		ax, [es:di+BDA.rgwVidCurPos]	; Load cursor position
	shl		ax, 1							; Cursor offsets to WORD offsets
	eMOVZX	di, al							; Copy X offset to DI
	mov		al, ah							; Y offset to AL
	xor		ah, ah							; Y offset to AX
	mul		WORD [es:BDA.wVidColumns]		; DX:AX = Y offset * Column cnt
	add		di, [es:BDA.wVidPageOff]		; Add page offset to DI
	add		di, ax							; Add row offset to DI

	; Get segment to VRAM
	mov		ax, SEG_COLOR					; Assume CGA+
	cmp		BYTE [es:BDA.bVidMode], 7		; MDA or Hercules?
	jne		.Return							;  If not, return
	mov		ax, SEG_MONO
ALIGN JUMP_ALIGN
.Return:
	mov		es, ax
	pop		dx
	ret


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
	call	PrntVram_TeleChar
%endmacro

ALIGN JUMP_ALIGN
PrntVram_TeleChar:
	cmp		dl, 20h					; Printable char?
	jb		.Bios					;  If not, use BIOS functions
	push	es
	push	di
	call	PrntVram_GetPtr			; VRAM pointer to ES:DI
	mov		[es:di], dl				; Store character
	call	PtnrVram_IncCursor		; Increment cursor position
	pop		di
	pop		es
	ret
ALIGN JUMP_ALIGN
.Bios:
	push	bp						; Save because of buggy BIOSes
	push	bx
	mov		ah, FN_BIOS_WR_CHAR_TEL
	mov		al, dl					; Copy char to write
	xor		bx, bx					; Page 0
	int		10h
	pop		bx
	pop		bp
	ret

ALIGN JUMP_ALIGN
PtnrVram_IncCursor:
	push	es
	xor		ax, ax					; Zero AX
	mov		es, ax					; Copy zero to ES (BDA segment)
	mov		al, [es:BDA.rgwVidCurPos]
	inc		ax
	cmp		al, [es:BDA.wVidColumns]
	pop		es
	je		.IncRow

	; Inc column only
	push	dx
	push	cx
	push	bx
	mov		cx, 1
	call	MenuCrsr_Move
	pop		bx
	pop		cx
	pop		dx
	ret
ALIGN JUMP_ALIGN
.IncRow:
	push	dx
	push	cx
	push	bx
	call	MenuCrsr_GetCursor
	xor		dl, dl
	inc		dh
	call	MenuCrsr_SetCursor
	pop		bx
	pop		cx
	pop		dx
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
	call	Print_VramTeleStr
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
	call	Print_VramTeleStr
%endmacro

ALIGN JUMP_ALIGN
Print_VramTeleStr:
	push	es
	push	di
	push	si
	call	PrntVram_GetPtr			; VRAM pointer to ES:DI
	mov		si, dx					; Copy offset to string
	xor		dx, dx					; Zero char counter
	cld								; STOSB to increment SI and DI
ALIGN JUMP_ALIGN
.CharLoop:
	lodsb							; Load char from [DS:SI] to AL
	cmp		al, 20h					; Printable character?
	jb		.Bios					;  If not, use BIOS functions

	push	dx
	mov		al, dl
	PRINT_CHAR
	pop		dx

	;stosb							; Store char to [ES:DI]
	inc		dx						; Increment chars printed
	;inc		di						; Skip attribute
	jmp		.CharLoop				; Loop while chars left
ALIGN JUMP_ALIGN
.Return:
	pop		si
	pop		di
	pop		es
	ret
ALIGN JUMP_ALIGN
.Bios:
	cmp		al, STOP				; End of string?
	je		.Return					;  If so, return
	push	dx
	mov		dl, al
	PRINT_CHAR
	pop		dx
	times 2 inc di
	inc		dx						; Increment chars printed
	jmp		.CharLoop				; Loop while chars left
