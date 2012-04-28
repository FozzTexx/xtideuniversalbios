; Project name	:	XTIDE Universal BIOS
; Description	:	Equates and structs used in Hotkey Bar.

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

%ifndef HOTKEYBAR_INC
%define HOTKEYBAR_INC

MIN_TIME_TO_DISPLAY_HOTKEY_BAR			EQU	(5000/55)	; 5000 ms


; Hotkeys
BOOT_MENU_HOTKEY_SCANCODE				EQU	3Ch	; F2
ROM_BOOT_HOTKEY_SCANCODE				EQU	42h	; F8

; Default drives
DEFAULT_FLOPPY_DRIVE_LETTER				EQU	'A'
DEFAULT_HARD_DRIVE_LETTER				EQU	'C'


%endif ; HOTKEYBAR_INC
