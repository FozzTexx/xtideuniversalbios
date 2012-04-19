; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for printing boot menu strings.

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
; BootMenuPrint_RefreshItem
;
;	Parameters:
;		CX:		Index of highlighted item
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		Does not matter
;--------------------------------------------------------------------
BootMenuPrint_RefreshItem:
	call	BootMenu_GetDriveToDXforMenuitemInCX
	jnc		BootMenuEvent_Completed					; if no menu item selected, out we go

	push	bp
	mov		bp, sp

	call	FindDPT_ForDriveNumberInDL
	jc		.notOurs

	call	DriveDetectInfo_ConvertDPTtoBX
	mov		si, g_szDriveNumBOOTNFO					; special g_szDriveNum that prints from BDA
	jmp		.go

.notOurs:
	mov		si,g_szDriveNum
	mov		bx,g_szForeignHD						; assume a hard disk for the moment

	test	dl, dl
	js		.go
	mov		bl,((g_szFloppyDrv)-$$ & 0xff)			; and revisit the earlier assumption...

.go:
	mov		ax, dx									; preserve DL for the floppy drive letter addition
	call	DriveXlate_ToOrBack
	push	dx										; translated drive number
	push	bx										; sub string
	add		al, 'A'									; floppy drive letter (we always push this although
	push	ax										; the hard disks don't ever use it, but it does no harm)

	jmp		SHORT BootMenuPrint_RefreshInformation.FormatRelay

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
BootMenuPrint_TitleStrings:
	mov		si, ROMVARS.szTitle
	call	DetectPrint_NullTerminatedStringFromCSSIandSetCF
	CALL_DISPLAY_LIBRARY PrintNewlineCharacters
	mov		si, ROMVARS.szVersion
	jmp		DetectPrint_NullTerminatedStringFromCSSIandSetCF


;--------------------------------------------------------------------
; BootMenuPrint_RefreshInformation
;	Parameters:
;		CX:		Index of highlighted item
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		Does not matter
;--------------------------------------------------------------------
BootMenuPrint_RefreshInformation:
	CALL_MENU_LIBRARY ClearInformationArea

	call	BootMenu_GetDriveToDXforMenuitemInCX
	jnc		BootMenuEvent_Completed						; if no menu selection, abort

	push	bp
	mov		bp, sp

	mov		si, g_szCapacity							; Setup print string now, carries through to print call

	call	FindDPT_ForDriveNumberInDL

	inc		dl											; are we a hard disk?
	dec		dl											; inc/dec will set SF, without modifying CF or DL
	js		.HardDiskRefreshInformation

	jnc		.ours										; Based on CF from FindDPT_ForDriveNumberInDL above
	call	FloppyDrive_GetType							; Get Floppy Drive type to BX
	jmp		.around
.ours:
	call	AH8h_GetDriveParameters
.around:

	mov		ax, g_szFddSizeOr	        				; .PrintXTFloppyType
	test	bl, bl										; Two possibilities? (FLOPPY_TYPE_525_OR_35_DD)
	jz		SHORT .PushAXAndOutput

	mov		al, (g_szFddUnknown - $$) & 0xff	        ; .PrintUnknownFloppyType
	cmp		bl, FLOPPY_TYPE_35_ED
	ja		SHORT .PushAXAndOutput

	; Fall to .PrintKnownFloppyType

;--------------------------------------------------------------------
; .PrintKnownFloppyType
;	Parameters:
;		BX:		Floppy drive type
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, BX, SI, DI
;
; Floppy Drive Types:
;
;   0  Handled above
;   1  FLOPPY_TYPE_525_DD          5 1/4   360K
;   2  FLOPPY_TYPE_525_HD          5 1/4   1.2M
;   3  FLOPPY_TYPE_35_DD           3 1/2   720K
;   4  FLOPPY_TYPE_35_HD           3 1/2   1.44M
;   5  3.5" ED on some BIOSes      3 1/2   2.88M
;   6  FLOPPY_TYPE_35_ED		   3 1/2   2.88M
;   >6 Unknown, handled above
;
;--------------------------------------------------------------------
.PrintKnownFloppyType:
	mov		al, (g_szFddSize - $$) & 0xff
	push	ax

	mov		al, (g_szFddThreeHalf - $$) & 0xff
	cmp		bl, FLOPPY_TYPE_525_HD
	ja		.ThreeHalf
	mov		al, (g_szFddFiveQuarter - $$) & 0xff
.ThreeHalf:
	push	ax											; "5 1/4" or "3 1/2"

	xor		bh, bh
	mov		al,FloppyTypes.rgbCapacityMultiplier
	mul		BYTE [cs:bx+FloppyTypes.rgbCapacity - 1]    ; -1 since 0 is handled above and not in the table

.PushAXAndOutput:
	push	ax

.FormatRelay:
	jmp		DetectPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; Prints Hard Disk Menuitem information strings.
;
; BootMenuPrint_HardDiskMenuitemInformation
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		BX, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
.HardDiskRefreshInformation:
	jc		.HardDiskMenuitemInfoForForeignDrive		; Based on CF from FindDPT_ForDriveNumberInDL (way) above

.HardDiskMenuitemInfoForOurDrive:
	ePUSH_T ax, g_szInformation							; Add substring for our hard disk information
	call	GetTotalSectorCount
	jmp		.ConvertSectorCountInBXDXAXtoSizeAndPushForFormat

.HardDiskMenuitemInfoForForeignDrive:
	call	DriveXlate_ToOrBack
	call	AH15h_GetSectorCountFromForeignDriveToDXAX

.ConvertSectorCountInBXDXAXtoSizeAndPushForFormat:
	ePUSH_T	cx, g_szCapacityNum		; Push format substring
	call	Size_ConvertSectorCountInBXDXAXtoKiB
	mov		cx, BYTE_MULTIPLES.kiB
	call	Size_GetSizeToAXAndCharToDLfromBXDXAXwithMagnitudeInCX
	push	ax						; Size in magnitude
	push	cx						; Tenths
	push	dx						; Magnitude character

	test	di, di
	jz		SHORT BootMenuPrint_RefreshInformation.FormatRelay

%include "BootMenuPrintCfg.asm"			; inline of code to fill out remainder of information string
	jmp		DetectPrint_FormatCSSIfromParamsInSSBP


FloppyTypes:
.rgbCapacityMultiplier equ 20	        ; Multiplier to reduce word sized values to byte size
.rgbCapacity:
	db		360   / FloppyTypes.rgbCapacityMultiplier    ;  type 1
	db		1200  / FloppyTypes.rgbCapacityMultiplier    ;  type 2
	db		720   / FloppyTypes.rgbCapacityMultiplier    ;  type 3
	db		1440  / FloppyTypes.rgbCapacityMultiplier    ;  type 4
	db		2880  / FloppyTypes.rgbCapacityMultiplier    ;  type 5
	db		2880  / FloppyTypes.rgbCapacityMultiplier    ;  type 6


;--------------------------------------------------------------------
; GetTotalSectorCount
;	Parameters:
;		DS:DI:		DPT Pointer
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
GetTotalSectorCount:
	test	BYTE [di+DPT.bFlagsLow], FLG_DRVNHEAD_LBA
	jnz		SHORT .ReturnFullCapacity
	jmp		AH15h_GetSectorCountToBXDXAX
.ReturnFullCapacity:
	jmp		AccessDPT_GetLbaSectorCountToBXDXAX
