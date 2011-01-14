; File name		:	BootMenu.asm
; Project name	:	IDE BIOS
; Created date	:	25.3.2010
; Last update	:	14.1.2011
; Author		:	Tomi Tilli,
;				:	Krister Nordvall (optimizations)
; Description	:	Displays Boot Menu.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Displays Boot Menu and returns Drive or Function number.
;
; BootMenu_DisplayAndReturnSelection
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DX:		Untranslated drive number to be used for booting (if CF cleared)
;				Function number (if CF set)
;		CF:		Cleared if drive selected
;				Set if function selected
;	Corrupts registers:
;		All General Purpose Registers
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_DisplayAndReturnSelection:
	call	DriveXlate_Reset
	call	BootMenuPrint_TheBottomOfScreen
	call	BootMenu_GetMenuitemCount
	mov		di, BootMenuEvent_Handler
	call	BootMenu_Enter			; Get selected menuitem index to CX
	call	BootMenuPrint_ClearScreen
	test	cx, cx					; -1 if nothing selected (ESC pressed)
	js		SHORT BootMenu_DisplayAndReturnSelection
	call	BootMenu_CheckAndConvertHotkeyToMenuitem
	jc		SHORT .SetDriveTranslationForHotkey
	jmp		BootMenu_ConvertMenuitemToDriveOrFunction
ALIGN JUMP_ALIGN
.SetDriveTranslationForHotkey:
	call	BootMenu_ConvertMenuitemToDriveOrFunction
	call	DriveXlate_SetDriveToSwap
	clc
	ret


;--------------------------------------------------------------------
; Returns number of menuitems in Boot Menu.
;
; BootMenu_GetMenuitemCount
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		CX:		Number of boot menu items
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetMenuitemCount:
	call	RamVars_GetHardDiskCountFromBDAtoCX
	xchg	ax, cx
	call	FloppyDrive_GetCount
	add		ax, cx
	call	BootMenu_GetMenuFunctionCount
	add		cx, ax
	ret

;--------------------------------------------------------------------
; Returns number of functions displayed in Boot Menu.
;
; BootMenu_GetMenuFunctionCount
;	Parameters:
;		Nothing
;	Returns:
;		CX:		Number of boot menu functions
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetMenuFunctionCount:
	xor		cx, cx
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_ROMBOOT
	jz		SHORT .DontIncludeRomBoot
	inc		cx
ALIGN JUMP_ALIGN
.DontIncludeRomBoot:
	ret


;--------------------------------------------------------------------
; Enters Boot Menu or submenu.
;
; BootMenu_Enter
;	Parameters:
;		CX:		Number of menuitems in menu
;		DS:SI:	User specific far pointer
;		CS:DI:	Pointer to menu event handler function
;	Returns:
;		CX:		Index of last pointed Menuitem (not necessary selected with ENTER)
;				FFFFh if cancelled with ESC
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_Enter:
	call	BootMenu_GetSelectionTimeout
	call	BootMenu_GetSize
	MIN_U	ah, [cs:ROMVARS.bBootMnuH]		; Limit to max height
	jmp		Menu_Enter

;--------------------------------------------------------------------
; Returns Boot Menu selection timeout in milliseconds.
;
; BootMenu_GetSelectionTimeout
;	Parameters:
;		Nothing
;	Returns:
;		DX:		Selection timeout in millisecs
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetSelectionTimeout:
	mov		ax, 1000			; Seconds to milliseconds
	eMOVZX	dx, BYTE [cs:ROMVARS.bBootDelay]
	mul		dx					; AX = seconds * milliseconds_per_second
	xchg	ax, dx				; DX = Timeout in millisecs
	ret

;--------------------------------------------------------------------
; Returns Boot Menu size.
;
; BootMenu_GetSize
;	Parameters:
;		Nothing
;	Returns:
;		AL:		Menu width with borders included (characters)
;		AH:		Menu height with borders included (characters)
;		BL:		Title line count
;		BH:		Info line count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetSize:
	mov		al, MENU_WIDTH_IN_CHARS
	mov		ah, cl						; Copy menuitem count to AH
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_DRVNFO
	jz		SHORT .GetHeightWithoutInfoArea
;.GetHeightWithInfoArea:
	add		ah, MENU_HEIGHT_IN_CHARS_WITH_INFO
	mov		bx, (MENU_INFO_LINE_CNT<<8) | MENU_TITLE_LINE_CNT
	ret
ALIGN JUMP_ALIGN
.GetHeightWithoutInfoArea:
	add		ah, MENU_HEIGHT_IN_CHARS_WITHOUT_INFO
	mov		bx, MENU_TITLE_LINE_CNT
	ret


