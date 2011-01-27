; Project name	:	XTIDE Universal BIOS
; Description	:	Int 19h BIOS functions for Boot Menu.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Initial Boot Menu Loader.
; Prepares BOOTVARS for displaying Boot Menu and accepting
; callbacks from INT 18h and 19h.
;
; Int19hMenu_BootLoader
;	Parameters:
;		Nothing
;	Returns:
;		Jumps to Int19hMenu_Display, then never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19hMenu_BootLoader:
	LOAD_BDA_SEGMENT_TO	ds, ax
	call	BootVars_StorePostStackPointer

	; Install new INT 19h handler now that BOOTVARS has been initialized
	mov		WORD [INTV_BOOTSTRAP*4], Int19hMenu_Display
	mov		WORD [INTV_BOOTSTRAP*4+2], cs
	; Fall to Int19hMenu_Display

;--------------------------------------------------------------------
; Displays Boot Menu so user can select drive to boot from.
;
; Int19hMenu_Display
;	Parameters:
;		Nothing
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19hMenu_Display:
	sti									; Enable interrupts
	call	BootVars_SwitchToBootMenuStack
	call	RamVars_GetSegmentToDS
	; Fall to Int19hMenu_ProcessMenuSelectionsUntilBootable

;--------------------------------------------------------------------
; Processes user menu selections until bootable drive is selected.
;
; Int19hMenu_ProcessMenuSelectionsUntilBootable
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19hMenu_ProcessMenuSelectionsUntilBootable:
	call	Int19hMenu_GetDriveOrFunctionFromBootMenu
	jc		SHORT Int19hMenu_ExecuteSelectedFunction
	call	Int19h_TryToLoadBootSectorFromDL
	jnc		SHORT Int19hMenu_ProcessMenuSelectionsUntilBootable	; Boot failure
	call	BootVars_SwitchBackToPostStack
	jmp		SHORT Int19h_JumpToBootSector


;--------------------------------------------------------------------
; Selects Floppy or Hard Disk Drive to boot from or some function.
;
; Int19hMenu_GetDriveOrFunctionFromBootMenu
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DX:		Drive number (translated, 00h or 80h) or
;				Function ID
;		CF:		Cleared if drive selected
;				Set if function selected
;	Corrupts registers:
;		All non segment regs
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19hMenu_GetDriveOrFunctionFromBootMenu:
	call	BootMenu_DisplayAndReturnSelection
	jc		SHORT .ReturnFunction
	call	DriveXlate_ToOrBack			; Translate drive number
	clc
ALIGN JUMP_ALIGN
.ReturnFunction:
	ret


;--------------------------------------------------------------------
; Executes any function (non-drive) selected from Boot Menu.
;
; Int19hMenu_ExecuteSelectedFunction
;	Parameters:
;		DX:		Function ID (selected from Boot Menu)
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		All non segment regs
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19hMenu_ExecuteSelectedFunction:
	ePUSH_T	ax, Int19hMenu_ProcessMenuSelectionsUntilBootable
	test	dx, dx						; 0, IDF_BOOTMNU_ROM
	jz		SHORT .Int18hRomBoot
	ret
ALIGN JUMP_ALIGN
.Int18hRomBoot:
	call	BootVars_SwitchBackToPostStack
	jmp		Int19h_BootFailure			; Never returns
