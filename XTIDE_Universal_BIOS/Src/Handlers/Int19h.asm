; Project name	:	XTIDE Universal BIOS
; Description	:	Int 19h Handler (Boot Loader).

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
; Int19h_BootLoaderHandler
;	Parameters:
;		Nothing
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
Int19h_BootLoaderHandler:
	sti											; Enable interrupts
	cld											; String instructions to increment pointers
%ifdef MODULE_VERY_LATE_INIT
	LOAD_BDA_SEGMENT_TO	ds, ax					; Load BDA segment (zero) to DS
	les		ax, [TEMPORARY_VECTOR_FOR_SYSTEM_INT13h*4]
	mov		[BIOS_DISK_INTERRUPT_13h*4], ax
	mov		[BIOS_DISK_INTERRUPT_13h*4+2], es
	push	ds									; BDA segment (zero)...
	pop		es									; ...to ES
%else
	LOAD_BDA_SEGMENT_TO	es, ax					; Load BDA segment (zero) to ES
%endif
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
.InitializeBiosAndDetectDrives:
%ifdef MODULE_HOTKEYS
	call	TimerTicks_ReadFromBdaToAX
	mov		[es:BOOTVARS.hotkeyVars+HOTKEYVARS.wTimeWhenDisplayed], ax
%endif

	call	Initialize_AndDetectDrives

%ifdef MODULE_HOTKEYS
	; Last hard drive might have scrolled Hotkey Bar out of screen.
	; We want to display it during wait.
	call	HotkeyBar_UpdateDuringDriveDetection

.WaitUntilTimeToCloseHotkeyBar:
	call	TimerTicks_ReadFromBdaToAX
	sub		ax, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.wTimeWhenDisplayed]
	cmp		ax, MIN_TIME_TO_DISPLAY_HOTKEY_BAR
	jb		SHORT .WaitUntilTimeToCloseHotkeyBar
%endif
	; Fall to .ResetAllDrives


;--------------------------------------------------------------------
; .ResetAllDrives
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Nothing
;--------------------------------------------------------------------
.ResetAllDrives:
	; Reset all drives in the system, not just our drives.
	xor		ax, ax		; Disk Controller Reset
	mov		dl, 80h		; Reset all hard drives and floppy drives
	int		BIOS_DISK_INTERRUPT_13h
	; Fall to SelectDriveToBootFrom


;--------------------------------------------------------------------
; SelectDriveToBootFrom
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
; The following macro could be easily inlined below.  Why a macro?  Depending on the combination
; of MODULE_HOTKEYS or MODULE_BOOT_MENU, this code needs to either come before or after the
; call to the boot menu.
;
%macro TRY_TO_BOOT_DL_AND_DH_DRIVES 0
	push	dx									; it's OK if this is left on the stack, if we are
												; successful, the following call does not return
	call	BootSector_TryToLoadFromDriveDL_AndBoot
	pop		dx
	mov		dl, dh
	call	BootSector_TryToLoadFromDriveDL_AndBoot
%endmacro


SelectDriveToBootFrom:		; Function starts here
%ifdef MODULE_HOTKEYS
	call	HotkeyBar_UpdateDuringDriveDetection
	mov		al, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.bScancode]
	cmp		al, ROM_BOOT_HOTKEY_SCANCODE
	je		SHORT .RomBoot						; CF clear so ROM boot
%ifdef MODULE_BOOT_MENU
	cmp		al, BOOT_MENU_HOTKEY_SCANCODE
	je		SHORT .BootMenu
%endif ; MODULE_BOOT_MENU

.TryUsingHotKeysCode:
	call	HotkeyBar_GetBootDriveNumbersToDX
	call	DriveXlate_SetDriveToSwap			; Enable primary boot device translation
	xchg	dl, dh
	call	DriveXlate_SetDriveToSwap			; Enable secondary boot device translation
	xchg	dl, dh
	call	DriveXlate_ToOrBack					; Translate now so boot device will appear as 00h or 80h to OS
	TRY_TO_BOOT_DL_AND_DH_DRIVES
	;; falls through to boot menu, if it is present.  If not present, falls through to rom boot.
%endif ; MODULE_HOTKEYS


%ifdef MODULE_BOOT_MENU
.BootMenu:
	call	BootMenu_DisplayAndReturnDriveInDLRomBootClearCF
	jnc		SHORT .RomBoot						; CF clear so ROM boot

	call	DriveXlate_Reset
%ifdef MODULE_HOTKEYS
	jmp		SHORT .TryUsingHotKeysCode			; Selected drive stored as hotkey
%else ; Boot menu without hotkeys, secondary boot drive is always 00h or 80h
	mov		dh, dl								; Setup for secondary drive
	not		dh									; Floppy goes to HD, or vice versa
	and		dh, 80h								; Go to first drive of the floppy or HD set
	call	DriveXlate_SetDriveToSwap
	call	DriveXlate_ToOrBack
	TRY_TO_BOOT_DL_AND_DH_DRIVES
	jmp		SHORT .BootMenu						; Show boot menu again
%endif ; MODULE_HOTKEYS

%endif ; MODULE_BOOT_MENU

; No hotkeys and no boot menu means fixed "A then C" boot order
%ifndef MODULE_HOTKEYS OR MODULE_BOOT_MENU
	xor		dl, dl								; Try to boot from Floppy Drive A
	call	BootSector_TryToLoadFromDriveDL_AndBoot
	mov		dl, 80h								; Try to boot from Hard Drive C
	call	BootSector_TryToLoadFromDriveDL_AndBoot
%endif

.RomBoot:
%ifdef MODULE_DRIVEXLATE
	call	DriveXlate_Reset					; Clean up any drive mappings before Rom Boot
%endif
	clc
	;; fall through to Int19_JumpToBootSectorOrRomBoot

;--------------------------------------------------------------------
; Int19_JumpToBootSectorOrRomBoot
;
; Switches back to the POST stack, clears the DS and ES registers,
; and either jumps to the MBR (Master Boot Record) that was just read,
; or calls the ROM's boot routine on interrupt 18.
;
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		CF:		Set for Boot Sector Boot
;				Clear for ROM Boot
;		ES:BX:	(if CF set) Ptr to boot sector
;
;	Returns:
;		Never returns
;--------------------------------------------------------------------
Int19_JumpToBootSectorOrRomBoot:
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
