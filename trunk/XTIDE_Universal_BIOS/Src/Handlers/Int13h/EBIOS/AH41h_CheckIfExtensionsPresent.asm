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

%ifdef RETURN_DPTE_ON_AH48H
	call	AH41h_GetSupportBitsToCX
	mov		[bp+IDEPACK.intpack+INTPACK.cx], cx
%else
	mov		WORD [bp+IDEPACK.intpack+INTPACK.cx], ENHANCED_DRIVE_ACCESS_SUPPORT
%endif

	and		BYTE [bp+IDEPACK.intpack+INTPACK.flags], ~FLG_FLAGS_CF	; Return with CF cleared
	jmp		Int13h_ReturnFromHandlerWithoutStoringErrorCode
.EbiosNotSupported:
	jmp		Int13h_DirectCallToAnotherBios


%ifdef RETURN_DPTE_ON_AH48H
;--------------------------------------------------------------------
; AH41h_GetSupportBitsToCX
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		CX:		Support bits returned by AH=41h
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AH41h_GetSupportBitsToCX:
	mov		cx, ENHANCED_DRIVE_ACCESS_SUPPORT

	; DPTE needs buffer from RAM so do not return it in lite mode
%ifndef USE_AT
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .DoNotSetEDDflag
%endif

%ifdef MODULE_8BIT_IDE OR MODULE_SERIAL
	; DPTE contains information for device drivers. We should not return
	; DPTE for 8-bit devices since software would think they are 16-bit devices.
	cmp		BYTE [di+DPT_ATA.bDevice], DEVICE_8BIT_ATA
	jae		SHORT .DoNotSetEDDflag
%endif

	or		cl, ENHANCED_DISK_DRIVE_SUPPORT	; AH=48h returns DPTE
.DoNotSetEDDflag:
	ret

%endif ; RETURN_DPTE_ON_AH48H
