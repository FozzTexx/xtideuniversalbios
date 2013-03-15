; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=41h, Check if Extensions Present.

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

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=41h, Check if Extensions Present.
;
; AH41h_HandlerForCheckIfExtensionsPresent
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		BX:		55AAh
;	Returns with INTPACK:
;		AH:		Major version of EBIOS extensions
;		BX:		AA55h
;		CX:		Support bits
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
AH41h_HandlerForCheckIfExtensionsPresent:
	cmp		WORD [bp+IDEPACK.intpack+INTPACK.bx], 55AAh
	jne		SHORT .EbiosNotSupported

	mov		BYTE [bp+IDEPACK.intpack+INTPACK.ah], EBIOS_VERSION
	mov		WORD [bp+IDEPACK.intpack+INTPACK.bx], 0AA55h
	mov		WORD [bp+IDEPACK.intpack+INTPACK.cx], ENHANCED_DRIVE_ACCESS_SUPPORT
	and		BYTE [bp+IDEPACK.intpack+INTPACK.flags], ~FLG_FLAGS_CF	; Return with CF cleared
	jmp		Int13h_ReturnFromHandlerWithoutStoringErrorCode
.EbiosNotSupported:
	jmp		Int13h_DirectCallToAnotherBios
