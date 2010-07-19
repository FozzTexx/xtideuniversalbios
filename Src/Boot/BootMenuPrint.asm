; File name		:	BootMenuPrint.asm
; Project name	:	IDE BIOS
; Created date	:	26.3.2010
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions for printing boot menu strings.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Prints information strings to the bottom of the screen.
;
; BootMenuPrint_TheBottomOfScreen
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_TheBottomOfScreen:
	call	FloppyDrive_GetCount
	mov		bl, cl					; Floppy Drive count to BL
	call	RamVars_GetDriveCounts
	mov		bh, cl					; Hard Disk count to BH
	call	BootMenuPrint_GetCoordinatesForBottomStrings
	call	BootMenuPrint_SetCursorPosition
	call	BootMenuPrint_FloppyHotkeyString
	jmp		BootMenuPrint_HardDiskHotkeyString


;--------------------------------------------------------------------
; Returns coordinates for bottom strings.
;
; BootMenuPrint_GetCoordinatesForBottomStrings
;	Parameters:
;		BL:		Number of floppy drives in system
;		BH:		Number of hard disks in system
;	Returns:
;		DL:		Cursor X coordinate
;		DH:		Cursor Y coordinate
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_GetCoordinatesForBottomStrings:
	mov		dx, 1800h				; (0, 24)
	xor		ax, ax					; Zero AX
	sub		al, bl					; Set CF if any floppy drives
	sbb		dh, 0					; Decrement Y-coordinate if necessary
	sub		ah, bh					; Set CF if any hard disks
	sbb		dh, 0					; Decrement Y-coordinate if necessary
	ret


;--------------------------------------------------------------------
; Sets cursor to wanted screen coordinates.
;
; BootMenuPrint_SetCursorPosition
;	Parameters:
;		DL:		Cursor X coordinate
;		DH:		Cursor Y coordinate
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_SetCursorPosition:
	push	bx
	call	MenuCrsr_SetCursor
	pop		bx
	ret


;--------------------------------------------------------------------
; Prints Floppy Drive hotkey string.
;
; BootMenuPrint_FloppyHotkeyString
;	Parameters:
;		BL:		Number of floppy drives in system
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FloppyHotkeyString:
	test	bl, bl					; Any floppy drives?
	jz		.Return
	ePUSH_T	ax, g_szHDD
	ePUSH_T	ax, g_szFDD
	mov		ax, 'A'-1
	add		al, bl					; Last Floppy Drive letter
	push	ax
	ePUSH_T	ax, 'A'
	jmp		SHORT BootMenuPrint_HotkeyString
.Return:
	ret

;--------------------------------------------------------------------
; Prints Floppy Drive or Hard Disk hotkey string when
; parameters are pushed to stack.
;
; BootMenuPrint_HotkeyString
;	Parameters:
;		Stack:	String formatting parameters
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HotkeyString:
	mov		si, g_szBottomScrn
	mov		dh, 8					; 8 bytes pushed to stack
	jmp		PrintString_JumpToFormat


;--------------------------------------------------------------------
; Prints Hard Disk hotkey string.
;
; BootMenuPrint_FloppyHotkeyString
;	Parameters:
;		BH:		Number of hard disks in system
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskHotkeyString:
	test	bh, bh					; Any hard disks?
	jz		.Return
	ePUSH_T	ax, g_szFDD
	ePUSH_T	ax, g_szHDD
	call	BootMenu_GetLetterForFirstHardDisk
	eMOVZX	ax, bh					; Hard disk count to AX
	add		ax, cx					; One past last hard disk letter
	dec		ax						; Last hard disk letter
	push	ax
	push	cx
	jmp		SHORT BootMenuPrint_HotkeyString
.Return:
	ret


;--------------------------------------------------------------------
; Clears screen.
;
; BootMenuPrint_ClearScreen
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_ClearScreen:
	push	cx
	call	MenuDraw_ClrScr
	pop		cx
	ret


