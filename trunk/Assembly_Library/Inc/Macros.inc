; Project name	:	Assembly Library
; Description	:	This is the place to put various generic macros.
;					Should be included immediately after emulate.inc

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
