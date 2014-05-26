; Project name	:	XTIDE Universal BIOS
; Description	:	Boot Menu event handler for menu library callbacks.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; GetMenuitemToDXforDriveInDL
;	Parameters:
;		DL:		Drive number
;	Returns:
;		DX:		Menuitem index (assuming drive is available)
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
GetMenuitemToDXforDriveInDL:
	xor		dh, dh						; Drive number now in DX
	test	dl, dl
	jns		SHORT .ReturnItemIndexInDX	; Return if floppy drive (HD bit not set)
	call	FloppyDrive_GetCountToAX
	and		dl, ~80h					; Clear HD bit
	add		dx, ax
.ReturnItemIndexInDX:
	ret


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
BootMenuEvent_Handler:
	LOAD_BDA_SEGMENT_TO	es, di
	call	RamVars_GetSegmentToDS

%ifdef MENUEVENT_INLINE_OFFSETS

	add		bx, FirstEvent
	jmp		bx

.EventNotHandled:
.DoNotSetDefaultMenuitem:
	xor		dx, dx		; Clear CF (and menuitem index for DoNotSetDefaultMenuitem)
	ret

MENUEVENT_InitializeMenuinitFromDSSI	equ (EventInitializeMenuinitFromSSBP	- FirstEvent)
MENUEVENT_ExitMenu						equ (BootMenuEvent_Completed			- FirstEvent)
MENUEVENT_ItemHighlightedFromCX			equ (EventItemHighlightedFromCX			- FirstEvent)
MENUEVENT_KeyStrokeInAX					equ (EventKeyStrokeInAX					- FirstEvent)
MENUEVENT_ItemSelectedFromCX			equ (EventItemSelectedFromCX			- FirstEvent)
MENUEVENT_RefreshTitle					equ (BootMenuPrint_TitleStrings			- FirstEvent)
MENUEVENT_RefreshInformation			equ (BootMenuPrint_RefreshInformation	- FirstEvent)
MENUEVENT_RefreshItemFromCX				equ (BootMenuPrint_RefreshItem			- FirstEvent)
;
; Note that there is no entry for MENUEVENT_IdleProcessing.  If MENUEVENT_IDLEPROCESSING_ENABLE is not %defined,
; then the entry point will not be called (saving memory on this end and at the CALL point).
;

%else

	cmp		bx, BYTE MENUEVENT.RefreshItemFromCX	; Above last supported item?
	ja		SHORT .EventNotHandled
	jmp		[cs:bx+rgfnEventSpecificHandlers]

.EventNotHandled:
.DoNotSetDefaultMenuitem:
	xor		dx, dx		; Clear CF (and menuitem index for DoNotSetDefaultMenuitem)
	ret

rgfnEventSpecificHandlers:
	dw		EventInitializeMenuinitFromSSBP		; MENUEVENT.InitializeMenuinitFromDSSI
	dw		EventCompleted						; MENUEVENT.ExitMenu
	dw		EventNotHandled						; MENUEVENT.IdleProcessing
	dw		EventItemHighlightedFromCX			; MENUEVENT.ItemHighlightedFromCX

	dw		EventItemSelectedFromCX				; MENUEVENT.ItemSelectedFromCX
	dw		EventKeyStrokeInAX					; MENUEVENT.KeyStrokeInAX
	dw		BootMenuPrint_TitleStrings			; MENUEVENT.RefreshTitle
	dw		BootMenuPrint_RefreshInformation	; MENUEVENT.RefreshInformation
	dw		BootMenuPrint_RefreshItem			; MENUEVENT.RefreshItemFromCX

%endif


;--------------------------------------------------------------------
; EventInitializeMenuinitFromSSBP
;	Parameters
;		DS:		Ptr to RAMVARS
;		ES:		Ptr to BDA (zero)
;		SS:BP:	Ptr to MENUINIT struct to initialize
;	Returns:
;		CF:		Set if event processed
;				Cleared if event not processed
;	Corrupts registers:
;		Does not matter
;--------------------------------------------------------------------
FirstEvent:
EventInitializeMenuinitFromSSBP:
	; Store number of Menuitems
	call	RamVars_GetHardDiskCountFromBDAtoAX
	xchg	ax, cx
	call	FloppyDrive_GetCountToAX
	add		ax, cx
	inc		ax								; extra entry for ROM Boot item
	mov		[bp+MENUINIT.wItems], ax

	; Store menu size
	mov		WORD [bp+MENUINIT.wTitleAndInfoLines], BOOT_MENU_TITLE_AND_INFO_LINES
	mov		BYTE [bp+MENUINIT.bWidth], BOOT_MENU_WIDTH
	add		al, BOOT_MENU_HEIGHT_WITHOUT_ITEMS
	xchg	cx, ax
	CALL_DISPLAY_LIBRARY	GetColumnsToALandRowsToAH
	MIN_U	ah, cl
	mov		[bp+MENUINIT.bHeight], ah

	; Store selection timeout
	mov		ax, [cs:ROMVARS.wBootTimeout]
	CALL_MENU_LIBRARY StartSelectionTimeoutWithTicksInAX

	; Store default Menuitem (=default drive to boot from)
	eMOVZX	dx, BYTE [cs:ROMVARS.bBootDrv]
	call	GetMenuitemToDXforDriveInDL
	mov		[bp+MENUINIT.wHighlightedItem], dx

	stc
	ret


