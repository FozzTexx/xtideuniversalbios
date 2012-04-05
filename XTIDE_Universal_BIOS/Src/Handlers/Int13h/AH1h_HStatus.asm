; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=1h, Read Disk Status.

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
; Int 13h function AH=1h, Read Disk Status.
;
; AH1h_HandlerForReadDiskStatus
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns with INTPACK:
;		AH:		Int 13h floppy return status
;		CF:		0 if AH = RET_HD_SUCCESS, 1 otherwise (error)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH1h_HandlerForReadDiskStatus:
	LOAD_BDA_SEGMENT_TO	ds, ax, !

%ifdef MODULE_SERIAL_FLOPPY
	test	dl, dl
	js		.HardDisk
	mov		ah, [BDA.bFDRetST]	; Unlike for hard disks below, floppy version does not clear the status
	jmp		.done
.HardDisk:
%endif

	xchg	ah, [BDA.bHDLastSt]	; Load and clear last error (AH is cleared with the LOAD_BDA_SEGMENT_TO above)

.done:
%ifndef USE_186
	call	Int13h_SetErrorCodeToIntpackInSSBPfromAH
	jmp		Int13h_ReturnFromHandlerWithoutStoringErrorCode
%else
	push	Int13h_ReturnFromHandlerWithoutStoringErrorCode
	jmp		Int13h_SetErrorCodeToIntpackInSSBPfromAH
%endif
