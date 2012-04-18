; Project name	:	XTIDE Universal BIOS
; Description	:	Hotkey Bar related functions.

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
; HotkeyBar_UpdateDuringDriveDetection
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
HotkeyBar_UpdateDuringDriveDetection:
	call	ScanHotkeysFromKeyBufferAndStoreToBootvars
	; Fall to HotkeyBar_DrawToTopOfScreen


;--------------------------------------------------------------------
; HotkeyBar_DrawToTopOfScreen
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
HotkeyBar_DrawToTopOfScreen:
	; Store current screen coordinates to be restored
	; when Hotkey Bar is rendered
	call	DetectPrint_GetSoftwareCoordinatesToAX
	push	ax

	call	MoveCursorToScreenTopLeftCorner
	; Fall to .PrintFloppyDriveHotkeys

;--------------------------------------------------------------------
; .PrintFloppyDriveHotkeys
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
.PrintFloppyDriveHotkeys:
	call	FloppyDrive_GetCountToAX
	test	ax, ax		; Any Floppy Drives?
	jz		SHORT .SkipFloppyDriveHotkeys

	mov		di, DEFAULT_FLOPPY_DRIVE_LETTER | (ANGLE_QUOTE_RIGHT<<8)
	mov		cl, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.bFddLetter]
	mov		si, g_szFDD
	call	FormatDriveHotkeyString

.SkipFloppyDriveHotkeys:
	; Fall to .PrintHardDriveHotkeys

;--------------------------------------------------------------------
; .PrintHardDriveHotkeys
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
	call	HotkeyBar_GetLetterForFirstHardDriveToAX
	mov		ah, ANGLE_QUOTE_RIGHT
	xchg	di, ax
	mov		cl, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.bHddLetter]
	mov		si, g_szHDD
	call	FormatDriveHotkeyString
	; Fall to .PrintBootMenuHotkey

;--------------------------------------------------------------------
; .PrintBootMenuHotkey
;	Parameters:
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
.PrintBootMenuHotkey:
%ifdef MODULE_BOOT_MENU
	mov		ah, BOOT_MENU_HOTKEY_SCANCODE
	mov		di, 'F' | ('2'<<8)		; F2
	mov		si, g_szBootMenu
	call	FormatFunctionHotkeyString
%endif
	; Fall to .PrintRomBootHotkey

;--------------------------------------------------------------------
; .PrintRomBootHotkey
;	Parameters:
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
.PrintRomBootHotkey:
	mov		ah, ROM_BOOT_HOTKEY_SCANCODE
	mov		di, 'F' | ('8'<<8)		; F8
	mov		si, g_szRomBoot
	call	FormatFunctionHotkeyString
	; Fall to .EndHotkeyBarRendering

;--------------------------------------------------------------------
; .EndHotkeyBarRendering
;	Parameters:
;		Stack:	Screen coordinates before drawing Hotkey Bar
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DI
;--------------------------------------------------------------------
.EndHotkeyBarRendering:
	call	HotkeyBar_ClearRestOfTopRow
	pop		ax
	jmp		SHORT HotkeyBar_RestoreCursorCoordinatesFromAX


;--------------------------------------------------------------------
; HotkeyBar_ClearRestOfTopRow
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DI
;--------------------------------------------------------------------
HotkeyBar_ClearRestOfTopRow:
	CALL_DISPLAY_LIBRARY	GetColumnsToALandRowsToAH
	eMOVZX	cx, al
	CALL_DISPLAY_LIBRARY	GetSoftwareCoordinatesToAX
	sub		cl, al
	mov		al, ' '
	CALL_DISPLAY_LIBRARY	PrintRepeatedCharacterFromALwithCountInCX
	ret


;--------------------------------------------------------------------
; FormatDriveHotkeyString
;	Parameters:
;		CL:			Drive letter hotkey from BOOTVARS
;		DI low:		First character for drive key string
;		DI high:	Second character for drive key string (ANGLE_QUOTE_RIGHT)
;		SI:			Offset to hotkey description string
;		ES:			BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
FormatDriveHotkeyString:
	ePUSH_T	ax, PushHotkeyParamsAndFormat
	jmp		SHORT GetNonSelectedHotkeyDescriptionAttributeToDX


;--------------------------------------------------------------------
; FormatFunctionHotkeyString
;	Parameters:
;		AH:			Hotkey scancode to compare with BOOTVARS.hotkeyVars+HOTKEYVARS.bScancode
;		SI:			Offset to hotkey description string
;		DI low:		First character for drive key string
;		DI high:	Second character for drive key string
;		ES:			BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
FormatFunctionHotkeyString:
	ePUSH_T	ax, PushHotkeyParamsAndFormat
	mov		cx, g_szBoot		; Description parameter string
	cmp		[es:BOOTVARS.hotkeyVars+HOTKEYVARS.bScancode], ah
	jne		SHORT GetNonSelectedHotkeyDescriptionAttributeToDX
	; Fall to GetSelectedHotkeyDescriptionAttributeToDX


