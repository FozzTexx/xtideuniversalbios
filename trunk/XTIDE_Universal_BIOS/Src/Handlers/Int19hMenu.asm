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
	call	BootMenu_DisplayAndReturnSelection
	call	DriveXlate_ToOrBack			; Translate drive number
	call	Int19h_TryToLoadBootSectorFromDL
	jnc		SHORT Int19hMenu_ProcessMenuSelectionsUntilBootable	; Boot failure, show menu again
	call	BootVars_SwitchBackToPostStack
	jmp		Int19h_JumpToBootSector


;--------------------------------------------------------------------
; Int19hMenu_RomBoot
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19hMenu_RomBoot:
	call	BootVars_SwitchBackToPostStack
	call	Int19h_ClearSegmentsForBoot
	int		INTV_BOOT_FAILURE		; Never returns
