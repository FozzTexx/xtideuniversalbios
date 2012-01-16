; Project name	:	XTIDE Universal BIOS
; Description	:	Boot Menu event handler for menu library callbacks.

; Section containing code
SECTION .text

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

%ifdef MENUEVENT_INLINE_OFFSETS

	add		bx, BootMenuEvent_Handler
	jmp		bx

MENUEVENT_InitializeMenuinitFromDSSI equ  (BootMenuEvent_Handler.InitializeMenuinitFromDSSI - BootMenuEvent_Handler)
MENUEVENT_ExitMenu equ  (BootMenuEvent_Handler.EventCompleted - BootMenuEvent_Handler)
MENUEVENT_ItemHighlightedFromCX equ (BootMenuEvent_Handler.ItemHighlightedFromCX - BootMenuEvent_Handler)
MENUEVENT_ItemSelectedFromCX equ (BootMenuEvent_Handler.ItemSelectedFromCX - BootMenuEvent_Handler)
MENUEVENT_KeyStrokeInAX equ (BootMenuEvent_Handler.KeyStrokeInAX - BootMenuEvent_Handler)
MENUEVENT_RefreshTitle equ (BootMenuPrint_TitleStrings - BootMenuEvent_Handler)
MENUEVENT_RefreshInformation equ (BootMenuEvent_Handler.RefreshInformation - BootMenuEvent_Handler)
MENUEVENT_RefreshItemFromCX equ (BootMenuEvent_Handler.RefreshItemFromCX - BootMenuEvent_Handler)
;
; Note that there is no entry for MENUEVENT_IdleProcessing.  If MENUEVENT_IDLEPROCESSING_ENABLE is not %defined,
; then the entry point will not be called (saving memory on this end and at the CALL point).
;

%else

	cmp		bx, BYTE MENUEVENT.RefreshItemFromCX	; Above last supported item?
	ja		SHORT .EventNotHandled
	jmp		[cs:bx+.rgfnEventSpecificHandlers]

.EventNotHandled:
	clc
	ret

ALIGN WORD_ALIGN
.rgfnEventSpecificHandlers:
	dw		.InitializeMenuinitFromDSSI	; MENUEVENT.InitializeMenuinitFromDSSI
	dw		.EventCompleted				; MENUEVENT.ExitMenu
	dw		.EventNotHandled			; MENUEVENT.IdleProcessing
	dw		.ItemHighlightedFromCX		; MENUEVENT.ItemHighlightedFromCX
	dw		.ItemSelectedFromCX			; MENUEVENT.ItemSelectedFromCX
	dw		.KeyStrokeInAX				; MENUEVENT.KeyStrokeInAX
	dw		BootMenuPrint_TitleStrings	; MENUEVENT.RefreshTitle
	dw		.RefreshInformation			; MENUEVENT.RefreshInformation
	dw		.RefreshItemFromCX			; MENUEVENT.RefreshItemFromCX

%endif


; Parameters:
;	DS:SI:		Ptr to MENUINIT struct to initialize
; Returns:
;	DS:SI:		Ptr to initialized MENUINIT struct
ALIGN JUMP_ALIGN
.InitializeMenuinitFromDSSI:
	push	ds
	call	RamVars_GetSegmentToDS
	call	.GetDefaultMenuitemToDX
	call	BootMenu_GetMenuitemCountToAX
	pop		ds
	mov		[si+MENUINIT.wItems], ax
	mov		[si+MENUINIT.wHighlightedItem], dx
	mov		WORD [si+MENUINIT.wTitleAndInfoLines], BOOT_MENU_TITLE_AND_INFO_LINES
	mov		BYTE [si+MENUINIT.bWidth], BOOT_MENU_WIDTH
	call	BootMenu_GetHeightToAHwithItemCountInAL
	mov		[si+MENUINIT.bHeight], ah
	mov		ax, [cs:ROMVARS.wBootTimeout]
	CALL_MENU_LIBRARY StartSelectionTimeoutWithTicksInAX
	stc
	ret

ALIGN JUMP_ALIGN
.GetDefaultMenuitemToDX:
	mov		dl, [cs:ROMVARS.bBootDrv]	; Default boot drive
	call	BootMenu_IsDriveInSystem
	jnc		SHORT .DoNotSetDefaultMenuitem
	call	DriveXlate_SetDriveToSwap
	jmp		BootMenu_GetMenuitemToDXforDriveInDL
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
	call	RamVars_GetSegmentToDS
	call	DriveXlate_Reset
	call	BootMenu_GetDriveToDXforMenuitemInCX
	call	DriveXlate_SetDriveToSwap

	xor		ax, ax	; Update first floppy drive (for translated drive number)
	CALL_MENU_LIBRARY RefreshItemFromAX
	mov		dl, 80h
	call	BootMenu_GetMenuitemToDXforDriveInDL
	xchg	ax, dx	; Update first hard disk (for translated drive number)
	CALL_MENU_LIBRARY RefreshItemFromAX
	pop		ax		; Update new item (for translated drive number)
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
	;; NOTE: carry flag will be clear after compare above that resulted in zero
	jmp		Int19hMenu_JumpToBootSector_or_RomBoot   	
ALIGN JUMP_ALIGN
.CheckDriveHotkeys:
	call	BootMenu_GetMenuitemToAXforAsciiHotkeyInAL
	cmp		ax, [bp+MENUINIT.wItems]
	jae		SHORT .EventCompleted	; Invalid key
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
	xor		bl, bl		; will result in SF being clear in .RefreshItemOrInformation...
	SKIP2B  dx			; dx corrupted below by BootMenu_GetDriveToDXforMenuitemInCX
	; Fall to .RefreshInformation

; Parameters:
;	CX:			Index of highlighted item
;	Cursor has been positioned to the beginning of first line
; NO ALIGN - in the shadow of SKIP2B
.RefreshInformation:
	mov		bl,040h		;  will result in SF being set in .RefreshItemOrInformation...
	; Fall to .RefreshItemOrInformationWithJumpTableInCSBX

;--------------------------------------------------------------------
; RefreshItemOrInformationWithJumpTableInCSBX
;	Parameters:
;		CX: 	Index of selected menuitem
;		CS:BX:	Ptr to ITEM_TYPE_REFRESH jump table
;	Returns:
;		CF:		set since event processed
;--------------------------------------------------------------------
.RefreshItemOrInformationWithJumpTableInCSBX:
	cmp		cl, NO_ITEM_HIGHLIGHTED
	je		SHORT .EventCompleted

	call	RamVars_GetSegmentToDS
	call	BootMenu_GetDriveToDXforMenuitemInCX
	or		bl,dl				;  or drive number with bit from .RefreshItemFromCX or .RefreshInformation
	shl		bl,1				;  drive letter high order bit to CF, Item/Information bit to SF
	jc		SHORT BootMenuPrint_HardDiskMenuitem
	; fall through to BootMenuEvent_FallThroughToFloppyMenuitem

;;;
;;; Fall-through (to BootMenuPrint_FloppyMenuitem)
;;; (checked at assembler time with the code after BootMenuPrint_FloppyMenuitem)
;;;
ALIGN JUMP_ALIGN
BootMenuEvent_FallThroughToFloppyMenuitem:
	; fall through to BootMenuPrint_FloppyMenuitem
