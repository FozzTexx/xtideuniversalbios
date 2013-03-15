; Project name	:	Assembly Library
; Description	:	Tests for Assembly Library.
;					Builds wanted library functions to check their size.

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

; Include .inc files
%define EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
;%define INCLUDE_DISPLAY_LIBRARY
;%define INCLUDE_FILE_LIBRARY
;%define INCLUDE_KEYBOARD_LIBRARY
%define INCLUDE_MENU_LIBRARY
;%define INCLUDE_MENU_DIALOGS
;%define INCLUDE_STRING_LIBRARY
;%define INCLUDE_TIME_LIBRARY
;%define INCLUDE_UTIL_LIBRARY

%include "AssemblyLibrary.inc"	; Assembly Library. Must be included first!


; Include library sources
%include "AssemblyLibrary.asm"