;--------------------------------------------------------------------
; Translates and prints drive number.
;
; BootMenuPrint_TranslatedDriveNumber
;	Parameters:
;		DL:		Untranslated drive number
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_TranslatedDriveNumber:
	push	dx
	call	DriveXlate_ToOrBack
	mov		al, dl						; Drive number to AL
	call	Print_IntHexB
	mov		dl, ' '
	PRINT_CHAR							; Print space
	pop		dx
	ret


;--------------------------------------------------------------------
; Prints Floppy Drive Menuitem string.
;
; BootMenuPrint_FloppyMenuitem
;	Parameters:
;		DL:		Untranslated Floppy Drive number
;	Returns:
;		AX:		1 if drive number was valid
;				0 if drive number was invalid
;	Corrupts registers:
;		CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FloppyMenuitem:
	ePUSH_T	ax, BootMenuPrint_HardDiskPrinted	; Return address
	add		dl, 'A'				; Number to letter
	push	dx
	ePUSH_T	ax, g_szFloppyDrv
	mov		si, g_szFDLetter
	mov		dh, 4				; 4 bytes pushed to stack
	jmp		PrintString_JumpToFormat


;--------------------------------------------------------------------
; Prints Hard Disk Menuitem string.
;
; BootMenuPrint_HardDiskMenuitem
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:		RAMVARS segment
;	Returns:
;		AX:		1 if drive number was valid
;				0 if drive number was invalid
;	Corrupts registers:
;		CX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskMenuitem:
	ePUSH_T	ax, BootMenuPrint_HardDiskPrinted
	call	FindDPT_ForDriveNumber		; DS:DI to point DPT
	jnc		SHORT BootMenuPrint_HardDiskMenuitemForForeignDrive
	jmp		SHORT BootMenuPrint_HardDiskMenuitemForOurDrive
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskPrinted:
	mov		ax, 1
	ret

;--------------------------------------------------------------------
; Prints Hard Disk Menuitem string for drive that is handled by
; some another BIOS.
;
; BootMenuPrint_HardDiskMenuitemForForeignDrive
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:		RAMVARS segment
;	Returns:
;		AX:		1 if drive number was valid
;				0 if drive number was invalid
;	Corrupts registers:
;		CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskMenuitemForForeignDrive:
	mov		si, g_szforeignHD
	jmp		PrintString_FromCS

;--------------------------------------------------------------------
; Prints Hard Disk Menuitem string for drive that is handled by our BIOS.
;
; BootMenuPrint_HardDiskMenuitemForOurDrive
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:		RAMVARS segment
;	Returns:
;		AX:		1 if drive number was valid
;				0 if drive number was invalid
;	Corrupts registers:
;		CX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskMenuitemForOurDrive:
	call	BootInfo_GetOffsetToBX
	LOAD_BDA_SEGMENT_TO	es, ax
	lea		si, [bx+BOOTNFO.szDrvName]
	jmp		PrintString_FromES


;--------------------------------------------------------------------
; Prints Function Menuitem string.
;
; BootMenuPrint_FunctionMenuitem
;	Parameters:
;		DX:		Function ID
;	Returns:
;		AX:		1 if function ID was valid
;				0 if function ID was invalid
;	Corrupts registers:
;		DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FunctionMenuitem:
	test	dx, dx					; ID_BOOTFUNC_ROMBOOT
	jz		SHORT .PrintRomBootMenuitem
	xor		ax, ax					; Event not processed
	ret

ALIGN JUMP_ALIGN
.PrintRomBootMenuitem:
	mov		si, g_szRomBoot
	; Fall to .PrintAndReturn

ALIGN JUMP_ALIGN
.PrintAndReturn:
	call	PrintString_FromCS
	mov		ax, 1					; Event processed
	ret


