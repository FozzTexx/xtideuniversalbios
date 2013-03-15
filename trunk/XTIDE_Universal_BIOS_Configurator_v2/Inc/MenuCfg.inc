; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	Menu configuration.

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

%ifndef MENUCFG_INC
%define MENUCFG_INC

TITLE_LINES_IN_MENU			EQU		3
INFO_LINES_IN_MENU			EQU		6
MENU_WIDTH					EQU		40
MAX_VALUE_STRING_LENGTH		EQU		12


KEY_BACK_TO_PREVIOUS_MENU	EQU		ESC
KEY_DISPLAY_ITEM_HELP		EQU		3Bh		; F1


%endif ; MENUCFG_INC
