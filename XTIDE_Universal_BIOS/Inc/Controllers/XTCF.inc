; Project name	:	XTIDE Universal BIOS
; Description	:	Lo-tech XT-CFv2 board specifications.
;
;					More information at http://www.lo-tech.co.uk/wiki/Lo-tech_XT-CFv2_Board

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

%ifndef XTCF_INC
%define XTCF_INC

; Possible base addresses. Note that all XT-CF IDE registers are SHL 1 compared
; to standard IDE registers.
XTCF_BASE_PORT_1					EQU		200h
XTCF_BASE_PORT_2					EQU		240h
XTCF_BASE_PORT_3					EQU		300h	; Default setting
XTCF_BASE_PORT_4					EQU		320h


; XT-CF Control Register (do not SHL 1 these!)
XTCF_CONTROL_REGISTER				EQU		1Fh
XTCT_CONTROL_REGISTER_INVERTED_in	EQU		1Eh


; Bit Definitions for XT-CF Control Register
MASK_XTCF_BASE_PORT_in				EQU		(3<<0)	; Bits 0...1
	XTCF_PORT_200h					EQU		0
	XTCF_PORT_240h					EQU		1
	XTCF_PORT_300h					EQU		2		; Default
	XTCF_PORT_320h					EQU		3
FLG_PIO8_INSTEAD_OF_DMA				EQU		(1<<2)	; Set to enable PIO8, clear to enable DMA (Channel 3)
FLG_AT_ZERO_WAIT_STATE_in			EQU		(1<<3)
MASK_SECTOR_WINDOW_SEGMENT_in		EQU		(7<<4)	; Bits 4...6
	XTCF_SECTOR_WINDOW_AT_C000h		EQU		0
	XTCF_SECTOR_WINDOW_AT_C800h		EQU		1
	XTCF_SECTOR_WINDOW_AT_D000h		EQU		2		; Default
	XTCF_SECTOR_WINDOW_AT_D800h		EQU		3
	XTCF_SECTOR_WINDOW_AT_E000h		EQU		4
	XTCF_SECTOR_WINDOW_AT_E800h		EQU		5
FLG_XTCF_ROM_ENABLE_in				EQU		(1<<7)


%endif ; XTCF_INC
