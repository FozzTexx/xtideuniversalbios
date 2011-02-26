; Project name	:	XTIDE Universal BIOS
; Description	:	Functions to access BOOTVARS struct.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Stores POST stack pointer to BOOTVARS.
;
; BootVars_StorePostStackPointer
;	Parameters:
;		DS:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootVars_StorePostStackPointer:
	pop		ax							; Pop return address
	mov		[BOOTVARS.dwPostStack], sp
	mov		[BOOTVARS.dwPostStack+2], ss
	jmp		ax


;--------------------------------------------------------------------
; Initializes stack for boot menu usage.
; POST stack is not large enough when DPTs are stored to 30:0h.
;
; Note regarding LOAD_BDA_SEGMENT_TO: If you force the use of SP
; then you also have to unconditionally enable the CLI/STI pair.
; The reason for this is that only some buggy 808x CPU:s need the
; CLI/STI instruction pair when changing stacks. Other CPU:s disable
; interrupts automatically when SS is modified for the duration of
; the immediately following instruction to give time to change SP.
;
; BootVars_SwitchToBootMenuStack
;	Parameters:
;		Nothing
;	Returns:
;		SS:SP:	Pointer to top of Boot Menu stack
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootVars_SwitchToBootMenuStack:
	pop		ax							; Pop return address
%ifndef USE_186
	cli									; Disable interrupts
%endif
	LOAD_BDA_SEGMENT_TO	ss, sp
	mov		sp, BOOTVARS.rgbMnuStack	; Load offset to stack
%ifndef USE_186
	sti									; Enable interrupts
%endif
	jmp		ax


;--------------------------------------------------------------------
; Restores SS and SP to initial boot loader values.
;
; Before doing any changes, see the note regarding
; LOAD_BDA_SEGMENT_TO in BootVars_SwitchToBootMenuStack
;
; BootVars_SwitchBackToPostStack
;	Parameters:
;		Nothing
;	Returns:
;		SS:SP:	Ptr to POST stack
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootVars_SwitchBackToPostStack:
	pop		ax							; Pop return address
%ifndef USE_186
	cli									; Disable interrupts
%endif
	LOAD_BDA_SEGMENT_TO	ss, sp
%ifndef USE_386
	mov		sp, [ss:BOOTVARS.dwPostStack]
	mov		ss, [ss:BOOTVARS.dwPostStack+2]
%else
	lss		sp, [ss:BOOTVARS.dwPostStack]
%endif
%ifndef USE_186
	sti									; Enable interrupts
%endif
	jmp		ax
