; Project name	:	XTIDE Universal BIOS
; Description	:	Displays Boot Menu.

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
; Displays Boot Menu and returns Drive or Function number.
;
; BootMenu_DisplayAndReturnDriveInDLRomBootClearCF
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Drive number selected
;		CF:		Set if selected item is an actual drive, DL is valid
;				Clear if selected item is Rom Boot, DL is invalid
;	Corrupts registers:
;		All General Purpose Registers
;--------------------------------------------------------------------
BootMenu_DisplayAndReturnDriveInDLRomBootClearCF:
	call	DriveXlate_Reset

	mov		bx, BootMenuEvent_Handler
	CALL_MENU_LIBRARY	DisplayWithHandlerInBXandUserDataInDXAX

	xchg	cx, ax

	; Clear Boot Menu from screen
	mov		ax, ' ' | (MONO_NORMAL<<8)
	CALL_DISPLAY_LIBRARY	ClearScreenWithCharInALandAttrInAH

	; fall through to BootMenu_GetDriveToDXforMenuitemInCX

;--------------------------------------------------------------------
; BootMenu_GetDriveToDXforMenuitemInCX
;	Parameters:
;		CX:		Index of menuitem selected from Boot Menu
;		DS:		RAMVARS segment
;	Returns:
;		DX:		Drive number to be used for booting
;       CF:     Set: There is a selected menu item, DL is valid
;               Clear: The item selected is Rom Boot, DL is not valid
;	Corrupts registers:
;		AX, BX
;
; NOTE: We can't use the menu structure in here, as we are falling through
; from BootMenu_DisplayAndReturnDriveInDLRomBootClearCF when the
; menu structure has already been destroyed.
;--------------------------------------------------------------------
BootMenu_GetDriveToDXforMenuitemInCX:
	mov		dl, cl							; Copy menuitem index to DX
	call	FloppyDrive_GetCountToAX
	cmp		dl, al							; Floppy drive?
	jb		SHORT .ReturnFloppyDriveInDX	; Set CF if branch taken
	or		al, 80h							; Or 80h into AL before the sub
											; shorter instruction than or'ing it in afterward
	sub		dl, al							; Remove floppy drives from index
	call	RamVars_GetHardDiskCountFromBDAtoAX
	or		al, 80h							; Or 80h into AL before the sub
	cmp		dl, al							; Set CF if hard disk
											; Clear CF if last item, beyond hard disk list, which indicates ROM boot
.ReturnFloppyDriveInDX:
	ret
