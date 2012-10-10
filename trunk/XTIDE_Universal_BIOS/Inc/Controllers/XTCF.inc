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

XTCF_DMA_MODE_MAX_BLOCK_SIZE		EQU		64		; Sectors
OFFSET_TO_CONTROL_BLOCK_REGISTERS	EQU		8

; Possible base addresses. Note that all XT-CF IDE registers are SHL 1 compared
; to standard IDE registers.
XTCF_BASE_PORT_1					EQU		200h
XTCF_BASE_PORT_2					EQU		240h
XTCF_BASE_PORT_3					EQU		300h	; Default setting
XTCF_BASE_PORT_4					EQU		340h


; XT-CF Control Register (do not SHL 1 these!)
XTCF_CONTROL_REGISTER				EQU		1Fh
XTCT_CONTROL_REGISTER_INVERTED_in	EQU		1Eh

; Control Register contents:
;
; Control Register holds high byte from Sector Window segment if >= A0h
; (First possible segment for Sector Window is A000h)
; 
; 8-bit PIO transfers (port I/O) are used if Control Register is zero.
; Any other value means DMA transfers (using DMA channel 3).
XTCF_8BIT_PIO_MODE					EQU		0
XTCF_MEMORY_MAPPED_MODE				EQU		0A0h



; Subcommands for AH=1Eh, Lo-tech XT-CF features.
; Return values common for all subcommands:
;		AH:		RET_HD_SUCCESS if drive is XT-CF
;				RET_HD_INVALID if drive is not XT-CF
;		CF:		0 if successful, 1 if error

;--------------------------------------------------------------------
; IS_THIS_DRIVE_XTCF
;	Parameters:
;		DL:		Drive Number
;--------------------------------------------------------------------
IS_THIS_DRIVE_XTCF					EQU		0

;--------------------------------------------------------------------
; READ_XTCF_CONTROL_REGISTER_TO_DH
;	Parameters:
;		DL:		Drive Number
;	Returns:
;		DH:		XT-CF Control Register contents
;--------------------------------------------------------------------
READ_XTCF_CONTROL_REGISTER_TO_DH	EQU		1

;--------------------------------------------------------------------
; WRITE_DH_TO_XTCF_CONTROL_REGISTER
;	Parameters:
;		DH:		Byte to write to XT-CF Control Register
;		DL:		Drive Number
;--------------------------------------------------------------------
WRITE_DH_TO_XTCF_CONTROL_REGISTER	EQU		2


%endif ; XTCF_INC
