; Project name	:	XTIDE Universal BIOS
; Description	:	ID words for Advanced IDE controllers

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

%ifndef ADVANCEDID_INC
%define ADVANCEDID_INC

; Controller IDs contained in high byte of ID word.
; Low byte is controller specific to be used in controller initialization and such

ID_NOT_ADVANCED_CONTROLLER	EQU	0

; Promise
ID_PDC20230					EQU		1
ID_PDC20630					EQU		2

; Vision
; QDI Vision Controller Identification nibbles used by hardware so do not modify these
ID_QD6580_ALTERNATE			EQU	0101b
ID_QD6580					EQU	1010b
ID_QD6500					EQU	1100b


%endif ; ADVANCEDID_INC