;--------------------------------------------------------------------
; EventItemHighlightedFromCX
;	Parameters
;		CX:		Index of new highlighted item
;		DX:		Index of previously highlighted item or NO_ITEM_HIGHLIGHTED
;		DS:		Ptr to RAMVARS
;		ES:		Ptr to BDA (zero)
;		SS:BP:	Menu library handle
;	Returns:
;		CF:		Set if event processed
;				Cleared if event not processed
;	Corrupts registers:
;		Does not matter
;--------------------------------------------------------------------
EventItemHighlightedFromCX:
	push	cx

	; Drive number translations and hotkeys must be reset to defaults so highlighted
	; selections are correctly displayed on Hotkey Bar and on Boot Menu
%ifdef MODULE_HOTKEYS
	call	BootVars_StoreDefaultDriveLettersToHotkeyVars
%endif
	call	DriveXlate_Reset

	; Set highlighted item to be drive to boot from for visual purposes only
	call	BootMenu_GetDriveToDXforMenuitemInCX
	jnc		SHORT .noDriveSwapSinceRomBootSelected
	call	DriveXlate_SetDriveToSwap

%ifdef MODULE_HOTKEYS
	; Store highlighted drive as hotkey
	call	HotkeyBar_StoreHotkeyToBootvarsForDriveNumberInDL
	jmp		SHORT .UpdateHotkeyBar
.noDriveSwapSinceRomBootSelected:
	mov		ah, ROM_BOOT_HOTKEY_SCANCODE
	call	HotkeyBar_StoreHotkeyToBootvarsIfValidKeystrokeInAX

.UpdateHotkeyBar:
	; Redraw Hotkey Bar for updated boot drive letters
	mov		al, MONO_NORMAL
	CALL_DISPLAY_LIBRARY	SetCharacterAttributeFromAL

	mov		bl, ATTRIBUTES_ARE_USED
	mov		ax, TELETYPE_OUTPUT_WITH_ATTRIBUTE
	CALL_DISPLAY_LIBRARY	SetCharOutputFunctionFromAXwithAttribFlagInBL
	call	HotkeyBar_DrawToTopOfScreen
%else
.noDriveSwapSinceRomBootSelected:
%endif ; MODULE_HOTKEYS

	; Redraw changes in drive numbers
	xor		ax, ax	; Update first floppy drive (for translated drive number)
	CALL_MENU_LIBRARY	RefreshItemFromAX
	mov		dl, 80h
	call	GetMenuitemToDXforDriveInDL
	xchg	ax, dx	; Update first hard disk (for translated drive number)
	CALL_MENU_LIBRARY	RefreshItemFromAX
	pop		ax		; Update new item (for translated drive number)
	CALL_MENU_LIBRARY	RefreshItemFromAX
	CALL_MENU_LIBRARY	RefreshInformation
	stc
	ret


;--------------------------------------------------------------------
; EventKeyStrokeInAX
;	Parameters
;		AL:		ASCII character for the key
;		AH:		Keyboard library scan code for the key
;		DS:		Ptr to RAMVARS
;		ES:		Ptr to BDA (zero)
;		SS:BP:	Menu library handle
;	Returns:
;		CF:		Set if event processed
;				Cleared if event not processed
;	Corrupts registers:
;		Does not matter
;--------------------------------------------------------------------
%ifdef MODULE_HOTKEYS
EventKeyStrokeInAX:
	; Keypress will be the primary boot drive
	cmp		ah, BOOT_MENU_HOTKEY_SCANCODE
	je		SHORT BootMenuEvent_Completed	; Ignore Boot Menu hotkey
	call	HotkeyBar_StoreHotkeyToBootvarsIfValidKeystrokeInAX
	jnc		SHORT BootMenuEvent_Completed
	; Fall to CloseBootMenu through EventItemSelectedFromCX
%endif


;--------------------------------------------------------------------
; EventItemSelectedFromCX
;	Parameters
;		CX:		Index of selected item
;		DS:		Ptr to RAMVARS
;		ES:		Ptr to BDA (zero)
;		SS:BP:	Menu library handle
;	Returns:
;		CF:		Set if event processed
;				Cleared if event not processed
;	Corrupts registers:
;		Does not matter
;--------------------------------------------------------------------
EventItemSelectedFromCX:
	; Fall to CloseBootMenu


;--------------------------------------------------------------------
; CloseBootMenu
;	Parameters
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		Does not matter
;--------------------------------------------------------------------
CloseBootMenu:
	CALL_MENU_LIBRARY	Close
	; Fall to BootMenuEvent_Completed


;--------------------------------------------------------------------
; BootMenuEvent_Completed
;	Parameters
;		Nothing
;	Returns:
;		CF:		Set to exit from menu
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
BootMenuEvent_Completed:
	stc
%ifndef MODULE_HOTKEYS
EventKeyStrokeInAX:
%endif
	ret
