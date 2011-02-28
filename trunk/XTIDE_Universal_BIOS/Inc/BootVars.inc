; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for BOOTVARS struct used by boot menu
;					and drive initialization.
%ifndef BOOTVARS_INC
%define BOOTVARS_INC


BOOT_READ_RETRY_TIMES		EQU		3


; Boot Menu Information Table. These are generated for all XTIDE Universal
; BIOS drives. Available only until boot is successfull.
LEN_BOOTNFO_DRV		EQU		26		; Bytes reserved for drive name
struc BOOTNFO
	.twSectCnt		resb	6		; Total user addressable sectors
	.szDrvName		resb	LEN_BOOTNFO_DRV+1	; Drive name
					resb	1		; Alignment
endstruc


; Pre-boot variables. These do not exist after successfull boot to OS.
; Segment is always 0000h, same as BDA segment
struc BOOTVARS
					resb	800h
	.dwPostStack	resb	4		;  804h, POST stack when entering INT 19h
					resb	8
	.rgBootNfo		resb	73F4h	;  80Ch, Array containing BOOTNFO structs
	.rgbMnuStack:					; 7C00h and below, Boot Menu stack
	.rgbAtaInfo:					; 7C00h, ATA Information for drive detection
	.rgbBootSect	resb 	512		; 7C00h, Boot sector
endstruc


;--------------------------------------------------------------------
; Stores POST stack pointer to BOOTVARS.
;
; STORE_POST_STACK_POINTER
;	Parameters:
;		DS:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro STORE_POST_STACK_POINTER 0
	mov		[BOOTVARS.dwPostStack], sp
	mov		[BOOTVARS.dwPostStack+2], ss
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
; Before doing any changes, see the note regarding
; LOAD_BDA_SEGMENT_TO in BootVars_SwitchToBootMenuStack
;
; SWITCH_BACK_TO_POST_STACK
;	Parameters:
;		Nothing
;	Returns:
;		SS:SP:	Ptr to POST stack
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro SWITCH_BACK_TO_POST_STACK 0
%ifndef USE_386
	cli									; Disable interrupts
	LOAD_BDA_SEGMENT_TO	ss, sp
	mov		sp, [ss:BOOTVARS.dwPostStack]
	mov		ss, [ss:BOOTVARS.dwPostStack+2]
	sti									; Enable interrupts
%else
	LOAD_BDA_SEGMENT_TO	ss, sp
	lss		sp, [ss:BOOTVARS.dwPostStack]
%endif
%endmacro


%endif ; BOOTVARS_INC
