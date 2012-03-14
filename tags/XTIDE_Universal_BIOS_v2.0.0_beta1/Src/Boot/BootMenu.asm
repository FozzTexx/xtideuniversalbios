; Project name	:	XTIDE Universal BIOS
; Description	:	Displays Boot Menu.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Displays Boot Menu and returns Drive or Function number.
;
; BootMenu_DisplayAndReturnSelectionInDX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DX:		Untranslated drive number to be used for booting
;	Corrupts registers:
;		All General Purpose Registers
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_DisplayAndReturnSelectionInDX:
	call	DriveXlate_Reset
	call	BootMenuPrint_TheBottomOfScreen
	call	BootMenu_Enter			; Get selected menuitem index to CX
	call	BootMenuPrint_ClearScreen
	call	BootMenu_GetDriveToDXforMenuitemInCX
	jnc		BootMenu_DisplayAndReturnSelectionInDX
	ret

;--------------------------------------------------------------------
; BootMenu_GetDriveToDXforMenuitemInCX_And_RamVars_GetSegmentToDS
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
ALIGN JUMP_ALIGN
BootMenu_GetDriveToDXforMenuitemInCX_And_RamVars_GetSegmentToDS:
	call	RamVars_GetSegmentToDS
;;; fall-through

ALIGN JUMP_ALIGN
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


;--------------------------------------------------------------------
; Enters Boot Menu or submenu.
;
; BootMenu_Enter
;	Parameters:
;		Nothing
;	Returns:
;		CX:		Index of selected item or NO_ITEM_SELECTED
;	Corrupts registers:
;		AX, BX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_Enter:
	mov		bx, BootMenuEvent_Handler
	CALL_MENU_LIBRARY DisplayWithHandlerInBXandUserDataInDXAX
	xchg	cx, ax
	ret


;--------------------------------------------------------------------
; Returns number of menuitems in Boot Menu.
;
; BootMenu_GetMenuitemCountToAX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AX:		Number of boot menu items
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetMenuitemCountToAX:
	call	RamVars_GetHardDiskCountFromBDAtoAX
	xchg	ax, cx
	call	FloppyDrive_GetCountToAX
	add		ax, cx
	ret


;--------------------------------------------------------------------
; BootMenu_GetHeightToAHwithItemCountInAL
;	Parameters:
;		AL:		Number of menuitems
;	Returns:
;		AH:		Boot menu height
;	Corrupts registers:
;		AL, CX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetHeightToAHwithItemCountInAL:
	add		al, BOOT_MENU_HEIGHT_WITHOUT_ITEMS
	xchg	cx, ax
	CALL_DISPLAY_LIBRARY GetColumnsToALandRowsToAH
	sub		ah, MENU_SCREEN_BOTTOM_LINES*2	; Leave space for bottom info
	cmp		ah, cl
	jb		SHORT .Return
	mov		ah, cl
ALIGN JUMP_ALIGN, ret
.Return:
	ret


;--------------------------------------------------------------------
; BootMenu_GetMenuitemToAXforAsciiHotkeyInAL
;	Parameters:
;		AL:		ASCII hotkey
;	Returns:
;		AX:		Menuitem index
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetMenuitemToAXforAsciiHotkeyInAL:
	call	Char_ALtoUpperCaseLetter
	cbw
	xchg	ax, cx
	call	BootMenu_GetLetterForFirstHardDiskToAL
	cmp		cl, al						; Letter is for Hard Disk?
	jae		SHORT .StartFromHardDiskLetter
	xchg	ax, cx
	sub		al, 'A'						; Letter to Floppy Drive menuitem
	ret
ALIGN JUMP_ALIGN
.StartFromHardDiskLetter:
	sub		cl, al						; Hard Disk index
	call	FloppyDrive_GetCountToAX
	add		ax, cx						; Menuitem index
										; Note: no need to xchg ax, cx as above, since adding with result to ax
	ret


;--------------------------------------------------------------------
; Returns letter for first hard disk. Usually it will be 'c' but it
; can be higher if more than two floppy drives are found.
;
; BootMenu_GetLetterForFirstHardDiskToCL
;	Parameters:
;		Nothing
;	Returns:
;		CL:		Upper case letter for first hard disk
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetLetterForFirstHardDiskToAL:
	call	FloppyDrive_GetCountToAX
	add		al, 'A'
	cmp		al, 'C'
	ja		.Return
	mov		al, 'C'
ALIGN JUMP_ALIGN, ret
.Return:
	ret


;--------------------------------------------------------------------
; BootMenu_GetMenuitemToDXforDriveInDL
;	Parameters:
;		DL:		Drive number
;	Returns:
;		DX:		Menuitem index (assuming drive is available)
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetMenuitemToDXforDriveInDL:
	xor		dh, dh						; Drive number now in DX
	test	dl, dl
	jns		SHORT .ReturnItemIndexInDX	; Return if floppy drive (HD bit not set)
	call	FloppyDrive_GetCountToAX
	and		dl, ~80h					; Clear HD bit
	add		dx, ax
.ReturnItemIndexInDX:
	ret


;--------------------------------------------------------------------
; Checks is drive number valid for this system.
;
; BootMenu_IsDriveInSystem
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set if drive number is valid
;				Clear if drive is not present in system
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_IsDriveInSystem:
	test	dl, dl								; Floppy drive?
	jns		SHORT .IsFloppyDriveInSystem
	call	RamVars_GetHardDiskCountFromBDAtoAX	; Hard Disk count to AX
	or		al, 80h								; Set Hard Disk bit to AX
	jmp		SHORT .CompareDriveNumberToDriveCount
.IsFloppyDriveInSystem:
	call	FloppyDrive_GetCountToAX
.CompareDriveNumberToDriveCount:
	cmp		dl, al								; Set CF when DL is smaller
	ret
