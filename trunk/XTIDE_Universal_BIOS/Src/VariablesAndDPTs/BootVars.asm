; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessings BOOTVARS.

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
; BootVars_Initialize
;	Parameters:
;		DS:		RAMVARS Segment
;		ES:		BDA Segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, DI
;--------------------------------------------------------------------
BootVars_Initialize:
%ifdef MODULE_8BIT_IDE_ADVANCED
	mov		WORD [es:BOOTVARS.wNextXTCFportToScan], XTCF_BASE_PORT_DETECTION_SEED
%endif

	; Clear to zero
	mov		al, DRVDETECTINFO_size
	mul		BYTE [cs:ROMVARS.bIdeCnt]
%ifdef MODULE_HOTKEYS ; We must not initialize anything before this!
	mov		di, BOOTVARS.hotkeyVars + HOTKEYVARS.clearToZeroFromThisPoint	
%else
	mov		di, BOOTVARS.clearToZeroFromThisPoint
%endif
	add		ax, BOOTVARS_size
	sub		ax, di
	xchg	cx, ax

%ifdef MODULE_HOTKEYS
	call	Memory_ZeroESDIwithSizeInCX

	; Store default drives to boot from
	mov		dl, [cs:ROMVARS.bBootDrv]

	; fall through to BootVars_StoreHotkeyForDriveNumberInDL

;--------------------------------------------------------------------
; BootVars_StoreHotkeyForDriveNumberInDL
;	Parameters:
;		DL:		Floppy or Hard Drive number
;		DS:		RAMVARS Segment
;		ES:		BDA Segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DI
;--------------------------------------------------------------------
BootVars_StoreHotkeyForDriveNumberInDL:
	mov		WORD [es:BOOTVARS.hotkeyVars+HOTKEYVARS.wFddAndHddLetters], DEFAULT_FLOPPY_DRIVE_LETTER | (DEFAULT_HARD_DRIVE_LETTER<<8)
	call	DriveXlate_ConvertDriveNumberFromDLtoDriveLetter
	jmp		HotkeyBar_StoreHotkeyToBootvarsForDriveLetterInDL

%else
	jmp		Memory_ZeroESDIwithSizeInCX

%endif ; MODULE_HOTKEYS
