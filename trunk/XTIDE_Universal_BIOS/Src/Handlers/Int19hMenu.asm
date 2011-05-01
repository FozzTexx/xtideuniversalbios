; Project name	:	XTIDE Universal BIOS
; Description	:	Int 19h BIOS functions for Boot Menu.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Boot Menu Loader.
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
	SWITCH_TO_BOOT_MENU_STACK
	call	RamVars_GetSegmentToDS
	; Fall to .InitializeDisplayForBootMenu

;--------------------------------------------------------------------
; .InitializeDisplayForBootMenu
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
.InitializeDisplayForBootMenu:
	; Change display mode if necessary
	mov		ax, [cs:ROMVARS.wDisplayMode]	; AH 00h = Set Video Mode
	cmp		al, DEFAULT_TEXT_MODE
	je		SHORT .InitializeDisplayLibrary
	int		BIOS_VIDEO_INTERRUPT_10h
.InitializeDisplayLibrary:	
	call	BootMenuPrint_InitializeDisplayContext
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
	call	DriveXlate_ToOrBack							; Translate drive number
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
	int		BIOS_BOOT_FAILURE_INTERRUPT_18h	; Never returns


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
