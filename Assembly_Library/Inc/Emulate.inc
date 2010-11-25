; File name		:	emulate.inc
; Project name	:	Emulation library
; Created date	:	21.10.2009
; Last update	:	25.11.2010
; Author		:	Tomi Tilli
; Description	:	Macros for emulating later x86 instruction with older
;					processors.
;					Macros are used so optimized builds could be done
;					easily for different processors.
;
;					This file must be first to be included to
;					any source file.
%ifndef EMULATE_INC
%define EMULATE_INC

; Defines for processor support. Unsupported instructions will be
; emulated using macros.
; If using 286, define USE_186 and USE_286
; If using 386, define USE_186, USE_286 and USE_386
; If AT class PC is used (instead of XT), define USE_AT
;%define USE_186				; Define to use 18x/V20/V30 instructions
;%define USE_286				; Define to use 286 instructions
;%define USE_386				; Define to use 386 instructions
;%define USE_AT					; Define for AT class machine
; Above defines should be set on makefile!

CPU 8086						; Allow 8088/8086 instructions only
%ifdef USE_186
CPU 186							; Allow instructions up to 188/186/V20/V30
%elifdef USE_286
CPU 286							; Allow instructions up to 286
%elifdef USE_386
CPU 386							; Allow instructions up to 386
%endif
BITS 16							; Set 16 bit code generation

; Alignments for jump targets.
; Following values are optimal for different processor types:
; 286 and 386SX			WORD (16-bit, 2 bytes)
; 386DX and 486			DWORD (32-bit, 4 bytes)
; Pentium and later		QWORD (64-bit, 8 bytes)
%ifdef USE_AT
	%ifdef USE_386
		JUMP_ALIGN		EQU		4
		WORD_ALIGN		EQU		2
	%else ; USE_286
		JUMP_ALIGN		EQU		2
		WORD_ALIGN		EQU		2
	%endif
%else ; XT
	JUMP_ALIGN		EQU		1
	WORD_ALIGN		EQU		1
%endif

;==========================================================================

;--------------------------------------------------------------------
; Emulates BSF (Bit Scan Forward) instruction when necessary.
; BSF is used to find index of least significant bit.
;
; eBSF
;	Parameters:
;		%1:		Destination WORD Register for bit index (not CX or same as %2!)
;		%2:		Source WORD operand where to search bit (not CX or same as %1!)
;	Returns:
;		%1:		Index of highest order bit from %2
;		ZF:		Set if %2 is zero
;				Cleared if %2 is non-zero
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro eBSF 2
%ifndef USE_386
	push	cx
	cmp		WORD %2, BYTE 0		; Source operand is zero?
	je		SHORT %%Return		;  If so, return with ZF set

	; Set destination to zero and load mask for bit 0
	xor		%1, %1
	mov		cx, 1

ALIGN JUMP_ALIGN
%%BitLoop:
	test	%2, cx				; Bit set?
	jnz		SHORT %%Return		;  If so, return with ZF cleared
	shl		cx, 1				; Prepare to test next bit
	inc		%1					; Increment bit index
	jmp		SHORT %%BitLoop		; Loop until bit found
%%Return:
	pop		cx
;-----------------------------------
%else
	bsf		%1, %2
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates BSR (Bit Scan Reverse) instruction when necessary.
; BSR is used to find index of most significant bit.
;
; eBSR
;	Parameters:
;		%1:		Destination WORD Register for bit index (not CX or same as %2!)
;		%2:		Source WORD operand where to search bit (not CX or same as %1!)
;	Returns:
;		%1:		Index of highest order bit from %2
;		ZF:		Set if %2 is zero
;				Cleared if %2 is non-zero
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro eBSR 2
%ifndef USE_386
	push	cx
	cmp		WORD %2, BYTE 0		; Source operand is zero?
	je		SHORT %%Return		;  If so, return with ZF set

	; Load mask for highest order bit
	mov		cx, 1<<15
	mov		%1, 15

ALIGN JUMP_ALIGN
%%BitLoop:
	test	%2, cx				; Bit set?
	jnz		SHORT %%Return		;  If so, return with ZF cleared
	shr		cx, 1				; Prepare to test next bit
	dec		%1					; Decrement bit index
	jmp		SHORT %%BitLoop		; Loop until bit found
