; File name		:	BootVars.asm
; Project name	:	IDE BIOS
; Created date	:	1.4.2010
; Last update	:	14.1.2011
; Author		:	Tomi Tilli,
;				:	Krister Nordvall (optimizations)
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
	cli									; Disable interrupts
	LOAD_BDA_SEGMENT_TO	ss, sp
	mov		sp, BOOTVARS.rgbMnuStack	; Load offset to stack
	sti									; Enable interrupts
	jmp		ax


;--------------------------------------------------------------------
; Restores SS and SP to initial boot loader values.
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
	cli									; Disable interrupts
	LOAD_BDA_SEGMENT_TO	ss, sp
;	eLSS	sp, ss:BOOTVARS.dwPostStack	; Expanded macro to remove
										; unneeded CLI instruction
%ifndef USE_386
	mov		sp, [ss:BOOTVARS.dwPostStack]
	mov		ss, [ss:BOOTVARS.dwPostStack+2]
%else
	lss		sp, [ss:BOOTVARS.dwPostStack]
%endif
	sti									; Enable interrupts
	jmp		ax


;--------------------------------------------------------------------
; Backups system INT 18h ROM Boot / Boot Failure handler and
; installs our own for boot menu INT 18h callbacks.
;
; BootVars_StoreSystemInt18hAndInstallOurs
;	Parameters:
;		DS:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootVars_StoreSystemInt18hAndInstallOurs:
	mov		bx, INTV_BOOT_FAILURE*4		; Offset to INT 18h vector
	les		ax, [bx]					; Load system INT 18h
	mov		[BOOTVARS.dwSys18h], ax
	mov		[BOOTVARS.dwSys18h+2], es
	mov		WORD [bx], Int18h_BootError	; Install our INT 18h
	mov		WORD [bx+2], cs
	ret


;--------------------------------------------------------------------
; Restores system INT 18h ROM Boot or Boot Error handler.
;
; BootVars_RestoreSystemInt18h
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootVars_RestoreSystemInt18h:
	LOAD_BDA_SEGMENT_TO	ds, ax
	les		ax, [BOOTVARS.dwSys18h]
	mov		[INTV_BOOT_FAILURE*4], ax
	mov		[INTV_BOOT_FAILURE*4+2], es
	ret