;--------------------------------------------------------------------
; Prints Floppy Drive Menuitem information strings.
;
; BootMenuPrint_FloppyMenuitemInformation
;	Parameters:
;		DL:		Untranslated Floppy Drive number
;		DS:		RAMVARS segment
;	Returns:
;		AX:		1 if drive number was valid
;				0 if drive number was invalid
;	Corrupts registers:
;		BX, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FloppyMenuitemInformation:
	call	FloppyDrive_GetType						; Get Floppy Drive type to BX
	ePUSH_T	ax, BootMenuPrint_ClearThreeInfoLines	; New return address
	test	bx, bx									; Two possibilities? (FLOPPY_TYPE_525_OR_35_DD)
	jz		SHORT BootMenuPrint_PrintXTFloppyType
	cmp		bl, FLOPPY_TYPE_35_ED
	ja		SHORT BootMenuPrint_PrintUnknownFloppyType
	jmp		SHORT BootMenuPrint_PrintKnownFloppyType

;--------------------------------------------------------------------
; Prints Menuitem information string for two possible XT floppy drives.
;
; BootMenuPrint_PrintXTFloppyType
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_PrintXTFloppyType:
	mov		si, g_szFddSizeOr
	jmp		SHORT BootMenuPrint_FormatUnknownFloppyType

;--------------------------------------------------------------------
; Prints Menuitem information string for unknown floppy drive type.
;
; BootMenuPrint_PrintUnknownFloppyType
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_PrintUnknownFloppyType:
	mov		si, g_szFddUnknown
BootMenuPrint_FormatUnknownFloppyType:
	ePUSH_T	ax, g_szCapacity
	mov		dh, 2					; 2 bytes pushed to stack
	jmp		PrintString_JumpToFormat

;--------------------------------------------------------------------
; Prints Menuitem information string for known floppy drive type.
;
; BootMenuPrint_PrintKnownFloppyType
;	Parameters:
;		BX:		Floppy drive type
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_PrintKnownFloppyType:
	dec		bx						; Cannot be 0 (FLOPPY_TYPE_525_OR_35_DD)
	shl		bx, 1					; Shift for WORD lookup
	push	WORD [cs:bx+.rgwCapacity]
	mov		ax, [cs:bx+.rgwPhysicalSize]
	push	ax						; '1/4' or '1/2'
	mov		al, ah
	push	ax						; '5' or '3'
	ePUSH_T	ax, g_szCapacity
	mov		si, g_szFddSize
	mov		dh, 8					; 8 bytes pushed to stack
	jmp		PrintString_JumpToFormat
ALIGN WORD_ALIGN
.rgwCapacity:
	dw		360
	dw		1200
	dw		720
	dw		1440
	dw		2880
	dw		2880
.rgwPhysicalSize:
	db		172, '5'	; 1, FLOPPY_TYPE_525_DD
	db		172, '5'	; 2, FLOPPY_TYPE_525_HD
	db		171, '3'	; 3, FLOPPY_TYPE_35_DD
	db		171, '3'	; 4, FLOPPY_TYPE_35_HD
	db		171, '3'	; 5, 3.5" ED on some BIOSes
	db		171, '3'	; 6, FLOPPY_TYPE_35_ED


;--------------------------------------------------------------------
; Clears remaining characters from current information line
; and clears following lines.
;
; BootMenuPrint_ClearThreeInfoLines
; BootMenuPrint_ClearTwoInfoLines
; BootMenuPrint_ClearOneInfoLine
;	Parameters:
;		Nothing
;	Returns:
;		AX:		1
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_ClearThreeInfoLines:
	call	MenuDraw_NewlineStrClrLn
ALIGN JUMP_ALIGN
BootMenuPrint_ClearTwoInfoLines:
	call	MenuDraw_NewlineStrClrLn
ALIGN JUMP_ALIGN
BootMenuPrint_ClearOneInfoLine:
	call	MenuDraw_NewlineStrClrLn
	mov		ax, 1
	ret