%%Return:
	pop		cx
;-----------------------------------
%else
	bsr		%1, %2
%endif
%endmacro


;--------------------------------------------------------------------
; Conditional Move.
;
; eCMOVcc
;	Parameters:
;		%1:		Destination data
;		%2:		Source data
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro eCMOVC 2
	jnc		SHORT %%Return
	mov		%1, %2
%%Return:
%endmacro

%macro eCMOVE 2
	jne		SHORT %%Return
	mov		%1, %2
%%Return:
%endmacro

%macro eCMOVB 2
	jnb		SHORT %%Return
	mov		%1, %2
%%Return:
%endmacro



;--------------------------------------------------------------------
; Moves byte with zero-extending to any Register.
;
; eMOVZX
;	Parameters:
;		%1:		Destination Register (SP not supported)
;		%2:		Byte register or byte address
;	Returns:
;		Nothing
;	Corrupts registers:
;		FLAGS
;--------------------------------------------------------------------
%macro eMOVZX 2
%ifndef USE_386
	%ifidni %1, ax
		mov		al, %2
		xor		ah, ah
	%elifidni %1, bx
		mov		bl, %2
		xor		bh, bh		; %2 may use BX in effective address
	%elifidni %1, cx
		mov		cl, %2
		xor		ch, ch
	%elifidni %1, dx
		mov		dl, %2
		xor		dh, dh
	%else	; SI, DI, BP (all may be used in effective address)
		push	ax
		mov		al, %2
		xor		ah, ah
		xchg	ax, %1
		pop		ax
	%endif
;-----------------------------------
%else
	movzx	%1, %2
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates PUSHA instruction when necessary.
;
; ePUSHA
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro ePUSHA 0
%ifndef USE_186
	push	ax
	push	cx
	push	dx
	push	bx
	; SP before first push should be pushed here
	push	bp
	push	si
	push	di
;-----------------------------------
%else
	pusha
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates POPA instruction when necessary.
;
; ePOPA
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro ePOPA 0
%ifndef USE_186
	pop		di
	pop		si
	pop		bp
	; Old SP should be skipped here
	pop		bx
	pop		dx
	pop		cx
	pop		ax
;-----------------------------------
%else
	popa
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates ENTER instruction when necessary.
;
; eENTER
;	Parameters:
;		%1:		Number of bytes to reserve from stack
;		%2:		The lexical nesting level (not emulated, set to 0)
;	Returns:
;		SS:BP:	Ptr to old BP
;				([bp-2] points to highest local stack frame word)
;	Corrupts registers:
;		FLAGS
;--------------------------------------------------------------------
%macro eENTER 2
%ifndef USE_186
	push	bp
	mov		bp, sp
	sub		sp, %1
;-----------------------------------
%else
	enter	%1, %2
%endif
%endmacro

;--------------------------------------------------------------------
; Emulates LEAVE instruction when necessary.
;
; eLEAVE
;	Parameters:
;		Nothing
;	Returns:
;		BP:		What it was before eENTER
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro eLEAVE 0
%ifndef USE_186
	mov		sp, bp
	pop		bp
;-----------------------------------
%else
	leave
%endif
%endmacro


;--------------------------------------------------------------------
; eENTER_STRUCT
;	Parameters:
;		%1:		Number of bytes to reserve from stack
;	Returns:
;		SS:BP:	Ptr to beginning of struct reserved from stack
;	Corrupts registers:
;		FLAGS
;--------------------------------------------------------------------
%macro eENTER_STRUCT 1
	push	bp
	sub		sp, %1
	mov		bp, sp
%endmacro

;--------------------------------------------------------------------
; eLEAVE_STRUCT
;	Parameters:
;		%1:		Number of bytes reserved with eENTER_STRUCT
;	Returns:
;		BP:		What it was before eENTER_STRUCT
;	Corrupts registers:
;		FLAGS
;--------------------------------------------------------------------
%macro eLEAVE_STRUCT 1
	add		sp, %1
	pop		bp
%endmacro


;--------------------------------------------------------------------
; Emulates LSS instruction when necessary.
;
; eLSS
;	Parameters:
;		%1:		Destination register
;		%2:		Source memory address without brackets
;	Returns:
;		IF:		0 (interrupts disabled)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro eLSS 2
%ifndef USE_386
	cli							; Disable interrupts
	mov		%1, [%2]			; Load offset
	mov		ss, [%2+2]			; Load segment