;--------------------------------------------------------------------
; GetSelectedHotkeyDescriptionAttributeToDX
; GetNonSelectedHotkeyDescriptionAttributeToDX
;	Parameters:
;		CF:		Set if selected hotkey
;				Cleared if unselected hotkey
;	Returns:
;		DX:		Description Attribute
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef MODULE_BOOT_MENU
GetSelectedHotkeyDescriptionAttributeToDX:
	push	si
	mov		si, ATTRIBUTE_CHARS.cHurryTimeout		; Selected hotkey
	jmp		SHORT GetDescriptionAttributeToDX

GetNonSelectedHotkeyDescriptionAttributeToDX:
	push	si
	mov		si, ATTRIBUTE_CHARS.cHighlightedItem	; Unselected hotkey

	; Display Library should not be called like this
GetDescriptionAttributeToDX:
	call	MenuAttribute_GetToAXfromTypeInSI
	pop		si
	xchg	dx, ax					; DX = Description attribute
	ret

%else	; No boot menu so use simpler attributes

GetSelectedHotkeyDescriptionAttributeToDX:
	mov		dl, MONO_REVERSE_BLINK
	ret

GetNonSelectedHotkeyDescriptionAttributeToDX:
	mov		dl, MONO_REVERSE
	ret
%endif


;--------------------------------------------------------------------
; PushHotkeyParamsAndFormat
;	Parameters:
;		DI low:		First character
;		DI high:	Second character
;		DX:			Description Attribute
;		CX:			Description string parameter
;		CS:SI:		Description string
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
PushHotkeyParamsAndFormat:
	push	bp
	mov		bp, sp

	mov		ax, MONO_BRIGHT
	push	ax				; Key attribute
	xchg	ax, di
	push	ax				; First character
	xchg	al, ah
	push	ax				; Second character

	push	dx				; Description attribute
	push	si				; Description string
	push	cx				; Description string parameter

	push	di				; Key attribute for last space
	mov		si, g_szHotkey
	jmp		DetectPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; MoveCursorToScreenTopLeftCorner
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
MoveCursorToScreenTopLeftCorner:
	xor		ax, ax			; Top left corner (0, 0)
	; Fall to HotkeyBar_RestoreCursorCoordinatesFromAX


;--------------------------------------------------------------------
; HotkeyBar_RestoreCursorCoordinatesFromAX
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
HotkeyBar_RestoreCursorCoordinatesFromAX:
	CALL_DISPLAY_LIBRARY	SetCursorCoordinatesFromAX
	ret


;--------------------------------------------------------------------
; HotkeyBar_StoreHotkeyToBootvarsForDriveLetterInDL
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;		DL:		Drive Letter ('A'...)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DI
;--------------------------------------------------------------------
HotkeyBar_StoreHotkeyToBootvarsForDriveLetterInDL:
	eMOVZX	ax, dl
	call	Char_ChangeCaseInAL	; Upper case drive letter to lower case keystroke
	jmp		SHORT HotkeyBar_StoreHotkeyToBootvarsIfValidKeystrokeInAX


;--------------------------------------------------------------------
; ScanHotkeysFromKeyBufferAndStoreToBootvars
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ScanHotkeysFromKeyBufferAndStoreToBootvars:
	call	Keyboard_GetKeystrokeToAX
	jz		SHORT NoHotkeyToProcess

	ePUSH_T	cx, ScanHotkeysFromKeyBufferAndStoreToBootvars
	; Fall to HotkeyBar_StoreHotkeyToBootvarsIfValidKeystrokeInAX


;--------------------------------------------------------------------
; HotkeyBar_StoreHotkeyToBootvarsIfValidKeystrokeInAX
;	Parameters:
;		AL:		Hotkey ASCII code
;		AH:		Hotkey Scancode
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		CF:		Set if valid keystroke
;				Clear if invalid keystroke
;	Corrupts registers:
;		AX, CX, DI
;--------------------------------------------------------------------
HotkeyBar_StoreHotkeyToBootvarsIfValidKeystrokeInAX:
	; Boot menu
%ifdef MODULE_BOOT_MENU
	cmp		ah, BOOT_MENU_HOTKEY_SCANCODE	; Display Boot Menu?
	je		SHORT .StoreFunctionHotkeyFromAH
