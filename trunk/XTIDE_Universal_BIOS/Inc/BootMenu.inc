; Project name	:	XTIDE Universal BIOS
; Description	:	Equates and structs used in Boot Menu.

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

%ifndef BOOTMENU_INC
%define BOOTMENU_INC

; Boot menu sizes
BOOT_MENU_DEFAULT_TIMEOUT				EQU	(30 * TICKS_PER_SECOND)
BOOT_MENU_TITLE_LINES					EQU	2	; Number of title lines
BOOT_MENU_INFO_LINES					EQU	3	; Number of info lines
BOOT_MENU_SEPARATOR_LINES_PLUS_SHADOW	EQU	5
BOOT_MENU_TITLE_AND_INFO_LINES			EQU	(BOOT_MENU_TITLE_LINES | (BOOT_MENU_INFO_LINES<<8))
BOOT_MENU_WIDTH							EQU	40	; Menu width in characters (including shadow)
BOOT_MENU_HEIGHT_WITHOUT_ITEMS			EQU	(BOOT_MENU_TITLE_LINES + BOOT_MENU_INFO_LINES + BOOT_MENU_SEPARATOR_LINES_PLUS_SHADOW)
MENU_SCREEN_BOTTOM_LINES				EQU	1


; Boot Menu Information Table. These are generated for all XTIDE Universal
; BIOS drives. Available only until boot is successful.
MAX_HARD_DISK_NAME_LENGTH				EQU		30		; Bytes reserved for drive name

struc BOOTMENUINFO
	.szDrvName				resb	MAX_HARD_DISK_NAME_LENGTH
							resb	2	; Zero word (ensures string terminates)
	.wInitErrorFlags		resb	2	; Errors during initialization
	
%ifdef MODULE_ADVANCED_ATA
							resb	6	; padding to make BOOTMENUINFO size an even multiple of DPT size
%else
							resb	2	; padding to make BOOTMENUINFO size an even multiple of DPT size
%endif				
endstruc


DPT_BOOTMENUINFO_SIZE_MULTIPLIER  equ	BOOTMENUINFO_size / LARGEST_DPT_SIZE

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS

%if MAX_HARD_DISK_NAME_LENGTH % 2 <> 0
	%error "MAX_HARD_DISK_NAME_LENGTH needs to be a multiple of 2, memory is moved with word operations."
%endif

%if BOOTMENUINFO_size % LARGEST_DPT_SIZE <> 0
	%error "BOOTMENUINFO's size must be an even multiple of DPT's size.  Add or remove padding at the bottom of BOOTMENUINFO to bring the two sizes into alignment.  As BOOTMENUINFO is only used at boot time, with plenty of memory to consume, it is OK to waste some space here."
%endif

%if BOOTMENUINFO.szDrvName <> 0
	%error "BOOTMENUINFO.szDrvName is assumed to be the first member of struc BOOTMENUINFO, in BootMenuPrint_RefreshItem"
%endif

%endif


%endif ; BOOTMENU_INC
