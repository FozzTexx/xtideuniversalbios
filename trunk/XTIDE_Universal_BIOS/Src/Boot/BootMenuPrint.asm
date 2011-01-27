; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for printing boot menu strings.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Prints Boot Menu title strings.
;
; BootMenuPrint_TitleStrings
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Set since menu event handled
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_TitleStrings:
	mov		si, ROMVARS.szTitle
	call	PrintNullTerminatedStringFromCSSIandSetCF
	call	BootMenuPrint_Newline
	mov		si, ROMVARS.szVersion
	jmp		PrintNullTerminatedStringFromCSSIandSetCF


;--------------------------------------------------------------------
; BootMenuPrint_Newline
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_Newline:
	CALL_DISPLAY_LIBRARY PrintNewlineCharacters
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
;		AX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FloppyHotkeyString:
	test	bl, bl					; Any floppy drives?
	jz		SHORT NoFloppyDrivesOrHardDisksToPrint
	push	bp

	mov		bp, sp
	mov		al, 'A'
	push	ax						; 'A'
	dec		ax
	add		al, bl
	push	ax						; Last floppy drive letter
	ePUSH_T	ax, g_szFDD
	ePUSH_T	ax, g_szHDD
	jmp		SHORT PrintHotkeyString

;--------------------------------------------------------------------
; Prints Hard Disk hotkey string.
;
; BootMenuPrint_FloppyHotkeyString
;	Parameters:
;		BH:		Number of hard disks in system
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskHotkeyString:
	test	bh, bh					; Any hard disks?
	jz		SHORT NoFloppyDrivesOrHardDisksToPrint
	push	bp

	mov		bp, sp
	call	BootMenu_GetLetterForFirstHardDisk
	push	cx						; First hard disk letter
	dec		cx
	add		cl, bh
	push	cx						; Last hard disk letter
	ePUSH_T	ax, g_szHDD
	ePUSH_T	ax, g_szFDD
	; Fall to PrintHotkeyString

ALIGN JUMP_ALIGN
PrintHotkeyString:
	mov		si, g_szBottomScrn
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP
NoFloppyDrivesOrHardDisksToPrint:
	ret

;--------------------------------------------------------------------
; BootMenuPrint_ClearScreen
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_ClearScreen:
	push	di
	mov		ax, ' ' | (MONO_NORMAL<<8)
	CALL_DISPLAY_LIBRARY ClearScreenWithCharInALandAttrInAH
	pop		di
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
	push	bx

	call	DriveXlate_ToOrBack
	eMOVZX	ax, dl		; Drive number to AL
	CALL_DISPLAY_LIBRARY PrintWordFromAXwithBaseInBX
	mov		al, ' '		; Print space
	CALL_DISPLAY_LIBRARY PrintCharacterFromAL

	pop		bx
	pop		dx
	ret


;--------------------------------------------------------------------
; BootMenuPrint_FloppyMenuitem
;	Parameters:
;		DL:		Untranslated Floppy Drive number
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FloppyMenuitem:
	push	bp

	mov		bp, sp
	mov		si, g_szFDLetter
	ePUSH_T	ax, g_szFloppyDrv
	add		dl, 'A'
	push	dx					; Drive letter
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; BootMenuPrint_HardDiskMenuitem
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set since menu event handled
;	Corrupts registers:
;		AX, BX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskMenuitem:
	call	FindDPT_ForDriveNumber		; DS:DI to point DPT
	jnc		SHORT .HardDiskMenuitemForForeignDrive
	; Fall to .HardDiskMenuitemForOurDrive

;--------------------------------------------------------------------
; .HardDiskMenuitemForOurDrive
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set since menu event handled
;	Corrupts registers:
;		AX, BX, SI, DI
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
.HardDiskMenuitemForOurDrive:
	call	BootInfo_GetOffsetToBX
	lea		si, [bx+BOOTNFO.szDrvName]
	xor		bx, bx			; BDA segment
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromBXSI
	stc
	ret

;--------------------------------------------------------------------
; BootMenuPrint_HardDiskMenuitemForForeignDrive
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set since menu event handled
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.HardDiskMenuitemForForeignDrive:
	mov		si, g_szforeignHD
	jmp		PrintNullTerminatedStringFromCSSIandSetCF


;--------------------------------------------------------------------
; BootMenuPrint_FunctionMenuitem
;	Parameters:
;		DX:		Function ID
;	Returns:
;		CF:		Set if menu event was handled successfully
;	Corrupts registers:
;		AX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FunctionMenuitem:
	test	dx, dx					; ID_BOOTFUNC_ROMBOOT
	jz		SHORT .PrintRomBootMenuitem
	ret

ALIGN JUMP_ALIGN
.PrintRomBootMenuitem:
	mov		si, g_szRomBoot
	jmp		PrintNullTerminatedStringFromCSSIandSetCF


;--------------------------------------------------------------------
; BootMenuPrint_FloppyMenuitemInformation
;	Parameters:
;		DL:		Untranslated Floppy Drive number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FloppyMenuitemInformation:
	call	BootMenuPrint_ClearInformationArea
	call	FloppyDrive_GetType			; Get Floppy Drive type to BX
	test	bx, bx						; Two possibilities? (FLOPPY_TYPE_525_OR_35_DD)
	jz		SHORT .PrintXTFloppyType
	cmp		bl, FLOPPY_TYPE_35_ED
	ja		SHORT .PrintUnknownFloppyType
	jmp		SHORT .PrintKnownFloppyType

;--------------------------------------------------------------------
; .PrintXTFloppyType
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.PrintXTFloppyType:
	push	bp
	mov		si, g_szFddSizeOr
	jmp		SHORT .FormatXTorUnknownTypeFloppyDrive

