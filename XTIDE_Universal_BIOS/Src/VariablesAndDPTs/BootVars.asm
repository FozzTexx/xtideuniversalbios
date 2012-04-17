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
	; Clear to zero
	mov		al, BOOTMENUINFO_size
	mul		BYTE [cs:ROMVARS.bIdeCnt]
	mov		di, BOOTVARS.hotkeyVars	; We must not initialize anything before this!
	add		ax, BOOTVARS_size
	sub		ax, di
	xchg	cx, ax
	call	Memory_ZeroESDIwithSizeInCX

	; Store default drives to boot from
	mov		di, BOOTVARS.hotkeyVars+HOTKEYVARS.wHddAndFddLetters
	call	HotkeyBar_GetLetterForFirstHardDriveToAX
	mov		ah, DEFAULT_FLOPPY_DRIVE_LETTER
	mov		[es:di], ax

	; Check if boot drive is overridden in ROMVARs
	mov		al, [cs:ROMVARS.bBootDrv]
	test	al, al
	js		SHORT .StoreUserHardDiskToBootFrom
	inc		di
	jmp		SHORT .AddToDefaultDrive

.StoreUserHardDiskToBootFrom:
	sub		al, 80h					; Clear HD bit
.AddToDefaultDrive:
	add		[es:di], al
	ret
