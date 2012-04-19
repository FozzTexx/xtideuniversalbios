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


%endif ; BOOTMENU_INC
