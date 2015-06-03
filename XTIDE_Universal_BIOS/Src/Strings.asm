; Project name	:	XTIDE Universal BIOS
; Description	:	Strings and equates for BIOS messages.

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

%ifdef MODULE_STRINGS_COMPRESSED_PRECOMPRESS
	%include "Display.inc"
%endif

; Section containing code
SECTION .text

; The following strings are used by DetectPrint_StartDetectWithMasterOrSlaveStringInCXandIdeVarsInCSBP
; To support an optimization in that code, these strings must start on the same 256 byte page,
; which is checked at assembly time below.
;
g_szDetectStart:
g_szDetectMaster:		db	"Master",NULL
g_szDetectSlave:		db	"Slave ",NULL
g_szDetectOuter:		db	"%s at %s: ",NULL
%ifdef MODULE_SERIAL
g_szDetectCOM:			db	"COM%c%s",NULL
g_szDetectCOMAuto:		db	" Detect",NULL
g_szDetectCOMSmall:		db	"/%u%u00",NULL					; IDE Master at COM1/9600:
g_szDetectCOMLarge:		db	"/%u.%uK",NULL					; IDE Master at COM1/19.2K:
%endif
g_szDetectEnd:
g_szDetectPort:			db	"%x",NULL						; IDE Master at 1F0h:

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if ((g_szDetectEnd-$$) & 0xff00) <> ((g_szDetectStart-$$) & 0xff00)
		%error "g_szDetect* strings must start on the same 256 byte page, required by DetectPrint_StartDetectWithMasterOrSlaveStringInCXandIdeVarsInCSBP.  Please move this block up or down within Strings.asm"
	%endif
%endif


; POST drive detection strings
g_szDashForZero:	db	"- ",NULL	; Required by Display Library
g_szRomAt:			db	LF,CR
					db	"%s @ %x",LF,CR						; -=XTIDE ... =- @ Segment
					db	"%s",LF,CR							; version string
					db	"Released under GNU GPL v2",LF,CR
					db	LF,CR,NULL
%ifdef MODULE_BOOT_MENU
g_szBootMenuTitle:	db	"%s%c",LF,CR						; -=XTIDE ... =- and null (eaten)
					db	"%s",NULL							; version string
%endif
g_szDriveName:		db	"%z",LF,CR,NULL


; Boot loader strings
g_szTryToBoot:			db	"Booting %c",ANGLE_QUOTE_RIGHT,"%c",LF,CR,NULL
g_szBootSectorNotFound:	db	"Boot sector " 			; String fall through...
g_szNotFound:			db	"not found",LF,CR,NULL
g_szReadError:			db	"Error %x!",LF,CR,NULL


%ifdef MODULE_HOTKEYS
; Hotkey Bar strings
g_szFDD:				db	"FDD [%c]",NULL			; "FDD [A]"
g_szHDD:				db	"HDD [%c]",NULL			; "HDD [C]"
%ifdef MODULE_BOOT_MENU
g_szBootMenu:			db	"BootMnu%c",NULL		; "BootMnu", location of %c doesn't matter
%endif ; MODULE_BOOT_MENU
g_szHotkey:				db	"%A%c%c%A%s%A ",NULL	; "C»HDD [A] ", "F2BootMnu " or "F8RomBoot "
%ifdef MODULE_SERIAL
g_szHotComDetect:		db	"ComDtct%c",NULL		; "ComDtct", location of %c doesn't matter
%endif ; MODULE_SERIAL
%endif ; MODULE_HOTKEYS

%ifdef MODULE_BOOT_MENU
g_szRomBootDash:		db	" -  "					; String fall through to g_szRomBoot
%endif
%ifdef MODULE_HOTKEYS OR MODULE_BOOT_MENU
g_szRomBoot:			db	"Rom%cBoot",NULL		; "RomBoot" or "Rom Boot"
%endif


%ifdef MODULE_BOOT_MENU
; Boot Menu Floppy Disk strings
;
; The following strings are used by BootMenuPrint_RefreshInformation
; To support optimizations in that code, these strings must start on the same 256 byte page,
; which is checked at assembly time below.
;
g_szFddStart:
g_szFddUnknown:		db	"Unknown",NULL
g_szFddSizeOr:		db	"5",ONE_QUARTER,QUOTATION_MARK," or 3",ONE_HALF,QUOTATION_MARK," DD",NULL
g_szFddSize:		db	"%s",QUOTATION_MARK,", %u kiB",NULL	; 3½", 1440 kiB
g_szFddThreeHalf:	db	"3",ONE_HALF,NULL
g_szFddEnd:
g_szFddFiveQuarter:	db	"5",ONE_QUARTER,NULL

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if ((g_szFddStart-$$) & 0xff00) <> ((g_szFddEnd-$$) & 0xff00)
		%error "g_szFdd* strings must start on the same 256 byte page, required by the BootMenuPrint_RefreshInformation routines for floppy drives.  Please move this block up or down within Strings.asm"
	%endif
