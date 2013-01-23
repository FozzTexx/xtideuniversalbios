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
	call	HotkeyBar_ScanHotkeysFromKeyBufferAndStoreToBootvars
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

	mov		ax, (ANGLE_QUOTE_RIGHT << 8) | DEFAULT_FLOPPY_DRIVE_LETTER
	mov		cl, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.bFddLetter]
	mov		di, g_szFDD
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
	call	DriveXlate_GetLetterForFirstHardDriveToAX
	mov		ah, ANGLE_QUOTE_RIGHT
	mov		cl, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.bHddLetter]
	mov		di, g_szHDD
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
	mov		ax, BOOT_MENU_HOTKEY_SCANCODE | ('2' << 8)
	mov		di, g_szBootMenu
	call	FormatFunctionHotkeyString
%endif
	; Fall to .PrintComDetectHotkey

;--------------------------------------------------------------------
; .PrintComDetectHotkey
;	Parameters:
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
.PrintComDetectHotkey:
%ifdef MODULE_SERIAL
	mov		ax, COM_DETECT_HOTKEY_SCANCODE | ('6' << 8)
	mov		di, g_szHotComDetect
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
	mov		ax, ROM_BOOT_HOTKEY_SCANCODE | ('8' << 8)
	mov		di, g_szRomBoot
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
;		AL:			First character for drive key string
;		AH:			Second character for drive key string (ANGLE_QUOTE_RIGHT)
;		SI:			Offset to hotkey description string
;		ES:			BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
;; No work to do before going into FormatFunctionHotkeyString
FormatDriveHotkeyString  equ  GetNonSelectedHotkeyDescriptionAttributeToDX

;--------------------------------------------------------------------
; FormatFunctionHotkeyString
;	Parameters:
;		AL:			Scancode of function key, to know which if any to show as selected
;					Later replaced with an 'F' for the call to the output routine
;		AH:			Second character for drive key string
;		SI:			Offset to hotkey description string
;		ES:			BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
FormatFunctionHotkeyString:
	xor		cx, cx		; Null character, eaten in output routines

	cmp		[es:BOOTVARS.hotkeyVars+HOTKEYVARS.bScancode], al
	mov		al, 'F'		; Replace scancode with character for output

%ifdef MODULE_BOOT_MENU

	mov		si, ATTRIBUTE_CHARS.cHurryTimeout		; Selected hotkey
	jz		SHORT GetDescriptionAttributeToDX		; From compare with bScancode above

GetNonSelectedHotkeyDescriptionAttributeToDX:
	mov		si, ATTRIBUTE_CHARS.cHighlightedItem	; Unselected hotkey

	; Display Library should not be called like this
GetDescriptionAttributeToDX:
	xchg	dx, ax
	call	MenuAttribute_GetToAXfromTypeInSI
	xchg	dx, ax					; DX = Description attribute
	;;  fall through to PushHotkeyParamsAndFormat 


%else ; if no MODULE_BOOT_MENU - No boot menu so use simpler attributes

	mov		dx, (COLOR_ATTRIBUTE(COLOR_YELLOW, COLOR_CYAN) << 8) | MONO_REVERSE_BLINK
	jz		SHORT SelectAttributeFromDHorDLbasedOnVideoMode			; From compare with bScancode above

GetNonSelectedHotkeyDescriptionAttributeToDX:
	mov		dx, (COLOR_ATTRIBUTE(COLOR_BLACK, COLOR_CYAN) << 8) | MONO_REVERSE

SelectAttributeFromDHorDLbasedOnVideoMode:
	mov		ch, [es:BDA.bVidMode]		; We only need to preserve CL
	shr		ch, 1
	jnc		SHORT .AttributeLoadedToDL	; Black & White modes
	shr		ch, 1
	jnz		SHORT .AttributeLoadedToDL	; MDA
	mov		dl, dh
.AttributeLoadedToDL:
	;;  fall through to PushHotkeyParamsAndFormat 		

%endif ; MODULE_BOOT_MENU


