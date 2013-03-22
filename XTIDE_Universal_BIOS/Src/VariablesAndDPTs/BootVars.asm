; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessings BOOTVARS.

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

	; Clear all DRVDETECTINFO structs to zero
	mov		al, DRVDETECTINFO_size
	mul		BYTE [cs:ROMVARS.bIdeCnt]
	mov		di, BOOTVARS.rgDrvDetectInfo	; We must not initialize anything before this!
	xchg	cx, ax
%ifndef MODULE_HOTKEYS
	jmp		Memory_ZeroESDIwithSizeInCX

%else ; if MODULE_HOTKEYS
	call	Memory_ZeroESDIwithSizeInCX

	; Initialize HOTKEYVARS by storing default drives to boot from
	call	BootVars_StoreDefaultDriveLettersToHotkeyVars
	mov		dl, [cs:ROMVARS.bBootDrv]
	jmp		HotkeyBar_StoreHotkeyToBootvarsForDriveNumberInDL


;--------------------------------------------------------------------
; BootVars_StoreDefaultDriveLettersToHotkeyVars
;	Parameters:
;		ES:		BDA Segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
BootVars_StoreDefaultDriveLettersToHotkeyVars:
	mov		WORD [es:BOOTVARS.hotkeyVars+HOTKEYVARS.wFddAndHddLetters], DEFAULT_FLOPPY_DRIVE_LETTER | (DEFAULT_HARD_DRIVE_LETTER<<8)
	ret

%endif ; MODULE_HOTKEYS