%endif


g_szAddressingModes:
g_szNORMAL:		db	"NORMAL",NULL
g_szLARGE:		db	"LARGE ",NULL
g_szLBA:		db	"LBA   ",NULL
g_szAddressingModes_Displacement equ (g_szLARGE - g_szAddressingModes)
;
; Ensure that addressing modes are correctly spaced in memory
;
%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if g_szNORMAL <> g_szAddressingModes
		%error "g_szAddressingModes Displacement Incorrect 1"
	%endif
	%if g_szLARGE <> g_szNORMAL + g_szAddressingModes_Displacement
		%error "g_szAddressingModes Displacement Incorrect 2"
	%endif
	%if g_szLBA <> g_szLARGE + g_szAddressingModes_Displacement
		%error "g_szAddressingModes Displacement Incorrect 3"
	%endif
%endif


g_szDeviceTypeValues:
g_szDeviceTypeValues_16bit:			db	" 16",NULL
g_szDeviceTypeValues_32bit:			db	" 32",NULL
g_szDeviceTypeValues_8bit:			db	"  8",NULL
g_szDeviceTypeValues_XTIDEr1:		db	"D8 ",NULL	; Dual 8-bit
g_szDeviceTypeValues_XTIDEr2:		db	"X8 ",NULL	; A0<->A3 swapped 8-bit
g_szDeviceTypeValues_XTCFpio8:		db	"T8 ",NULL	; True 8-bit
g_szDeviceTypeValues_XTCFpio8BIU:	db	"T8B",NULL
g_szDeviceTypeValues_XTCFpio16BIU:	db	"16B",NULL
g_szDeviceTypeValues_XTCFdma:		db	"8MA",NULL	; DMA 8-bit
g_szDeviceTypeValues_JrIde:			db	"M8 ",NULL	; Memory Mapped 8-bit
g_szDeviceTypeValues_ADP50L:		db	"M8 ",NULL	; Memory Mapped 8-bit
g_szDeviceTypeValues_Serial:		db	"SER",NULL

g_szDeviceTypeValues_Displacement equ (g_szDeviceTypeValues_32bit - g_szDeviceTypeValues)
;
; Ensure that device type strings are correctly spaced in memory
;
%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if g_szDeviceTypeValues_16bit <> g_szDeviceTypeValues
		%error "g_szDeviceTypeValues Displacement Incorrect 1"
	%endif
	%if g_szDeviceTypeValues_32bit <> g_szDeviceTypeValues_16bit + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 2"
	%endif
	%if g_szDeviceTypeValues_8bit <> g_szDeviceTypeValues_32bit + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 3"
	%endif
	%if g_szDeviceTypeValues_XTIDEr1 <> g_szDeviceTypeValues_8bit + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 4"
	%endif
	%if g_szDeviceTypeValues_XTIDEr2 <> g_szDeviceTypeValues_XTIDEr1 + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 5"
	%endif
	%if g_szDeviceTypeValues_XTCFpio8 <> g_szDeviceTypeValues_XTIDEr2 + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 6"
	%endif
	%if g_szDeviceTypeValues_XTCFpio8BIU <> g_szDeviceTypeValues_XTCFpio8 + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 7"
	%endif
	%if g_szDeviceTypeValues_XTCFpio16BIU <> g_szDeviceTypeValues_XTCFpio8BIU + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 8"
	%endif
	%if g_szDeviceTypeValues_XTCFdma <> g_szDeviceTypeValues_XTCFpio16BIU + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 9"
	%endif
	%if g_szDeviceTypeValues_JrIde <> g_szDeviceTypeValues_XTCFdma + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 10"
	%endif
	%if g_szDeviceTypeValues_ADP50L <> g_szDeviceTypeValues_JrIde + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 11"
	%endif
	%if g_szDeviceTypeValues_Serial <> g_szDeviceTypeValues_ADP50L + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 12"
	%endif
%endif


g_szSelectionTimeout:	db	DOUBLE_BOTTOM_LEFT_CORNER,DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL,"%ASelection in %2-u s",NULL


; Boot Menu menuitem strings
;
; The following strings are used by BootMenuPrint_* routines.
; To support optimizations in that code, these strings must start on the same 256 byte page,
; which is checked at assembly time below.
;
g_szDriveNumSpace:		db	" "							; leading space, used if drive number is less than 0fh
														; must come immediately before g_szDriveNum!