;--------------------------------------------------------------------
; Checks if hotkey has been pressed on Boot Menu.
; If it has been, it will be converted to menuitem index.
;
; BootMenu_CheckAndConvertHotkeyToMenuitem
;	Parameters:
;		CX:		Menuitem index (if no hotkey)
;	Returns:
;		CX:		Menuitem index
;		CF:		Set if hotkey has been pressed
;				Cleared if no hotkey selection
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_CheckAndConvertHotkeyToMenuitem:
	push	es
	LOAD_BDA_SEGMENT_TO	es, ax				; Zero AX
	xchg	al, [es:BOOTVARS.bMenuHotkey]	; Load and clear hotkey
	test	al, al							; No hotkey? (clears CF)
	jz		SHORT .Return
	call	BootMenu_ConvertHotkeyToMenuitem
	stc
ALIGN JUMP_ALIGN
.Return:
	pop		es
	ret

;--------------------------------------------------------------------
; Converts any hotkey to Boot Menu menuitem index.
;
; BootMenu_ConvertHotkeyToMenuitem
;	Parameters:
;		AX:		ASCII hotkey starting from upper case 'A'
;	Returns:
;		CX:		Menuitem index
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_ConvertHotkeyToMenuitem:
	call	BootMenu_GetLetterForFirstHardDisk
	cmp		al, cl						; Letter is for Hard Disk?
	jae		SHORT .StartFromHardDiskLetter
	sub		al, 'A'						; Letter to Floppy Drive menuitem
	xchg	ax, cx						; Menuitem index to CX
	ret
ALIGN JUMP_ALIGN
.StartFromHardDiskLetter:
	sub		al, cl						; Hard Disk index
	call	FloppyDrive_GetCount
	add		cx, ax						; Menuitem index
	ret

;--------------------------------------------------------------------
; Returns letter for first hard disk. Usually it will be 'c' but it
; can be higher if more than two floppy drives are found.
;
; BootMenu_GetLetterForFirstHardDisk
;	Parameters:
;		Nothing
;	Returns:
;		CL:		Upper case letter for first hard disk
;	Corrupts registers:
;		CH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_GetLetterForFirstHardDisk:
	call	FloppyDrive_GetCount
	add		cl, 'A'
	MAX_U	cl, 'C'
	ret


;--------------------------------------------------------------------
; Converts selected menuitem index to drive number or function ID.
;
; BootMenu_ConvertMenuitemToDriveOrFunction
;	Parameters:
;		CX:		Index of menuitem selected from Boot Menu
;		DS:		RAMVARS segment
;	Returns:
;		DX:		Drive number to be used for booting (if CF cleared)
;				Function ID (if CF set)
;		CF:		Cleared if drive selected
;				Set if function selected
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_ConvertMenuitemToDriveOrFunction:
	mov		dx, cx					; Copy menuitem index to DX
	call	FloppyDrive_GetCount
	cmp		dx, cx					; Floppy drive?
	jb		SHORT .ReturnFloppyDriveInDX
	sub		dx, cx					; Remove floppy drives from index
	call	RamVars_GetHardDiskCountFromBDAtoCX
	cmp		dx, cx					; Hard disk?
	jb		SHORT .ReturnHardDiskInDX
	sub		dx, cx					; Remove hard disks from index
	jmp		SHORT BootMenu_ConvertFunctionIndexToID
ALIGN JUMP_ALIGN
.ReturnHardDiskInDX:
	or		dl, 80h
ALIGN JUMP_ALIGN
.ReturnFloppyDriveInDX:
	clc
	ret


;--------------------------------------------------------------------
; Converts selected menuitem index to drive number or function ID.
;
; BootMenu_ConvertFunctionIndexToID
;	Parameters:
;		CX:		Menuitem index
;		DX:		Function index (Menuitem index - floppy count - HD count)
;	Returns:
;		DX:		Function ID
;		CF:		Set to indicate function
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_ConvertFunctionIndexToID:
	mov		dx, ID_BOOTFUNC_ROMBOOT
	stc
	ret


;--------------------------------------------------------------------
; Converts Floppy or Hard Disk Drive number to menuitem index.
; This function does not check does the drive really exists.
;
; BootMenu_ConvertDriveToMenuitem
;	Parameters:
;		DL:		Drive number
;	Returns:
;		CX:		Menuitem index (assuming drive is available)
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenu_ConvertDriveToMenuitem:
	test	dl, 80h					; Floppy drive?
	jz		SHORT .ReturnFloppyMenuitem
	call	FloppyDrive_GetCount
	mov		ax, 7Fh					; Load mask to clear floppy bit
	and		ax, dx					; AX = Hard Disk index
	add		cx, ax					; Add hard disk index to floppy drive count
	ret
ALIGN JUMP_ALIGN
.ReturnFloppyMenuitem:
	eMOVZX	cx, dl					; Drive number and item index are equal
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
	test	dl, 80h								; Floppy drive?
	jz		SHORT .IsFloppyDriveIsInSystem
	call	RamVars_GetHardDiskCountFromBDAtoCX	; Hard Disk count to CX
	or		cl, 80h								; Set Hard Disk bit to CX
	jmp		SHORT .CompareDriveNumberToDriveCount
.IsFloppyDriveIsInSystem:
	call	FloppyDrive_GetCount				; Floppy Drive count to CX
.CompareDriveNumberToDriveCount:
	cmp		dl, cl
	ret
