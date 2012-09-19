; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for swapping drive letters.

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
; DriveXlate_ToOrBack
;	Parameters:
;		DL:		Drive number to be possibly translated
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Translated drive number
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DriveXlate_ToOrBack:
	xchg	di, ax					; Backup AX

	mov		ah, 80h					; Assume hard disk
	mov		al, [RAMVARS.xlateVars+XLATEVARS.bHDSwap]
	test	dl, ah					; Hard disk?
	jnz		SHORT .SwapDrive		; If so, jump to swap
	mov		al, [RAMVARS.xlateVars+XLATEVARS.bFDSwap]
	cbw

ALIGN JUMP_ALIGN
.SwapDrive:
	cmp		ah, dl					; Swap DL from 00h/80h to xxh?
	je		SHORT .SwapToXXhInAL
	cmp		al, dl					; Swap DL from xxh to 00h/80h?
	jne		SHORT .RestoreAXandReturn
	mov		al, ah
ALIGN JUMP_ALIGN
.SwapToXXhInAL:
	mov		dl, al
ALIGN JUMP_ALIGN
.RestoreAXandReturn:
	xchg	ax, di					; Restore AX
	ret


;--------------------------------------------------------------------
; Resets drive swapping variables to defaults (no swapping).
;
; DriveXlate_Reset
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
DriveXlate_Reset:
	mov		WORD [RAMVARS.xlateVars+XLATEVARS.wFDandHDswap], 8000h
	ret


;--------------------------------------------------------------------
; Stores drive to be swapped.
;
; DriveXlate_SetDriveToSwap
;	Parameters:
;		DL:		Drive to swap to 00h or 80h
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
DriveXlate_SetDriveToSwap:
	test	dl, dl				; Floppy drive?
	js		SHORT .SetHardDriveToSwap

	; Set Floppy Drive to swap
	mov		[RAMVARS.xlateVars+XLATEVARS.bFDSwap], dl
	ret

.SetHardDriveToSwap:
	mov		[RAMVARS.xlateVars+XLATEVARS.bHDSwap], dl
	ret
