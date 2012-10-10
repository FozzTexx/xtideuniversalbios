; /*
; Project name	:	XTIDE Universal BIOS
; Description	:	Dependencies for optional modules.

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

; Boot Menu requires Hotkey support
%ifdef MODULE_BOOT_MENU
	%ifndef MODULE_HOTKEYS
		%define MODULE_HOTKEYS
	%endif
%endif

%ifdef MODULE_SERIAL_FLOPPY
	%ifndef MODULE_SERIAL
		%define MODULE_SERIAL
	%endif
%endif



; Include module specific .INC files
%ifdef MODULE_8BIT_IDE
	%include "IDE_8bit.inc"			; For IDE 8-bit data port macros
	%include "XTCF.inc"				; For Lo-tech XT-CF
	%include "JRIDE_ISA.inc"		; For JR-IDE/ISA
%endif

%ifdef MODULE_ADVANCED_ATA
	%include "Vision.inc"			; For QDI Vision QD65xx VLB IDE Controllers
%endif

%ifdef MODULE_EBIOS
	%include "EBIOS.inc"			; Equates for EBIOS functions
%endif

%ifdef MODULE_HOTKEYS
	%include "HotkeyBar.inc"		; For Hotkeys
	%ifdef MODULE_BOOT_MENU
		%include "BootMenu.inc"			; For Boot Menu
	%endif
%endif

%ifdef MODULE_IRQ
	%include "IntController.inc"
%endif



; Included modules for ROMVARS.wFlags
%ifdef MODULE_8BIT_IDE
	MAIN_FLG_MODULE_8BIT_IDE	EQU	FLG_ROMVARS_MODULE_8BIT_IDE
%else
	MAIN_FLG_MODULE_8BIT_IDE	EQU	0
%endif

%ifdef MODULE_ADVANCED_ATA
	MAIN_FLG_MODULE_ADVANCED_ATA	EQU	FLG_ROMVARS_MODULE_ADVANCED_ATA
%else
	MAIN_FLG_MODULE_ADVANCED_ATA	EQU	0
%endif

%ifdef MODULE_BOOT_MENU
	MAIN_FLG_MODULE_BOOT_MENU	EQU	FLG_ROMVARS_MODULE_BOOT_MENU
%else
	MAIN_FLG_MODULE_BOOT_MENU	EQU	0
%endif

%ifdef MODULE_EBIOS
	MAIN_FLG_MODULE_EBIOS	EQU	FLG_ROMVARS_MODULE_EBIOS
%else
	MAIN_FLG_MODULE_EBIOS	EQU	0
%endif

%ifdef MODULE_HOTKEYS
	MAIN_FLG_MODULE_HOTKEYS	EQU	FLG_ROMVARS_MODULE_HOTKEYS
%else
	MAIN_FLG_MODULE_HOTKEYS	EQU	0
%endif

%ifdef MODULE_IRQ
	MAIN_FLG_MODULE_IRQ		EQU	FLG_ROMVARS_MODULE_IRQ
%else
	MAIN_FLG_MODULE_IRQ		EQU	0
%endif

%ifdef MODULE_SERIAL
	MAIN_FLG_MODULE_SERIAL	EQU	FLG_ROMVARS_MODULE_SERIAL
%else
	MAIN_FLG_MODULE_SERIAL	EQU	0
%endif

%ifdef MODULE_SERIAL_FLOPPY
	MAIN_FLG_MODULE_SERIAL_FLOPPY	EQU	FLG_ROMVARS_MODULE_SERIAL_FLOPPY
%else
	MAIN_FLG_MODULE_SERIAL_FLOPPY	EQU	0
%endif

%ifdef MODULE_STRINGS_COMPRESSED
	MAIN_FLG_MODULE_STRINGS_COMPRESSED	EQU	FLG_ROMVARS_MODULE_STRINGS_COMPRESSED
%else
	MAIN_FLG_MODULE_STRINGS_COMPRESSED	EQU	0
%endif

%ifdef MODULE_FEATURE_SETS
	MAIN_FLG_MODULE_FEATURE_SETS	EQU	FLG_ROMVARS_MODULE_FEATURE_SETS
%else
	MAIN_FLG_MODULE_FEATURE_SETS	EQU	0
%endif

MASK_ROMVARS_INCLUDED_MODULES	EQU	MAIN_FLG_MODULE_8BIT_IDE | MAIN_FLG_MODULE_ADVANCED_ATA | MAIN_FLG_MODULE_BOOT_MENU | MAIN_FLG_MODULE_EBIOS | MAIN_FLG_MODULE_HOTKEYS | MAIN_FLG_MODULE_IRQ | MAIN_FLG_MODULE_SERIAL | MAIN_FLG_MODULE_SERIAL_FLOPPY | MAIN_FLG_MODULE_STRINGS_COMPRESSED | MAIN_FLG_MODULE_FEATURE_SETS