;--------------------------------------------------------------------
; PushHotkeyParamsAndFormat
;	Parameters:
;		AL:			First character
;		AH:			Second character
;		DX:			Description Attribute
;		CX:			Description string parameter
;		CS:DI:		Description string
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
PushHotkeyParamsAndFormat:
	push	bp
	mov		bp, sp

	mov		si, MONO_BRIGHT

	push	si				; Key attribute
	push	ax				; First Character
	mov		al, ah
	push	ax				; Second Character

	push	dx				; Description attribute
	push	di				; Description string
	push	cx				; Description string parameter
		
	push	si				; Key attribute for last space

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
	xor		al, 32	; Upper case drive letter to lower case keystroke
	jmp		SHORT HotkeyBar_StoreHotkeyToBootvarsIfValidKeystrokeInAX


;--------------------------------------------------------------------
; HotkeyBar_ScanHotkeysFromKeyBufferAndStoreToBootvars
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		AL:		Last scancode value
;	Corrupts registers:
;		AH, CX
;--------------------------------------------------------------------
HotkeyBar_ScanHotkeysFromKeyBufferAndStoreToBootvars:
	call	Keyboard_GetKeystrokeToAX
	jz		SHORT NoHotkeyToProcess

	ePUSH_T	cx, HotkeyBar_ScanHotkeysFromKeyBufferAndStoreToBootvars
	; Fall to HotkeyBar_StoreHotkeyToBootvarsIfValidKeystrokeInAX


;--------------------------------------------------------------------
; HotkeyBar_StoreHotkeyToBootvarsIfValidKeystrokeInAX
;	Parameters:
;		AL:		Hotkey ASCII code
;		AH:		Hotkey Scancode
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;       AL:     Last scancode seen
;	Corrupts registers:
;		AH, CX, DI
;--------------------------------------------------------------------
HotkeyBar_StoreHotkeyToBootvarsIfValidKeystrokeInAX:
	mov		di, BOOTVARS.hotkeyVars+HOTKEYVARS.bScancode

	; All scancodes are saved, even if it wasn't a drive letter,
	; which also covers our function key case.  Invalid function keys
	; will not do anything (won't be printed, won't be accepted as input)		
	mov		[es:di], ah
		
	; Drive letter hotkeys remaining, allow 'a' to 'z'
	call	Char_IsLowerCaseLetterInAL
	jnc		SHORT .KeystrokeIsNotValidDriveLetter
	xor		al, 32					; We want to print upper case letters

	; Clear HD First flag to assume Floppy Drive hotkey
	dec		di
	and		BYTE [es:di], ~FLG_HOTKEY_HD_FIRST

	; Determine if Floppy or Hard Drive hotkey
	eMOVZX	cx, al					; Clear CH to clear scancode
	call	DriveXlate_GetLetterForFirstHardDriveToAX
	cmp		cl, al
	jb		SHORT .StoreDriveLetter	; Store Floppy Drive letter

	; Store Hard Drive letter
	or		BYTE [es:di], FLG_HOTKEY_HD_FIRST

.StoreDriveLetter:
	sbb		di, BYTE 1			; Sub CF if Floppy Drive
	xchg	ax, cx
	mov		[es:di], al			; AH = zero to clear function hotkey

.KeystrokeIsNotValidDriveLetter:		
NoHotkeyToProcess:
	mov		al, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.bScancode]
	ret

;--------------------------------------------------------------------
; HotkeyBar_GetBootDriveNumbersToDX
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		DX:		Drives selected as boot device, DL is primary
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
HotkeyBar_GetBootDriveNumbersToDX:
	mov		dx, [es:BOOTVARS.hotkeyVars+HOTKEYVARS.wFddAndHddLetters]
	test	BYTE [es:BOOTVARS.hotkeyVars+HOTKEYVARS.bFlags], FLG_HOTKEY_HD_FIRST		
	jnz		.noflip
	xchg	dl, dh
.noflip:	
	call	DriveXlate_ConvertDriveLetterInDLtoDriveNumber
	xchg	dl, dh
	; Fall to HotkeyBar_FallThroughTo_DriveXlate_ConvertDriveLetterInDLtoDriveNumber		
		
HotkeyBar_FallThroughTo_DriveXlate_ConvertDriveLetterInDLtoDriveNumber:		

