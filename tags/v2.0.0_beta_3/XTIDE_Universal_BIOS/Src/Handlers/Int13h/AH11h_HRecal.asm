; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=11h, Recalibrate.

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

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=11h, Recalibrate.
;
; AH11h_HandlerForRecalibrate
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns with INTPACK:
;		AH:		BIOS Error code
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
AH11h_HandlerForRecalibrate:
%ifndef USE_186
	call	AH11h_RecalibrateDrive
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%else
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall to AH11h_RecalibrateDrive
%endif


;--------------------------------------------------------------------
; AH11h_HRecalibrate
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if successful, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
AH11h_RecalibrateDrive:
	; Recalibrate command is optional, vendor specific and not even
	; supported on later ATA-standards. Let's do seek instead.
	mov		cx, 1						; Seek to Cylinder 0, Sector 1
	xor		dh, dh						; Head 0
	jmp		AHCh_SeekToCylinder
