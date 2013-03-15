; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=2h, Read Disk Sectors.

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
; Int 13h function AH=2h, Read Disk Sectors.
;
; AH2h_HandlerForReadDiskSectors
;	Parameters:
;		AL, CX, DH, ES:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		AL:		Number of sectors to read (1...128)
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		ES:BX:	Pointer to buffer receiving data
;	Returns with INTPACK:
;		AH:		Int 13h/40h floppy return status
;		AL:		Burst error length if AH returns 11h (we never return error code 11h)
;				Number of sectors actually read (only valid if CF set for someBIOSes)
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH2h_HandlerForReadDiskSectors:
	call	Prepare_BufferToESSIforOldInt13hTransfer
	call	Prepare_GetOldInt13hCommandIndexToBX
	mov		ah, [cs:bx+g_rgbReadCommandLookup]
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAHandTransferredSectorsFromCL
	jmp		Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
%else
	call	Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAHandTransferredSectorsFromCL
%endif