;-----------------------------------
%else
	lss		%1, [%2]
%endif
%endmacro


;--------------------------------------------------------------------
; Segment override prefix instruction.
;
; eSEG
;	Parameters:
;		%1:		Name of the segment (ES, CS, SS, DS, FS or GS)
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro eSEG 1
	%ifidni %1, es
		db	00100110b
	%elifidni %1, cs
		db	00101110b
	%elifidni %1, ss
		db	00110110b
	%elifidni %1, ds
		db	00111110b
	%elifidni %1, fs
		db	01100100b
	%elifidni %1, gs
		db	01100101b
	%else
		%error "Invalid segment overried passed to eSEG!"
	%endif
%endmacro


;--------------------------------------------------------------------
; Repeats string instruction with segment override.
; This macro prevents 8088/8086 restart bug.
;
; eSEG_STR
;	Parameters:
;		%1:		REP/REPNE or REPE prefix
;		%2:		Source segment override (destination is always ES)
;		%3:		String instruction
;		CX:		Repeat count
;	Returns:
;		FLAGS for cmps and scas only
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro eSEG_STR 3
%ifndef USE_186	; 8088/8086 has string instruction restart bug when more than one prefix
	 %%Loop:
	 	%1						; REP is the prefix that can be lost
	 	eSEG	%2				; SEG is the prefix that won't be lost
	 	%3						; String instruction
	 	jcxz	%%End			; Jump to end if no repeats left (preserves FLAGS)
	 	jmp		SHORT %%Loop	; Loop while repeats left
	 %%End:
%else	; No bug on V20/V30 and later, don't know about 188/186
	eSEG	%2
	%1		%3
%endif
%endmacro


;--------------------------------------------------------------------
; Bit shifts and rotates with immediate.
;
; eSHIFT_IM
;	Parameters:
;		%1:		Shift target
;		%2:		Number of bits to shift
;		%3:		Instruction (SHL, SHR, ROL, ROR, RCL, RCR)
;	Returns:
;		FLAGS
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro eSHIFT_IM 3
%ifndef USE_186
	%ifidni %1, cl
		times %2	%3		%1, 1
	%elifidni %1, ch
		times %2	%3		%1, 1
	%elifidni %1, cx
		times %2	%3		%1, 1
	%else
		%if %2 > 7
			push	cx
			mov		cl, %2
			%3		%1, cl
			pop		cx
		%else
			times %2	%3		%1, 1
		%endif
	%endif
;-----------------------------------
%else
	%3		%1, %2
%endif
%endmacro
%macro eSHR_IM 2
	eSHIFT_IM	%1, %2, shr
%endmacro
%macro eSHL_IM 2
	eSHIFT_IM	%1, %2, shl
%endmacro
%macro eROR_IM 2
	eSHIFT_IM	%1, %2, ror
%endmacro
%macro eROL_IM 2
	eSHIFT_IM	%1, %2, rol
%endmacro
%macro eRCR_IM 2
	eSHIFT_IM	%1, %2, rcr
%endmacro
%macro eRCL_IM 2
	eSHIFT_IM	%1, %2, rcl
%endmacro


;--------------------------------------------------------------------
; Emulates PUSH imm instruction when necessary.
;
; ePUSH_I
;	Parameters:
;		%1:		Immediate to push
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro ePUSH_I 1
%ifndef USE_186
	push	bp					; Immediate goes here
	push	bp
	mov		bp, sp
	mov		WORD [bp+2], %1
	pop		bp
;-----------------------------------
%else
	push	%1
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates PUSH imm instruction when necessary.
; ePUSH_T uses temporary register for faster performance
; and smaller code size than ePUSH_I.
;
; ePUSH_T
;	Parameters:
;		%1:		Temporary Register
;		%2:		Immediate to push
;	Returns:
;		Nothing
;	Corrupts registers:
;		%1
;--------------------------------------------------------------------
%macro ePUSH_T 2
%ifndef USE_186
	%ifidni %2, 0
		xor		%1, %1
	%else
		mov		%1, %2
	%endif
	push	%1
;-----------------------------------
%else
	push	%2
%endif
%endmacro


%endif ; EMULATE_INC
