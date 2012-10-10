; Project name	:	XTIDE Universal BIOS
; Description	:	JR-IDE/ISA specifications.

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

%ifndef JRIDEISA_INC
%define JRIDEISA_INC

JRIDE_SECTOR_ACCESS_WINDOW_OFFSET			EQU	3C00h	; 512 byte IDE Sector Access Window
JRIDE_COMMAND_BLOCK_REGISTER_WINDOW_OFFSET	EQU	3E00h	; 8 byte CS0 IDE Register Window
JRIDE_CONTROL_BLOCK_REGISTER_WINDOW_OFFSET	EQU	3E08h	; 8 byte CS1 IDE Register Window


%endif ; JRIDEISA_INC
