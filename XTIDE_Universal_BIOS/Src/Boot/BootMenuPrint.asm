; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for printing boot menu strings.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; BootMenuPrint_ClearScreen
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_ClearScreen:
	call	BootMenuPrint_InitializeDisplayContext
	xor		ax, ax
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	mov		ax, ' ' | (MONO_NORMAL<<8)
	CALL_DISPLAY_LIBRARY ClearScreenWithCharInALandAttrInAH
	ret


;--------------------------------------------------------------------
; BootMenuPrint_InitializeDisplayContext
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_InitializeDisplayContext:
	CALL_DISPLAY_LIBRARY InitializeDisplayContext
	ret


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
	call	BootMenuPrint_NullTerminatedStringFromCSSIandSetCF
	CALL_DISPLAY_LIBRARY PrintNewlineCharacters
	mov		si, ROMVARS.szVersion
	; Fall through to BootMenuPrint_NullTerminatedStringFromCSSIandSetCF


;--------------------------------------------------------------------
; BootMenuPrint_NullTerminatedStringFromCSSIandSetCF
;	Parameters:
;		CS:SI:	Ptr to NULL terminated string to print
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_NullTerminatedStringFromCSSIandSetCF:
	push	di
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromCSSI
	pop		di
	stc
	ret


;--------------------------------------------------------------------
; BootMenuPrint_FloppyMenuitem
;	Parameters:
;		DL:		Untranslated Floppy Drive number
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FloppyMenuitem:
	call	PrintDriveNumberAfterTranslationFromDL
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
	call	PrintDriveNumberAfterTranslationFromDL
	call	RamVars_IsDriveHandledByThisBIOS
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
	jmp		SHORT BootMenuPrint_NullTerminatedStringFromCSSIandSetCF


;--------------------------------------------------------------------
; PrintDriveNumberAfterTranslationFromDL
;	Parameters:
;		DL:		Untranslated Floppy Drive number
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrintDriveNumberAfterTranslationFromDL:
	mov		ax, dx
	call	DriveXlate_ToOrBack
	xchg	dx, ax				; Restore DX, WORD to print in AL
	xor		ah, ah
	push	bp
	mov		bp, sp
	mov		si, g_szDriveNum
	push	ax
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP


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
	call	RamVars_IsDriveHandledByThisBIOS
	jnc		SHORT .HardDiskMenuitemInfoForForeignDrive
	call	FindDPT_ForDriveNumber		; DS:DI to point DPT
	; Fall to .HardDiskMenuitemInfoForOurDrive

;--------------------------------------------------------------------
; .HardDiskMenuitemInfoForOurDrive
;	Parameters:
;		DL:		Untranslated Hard Disk number
;		DS:DI:	Ptr to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.HardDiskMenuitemInfoForOurDrive:
	push	di
	ePUSH_T	ax, BootMenuPrintCfg_ForOurDrive	; Return from BootMenuPrint_FormatCSSIfromParamsInSSBP
	push	bp
	mov		bp, sp
	ePUSH_T	ax, g_szCapacity

	; Get and push L-CHS size
	mov		[RAMVARS.wTimeoutCounter], dl		; Store drive number
	call	AH15h_GetSectorCountToDXAX
	call	ConvertSectorCountInBXDXAXtoSizeAndPushForFormat

	; Get and push total LBA size
	mov		dl, [RAMVARS.wTimeoutCounter]		; Restore drive number
	call	BootInfo_GetTotalSectorCount
	call	ConvertSectorCountInBXDXAXtoSizeAndPushForFormat

	mov		si, g_szSizeDual
	jmp		SHORT BootMenuPrint_FormatCSSIfromParamsInSSBP


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
	call	AH15h_GetSectorCountFromForeignDriveToDXAX
	call	ConvertSectorCountInBXDXAXtoSizeAndPushForFormat

	mov		si, g_szSizeSingle
	; Fall to BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; BootMenuPrint_FormatCSSIfromParamsInSSBP
;	Parameters:
;		CS:SI:	Ptr to string to format
;		BP:		SP before pushing parameters
;	Returns:
;		BP:		Popped from stack
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FormatCSSIfromParamsInSSBP:
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	stc				; Successfull return from menu event
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
; BootMenuPrint_TheBottomOfScreen
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_TheBottomOfScreen:
	call	FloppyDrive_GetCountToCX
	mov		bl, cl					; Floppy Drive count to BL
	call	RamVars_GetHardDiskCountFromBDAtoCX
	mov		bh, cl					; Hard Disk count to BH
	; Fall to .MoveCursorToHotkeyStrings

;--------------------------------------------------------------------
; .MoveCursorToHotkeyStrings
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
.MoveCursorToHotkeyStrings:
	CALL_DISPLAY_LIBRARY GetColumnsToALandRowsToAH
	xor		al, al
	dec		ah
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	; Fall to .PrintHotkeyString

;--------------------------------------------------------------------
; .PrintHotkeyString
;	Parameters:
;		BL:		Floppy Drives
;		BH:		Hard Drives
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
.PrintHotkeyString:
	; Display Library should not be called like this
	mov		si, ATTRIBUTE_CHARS.cHighlightedItem
	call	MenuAttribute_GetToAXfromTypeInSI
	xchg	dx, ax
	mov		cx, MONO_BRIGHT

	test	bl, bl		; Any Floppy Drives?
	jz		SHORT .SkipFloppyDriveHotkeys
	mov		ax, 'A' | (ANGLE_QUOTE_RIGHT<<8)
	mov		si, g_szFDD
	call	PushHotkeyParamsAndFormat

.SkipFloppyDriveHotkeys:
	test	bh, bh		; Any Hard Drives?
	jz		SHORT .SkipHardDriveHotkeys
	xchg	ax, cx		; Store Key Attribute
	call	BootMenu_GetLetterForFirstHardDiskToCL
	mov		ch, ANGLE_QUOTE_RIGHT
	xchg	ax, cx
	mov		si, g_szHDD
	call	PushHotkeyParamsAndFormat

.SkipHardDriveHotkeys:
	; Fall to .PrintRomBootHotkey

;--------------------------------------------------------------------
; .PrintRomBootHotkey
;	Parameters:
;		CX:		Key Attribute
;		DX:		Description Attribute
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
.PrintRomBootHotkey:
	mov		ax, 'F' | ('8'<<8)		; F8
	mov		si, g_szRomBoot
	; Fall to PushHotkeyParamsAndFormat

;--------------------------------------------------------------------
; PushHotkeyParamsAndFormat
;	Parameters:
;		AL:		First character
;		AH:		Second character
;		CX:		Key Attribute
;		DX:		Description Attribute
;		CS:SI:	Description string
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PushHotkeyParamsAndFormat:
	push	bp
	mov		bp, sp

	push	cx			; Key attribute
	push	ax			; First character
	xchg	al, ah
	push	ax			; Second character
	push	dx			; Description attribute
	push	si			; Description string
	push	cx			; Key attribute for last space
	mov		si, g_szHotkey
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP
