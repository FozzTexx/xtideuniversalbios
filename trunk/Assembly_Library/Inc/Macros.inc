; Project name	:	Assembly Library
; Description	:	This is the place to put various generic macros.
;					Should be included immediately after Emulate.inc
%ifndef MACROS_INC
%define MACROS_INC

;--------------------------------------------------------------------
; Skips the immediately following 2 byte instruction by using it
; as an immediate value to a dummy instruction.
; Destroys the contents of %1.
;
; SKIP2B
;	Parameters:
;		%1:		Any 16 bit general purpose register or F for flags.
;	Returns:
;		Nothing
;	Corrupts registers:
;		%1
;--------------------------------------------------------------------
%macro SKIP2B 1
	%ifidni		%1, f
		db	03Dh					; Opcode byte for CMP AX, <immed>
		;db	0A9h					; Alt. version TEST AX, <immed>
	%elifidni	%1, ax
		db	0B8h					; Opcode byte for MOV AX, <immed>
	%elifidni	%1, cx
		db	0B9h					; Opcode byte for MOV CX, <immed>
	%elifidni	%1, dx
		db	0BAh					; Opcode byte for MOV DX, <immed>
	%elifidni	%1, bx
		db	0BBh					; Opcode byte for MOV BX, <immed>
	%elifidni	%1, sp
		db	0BCh					; Opcode byte for MOV SP, <immed>
	%elifidni	%1, bp
		db	0BDh					; Opcode byte for MOV BP, <immed>
	%elifidni	%1, si
		db	0BEh					; Opcode byte for MOV SI, <immed>
	%elifidni	%1, di
		db	0BFh					; Opcode byte for MOV DI, <immed>
	%else
		%error "Invalid parameter passed to SKIP2B"
	%endif
%endmacro


;--------------------------------------------------------------------
; Load BDA (Bios Data Area) segment to wanted segment register.
;
; Use an exclamation point (!) as the third parameter when you want
; to force the use of the register in the second parameter. This is
; useful when that register needs to be zeroed in subsequent code or
; when stack usage is undesirable (ie speed is critical).
;
; The PRESERVE_FLAGS version will zero the register with a MOV instead
; of an XOR, thus preserving the flags.  It is one byte larger on
; non-186 or higher systems.
;
; LOAD_BDA_SEGMENT_TO
; LOAD_BDA_SEGMENT_PRESERVE_FLAGS_TO
;	Parameters:
;		%1:		Destination Segment Register
;		%2:		Temporary WORD Register
;		%3:		Can be ! or empty
;	Returns:
;		%1:		BDA segment (zero)
;	Corrupts registers:
;		%2
;--------------------------------------------------------------------
%macro LOAD_BDA_SEGMENT_TO 2-3
%ifndef USE_186
	xor		%2, %2
	mov		%1, %2
%elifidn %3, !
	xor		%2, %2
	mov		%1, %2
%else
	push	BYTE 0
	pop		%1
%endif
%endmacro

%macro LOAD_BDA_SEGMENT_PRESERVE_FLAGS_TO 2-3
%ifndef USE_186
	mov		%2, 0
	mov		%1, %2
%elifidn %3, !
	mov		%2, 0
	mov		%1, %2
%else
	push	BYTE 0
	pop		%1
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


%endif ; MACROS_INC
