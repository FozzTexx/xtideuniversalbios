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
	; Store POST stack pointer
	LOAD_BDA_SEGMENT_TO	ds, ax
	STORE_POST_STACK_POINTER

	; Install new INT 19h handler now that BOOTVARS has been initialized
	mov		WORD [INTV_BOOTSTRAP*4], DisplayBootMenu
	mov		WORD [INTV_BOOTSTRAP*4+2], cs
	; Fall to DisplayBootMenu

;--------------------------------------------------------------------
; DisplayBootMenu
;	Parameters:
;		Nothing
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayBootMenu:
	SWITCH_TO_BOOT_MENU_STACK
	CALL_DISPLAY_LIBRARY InitializeDisplayContext
	call	RamVars_GetSegmentToDS
	; Fall to .ProcessMenuSelectionsUntilBootable

;--------------------------------------------------------------------
; .ProcessMenuSelectionsUntilBootable
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ProcessMenuSelectionsUntilBootable:
	call	BootMenu_DisplayAndReturnSelection
	call	DriveXlate_ToOrBack			; Translate drive number
	call	BootSector_TryToLoadFromDriveDL
	jnc		SHORT .ProcessMenuSelectionsUntilBootable	; Boot failure, show menu again
	SWITCH_BACK_TO_POST_STACK
	; Fall to JumpToBootSector

;--------------------------------------------------------------------
; JumpToBootSector
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		ES:BX:	Ptr to boot sector
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
JumpToBootSector:
	push	es								; Push boot sector segment
	push	bx								; Push boot sector offset
	call	ClearSegmentsForBoot
	retf


;--------------------------------------------------------------------
; Int19hMenu_RomBoot
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19hMenu_RomBoot:
	SWITCH_BACK_TO_POST_STACK
	call	ClearSegmentsForBoot
	int		INTV_BOOT_FAILURE		; Never returns


;--------------------------------------------------------------------
; ClearSegmentsForBoot
;	Parameters:
;		Nothing
;	Returns:
;		DX:		Zero
;		DS=ES:	Zero
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ClearSegmentsForBoot:
	xor		dx, dx					; Device supported by INT 13h
	mov		ds, dx
	mov		es, dx
	ret
