; Project name	:	XTIDE Universal BIOS
; Description	:	Boot Menu event handler for menu library callbacks.

; Section containing code
SECTION .text

struc ITEM_TYPE_REFRESH
	.HardDisk			resb	2
	.FloppyDrive		resb	2
	.SpecialFunction	resb	2
endstruc


;--------------------------------------------------------------------
; BootMenuEvent_Handler
;	Common parameters for all events:
;		BX:			Menu event (anything from MENUEVENT struct)
;		SS:BP:		Menu library handle
;	Common return values for all events:
;		CF:			Set if event processed
;					Cleared if event not processed
;	Corrupts registers:
;		All
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuEvent_Handler:
	cmp		bx, MENUEVENT.RefreshItemFromCX	; Above last supported item?
	ja		SHORT .EventNotHandled
	jmp		[bx+.rgfnEventSpecificHandlers]
.EventNotHandled:
.IdleProcessing:
	clc
	ret

ALIGN WORD_ALIGN
.rgfnEventSpecificHandlers:
	dw		.InitializeMenuinitFromDSSI
	dw		.EventCompleted
	dw		.IdleProcessing
	dw		.ItemHighlightedFromCX
	dw		.ItemSelectedFromCX
	dw		.KeyStrokeInAX
	dw		BootMenuPrint_TitleStrings
	dw		.RefreshInformation
	dw		.RefreshItemFromCX


; Parameters:
;	DS:SI:		Ptr to MENUINIT struct to initialize
; Returns:
;	DS:SI:		Ptr to initialized MENUINIT struct
ALIGN JUMP_ALIGN
.InitializeMenuinitFromDSSI:
	push	ds
	call	RamVars_GetSegmentToDS
	call	.GetDefaultMenuitemToDX
	call	BootMenu_GetMenuitemCountToCX
	pop		ds
	mov		[si+MENUINIT.wItems], cx
	mov		[si+MENUINIT.wHighlightedItem], dx
	mov		WORD [si+MENUINIT.wTitleAndInfoLines], BOOT_MENU_TITLE_AND_INFO_LINES
	mov		BYTE [si+MENUINIT.bWidth], BOOT_MENU_WIDTH
	call	BootMenu_GetHeightToAHwithItemCountInCL
	mov		[si+MENUINIT.bHeight], ah
	stc
	ret

ALIGN JUMP_ALIGN
.GetDefaultMenuitemToDX:
	mov		dl, [cs:ROMVARS.bBootDrv]	; Default boot drive
	call	BootMenu_IsDriveInSystem
	jnc		SHORT .DoNotSetDefaultMenuitem
	call	DriveXlate_SetDriveToSwap
	call	BootMenu_ConvertDriveToMenuitem
	mov		dx, cx
	ret
ALIGN JUMP_ALIGN
.DoNotSetDefaultMenuitem:
	xor		dx, dx						; Whatever appears first on boot menu
	ret


; Parameters:
;	CX:			Index of new highlighted item
;	DX:			Index of previously highlighted item or NO_ITEM_HIGHLIGHTED
ALIGN JUMP_ALIGN
.ItemHighlightedFromCX:
	push	cx
	push	dx
	call	RamVars_GetSegmentToDS
	call	DriveXlate_Reset
	call	BootMenu_ConvertMenuitemFromCXtoDriveInDX
	call	DriveXlate_SetDriveToSwap
	pop		ax		; Update previous item
	CALL_MENU_LIBRARY RefreshItemFromAX
	pop		ax		; Update new item
	CALL_MENU_LIBRARY RefreshItemFromAX
	CALL_MENU_LIBRARY RefreshInformation
	stc
	ret


; Parameters:
;	AL:			ASCII character for the key
;	AH:			Keyboard library scan code for the key
ALIGN JUMP_ALIGN
.KeyStrokeInAX:
	cmp		ah, ROM_BOOT_HOTKEY_SCANCODE
	jne		SHORT .CheckDriveHotkeys
	jmp		Int19hMenu_RomBoot
ALIGN JUMP_ALIGN
.CheckDriveHotkeys:
	call	BootMenu_ConvertAsciiHotkeyFromALtoMenuitemInCX
	cmp		cx, [bp+MENUINIT.wItems]
	jae		SHORT .EventCompleted	; Invalid key
	xchg	ax, cx
	CALL_MENU_LIBRARY HighlightItemFromAX
	; Fall to .ItemSelectedFromCX


; Parameters:
;	CX:			Index of selected item
ALIGN JUMP_ALIGN
.ItemSelectedFromCX:
	CALL_MENU_LIBRARY Close
.EventCompleted:
	stc
	ret


; Parameters:
;	CX:			Index of item to refresh
;	Cursor has been positioned to the beginning of item line
ALIGN JUMP_ALIGN
.RefreshItemFromCX:
	mov		bx, .rgwItemTypeRefresh
	jmp		SHORT .RefreshItemOrInformationWithJumpTableInCSBX


; Parameters:
;	CX:			Index of highlighted item
;	Cursor has been positioned to the beginning of first line
ALIGN JUMP_ALIGN
.RefreshInformation:
	mov		bx, .rgwInformationItemTypeRefresh
	; Fall to .RefreshItemOrInformationWithJumpTableInCSBX

;--------------------------------------------------------------------
; RefreshItemOrInformationWithJumpTableInCSBX
;	Parameters:
;		CX: 	Index of selected menuitem
;		CS:BX:	Ptr to ITEM_TYPE_REFRESH jump table
;	Returns:
;		CF:		set since event processed
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.RefreshItemOrInformationWithJumpTableInCSBX:
	cmp		cl, NO_ITEM_HIGHLIGHTED
	je		SHORT .EventCompleted

	call	RamVars_GetSegmentToDS
	call	BootMenu_ConvertMenuitemFromCXtoDriveInDX
	test	dl, 80h					; Floppy drive?
	jz		SHORT .DrawFloppyDrive
	jmp		[cs:bx+ITEM_TYPE_REFRESH.HardDisk]
ALIGN JUMP_ALIGN
.DrawFloppyDrive:
	jmp		[cs:bx+ITEM_TYPE_REFRESH.FloppyDrive]

; Jump tables for .RefreshItemOrInformationWithJumpTableInCSBX
ALIGN WORD_ALIGN
.rgwItemTypeRefresh:
istruc ITEM_TYPE_REFRESH
	at	ITEM_TYPE_REFRESH.HardDisk,			dw	BootMenuPrint_HardDiskMenuitem
	at	ITEM_TYPE_REFRESH.FloppyDrive,		dw	BootMenuPrint_FloppyMenuitem
iend
.rgwInformationItemTypeRefresh:
istruc ITEM_TYPE_REFRESH
	at	ITEM_TYPE_REFRESH.HardDisk,			dw	BootMenuPrint_HardDiskMenuitemInformation
	at	ITEM_TYPE_REFRESH.FloppyDrive,		dw	BootMenuPrint_FloppyMenuitemInformation
iend
