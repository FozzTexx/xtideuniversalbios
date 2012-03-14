; Project name	:	Assembly Library
; Description	:	Math related macros.
%ifndef MATH_INC
%define MATH_INC

FALSE		EQU		0
TRUE		EQU		1


;--------------------------------------------------------------------
; MIN_U		Unsigned comparison
; MIN_S		Signed comparison
;	Parameters:
;		%1:		Operand 1
;		%2:		Operand 2
;	Returns:
;		%1:		Lesser operand
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

%macro MIN_S 2
	cmp		%1, %2				; Is %1 smaller?
	jl		%%Return			;  If so, return
	mov		%1, %2				; Copy %2 to %1
ALIGN JUMP_ALIGN
%%Return:
%endmacro


;--------------------------------------------------------------------
; MAX_U		Unsigned comparison
; MAX_S		Signed comparison
;	Parameters:
;		%1:		Operand 1
;		%2:		Operand 2
;	Returns:
;		%1:		Greater operand
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

%macro MAX_S 2
	cmp		%1, %2				; Is %1 greater?
	jg		%%Return			;  If so, return
	mov		%1, %2				; Copy %2 to %1
ALIGN JUMP_ALIGN
%%Return:
%endmacro


;--------------------------------------------------------------------
; SHL_DXAX
;	Parameters:
;		%1:		Number of bits to shift
;	Returns:
;		DX:AX	Shifted value
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
%macro SHL_DXAX 1
	%ifnidni %1, cx
		mov		cx, %1
	%endif
ALIGN JUMP_ALIGN
.ShiftNextBit:
	shl		ax, 1
	rcl		dx, 1
	loop	.ShiftNextBit
%endmacro


;--------------------------------------------------------------------
; SHR_DXAX
;	Parameters:
;		%1:		Number of bits to shift
;	Returns:
;		DX:AX	Shifted value
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
%macro SHR_DXAX 1
	%ifnidni %1, cx
		mov		cx, %1
	%endif
ALIGN JUMP_ALIGN
.ShiftNextBit:
	shr		dx, 1
	rcr		ax, 1
	loop	.ShiftNextBit
%endmacro


%endif ; MATH_INC
