; Project name	:	BIOS Drive Information Tool
; Description	:	BIOS Drive Information Tool reads and displays
;					drive information from BIOS.

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

; Include .inc files
%define INCLUDE_DISPLAY_LIBRARY
%define INCLUDE_KEYBOARD_LIBRARY
%include "AssemblyLibrary.inc"	; Assembly Library. Must be included first!
%include "Version.inc"			; From XTIDE Universal BIOS
%include "ATA_ID.inc"			; From XTIDE Universal BIOS
%include "Int13h.inc"			; From XTIDE Universal BIOS
%include "EBIOS.inc"			; From XTIDE Universal BIOS
FLG_DRVNHEAD_DRV	EQU	(1<<4)	; Required by CustomDPT.inc
%include "Romvars.inc"			; From XTIDE Universal BIOS
%include "CustomDPT.inc"		; From XTIDE Universal BIOS


; Section containing code
SECTION .text

; Program first instruction.
ORG	100h						; Code starts at offset 100h (DOS .COM)
Start:
	jmp		StartBiosDriveInformationTool

; Include library and other sources
%include "AssemblyLibrary.asm"
%include "AtaGeometry.asm"		; From XTIDE Universal BIOS
%include "Strings.asm"
%include "AtaInfo.asm"
%include "Bios.asm"
%include "Print.asm"


;--------------------------------------------------------------------
; Program start
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
StartBiosDriveInformationTool:
	CALL_DISPLAY_LIBRARY	InitializeDisplayContext
	call	Print_SetCharacterOutputToSTDOUT

	; Display program name and version
	mov		si, g_szProgramName
	call	Print_NullTerminatedStringFromSI

	call	ReadAndDisplayAllHardDrives

	; Exit to DOS
	mov 	ax, 4C00h			; Exit to DOS
	int 	21h


;--------------------------------------------------------------------
; ReadAndDisplayAllHardDrives
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except segments
;--------------------------------------------------------------------
ReadAndDisplayAllHardDrives:
	call	Bios_GetNumberOfHardDrivesToDX
	jc		SHORT .NoDrivesAvailable
	mov		cx, dx
	mov		dl, 80h				; First hard drive
	jmp		SHORT .DisplayFirstDrive

.DisplayNextDriveFromDL:
	mov		si, g_szPressAnyKey
	call	Print_NullTerminatedStringFromSI
	call	Keyboard_GetKeystrokeToAXandWaitIfNecessary

.DisplayFirstDrive:
	; Display drive number
	mov		si, g_szHeaderDrive
	call	Print_DriveNumberFromDLusingFormatStringInSI

	; Display ATA information read from drive
	mov		si, g_szAtaInfoHeader
	call	Print_NullTerminatedStringFromSI
	call	AtaInfo_DisplayAtaInformationForDriveDL

	; Display INT 13h AH=08h and AH=15h information
	mov		si, g_szOldInfoHeader
	call	Print_NullTerminatedStringFromSI
	call	DisplayOldInt13hInformationForDriveDL

	; Display EBIOS information
	mov		si, g_szNewInfoHeader
	call	Print_NullTerminatedStringFromSI
	call	DisplayNewInt13hInformationFromDriveDL

	inc		dx
	loop	.DisplayNextDriveFromDL
.NoDrivesAvailable:
	ret


;--------------------------------------------------------------------
; DisplayOldInt13hInformationForDriveDL
;	Parameters:
;		DL:		Drive Number
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except CX and DX
;--------------------------------------------------------------------
DisplayOldInt13hInformationForDriveDL:
	push	cx
	push	dx

	; Print L-CHS from AH=08h
	call	Bios_ReadOldInt13hParametersFromDriveDL
	call	Print_ErrorMessageFromAHifError
	jc		SHORT .SkipOldInt13hSinceError
	call	Print_CHSfromCXDXAX

	; Print total sector count from AH=15h
	mov		si, g_szSectors
	call	Print_NullTerminatedStringFromSI
	pop		dx
	push	dx
	call	Bios_ReadOldInt13hCapacityFromDriveDL
	call	Print_ErrorMessageFromAHifError
	jc		SHORT .SkipOldInt13hSinceError

	xchg	ax, dx
	mov		dx, cx
	xor		bx, bx
	call	Print_TotalSectorsFromBXDXAX
.SkipOldInt13hSinceError:
	pop		dx
	pop		cx
	ret


;--------------------------------------------------------------------
; DisplayNewInt13hInformationFromDriveDL
;	Parameters:
;		DL:		Drive Number
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except CX and DX
;--------------------------------------------------------------------
DisplayNewInt13hInformationFromDriveDL:
	push	cx
	push	dx

	; Display EBIOS version
	call	Bios_ReadEbiosVersionFromDriveDL
	call	Print_ErrorMessageFromAHifError
	jc		SHORT .SkipNewInt13hSinceError
	call	Print_EbiosVersionFromBXandExtensionsFromCX

	; Display drive info from AH=48h
	call	Bios_ReadEbiosInfoFromDriveDLtoDSSI
	call	Print_ErrorMessageFromAHifError
	jc		SHORT .SkipNewInt13hSinceError

	; Display CHS
	test	WORD [si+EDRIVE_INFO.wFlags], FLG_CHS_INFORMATION_IS_VALID
	jz		SHORT .SkipEbiosCHS
	mov		cx, [si+EDRIVE_INFO.dwCylinders]
	mov		dx, [si+EDRIVE_INFO.dwHeads]
	mov		ax, [si+EDRIVE_INFO.dwSectorsPerTrack]
	call	Print_CHSfromCXDXAX
.SkipEbiosCHS:

	; Display total sector count
	push	si
	mov		si, g_szSectors
	call	Print_NullTerminatedStringFromSI
	pop		si
	mov		ax, [si+EDRIVE_INFO.qwTotalSectors]
	mov		dx, [si+EDRIVE_INFO.qwTotalSectors+2]
	mov		bx, [si+EDRIVE_INFO.qwTotalSectors+4]
	call	Print_TotalSectorsFromBXDXAX

	; Display sector size
	mov		ax, [si+EDRIVE_INFO.wSectorSize]
	mov		si, g_szNewSectorSize
	call	Print_FormatStringFromSIwithParameterInAX

.SkipNewInt13hSinceError:
	pop		dx
	pop		cx
	ret
