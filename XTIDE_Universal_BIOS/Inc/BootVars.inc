; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for BOOTVARS struct used by boot menu
;					and drive initialization.
%ifndef BOOTVARS_INC
%define BOOTVARS_INC


BOOT_READ_RETRY_TIMES		EQU		3



; Pre-boot variables. These do not exist after successful boot to OS.
; Segment is always 0000h, same as BDA segment
struc BOOTVARS
					resb	7C00h
	.rgbAtaInfo:					; 7C00h, ATA Information for drive detection
	.rgbBootSect	resb 	512		; 7C00h, Boot sector
					resb	256		; Boot Menu stack
	.rgbMnuStack:
	.dwPostStack	resb	4		; POST stack pointer when entering INT 19h
	.rgBootNfo:						; Array containing BOOTNFO structs
endstruc


;--------------------------------------------------------------------
; Stores POST stack pointer to BOOTVARS.
;
; STORE_POST_STACK_POINTER
;	Parameters:
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro STORE_POST_STACK_POINTER 0
	mov		[es:BOOTVARS.dwPostStack], sp
	mov		[es:BOOTVARS.dwPostStack+2], ss
%endmacro


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
; SWITCH_TO_BOOT_MENU_STACK
;	Parameters:
;		Nothing
;	Returns:
;		SS:SP:	Pointer to top of Boot Menu stack
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro SWITCH_TO_BOOT_MENU_STACK 0
%ifndef USE_186
	cli									; Disable interrupts
%endif
	LOAD_BDA_SEGMENT_TO	ss, sp
	mov		sp, BOOTVARS.rgbMnuStack	; Load offset to stack
%ifndef USE_186
	sti									; Enable interrupts
%endif
%endmacro


;--------------------------------------------------------------------
; Restores SS and SP to initial boot loader values.
;
; Note! Must return with AX=0 and CF preserved.
; See Int19hMenu_JumpToBootSector_or_RomBoot.
;
; SWITCH_BACK_TO_POST_STACK
;	Parameters:
;		AX:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		SS:SP:	Ptr to POST stack
;	Corrupts registers:
;		Nothing (not even FLAGS)
;--------------------------------------------------------------------
%macro SWITCH_BACK_TO_POST_STACK 0
%ifndef USE_386
	cli
	mov		ss, ax
	mov		sp, [ss:BOOTVARS.dwPostStack]
	mov		ss, [ss:BOOTVARS.dwPostStack+2]
	sti
%else
	mov		ss, ax
	lss		sp, [ss:BOOTVARS.dwPostStack]
%endif
%endmacro


%endif ; BOOTVARS_INC