g_szBootMenuPrintStart:
g_szDriveNum:			db	"%x %s",NULL
g_szDriveNumBNSpace:	db	" "							; leading space, used if drive number is less than 0fh
														; must come immediately before g_szDriveNumBOOTNFO!
g_szDriveNumBOOTNFO:	db	"%x %z",NULL
g_szFloppyDrv:			db	"Floppy Drive %c",NULL
g_szBootMenuPrintEnd:
g_szForeignHD:			db	"Foreign Hard Disk",NULL

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if ((g_szBootMenuPrintStart-$$) & 0xff00) <> ((g_szBootMenuPrintEnd-$$) & 0xff00)
		%error "g_szBootMenuPrint* strings must start on the same 256 byte page, required by the BootMenuPrint_* routines.  Please move this block up or down within Strings.asm"
	%endif
	%if g_szDriveNumSpace+1 != g_szDriveNum || g_szDriveNumBNSpace+1 != g_szDriveNumBOOTNFO
		%error "g_szDriveNumSpace or g_szDriveNumBNSpace are out of position"
	%endif
%endif


; Boot Menu information strings
g_szCapacity:			db	"Capacity : %s",NULL
g_szCapacityNum:		db	"%5-u.%u %ciB",NULL
g_szInformation:		db	"%s",LF,CR
						db	"Addr. ",SINGLE_VERTICAL,"Block",SINGLE_VERTICAL,"Bus",SINGLE_VERTICAL,"IRQ",SINGLE_VERTICAL,"Reset",LF,CR
						db	"%s",SINGLE_VERTICAL,"%5-u",SINGLE_VERTICAL,"%s",SINGLE_VERTICAL," %2-I",SINGLE_VERTICAL,"%5-x",NULL

%endif ; MODULE_BOOT_MENU


;------------------------------------------------------------------------------------------
;
; Tables for StringsCompress.pl
;
; Items can be added and removed from this table as needed, with the following rules:
;  * Formats follow the special characters.  But other than that, order makes no difference.
;  * Some of the formats require "even" and "odd" numbering.  Even tells the code that
;    it is a "number-" format, otherwise it doesn't interpret a number first.  The easiest
;    way to maintain this is to move one of the "n/a" items to/from the front of the format
;    list to maintain the even/odd.
;  * Values do not need to remain consistent across versions.  This table is only used
;    internally to this file.
;  * There can only be 32 of these (0-31).
;  * Keeping the list short is good - this translates to a table in the compressed version.
;    An error will be reported if a character or format is no longer being used by any
;    strings above.
;  * Please keep items sequential for ease of further editing.
;
;$translate{ord(' ')} = 0;
;$translate{172}      = 1;     # ONE_QUARTER
;$translate{171}      = 2;     # ONE_HALF
;$translate{179}      = 3;     # SINGLE_VERTICAL
;$translate{175}      = 4;     # ANGLE_QUOTE_RIGHT
;$translate{ord('!')} = 5;
;$translate{ord('"')} = 6;
;$translate{ord(',')} = 7;
;$translate{ord('-')} = 8;
;$translate{ord('.')} = 9;
;$translate{ord('/')} = 10;
;$translate{ord('1')} = 11;
;$translate{ord('2')} = 12;
;$translate{ord('3')} = 13;
;$translate{ord('5')} = 14;
;$translate{ord('6')} = 15;
;$translate{ord('8')} = 16;
;$translate{200}      = 17;    # DOUBLE_BOTTOM_LEFT_CORNER
;$translate{181}      = 18;    # DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL
;$translate{ord('0')} = 19;
;
; Formats begin immediately after the last Translated character (they are in the same table)
;
;$format_begin = 20;
;
;$format{"2-I"} = 20;        # must be even
;$format{"u"}   = 21;        # must be odd
;$format{"5-u"} = 22;        # must be even
;$format{"x"}   = 23;        # must be odd
;$format{"5-x"} = 24;        # must be even
;$format{"nl"}  = 25;        # n/a
;$format{"2-u"} = 26;        # must be even
;$format{"A"}   = 27;        # n/a
;$format{"c"}   = 28;        # n/a
;$format{"s"}   = 29;        # n/a, normal string from DS
;$format{"z"}   = 30;        # n/a, boot string from BDA
;
; NOTE: The last $format cannot exceed 31 (stored in a 5-bit quantity).
;
; Starting point for the "normal" range, typically around 0x40 to cover upper and lower case
; letters.  If lower case 'z' is not used, 0x3a can be a good choice as it adds ':' to the
; front end.
;
;$normal_base = 0x3a;
;
; End of StringsCompress.pl information
;
;------------------------------------------------------------------------------------------
