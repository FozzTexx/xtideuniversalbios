; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device DMA transfer functions.

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

; Structure containing variables for DMA transfer functions.
; This struct must not be larger than IDEPACK without INTPACK.
struc DMAVARS	; Must not be larger than 9 bytes! See IDEPACK in RamVars.inc.
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeDmaTransfer_StartWithCommandInAL
;	Parameters:
;		AL:		IDE command that was used to start the transfer
;				(all PIO read and write commands including Identify Device)
;		ES:SI:	Ptr to normalized data buffer
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CX:		Number of successfully transferred sectors
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeDmaTransfer_StartWithCommandInAL:
