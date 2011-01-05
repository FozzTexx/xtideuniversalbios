; File name		:	print.asm
; Project name	:	Print library
; Created date	:	6.10.2009
; Last update	:	4.1.2011
; Author		:	Tomi Tilli,
;				:	Krister Nordvall (optimizations)
; Description	:	ASM library for character and string
;					printing related functions.

;--------------- Equates -----------------------------

; String library function to include
%define USE_PRINT_FORMAT			; Print_Format
%define USE_PRINT_NEWLINE			; Print_Newline
%define USE_PRINT_CHARBUFFER		; Print_CharBuffer
%define USE_PRINT_REPEAT			; Print_Repeat
;%define USE_PRINT_BOOL				; Print_Bool
;%define USE_PRINT_INTSW			; Print_IntSW
%define USE_PRINT_INTUW				; Print_IntUW
;%define USE_PRINT_INTUDW			; Print_IntUDW
%define USE_PRINT_INTHEXB			; Print_IntHexB
%define USE_PRINT_INTHEXW			; Print_IntHexW
;%define USE_PRINT_INTHEXDW			; Print_IntHexDW


; Text mode character attribute byte bits for CGA+
FLG_CGA_FG_B		EQU		(1<<0)
FLG_CGA_FG_G		EQU		(1<<1)
FLG_CGA_FG_R		EQU		(1<<2)
FLG_CGA_FG_I		EQU		(1<<3)
FLG_CGA_BG_B		EQU		(1<<4)
FLG_CGA_BG_G		EQU		(1<<5)
FLG_CGA_BG_R		EQU		(1<<6)
FLG_CGA_BG_I		EQU		(1<<7)
FLG_CGA_BG_BLNK		EQU		(1<<7)	; Blinking is default

; Text mode character attribute bytes for MDA/Hercules (mono)
; *Not displayed on some monitors
ATTR_MDA_HIDDEN		EQU		00h	; Not displayed
ATTR_MDA_ULINE		EQU		01h	; Underlined
ATTR_MDA_NORMAL		EQU		07h	; Normal (white on black)
ATTR_MDA_INT_U		EQU		09h	; High intensity, underlined
ATTR_MDA_INT		EQU		0Fh	; High intensity
ATTR_MDA_REVERSE	EQU		70h	; Reverse video (black on white)
ATTR_MDA_BLNK		EQU		87h	; Blinking white on black*
ATTR_MDA_BLNK_INT	EQU		8Fh	; Blinking high intensity*
ATTR_MDA_BLNK_REV	EQU		0F0h; Blinking reverse video


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data

g_rgbHex:		db	"0123456789ABCDEF"	; Hexadecimal printing
g_rgbFormat:	; Placeholders for Print_Format
%ifdef USE_PRINT_INTSW
				db	'd'	; Prints signed 16-bit integer (WORD)
%endif
%ifdef USE_PRINT_INTUW
				db	'u'	; Prints unsigned 16-bit integer (WORD)
%endif
%ifdef USE_PRINT_INTUDW
				db	'U'	; Prints unsigned 32-bit integer (DWORD)
%endif
%ifdef USE_PRINT_INTHEXW
				db	'x'	; Prints 8- or 16-bit hexadecimal (BYTE, WORD)
%endif
%ifdef USE_PRINT_INTHEXDW
				db	'X'	; Prints 32-bit hexadecimal (DWORD)
%endif
				db	's'	; Prints string (DS segment)
				db	'S'	; Prints string (far pointer)
%ifdef USE_PRINT_BOOL
				db	'b'	; Prints boolean value 0 or 1
%endif
				db	'c'	; Prints character
				db	'C'	; Prints character number of times
_g_rgbFormatEnd:

; Number of different placeholders for Print_Format
CNT_PLCEHLDRS		EQU		(_g_rgbFormatEnd-g_rgbFormat)



;-------------- Public functions ---------------------
; Section containing code
SECTION .text