%endif

	; ROM Boot
	cmp		ah, ROM_BOOT_HOTKEY_SCANCODE	; ROM Boot?
	je		SHORT .StoreFunctionHotkeyFromAH

	; Drive letter hotkeys remaining, allow 'a' to 'z'
	call	Char_IsLowerCaseLetterInAL
	jnc		SHORT .KeystrokeIsNotValidHotkey
	call	Char_ChangeCaseInAL		; We want to print upper case letters

	; Clear HD First flag to assume Floppy Drive hotkey
	mov		di, BOOTVARS.hotkeyVars+HOTKEYVARS.bFlags
	and		BYTE [es:di], ~FLG_HOTKEY_HD_FIRST

	; Determine if Floppy or Hard Drive hotkey
	eMOVZX	cx, al					; Clear CH to clear scancode
	call	HotkeyBar_GetLetterForFirstHardDriveToAX
	cmp		cl, al
	jb		SHORT .StoreDriveLetter	; Store Floppy Drive letter

	; Store Hard Drive letter
	or		BYTE [es:di], FLG_HOTKEY_HD_FIRST

.StoreDriveLetter:
	adc		di, BYTE 0			; Add 1 if Floppy Drive
	xchg	ax, cx
	mov		[es:di+1], al		; AH = zero to clear function hotkey

.StoreFunctionHotkeyFromAH:
	mov		[es:BOOTVARS.hotkeyVars+HOTKEYVARS.bScancode], ah
	stc		; Valid hotkey

.KeystrokeIsNotValidHotkey:
NoHotkeyToProcess:
	ret


;--------------------------------------------------------------------
; HotkeyBar_GetSecondaryBootDriveNumberToDL
; HotkeyBar_GetPrimaryBootDriveNumberToDL
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		DL:		Drive selected as boot device
;	Corrupts registers:
;		AX, DH
;--------------------------------------------------------------------
HotkeyBar_GetSecondaryBootDriveNumberToDL:
	mov		dx, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.wHddAndFddLetters]
	xchg	dl, dh
	jmp		SHORT GetBootDriveNumberFromLettersInDX

HotkeyBar_GetPrimaryBootDriveNumberToDL:
	mov		dx, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.wHddAndFddLetters]
GetBootDriveNumberFromLettersInDX:
	test	BYTE [es:BOOTVARS.hotkeyVars+HOTKEYVARS.bFlags], FLG_HOTKEY_HD_FIRST
	eCMOVZ	dl, dh
	; Fall to HotkeyBar_ConvertDriveLetterInDLtoDriveNumber


;--------------------------------------------------------------------
; HotkeyBar_ConvertDriveLetterInDLtoDriveNumber
;	Parameters:
;		DS:		RAMVARS segment
;		DL:		Drive letter ('A'...)
;	Returns:
;		DL:		Drive number (0xh for Floppy Drives, 8xh for Hard Drives)
;	Corrupts registers:
;		AX, DH
;--------------------------------------------------------------------
HotkeyBar_ConvertDriveLetterInDLtoDriveNumber:
	call	HotkeyBar_GetLetterForFirstHardDriveToAX
	cmp		dl, al
	jb		SHORT .ConvertLetterInDLtoFloppyDriveNumber

	; Convert letter in DL to Hard Drive number
	sub		dl, al
	or		dl, 80h
	ret

.ConvertLetterInDLtoFloppyDriveNumber:
	sub		dl, DEFAULT_FLOPPY_DRIVE_LETTER
	ret


;--------------------------------------------------------------------
; HotkeyBar_ConvertDriveNumberFromDLtoDriveLetter
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
HotkeyBar_ConvertDriveNumberFromDLtoDriveLetter:
	test	dl, dl
	jns		SHORT .GetDefaultFloppyDrive

	; Store default hard drive to boot from
	call	HotkeyBar_GetLetterForFirstHardDriveToAX
	sub		dl, 80h
	add		dl, al
	stc
	ret

.GetDefaultFloppyDrive:
	add		dl, DEFAULT_FLOPPY_DRIVE_LETTER		; Clears CF
	ret


;--------------------------------------------------------------------
; Returns letter for first hard disk. Usually it will be 'C' but it
; can be higher if more than two floppy drives are found.
;
; HotkeyBar_GetLetterForFirstHardDriveToAX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AX:		Upper case letter for first hard disk
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
HotkeyBar_GetLetterForFirstHardDriveToAX:
	call	FloppyDrive_GetCountToAX
	add		al, DEFAULT_FLOPPY_DRIVE_LETTER
	MAX_U	al, DEFAULT_HARD_DRIVE_LETTER
	ret
