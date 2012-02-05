; Project name	:	XTIDE Universal BIOS
; Description	:	Macros for normal I/O mapped ATA controllers.

%ifndef IO_MAPPED_IDE_INC
%define IO_MAPPED_IDE_INC

;--------------------------------------------------------------------
; OUTPUT_AL_TO_IDE_REGISTER_IN_DL
; JUMP_TO_OUTPUT_AL_TO_IDE_REGISTER_IN_DL
; OUTPUT_AL_TO_IDE_CONTROL_BLOCK_REGISTER_IN_DL
;	Parameters:
;		AL:		Byte to output
;		%1:		IDE Register				(OUTPUT_AL_TO_IDE_REGISTER)
;				IDE Control Block Register	(OUTPUT_AL_TO_IDE_CONTROL_BLOCK_REGISTER)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
%macro OUTPUT_AL_TO_IDE_REGISTER 1
%ifnidni %1, dl
	mov		dl, %1
%endif
	call	IdeIO_OutputALtoIdeRegisterInDL
%endmacro

%macro JUMP_TO_OUTPUT_AL_TO_IDE_REGISTER 1
%ifnidni %1, dl
	mov		dl, %1
%endif
	jmp		IdeIO_OutputALtoIdeRegisterInDL
%endmacro

%macro OUTPUT_AL_TO_IDE_CONTROL_BLOCK_REGISTER 1
%ifnidni %1, dl
	mov		dl, %1
%endif
	call	IdeIO_OutputALtoIdeControlBlockRegisterInDL
%endmacro


;--------------------------------------------------------------------
; INPUT_TO_AL_FROM_IDE_REGISTER
; JUMP_TO_INPUT_TO_AL_FROM_IDE_REGISTER
;	Parameters:
;		%1:		IDE Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AL:		Inputted byte
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
%macro INPUT_TO_AL_FROM_IDE_REGISTER 1
%ifnidni %1, dl
	mov		dl, %1
%endif
	call	IdeIO_InputToALfromIdeRegisterInDL
%endmacro

%macro JUMP_TO_INPUT_TO_AL_FROM_IDE_REGISTER 1
%ifnidni %1, dl
	mov		dl, %1
%endif
	jmp		IdeIO_InputToALfromIdeRegisterInDL
%endmacro


%endif ; IO_MAPPED_IDE_INC
