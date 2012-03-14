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

	add		bx, BootMenuEvent_Handler.FirstEvent
	jmp		bx

MENUEVENT_InitializeMenuinitFromDSSI equ  (BootMenuEvent_Handler.InitializeMenuinitFromDSSI - BootMenuEvent_Handler.FirstEvent)
MENUEVENT_ExitMenu equ  (BootMenuEvent_EventCompleted - BootMenuEvent_Handler.FirstEvent)
MENUEVENT_ItemHighlightedFromCX equ (BootMenuEvent_Handler.ItemHighlightedFromCX - BootMenuEvent_Handler.FirstEvent)
MENUEVENT_ItemSelectedFromCX equ (BootMenuEvent_Handler.ItemSelectedFromCX - BootMenuEvent_Handler.FirstEvent)
MENUEVENT_KeyStrokeInAX equ (BootMenuEvent_Handler.KeyStrokeInAX - BootMenuEvent_Handler.FirstEvent)
MENUEVENT_RefreshTitle equ (BootMenuPrint_TitleStrings - BootMenuEvent_Handler.FirstEvent)
MENUEVENT_RefreshInformation equ (BootMenuPrint_RefreshInformation - BootMenuEvent_Handler.FirstEvent)
MENUEVENT_RefreshItemFromCX equ (BootMenuPrint_RefreshItem - BootMenuEvent_Handler.FirstEvent)
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
	dw		.InitializeMenuinitFromDSSI			; MENUEVENT.InitializeMenuinitFromDSSI
	dw		BootMenuEvent_EventCompleted		; MENUEVENT.ExitMenu
	dw		.EventNotHandled					; MENUEVENT.IdleProcessing
	dw		.ItemHighlightedFromCX				; MENUEVENT.ItemHighlightedFromCX
	dw		.ItemSelectedFromCX					; MENUEVENT.ItemSelectedFromCX
	dw		.KeyStrokeInAX						; MENUEVENT.KeyStrokeInAX
	dw		BootMenuPrint_TitleStrings			; MENUEVENT.RefreshTitle
	dw		BootMenuPrint_RefreshInformation	; MENUEVENT.RefreshInformation
	dw		BootMenuPrint_RefreshItem			; MENUEVENT.RefreshItemFromCX

%endif


; Parameters:
;	DS:SI:		Ptr to MENUINIT struct to initialize
; Returns:
;	DS:SI:		Ptr to initialized MENUINIT struct
ALIGN JUMP_ALIGN
.FirstEvent:	
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
	call	BootMenu_GetDriveToDXforMenuitemInCX_And_RamVars_GetSegmentToDS		
	call	DriveXlate_Reset
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
	jae		SHORT BootMenuEvent_EventCompleted	; Invalid key

	; Highlighting new item resets drive translation and we do not want that.
	; We must be able to translate both floppy drive and hard drive when using hotkey.
	call	RamVars_GetSegmentToDS	
	mov		dx, [RAMVARS.xlateVars+XLATEVARS.wFDandHDswap]
	CALL_MENU_LIBRARY HighlightItemFromAX
	or		[RAMVARS.xlateVars+XLATEVARS.wFDandHDswap], dx
	; Fall to .ItemSelectedFromCX


; Parameters:
;	CX:			Index of selected item
ALIGN JUMP_ALIGN
.ItemSelectedFromCX:
	CALL_MENU_LIBRARY Close

BootMenuEvent_EventCompleted:
	stc
	ret

