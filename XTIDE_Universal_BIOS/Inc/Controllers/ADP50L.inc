; Project name	:	XTIDE Universal BIOS
; Description	:	Silicon Valley Computer ADP50L specifications.

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

%ifndef ADP50L_INC
%define ADP50L_INC

; | BIOS Segment --------- | Unknown - | ROM Chip ---------- |
;	Jumper:		J1	J2	J3	J4	J5	J6	J7
;	Disabled	N/A	N/A	OFF	OFF	OFF	OFF	OFF	= 2764 / 27C64 *
;	C800h *		OFF	OFF	ON				ON	= 27256 / 27C256
;	CA00h		ON	OFF	ON
;	CC00h		OFF	ON	ON
;	CE00h		ON	ON	ON
;
; * Defaults
; Unknown = "Factory configured - do not alter"
; Bits 11...9 of the segment address corresponds to jumpers J3...J1.

ADP50L_BIOS_SEGMENT_ADDRESS_1		EQU		0C800h	; Default
ADP50L_BIOS_SEGMENT_ADDRESS_2		EQU		0CA00h
ADP50L_BIOS_SEGMENT_ADDRESS_3		EQU		0CC00h
ADP50L_BIOS_SEGMENT_ADDRESS_4		EQU		0CE00h
ADP50L_DEFAULT_BIOS_SEGMENT_ADDRESS	EQU		ADP50L_BIOS_SEGMENT_ADDRESS_1

; Offsets from BIOS segment address
ADP50L_COMMAND_BLOCK_REGISTER_WINDOW_OFFSET	EQU	1D00h
ADP50L_CONTROL_BLOCK_REGISTER_WINDOW_OFFSET	EQU	1D10h	; The low byte is (8 SHL 1)
ADP50L_SECTOR_ACCESS_WINDOW_OFFSET			EQU	1E00h	; 512 byte IDE Sector Access Window

; All IDE register offsets are SHL 1 compared to the standard offsets.
; Example 1: STATUS_REGISTER_in = ADP50L_COMMAND_BLOCK_REGISTER_WINDOW_OFFSET + (STATUS_REGISTER_in << 1)
; Example 2: DEVICE_CONTROL_REGISTER_out = ADP50L_CONTROL_BLOCK_REGISTER_WINDOW_OFFSET + (DEVICE_CONTROL_REGISTER_out << 1)

%endif ; ADP50L_INC
