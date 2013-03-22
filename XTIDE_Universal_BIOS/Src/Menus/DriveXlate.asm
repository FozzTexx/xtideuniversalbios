; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for swapping drive letters.

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
; DriveXlate_ConvertDriveLetterInDLtoDriveNumber
;	Parameters:
;		DS:		RAMVARS segment
;		DL:		Drive letter ('A'...)
;	Returns:
;		DL:		Drive number (0xh for Floppy Drives, 8xh for Hard Drives)
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
DriveXlate_ConvertDriveLetterInDLtoDriveNumber:
	call	DriveXlate_GetLetterForFirstHardDriveToAX
	cmp		dl, al
	jb		SHORT .ConvertLetterInDLtoFloppyDriveNumber

	; Convert letter in DL to Hard Drive number
	sub		dl, al
	or		dl, 80h
	ret

.ConvertLetterInDLtoFloppyDriveNumber:
	sub		dl, DEFAULT_FLOPPY_DRIVE_LETTER
	ret

%ifdef MODULE_HOTKEY
%if HotkeyBar_FallThroughTo_DriveXlate_ConvertDriveLetterInDLtoDriveNumber <> DriveXlate_ConvertDriveLetterInDLtoDriveNumber
	%error "DriveXlate_ConvertDriveLetterInDLtoDriveNumber must be at the top of DriveXlate.asm, and that file must immediately follow HotKeys.asm"
%endif
%endif

;--------------------------------------------------------------------
; DriveXlate_ConvertDriveNumberFromDLtoDriveLetter
;	Parameters:
;		DL:		Drive number (0xh for Floppy Drives, 8xh for Hard Drives)
;		DS:		RAMVARS Segment
;	Returns:
;		DL:		Drive letter ('A'...)
;		CF:		Set if Hard Drive
;				Clear if Floppy Drive
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
DriveXlate_ConvertDriveNumberFromDLtoDriveLetter:
	xor		dl, 80h
	js		SHORT .GetDefaultFloppyDrive

	; Store default hard drive to boot from
	call	DriveXlate_GetLetterForFirstHardDriveToAX
	add		dl, al
	stc
	ret

.GetDefaultFloppyDrive:
	sub		dl, 80h - DEFAULT_FLOPPY_DRIVE_LETTER	; Clears CF
	ret


;--------------------------------------------------------------------
; Returns letter for first hard disk. Usually it will be 'C' but it
; can be higher if more than two floppy drives are found.
;
; DriveXlate_GetLetterForFirstHardDriveToAX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AX:		Upper case letter for first hard disk
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
DriveXlate_GetLetterForFirstHardDriveToAX:
	call	FloppyDrive_GetCountToAX
	add		al, DEFAULT_FLOPPY_DRIVE_LETTER
	MAX_U	al, DEFAULT_HARD_DRIVE_LETTER
	ret


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
;		DL:		Hard Drive to swap to first Hard Drive
;				Floppy Drive to swap to first Floppy Drive
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
