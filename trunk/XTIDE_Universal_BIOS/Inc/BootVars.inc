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
	.szDrvName		resb	LEN_BOOTNFO_DRV		; Drive name
					resb	2		; Zero word (ensures string terminates)
	.twSectCnt		resb	6		; Total user addressable sectors
					resb	2		; padding to make BOOTNFO size an even multiple of DPT size
endstruc

DPT_BOOTNFO_SIZE_MULTIPLIER  equ	BOOTNFO_size / LARGEST_DPT_SIZE

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS				

%if BOOTNFO_size % LARGEST_DPT_SIZE <> 0
%error "BOOTNFO's size must be an even multiple of DPT's size.  Add or remove padding at the bottom of BOOTNFO to bring the two sizes into alignment.  As BOOTNFO is only used at boot time, with plenty of memory to consume, it is OK to waste some space here."
%endif

%if BOOTNFO.szDrvName <> 0
%error "BOOTNFO.szDrvName is assumed to be the first member of struc BOOTNFO, in BootMenuPrint_RefreshItem"
%endif

%if BOOTNFO.szDrvName + LEN_BOOTNFO_DRV + 2 <> BOOTNFO.twSectCnt
%error "BOOTNFO.twSectCnt is assumed to come immediately after BOOTNFO.szDrvName (with zero padding), in BootInfo_CreateForHardDisk"
%endif

%endif


; Pre-boot variables. These do not exist after successfull boot to OS.
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