;--------------------------------------------------------------------
; Prints Hard Disk Menuitem information strings.
;
; BootMenuPrint_HardDiskMenuitemInformation
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:		RAMVARS segment
;	Returns:
;		AX:		1 if drive number was valid
;				0 if drive number was invalid
;	Corrupts registers:
;		BX, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskMenuitemInformation:
	ePUSH_T	ax, BootMenuPrint_HardDiskPrinted
	call	FindDPT_ForDriveNumber		; DS:DI to point DPT
	jnc		SHORT BootMenuPrint_HardDiskMenuitemInfoForForeignDrive
	call	BootMenuPrint_HardDiskMenuitemInfoSizeForOurDrive
	jmp		BootMenuPrintCfg_ForOurDrive

;--------------------------------------------------------------------
; Prints Hard Disk Menuitem information strings for drive that
; is handled by some other BIOS.
;
; BootMenuPrint_HardDiskMenuitemInfoForForeignDrive
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskMenuitemInfoForForeignDrive:
	call	DriveXlate_ToOrBack
	call	HCapacity_GetSectorCountFromForeignAH08h
	call	HCapacity_ConvertSectorCountToSize
	ePUSH_T	dx, BootMenuPrint_ClearThreeInfoLines	; Return address
	push	cx							; Magnitude character
	push	si							; Tenths
	push	ax							; Size in magnitude
	ePUSH_T	ax, g_szCapacity			; "Capacity"
	mov		si, g_szSizeSingle
	mov		dh, 8						; 8 bytes pushed to stack
	jmp		PrintString_JumpToFormat

;--------------------------------------------------------------------
; Prints Hard Disk Menuitem information size string for drive that
; is handled by our BIOS.
;
; BootMenuPrint_HardDiskMenuitemInfoSizeForOurDrive
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:DI:	Ptr to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskMenuitemInfoSizeForOurDrive:
	ePUSH_T	ax, BootMenuPrint_ClearOneInfoLine	; Return address

	; Get and push total LBA size
	call	BootInfo_GetTotalSectorCount
	call	HCapacity_ConvertSectorCountToSize
	push	cx								; Magnitude character
	push	si								; Tenths
	push	ax								; Size in magnitude

	; Get and push L-CHS size
	mov		dl, [di+DPT.bDrvNum]			; Restore drive number
	call	HCapacity_GetSectorCountFromOurAH08h
	call	HCapacity_ConvertSectorCountToSize
	push	cx								; Magnitude character
	push	si								; Tenths
	push	ax								; Size in magnitude

	ePUSH_T	ax, g_szCapacity				; "Capacity"
	mov		si, g_szSizeDual
	mov		dh, 14							; 14 bytes pushed to stack
	jmp		PrintString_JumpToFormat


;--------------------------------------------------------------------
; Prints Function Menuitem information strings.
;
; BootMenuPrint_HardDiskMenuitemInformation
;	Parameters:
;		DX:		Function ID
;		DS:		RAMVARS segment
;	Returns:
;		AX:		1 if function ID was valid
;				0 if function ID was valid
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FunctionMenuitemInformation:
	jmp		SHORT BootMenuPrint_ClearThreeInfoLines


;--------------------------------------------------------------------
; Prints Boot Menu title strings.
;
; BootMenuPrint_TitleStrings
;	Parameters:
;		Nothing
;	Returns:
;		AX:		Was printing successfull
;	Corrupts registers:
;		BX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_TitleStrings:
	mov		si, ROMVARS.szTitle
	call	PrintString_FromCS
	call	BootMenuPrint_ClearOneInfoLine
	mov		si, ROMVARS.szVersion
	call	PrintString_FromCS
	call	BootMenuPrint_ClearOneInfoLine
	mov		si, g_szTitleLn3
	call	PrintString_FromCS
	jmp		SHORT BootMenuPrint_ClearOneInfoLine
