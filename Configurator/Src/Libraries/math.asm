; Project name	:	Math library
; Description	:	ASM library for math related functions.

;--------------- Equates -----------------------------

; String library function to include
%define USE_MATH_MULDWBYW		; Math_MulDWbyW
%define USE_MATH_DIVDWBYW		; Math_DivDWbyW
%define USE_MATH_REMTOTENTHS	; Math_RemToTenths


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data


;-------------- Public functions ---------------------
; Section containing code
SECTION .text


;--------------------------------------------------------------------
; Macro to select lesser of two unsigned operands.
;
; MIN_U
;	Parameters:
;		%1:		Operand 1
;		%2:		Operand 2
;	Returns:
;		%1:		Lesser unsigned operand
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro MIN_U 2
	cmp		%1, %2				; Is %1 smaller?
	jb		%%Return			;  If so, return
	mov		%1, %2				; Copy %2 to %1
ALIGN JUMP_ALIGN
%%Return:
%endmacro


;--------------------------------------------------------------------
; Macro to select greater of two unsigned operands.
;
; MAX_U
;	Parameters:
;		%1:		Operand 1
;		%2:		Operand 2
;	Returns:
;		%1:		Greater unsigned operand
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro MAX_U 2
	cmp		%1, %2				; Is %1 greater?
	ja		%%Return			;  If so, return
	mov		%1, %2				; Copy %2 to %1
ALIGN JUMP_ALIGN
%%Return:
%endmacro


;--------------------------------------------------------------------
; Macro to select lesser and greater of two unsigned operands.
;
; MINMAX_U
;	Parameters:
;		%1:		Operand 1
;		%2:		Operand 2
;	Returns:
;		%1:		Lesser unsigned operand
;		%2:		Greater unsigned operand
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro MINMAX_U 2
	cmp		%1, %2				; Is %1 smaller?
	jb		%%Return			;  If so, return
	xchg	%1, %2				; Exchange operands
ALIGN JUMP_ALIGN
%%Return:
%endmacro


;--------------------------------------------------------------------
; DWORD * WORD multiplication.
; Multiplies unsigned 32-bit integer by unsigned 16-bit integer.
; Result is unsigned 32-bit integer, so overflow is possible.
;
; Math_MulDWbyW
;	Parameters:
;		DX:AX:	32-bit unsigned integer to multiply
;		CX:		16-bit unsigned multiplier
;	Returns:
;		DX:AX:	32-bit unsigned integer
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_MATH_MULDWBYW
ALIGN JUMP_ALIGN
Math_MulDWbyW:
	jcxz	.RetZero			; If CX=0, return 0
	push	bx
	mov		bx, dx				; Copy hiword to BX
	mul		cx					; DX:AX = AX (loword) * CX (multiplier)
	push	dx					; Push possible overflow
	xchg	ax, bx				; => AX=old hiword, BX=new loword
	mul		cx					; DX:AX = AX (hiword) * CX (multiplier)
	pop		dx					; Pop possible overflow from first mul
	add		dx, ax				; Add new hiword to overflow from first mul
	mov		ax, bx				; Copy new loword to AX
	pop		bx
	ret
ALIGN JUMP_ALIGN
.RetZero:						; Return 0 in DX:AX
	xor		ax, ax
	cwd
	ret
%endif


;--------------------------------------------------------------------
; Divide a 32-bit unsigned integer so that quotient can be 32-bit.
;
; Math_DivDWbyW
;	Parameters:
;		DX:AX:	32-bit unsigned divident
;		CX:		16-bit unsigned divisor
;	Returns:
;		DX:AX:	32-bit unsigned quotient
;		BX:		16-bit unsigned remainder
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_MATH_DIVDWBYW
ALIGN JUMP_ALIGN
Math_DivDWbyW:
	xor		bx, bx
	xchg	bx, ax
	xchg	dx, ax
	div		cx
	xchg	ax, bx
	div		cx
	xchg	dx, bx
	ret
%endif


;--------------------------------------------------------------------
; Converts remainder to tenths.
;
; Math_RemToTenths
;	Parameters:
;		BX:		16-bit unsigned remainder
;		CX:		16-bit unsigned divisor used when calculated the remainder (max 2559)
;	Returns:
;		BX:		Remainder converted to tenths
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_MATH_REMTOTENTHS
ALIGN JUMP_ALIGN
Math_RemToTenths:
	push	cx
	push	ax
	mov		al, 10				; Load 10 to AL
	xchg	cx, ax				; AX = Divisor CL = 10
	div		cl					; AL = Divisor divided by 10
	inc		ax					; Increment to compensate new remainder
	xchg	ax, bx				; AX = 16-bit remainder to convert
								; BL = Original divisor divided by 10
	div		bl					; AX = Original remainder converted to tenths
	eMOVZX	bx, al				; Copy return value to BX
	pop		ax
	pop		cx
	ret
%endif
