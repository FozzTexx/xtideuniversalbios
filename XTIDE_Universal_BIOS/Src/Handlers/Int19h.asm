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
	sti									; Enable interrupts
	cld									; String instructions to increment pointers
	LOAD_BDA_SEGMENT_TO	es, ax			; Load BDA segment (zero) to ES
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
%ifdef MODULE_HOTKEYS
	call	TimerTicks_ReadFromBdaToAX
	add		ax, MIN_TIME_TO_DISPLAY_HOTKEY_BAR
	mov		[es:BOOTVARS.hotkeyVars+HOTKEYVARS.wTimeToClose], ax
%endif

	call	Initialize_AndDetectDrives

%ifdef MODULE_HOTKEYS
.WaitUntilTimeToCloseHotkeyBar:
	call	TimerTicks_ReadFromBdaToAX
	cmp		ax, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.wTimeToClose]
	jb		SHORT .WaitUntilTimeToCloseHotkeyBar
%endif
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

; The following macro could be easily inlined below.  Why a macro?  Depending on the combination
; of MODULE_HOTKEYS or MODULE_BOOT_MENU, this code needs to either come before or after the
; call to the boot menu.  
;
%macro TRY_TO_BOOT_DL_AND_DH_DRIVES 0
	push	dx									; it's OK if this is left on the stack, if we are
												; are successful, the following call does not return
	call	TryToBootFromPrimaryOrSecondaryBootDevice_AndBoot
	pop		dx
	mov		dl, dh
	call	TryToBootFromPrimaryOrSecondaryBootDevice_AndBoot
%endmacro
				
%ifdef MODULE_HOTKEYS
	call	HotkeyBar_ScanHotkeysFromKeyBufferAndStoreToBootvars		
	cmp		al, ROM_BOOT_HOTKEY_SCANCODE
	jz		JumpToBootSector_or_RomBoot			; CF clear so ROM boot
%ifdef MODULE_BOOT_MENU
	cmp		al, BOOT_MENU_HOTKEY_SCANCODE
	jz		.BootMenu
%endif
	call	HotkeyBar_GetBootDriveNumbersToDX
.TryUsingHotKeysCode:
	TRY_TO_BOOT_DL_AND_DH_DRIVES
	;; falls through to boot menu, if it is present.  If not present, falls through to rom boot.
%endif

%ifdef MODULE_BOOT_MENU
.BootMenu:		
	call	BootMenu_DisplayAndReturnDriveInDLRomBootClearCF
	jnc		JumpToBootSector_or_RomBoot			; CF clear so ROM boot

	mov		dh, dl								; Setup for secondary drive
	not		dh									; Floppy goes to HD, or vice veras
	and		dh, 080h							; Go to first drive of the floppy or HD set

%ifdef MODULE_HOTKEYS
	jmp		.TryUsingHotKeysCode
%else
	TRY_TO_BOOT_DL_AND_DH_DRIVES		
	jmp		.BootMenu
%endif
%endif

%ifndef MODULE_HOTKEYS
%ifndef MODULE_BOOT_MENU
	xor		dl, dl			; Try to boot from Floppy Drive A
	call	TryToBootFromPrimaryOrSecondaryBootDevice_AndBoot
	mov		dl, 80h			; Try to boot from Hard Drive C
	call	TryToBootFromPrimaryOrSecondaryBootDevice_AndBoot
%endif
%endif

%ifndef MODULE_BOOT_MENU
	clc		;  fall through with flag for ROM boot.  Boot Menu goes back to menu and doesn't fall through.
%endif		

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
%ifndef MODULE_DRIVEXLATE
TryToBootFromPrimaryOrSecondaryBootDevice_AndBoot	EQU		BootSector_TryToLoadFromDriveDL_AndBoot

%else
TryToBootFromPrimaryOrSecondaryBootDevice_AndBoot:
	call	DriveXlate_SetDriveToSwap
	call	DriveXlate_ToOrBack
	; fall through to TryToBoot_FallThroughTo_BootSector_TryToLoadFromDriveDL_AndBoot

TryToBoot_FallThroughTo_BootSector_TryToLoadFromDriveDL_AndBoot:
; fall through to BootSector_TryToLoadFromDriveDL_AndBoot				
%endif
		