; Include one file to use DOS, BIOS or VRAM macros and functions
;%include "prntdos.asm"			; Include to use DOS printing functions
%include "prntbios.asm"			; Include to use BIOS printing functions
;%include "prntvram.asm"			; Include to access VRAM directly


;--------------------------------------------------------------------
; Debugging macro that prints wanted character and newline.
; 
; PRINT_DBG_CH
;	Parameters:
;		%1:		Character to print
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro PRINT_DBG_CH 1
	pushf
	push	dx
	push	ax
	mov		dl, %1
	PRINT_CHAR
	;mov		dl, CR
	;PRINT_CHAR
	;mov		dl, LF
	;PRINT_CHAR
	pop		ax
	pop		dx
	popf
%endmacro


;--------------------------------------------------------------------
; Simplified printf-style string formatting function.
; Strings must end to STOP character.
; Supports following formatting types:
;	%d		Prints signed 16-bit integer (WORD)
;	%u		Prints unsigned 16-bit integer (WORD)
;	%U		Prints unsigned 32-bit integer (DWORD)
;	%x		Prints 8- or 16-bit hexadecimal (BYTE, WORD)
;	%X		Prints 32-bit hexadecimal (DWORD)
;	%s		Prints string (DS segment)
;	%S		Prints string (far pointer)
;	%b		Prints boolean value 0 or 1
;	%c		Prints character
;	%[num]C	Prints character number of times (up to 256, 0=256)
;	%%		Prints '%' character (no parameter pushed)
;
;	Any placeholder can be set to minimum length by specifying
;	minimum number of characters. For example %8d would append spaces
;	after integer so that at least 8 characters would be printed.
;
;	NOTE! Caller must clean the stack variables!
; 
; Print_Format
;	Parameters:
;		DL:			Min length character (usually space)
;		DS:SI:		Pointer to string to format
;		Stack:		Parameters for formatting placeholders.
;					Parameter for first placeholder must be pushed last
;					(to top of stack).
;					High word must be pushed first for 32-bit parameters.
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI
;--------------------------------------------------------------------
%ifdef USE_PRINT_FORMAT
ALIGN JUMP_ALIGN
Print_Format:
	push	es
	push	bp
	push	di
	push	cx
	push	dx					; Push min length character
	push	cs					; Copy CS...
	pop		es					; ...to ES
	mov		bp, sp				; Copy SP to BP
	add		bp, 2*6				; Set BP to point first stack parameter
	cld							; Set LODSB to increment SI
ALIGN JUMP_ALIGN
.PrintLoop:			; Load characters from string
	lodsb						; Load char from DS:SI to AL, increment SI
	xor		cx, cx				; Zero minimum length
	cmp		al, STOP			; End of string?
	je		.Return				;  If so, return
	cmp		al, '%'				; Format placeholder?
	je		.Format				;  If so, jump to format
ALIGN JUMP_ALIGN
.PrintChar:			; Prints single character from AL
	mov		dl, al				; Copy character to DL
	PRINT_CHAR					; Print character
	mov		dx, 1				; One char printed
ALIGN JUMP_ALIGN
.PrintXtraSoMin:	; Checks how many spaces to append
	sub		cx, dx				; Number of spaces needed
	jle		.PrintLoop			; Read next character if no spaces needed
	pop		dx					; Pop min length character to DL
ALIGN JUMP_ALIGN
.PrintSpaceLoop:	; Loop to print the required spaces
	PRINT_CHAR
	loop	.PrintSpaceLoop
	push	dx					; Store min length character
	jmp		.PrintLoop			; Jump to read next character
ALIGN JUMP_ALIGN
.Return:			; The only return point for this function
	pop		dx
	pop		cx
	pop		di
	pop		bp
	pop		es
	ret