;--------------------------------------------------------------------
; .PrintUnknownFloppyType
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.PrintUnknownFloppyType:
	push	bp
	mov		si, g_szFddUnknown
.FormatXTorUnknownTypeFloppyDrive:
	mov		bp, sp
	ePUSH_T	ax, g_szCapacity
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP

;--------------------------------------------------------------------
; .PrintKnownFloppyType
;	Parameters:
;		BX:		Floppy drive type
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, BX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.PrintKnownFloppyType:
	push	bp

	mov		bp, sp
	mov		si, g_szFddSize
	ePUSH_T	ax, g_szCapacity
	dec		bx						; Cannot be 0 (FLOPPY_TYPE_525_OR_35_DD)
	shl		bx, 1					; Shift for WORD lookup
	mov		ax, [cs:bx+.rgwPhysicalSize]
	push	ax						; '5' or '3'
	mov		al, ah
	push	ax						; '1/4' or '1/2'
	push	WORD [cs:bx+.rgwCapacity]
	jmp		SHORT BootMenuPrint_FormatCSSIfromParamsInSSBP

ALIGN WORD_ALIGN
.rgwCapacity:
	dw		360
	dw		1200
	dw		720
	dw		1440
	dw		2880
	dw		2880
.rgwPhysicalSize:
	db		'5', 172	; 1, FLOPPY_TYPE_525_DD
	db		'5', 172	; 2, FLOPPY_TYPE_525_HD
	db		'3', 171	; 3, FLOPPY_TYPE_35_DD
	db		'3', 171	; 4, FLOPPY_TYPE_35_HD
	db		'3', 171	; 5, 3.5" ED on some BIOSes
	db		'3', 171	; 6, FLOPPY_TYPE_35_ED


;--------------------------------------------------------------------
; Prints Hard Disk Menuitem information strings.
;
; BootMenuPrint_HardDiskMenuitemInformation
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		BX, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskMenuitemInformation:
	call	FindDPT_ForDriveNumber		; DS:DI to point DPT
	jnc		SHORT .HardDiskMenuitemInfoForForeignDrive
	call	.HardDiskMenuitemInfoSizeForOurDrive
	jmp		BootMenuPrintCfg_ForOurDrive

;--------------------------------------------------------------------
; .HardDiskMenuitemInfoForForeignDrive
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.HardDiskMenuitemInfoForForeignDrive:
	push	bp
	mov		bp, sp
	ePUSH_T	ax, g_szCapacity

	call	DriveXlate_ToOrBack
	call	HCapacity_GetSectorCountFromForeignAH08h
	call	ConvertSectorCountInBXDXAXtoSizeAndPushForFormat

	mov		si, g_szSizeSingle
	jmp		SHORT BootMenuPrint_FormatCSSIfromParamsInSSBP

;--------------------------------------------------------------------
; .HardDiskMenuitemInfoSizeForOurDrive
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:DI:	Ptr to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.HardDiskMenuitemInfoSizeForOurDrive:
	push	bp
	mov		bp, sp
	ePUSH_T	ax, g_szCapacity

	; Get and push L-CHS size
	call	HCapacity_GetSectorCountFromOurAH08h
	call	ConvertSectorCountInBXDXAXtoSizeAndPushForFormat

	; Get and push total LBA size
	call	BootInfo_GetTotalSectorCount
	call	ConvertSectorCountInBXDXAXtoSizeAndPushForFormat

	mov		si, g_szSizeDual
	; Fall to BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; BootMenuPrint_FormatCSSIfromParamsInSSBP
;	Parameters:
;		CS:SI:	Ptr to string to format
;		SS:BP:	Ptr to format parameters
;	Returns:
;		BP:		Popped from stack
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FormatCSSIfromParamsInSSBP:
	push	di
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	stc				; Successfull return from menu event
	pop		di
	pop		bp
	ret


;--------------------------------------------------------------------
; ConvertSectorCountInBXDXAXtoSizeAndPushForFormat
;	Parameters:
;		BX:DX:AX:	Sector count
;	Returns:
;		Size in stack
;	Corrupts registers:
;		AX, BX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConvertSectorCountInBXDXAXtoSizeAndPushForFormat:
	pop		si		; Pop return address
	call	Size_ConvertSectorCountInBXDXAXtoKiB
	mov		cx, BYTE_MULTIPLES.kiB
	call	Size_GetSizeToAXAndCharToDLfromBXDXAXwithMagnitudeInCX
	push	ax		; Size in magnitude
	push	cx		; Tenths
	push	dx		; Magnitude character
	jmp		si


;--------------------------------------------------------------------
; PrintNullTerminatedStringFromCSSIandSetCF
;	Parameters:
;		CS:SI:	Ptr to NULL terminated string to print
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrintNullTerminatedStringFromCSSIandSetCF:
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromCSSI
	stc
	ret


;--------------------------------------------------------------------
; BootMenuPrint_ClearInformationArea
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Set
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_ClearInformationArea:
	CALL_MENU_LIBRARY ClearInformationArea
	stc
	ret


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
	call	RamVars_GetHardDiskCountFromBDAtoCX
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
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_GetCoordinatesForBottomStrings:
	mov		dx, 1800h				; (0, 24)
	cmp		dl, bl					; Set CF if any floppy drives
	sbb		dh, dl					; Decrement Y-coordinate if necessary
	cmp		dl, bh					; Set CF if any hard disks
	sbb		dh, dl					; Decrement Y-coordinate if necessary
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
	push	di
	mov		ax, dx
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	pop		di
	ret
