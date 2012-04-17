; Project name	:	XTIDE Universal BIOS
; Description	:	Displays Boot Menu.

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
; Displays Boot Menu and returns Drive or Function number.
;
; BootMenu_DisplayAndReturnSelectionInDX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing, selected drive is converted to hotkey
;	Corrupts registers:
;		All General Purpose Registers
;--------------------------------------------------------------------
BootMenu_DisplayAndStoreSelectionAsHotkey:
	call	DriveXlate_Reset

	mov		bx, BootMenuEvent_Handler
	CALL_MENU_LIBRARY	DisplayWithHandlerInBXandUserDataInDXAX

	; Clear Boot Menu from screen
	mov		ax, ' ' | (MONO_NORMAL<<8)
	CALL_DISPLAY_LIBRARY	ClearScreenWithCharInALandAttrInAH
	ret


;--------------------------------------------------------------------
; BootMenu_GetDriveToDXforMenuitemInCX
;	Parameters:
;		CX:		Index of menuitem selected from Boot Menu
;	Returns:
;		DX:		Drive number to be used for booting
;		DS:		RAMVARS segment
;       CF:     Set: There is a selected menu item, DL is valid
;               Clear: There is no selected menu item, DL is not valid
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
BootMenu_GetDriveToDXforMenuitemInCX:
	cmp		cl, NO_ITEM_HIGHLIGHTED
	je		SHORT .ReturnFloppyDriveInDX	; Clear CF if branch taken

	mov		dl, cl							; Copy menuitem index to DX
	call	FloppyDrive_GetCountToAX
	cmp		dl, al							; Floppy drive?
	jb		SHORT .ReturnFloppyDriveInDX	; Set CF if branch taken
	or		al, 80h							; Or 80h into AL before the sub
											; to cause CF to be set after
											; and result has high order bit set
	sub		dl, al							; Remove floppy drives from index

.ReturnFloppyDriveInDX:
	ret