ALIGN JUMP_ALIGN
.UpdateMinLen:		; Updates placeholder minimum length
	mov		al, ah				; Copy digit to AL
	mov		ah, cl				; Copy previous length to AH
	aad							; AL=10*AH+AL, AH=0
	mov		cx, ax				; Copy new length to CX
ALIGN JUMP_ALIGN
.Format:
	lodsb						; Load char from DS:SI to AL, increment SI
	cmp		al, STOP
	je		.Return				; Invalid string
	mov		ah, al				; Copy char to AH
	sub		ah, '0'				; Possible digit char to digit
	cmp		ah, 9				; Was valid digit?
	jbe		.UpdateMinLen		;  If so, jump to update minimum length
	push	cx					; Store number of spaces needed
	mov		cx, CNT_PLCEHLDRS	; Load number of placeholders to CX
	mov		di, g_rgbFormat		; Load offset to format placeholder table
	repne scasb					; Compare AL to [ES:DI] until match
	pop		cx					; Restore spaces needed
	jne		.PrintChar			; If no match, jump to print character
	sub		di, g_rgbFormat+1	; To placeholder index
	shl		di, 1				; Shift for word lookup
	jmp		[cs:di+.g_rgwFormJump]	; Jump to format

%ifdef USE_PRINT_INTSW
ALIGN JUMP_ALIGN
.Print_d:	; Print signed 16-bit integer
	mov		ax, [bp]			; Load word to print
	times 2 inc	bp
	call	Print_IntSW
	jmp		.PrintXtraSoMin
%endif
%ifdef USE_PRINT_INTUW
ALIGN JUMP_ALIGN
.Print_u:	; Print unsigned 16-bit integer
	mov		ax, [bp]			; Load word to print
	times 2 inc	bp
	call	Print_IntUW
	jmp		.PrintXtraSoMin
%endif
%ifdef USE_PRINT_INTUDW
ALIGN JUMP_ALIGN
.Print_U:	; Print unsigned 32-bit integer
	mov		ax, [bp]			; Load loword
	mov		dx, [bp+2]			; Load hiword
	add		bp, 4
	call	Print_IntUDW
	jmp		.PrintXtraSoMin
%endif
%ifdef USE_PRINT_INTHEXW
ALIGN JUMP_ALIGN
.Print_x:	; Prints 8- or 16-bit hexadecimal
	mov		ax, [bp]			; Load word to print
	times 2 inc	bp
%ifdef USE_PRINT_INTHEXB
	test	ah, ah				; 16-bit hexadecimal?
	jnz		.Print_x16			;  If so, jump to print it
	call	Print_IntHexB
	jmp		.PrintXtraSoMin
.Print_x16:
%endif
	call	Print_IntHexW
	jmp		.PrintXtraSoMin
%endif
%ifdef USE_PRINT_INTHEXDW
ALIGN JUMP_ALIGN
.Print_X:	; Prints 32-bit hexadecimal
	mov		ax, [bp]			; Load loword
	mov		dx, [bp+2]			; Load hiword
	add		bp, 4
	call	Print_IntHexDW
	jmp		.PrintXtraSoMin
%endif
ALIGN JUMP_ALIGN
.Print_s:	; Prints string from DS segment
	mov		dx, [bp]			; Load offset to string
	times 2 inc	bp
	PRINT_STR_LEN				; Print string
	jmp		.PrintXtraSoMin
ALIGN JUMP_ALIGN
.Print_S:	; Prints string using far pointer
	push	ds					; Store DS
	mov		dx, [bp]			; Load offset to string
	mov		ds, [bp+2]			; Load segment to string
	add		bp, 4
	PRINT_STR_LEN				; Print string
	pop		ds					; Restore DS
	jmp		.PrintXtraSoMin
%ifdef USE_PRINT_BOOL
ALIGN JUMP_ALIGN
.Print_b:	; Prints boolean value
	mov		ax, [bp]			; Load boolean value to print
	times 2 inc	bp
	call	Print_Bool
	jmp		.PrintXtraSoMin
