; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=10h, Check Drive Ready.

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
; Int 13h function AH=10h, Check Drive Ready.
;
; AH10h_HandlerForCheckDriveReady
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH10h_HandlerForCheckDriveReady:
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	jmp		Device_SelectDrive
%else
	call	Device_SelectDrive
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif
