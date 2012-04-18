; Project name	:	XTIDE Universal BIOS
; Description	:	Int 19h Handler (Boot Loader).

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
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
; Int19h_BootLoaderHandler
;	Parameters:
;		Nothing
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
Int19h_BootLoaderHandler:
	sti											; Allow timer interrupts
	LOAD_BDA_SEGMENT_TO	es, ax					; Load BDA segment (zero) to ES
	; Fall to .PrepareBootLoaderStack


;--------------------------------------------------------------------
; Drive detection and boot menu use lots of stack so it is
; wise to relocate stack. Otherwise something important from
; interrupt vectors are likely corrupted, likely our own DPTs if
; they are located to 30:0h.
;
; .PrepareBootLoaderStack
;	Parameters:
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
.PrepareBootLoaderStack:
	STORE_POST_STACK_POINTER
	SWITCH_TO_BOOT_MENU_STACK
	; Fall to .InitializeDisplay


;--------------------------------------------------------------------
; .InitializeDisplay
;	Parameters:
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
.InitializeDisplay:
	; Change display mode if necessary
	mov		ax, [cs:ROMVARS.wDisplayMode]	; AH 00h = Set Video Mode
	cmp		al, DEFAULT_TEXT_MODE
	je		SHORT .InitializeDisplayLibrary
	int		BIOS_VIDEO_INTERRUPT_10h
.InitializeDisplayLibrary:
	call	DetectPrint_InitializeDisplayContext
	; Fall to .InitializeBiosAndDetectDrives


;--------------------------------------------------------------------
; .InitializeBiosAndDetectDrives
;	Parameters:
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		DS:		RAMVARS segment
;--------------------------------------------------------------------
	call	Initialize_AndDetectDrives	
	; Fall to SelectDriveToBootFrom


;--------------------------------------------------------------------
; SelectDriveToBootFrom
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
SelectDriveToBootFrom:
%ifdef MODULE_HOTKEYS
	call	HotkeyBar_UpdateDuringDriveDetection

%ifdef MODULE_BOOT_MENU
	mov		di, BOOTVARS.hotkeyVars+HOTKEYVARS.bScancode
	cmp		BYTE [es:di], BOOT_MENU_HOTKEY_SCANCODE
	jne		SHORT .DoNotDisplayBootMenu

	; Stop blinking the Boot Menu hotkey and display menu
	mov		BYTE [es:di], 0
	call	HotkeyBar_DrawToTopOfScreen
	call	BootMenu_DisplayAndStoreSelectionAsHotkey
.DoNotDisplayBootMenu:
%endif
%endif

	; Check if ROM boot (INT 18h) wanted
	cmp		BYTE [es:BOOTVARS.hotkeyVars+HOTKEYVARS.bScancode], ROM_BOOT_HOTKEY_SCANCODE
	je		SHORT JumpToBootSector_or_RomBoot	; CF clear so ROM boot

	; Try to boot from Primary boot drive (00h by default)
%ifdef MODULE_HOTKEYS
	call	HotkeyBar_GetPrimaryBootDriveNumberToDL
%else
	mov		dl, [cs:ROMVARS.bBootDrv]
	and		dl, 80h		; Only 00h and 80h allowed when not using MODULE_HOTKEYS
%endif
	call	TryToBootFromPrimaryOrSecondaryBootDevice
	jc		SHORT JumpToBootSector_or_RomBoot

	; Try to boot from Secondary boot device (80h by default)
%ifdef MODULE_HOTKEYS
	call	HotkeyBar_GetSecondaryBootDriveNumberToDL
%else
	mov		dl, [cs:ROMVARS.bBootDrv]
	and		dl, 80h
	xor		dl, 80h
%endif
	call	TryToBootFromPrimaryOrSecondaryBootDevice

%ifdef MODULE_BOOT_MENU
	; Force Boot Menu hotkey to display boot menu
	mov		BYTE [es:BOOTVARS.hotkeyVars+HOTKEYVARS.bScancode], BOOT_MENU_HOTKEY_SCANCODE
	jnc		SHORT SelectDriveToBootFrom
%endif
	; Fall to JumpToBootSector_or_RomBoot


;--------------------------------------------------------------------
; JumpToBootSector_or_RomBoot
;
; Switches back to the POST stack, clears the DS and ES registers,
; and either jumps to the MBR (Master Boot Record) that was just read,
; or calls the ROM's boot routine on interrupt 18.
;
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;       CF:     Set for Boot Sector Boot 
;               Clear for ROM Boot
;	   	ES:BX:	(if CF set) Ptr to boot sector
;
;	Returns:
;		Never returns
;--------------------------------------------------------------------
JumpToBootSector_or_RomBoot:
	mov		cx, es		; Preserve MBR segment (can't push because of stack change)
	mov		ax, 0		; NOTE: can't use XOR (LOAD_BDA_SEGMENT_TO) as it impacts CF
	SWITCH_BACK_TO_POST_STACK

; clear segment registers before boot sector or rom call
	mov		ds, ax		
	mov		es, ax
%ifdef USE_386
	mov		fs, ax
	mov		gs, ax
%endif
	jnc		SHORT .romboot

; jump to boot sector
	push	cx			; sgment address for MBR
	push	bx			; offset address for MBR
	retf				; NOTE:	DL is set to the drive number

; Boot by calling INT 18h (ROM Basic of ROM DOS)
.romboot:
	int		BIOS_BOOT_FAILURE_INTERRUPT_18h	; Never returns	


;--------------------------------------------------------------------
; TryToBootFromPrimaryOrSecondaryBootDevice
;	Parameters
;		DL:		Drive selected as boot device
;		DS:		RAMVARS segment
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		DL:		Drive to boot from (translated, 00h or 80h)
;       CF:     Set for Boot Sector Boot
;               Clear for ROM Boot
;	   	ES:BX:	(if CF set) Ptr to boot sector
;	Corrupts registers:
;		AX, CX, DH, SI, DI, (DL if failed to read boot sector)
;--------------------------------------------------------------------
%ifndef MODULE_HOTKEYS
TryToBootFromPrimaryOrSecondaryBootDevice	EQU		BootSector_TryToLoadFromDriveDL

%else
TryToBootFromPrimaryOrSecondaryBootDevice:
	call	DriveXlate_SetDriveToSwap
	call	DriveXlate_ToOrBack
	jmp		BootSector_TryToLoadFromDriveDL
%endif