%endif
ALIGN JUMP_ALIGN
.Print_c:	; Prints character
	mov		ax, [bp]			; Load character to print
	times 2 inc	bp
	jmp		.PrintChar			; Jump to print character
ALIGN JUMP_ALIGN
.Print_C:
	mov		dx, [bp]			; Load character to print
	times 2 inc	bp
ALIGN JUMP_ALIGN
.CharLoop:
	PRINT_CHAR
	loop	.CharLoop
	jmp		.PrintLoop

ALIGN JUMP_ALIGN
.g_rgwFormJump:					; Jump table for Print_Format
%ifdef USE_PRINT_INTSW
	dw		.Print_d
%endif
%ifdef USE_PRINT_INTUW
	dw		.Print_u
%endif
%ifdef USE_PRINT_INTUDW
	dw		.Print_U
%endif
%ifdef USE_PRINT_INTHEXW
	dw		.Print_x
%endif
%ifdef USE_PRINT_INTHEXDW
	dw		.Print_X
%endif
	dw		.Print_s
	dw		.Print_S
%ifdef USE_PRINT_BOOL
	dw		.Print_b
%endif
	dw		.Print_c
	dw		.Print_C
%endif


;--------------------------------------------------------------------
; Prints newline character to change line.
; 
; Print_Newline
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_PRINT_NEWLINE
ALIGN JUMP_ALIGN
Print_Newline:
	push	ax
	push	dx
	mov		dl, LF
	PRINT_CHAR
	mov		dl, CR
	PRINT_CHAR
	pop		dx
	pop		ax
	ret
%endif
	

;--------------------------------------------------------------------
; Prints wanted number of characters.
; 
; Print_CharBuffer
;	Parameters:
;		CX:		Number of characters to print
;		ES:DI:	Ptr to character buffer
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
%ifdef USE_PRINT_CHARBUFFER
ALIGN JUMP_ALIGN
Print_CharBuffer:
	jcxz	.Return
	push	ds
	push	si
	push	dx
	push	es
	pop		ds
	mov		si, di
	cld							; LODSB to increment SI
ALIGN JUMP_ALIGN
.Rep:
	lodsb						; Load from [DS:SI] to AL
	mov		dl, al				; Copy to DL for printing
	PRINT_CHAR
	loop	.Rep
	pop		dx
	pop		si
	pop		ds
.Return:
	ret
%endif


;--------------------------------------------------------------------
; Repeats wanted character.
; 
; Print_Repeat
;	Parameters:
;		CX:		Number of times to repeat character
;		DL:		Character to repeat
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
%ifdef USE_PRINT_REPEAT
ALIGN JUMP_ALIGN
Print_Repeat:
	jcxz	.Return
ALIGN JUMP_ALIGN
.Rep:
	PRINT_CHAR
	loop	.Rep
.Return:
	ret
%endif


;--------------------------------------------------------------------
; Prints boolean value.
; 
; Print_Bool
;	Parameters:
;		AX:		Boolean value (0=FALSE, non-zero=TRUE)
;	Returns:
;		DX:		Number of characters printed
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_PRINT_BOOL
ALIGN JUMP_ALIGN
Print_Bool:
	mov		dl, '0'				; Assume FALSE
	test	ax, ax				; Is FALSE?
	jz		.Print				;  If so, jump to print
	inc		dx					; Increment to '1'
ALIGN JUMP_ALIGN
.Print:
	PRINT_CHAR
	mov		dx, 1				; One character printed
	ret
%endif


;--------------------------------------------------------------------
; Prints signed or unsigned 16-bit integer.
; 
; Print_IntSW	Prints signed 16-bit word
; Print_IntUW	Prints unsigned 16-bit word
;	Parameters:
;		AX:		Word to print
;	Returns:
;		DX:		Number of characters printed
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_PRINT_INTSW
ALIGN JUMP_ALIGN
Print_IntSW:
	test	ax, ax				; Positive integer?
	jns		Print_IntUW			;  If so, jump to print it
	push	di					; Store DI
	push	ax					; Store word
	mov		dl, '-'				; Print '-'
	PRINT_CHAR
	mov		di, 1				; One character printed
	pop		ax					; Restore word
	neg		ax					; Negative to positive
	jmp		Print_ContinueFromIntSW
%endif

%ifdef USE_PRINT_INTUW or USE_PRINT_INTSW
ALIGN JUMP_ALIGN
Print_IntUW:
	push	di					; Store DI
	xor		di, di				; Zero character counter
Print_ContinueFromIntSW:
	push	bx					; Store BX
	push	cx					; Store CX
	mov		bx, 10				; Load divisor to BX
	mov		cx, 5				; Load number of divisions to CX
ALIGN JUMP_ALIGN
.DivLoop:
	xor		dx, dx				; Zero DX for division
	div		bx					; DX:AX / 10 => AX=quot, DX=rem
	push	dx					; Push digit
	loop	.DivLoop			; Loop to separate all characters
	xor		bx, bx				; First char printed flag
	mov		cl, 5				; Load number of characters to CL
ALIGN JUMP_ALIGN
.PrintLoop:
	pop		dx					; Pop character to DX
	or		bx, dx				; Still skipping zeroes?
	loopz	.PrintLoop			;  If so, loop
	add		dx, '0'				; Digit to character
	PRINT_CHAR					; Print character
	inc		di					; Increment chars printed
	test	cx, cx				; Characters left
	jnz		.PrintLoop			;  If so, loop
	mov		dx, di				; Copy chars printed to DX
	pop		cx
	pop		bx
	pop		di
	ret
%endif


;--------------------------------------------------------------------
; Prints unsigned 32-bit integer.
; 
; Print_IntUDW
;	Parameters:
;		DX:AX:	32-bit unsigned integer to print
;	Returns:
;		DX:		Number of characters printed
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_PRINT_INTUDW
ALIGN JUMP_ALIGN
Print_IntUDW:
	push	di					; Store DI
	push	si					; Store SI
	push	bx					; Store BX
	push	cx					; Store CX
	mov		cx, 10				; Load divider to CX
	mov		si, cx				; Load number of divisions (10) to SI
	xor		di, di				; Zero DI (char counter)
ALIGN JUMP_ALIGN
.DivLoop:
	call	Math_DivDWbyW		; DX:AX / 10 => DX:AX=quot, BX=rem
	push	bx					; Push digit
	dec		si					; Decrement number of divisions
	jnz		.DivLoop			;  Loop while divisions left
	xor		bx, bx				; First char printed flag
ALIGN JUMP_ALIGN
.PrintLoop:
	pop		dx					; Pop character to DX
	or		bx, dx				; Still skipping zeroes?
	loopz	.PrintLoop			;  If so, loop
	add		dx, '0'				; Digit to character
	PRINT_CHAR					; Print character
	inc		di					; Increment chars printed
	test	cx, cx				; Characters left
	jnz		.PrintLoop			;  If so, loop
	mov		dx, di				; Copy characters printed to DX
	pop		cx
	pop		bx
	pop		si
	pop		di
	ret
%endif


;--------------------------------------------------------------------
; Prints 8-bit byte as hexadecimal string.
; 
; Print_IntHexB
;	Parameters:
;		AL:		8-bit BYTE to print
;	Returns:
;		DX:		Number of characters printed
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_PRINT_INTHEXB
ALIGN JUMP_ALIGN
Print_IntHexB:
	push	bx
	xor		ah, ah				; Zero AH, AX=word to print
	mov		bx, 0FFh			; Set to print two digits
	call	Print_HexString		; Print hex string
	push	dx					; Store number of chars printed
	mov		dl, 'h'				; Print 'h' at the end
	PRINT_CHAR
	pop		dx					; Restore number of chars printed
	inc		dx					; Increment for 'h'
	pop		bx
	ret
%endif


;--------------------------------------------------------------------
; Prints 16-bit word as hexadecimal string.
; 
; Print_IntHexW
;	Parameters:
;		AX:		16-bit WORD to print
;	Returns:
;		DX:		Number of characters printed
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_PRINT_INTHEXW
ALIGN JUMP_ALIGN
Print_IntHexW:
	push	bx
	xor		bx, bx				; Set to print all zeroes...
	dec		bx					; ...BX = FFFFh
	call	Print_HexString		; Print hex string
	push	dx					; Store number of chars printed
	mov		dl, 'h'				; Print 'h' at the end
	PRINT_CHAR
	pop		dx					; Restore number of chars printed
	inc		dx					; Increment for 'h'
	pop		bx
	ret
%endif


;--------------------------------------------------------------------
; Prints 32-bit dword as hexadecimal string.
; 
; Print_IntHexDW
;	Parameters:
;		DX:AX:	32-bit DWORD to print
;	Returns:
;		DX:		Number of characters printed
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_PRINT_INTHEXDW
ALIGN JUMP_ALIGN
Print_IntHexDW:
	push	cx
	push	bx
	push	ax					; Store loword
	mov		ax, dx				; Copy hiword to AX
	xor		bx, bx				; Set to print all zeroes...
	dec		bx					; ...BX = FFFFh
	call	Print_HexString		; Print hex string
	mov		cx, dx				; Copy number of chars printed
	pop		ax					; Pop loword
	call	Print_HexString		; Print hex string
	add		cx, dx				; Add number of chars printed
	mov		dl, 'h'				; Print 'h' at the end
	PRINT_CHAR
	inc		cx					; Increment number of chars printed
	mov		dx, cx				; Copy number of chars printed to DX
	pop		bx
	pop		cx
	ret
%endif


;-------------- Private functions --------------------

;--------------------------------------------------------------------
; Prints hexadecimal character for every nybble for WORD.
; 
; Print_HexString
;	Parameters:
;		AX:		16-bit WORD to print
;		BX:		Mask for zero nybbles to print:
;				FFFFh	= prints all digits
;				0FFFh	= does not print digit 3 if it is zero
;				00FFh	= does not print digits 3 and 2 if both are zeroes
;				000Fh	= prints only digit 0 if other are zeroes
;				0000h	= prints nothing if value is zero
;	Returns:
;		DX:		Number of characters printed
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_PRINT_INTHEXB or USE_PRINT_INTHEXW or USE_PRINT_INTHEXDW
ALIGN JUMP_ALIGN
Print_HexString:
	push	bp
	push	di
	push	si
	push	cx

	mov		di, ax				; Backup WORD to DI
	mov		cl, 12				; Prepare to shift nybbles
	xor		dx, dx				; Zero DX
ALIGN JUMP_ALIGN
.NybbleLoop:
	mov		bp, bx				; Copy mask to BP
	mov		si, di				; Copy WORD to SI
	shr		bp, cl				; Shift wanted mask nybble to BP
	shr		si, cl				; Shift wanted nybble to SI
	and		bp, 0Fh				; Clear unwanted mask bits
	and		si, 0Fh				; Clear unwanted bits
	or		bp, si				; Skip zeroes in front?
	jz		.SkipPrint			;  If so, skip printing
	mov		dl, [cs:si+g_rgbHex]; Load char to DL
	PRINT_CHAR					; Print character
	inc		dh					; Increment characters printed
.SkipPrint:
	sub		cl, 4				; Prepare to shift next nybble
	jnc		.NybbleLoop			; Loop while nybbles left
	mov		dl, dh				; Copy chars printed to DL
	xor		dh, dh				; Zero DH

	pop		cx
	pop		si
	pop		di
	pop		bp
	ret
%endif
