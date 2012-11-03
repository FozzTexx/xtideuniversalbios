; Project name	:	XTIDE Universal BIOS
; Description	:	Strings and equates for BIOS messages.

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

%ifdef MODULE_STRINGS_COMPRESSED_PRECOMPRESS
	%include "Display.inc"
%endif

; Section containing code
SECTION .text

; POST drive detection strings
g_szDashForZero:	db	"- ",NULL	; Required by Display Library
g_szRomAt:			db	LF,CR,"%s @ %x",LF,CR
					db  "Released under GNU GPL v2",LF,CR,LF,CR,NULL


; The following strings are used by DetectPrint_StartDetectWithMasterOrSlaveStringInCXandIdeVarsInCSBP
; To support an optimization in that code, these strings must start on the same 256 byte page,
; which is checked at assembly time below.
;
g_szDetectStart:
g_szDetectMaster:		db	"Master",NULL
g_szDetectSlave:		db	"Slave ",NULL
g_szDetectOuter:		db	"%s at %s: ",NULL
%ifdef MODULE_SERIAL
g_szDetectCOM:			db  "COM%c%s",NULL
g_szDetectCOMAuto:		db	" Detect",NULL
g_szDetectCOMSmall:		db	"/%u%u00",NULL					; IDE Master at COM1/9600:
g_szDetectCOMLarge:		db	"/%u.%uK",NULL					; IDE Master at COM1/19.2K:
%endif
g_szDetectEnd:
g_szDetectPort:			db	"%x",NULL					   	; IDE Master at 1F0h:

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if ((g_szDetectEnd-$$) & 0xff00) <> ((g_szDetectStart-$$) & 0xff00)
		%error "g_szDetect* strings must start on the same 256 byte page, required by DetectPrint_StartDetectWithMasterOrSlaveStringInCXandIdeVarsInCSBP.  Please move this block up or down within strings.asm"
	%endif
%endif


; Boot loader strings
g_szTryToBoot:			db	"Booting %c",ANGLE_QUOTE_RIGHT,"%c",LF,CR,NULL
g_szBootSectorNotFound:	db	"Boot sector "
g_szNotFound:			db	"not found",LF,CR,NULL
g_szReadError:			db	"Error %x!",LF,CR,NULL


%ifdef MODULE_HOTKEYS

; Hotkey Bar strings
g_szFDD:		db	"FDD [%c]",NULL			; "FDD [A]"
g_szHDD:		db	"HDD [%c]",NULL			; "HDD [C]"
g_szBootMenu:	db	"%sMnu",NULL			; "BootMnu"
g_szRomBoot:	db	"Rom%s",NULL			; "RomBoot"
g_szBoot:		db	"Boot",NULL
g_szHotkey:		db	"%A%c%c%A%s%A ",NULL	; "C»HDD [A] ", "F2BootMnu " or "F8RomBoot "


%ifdef MODULE_BOOT_MENU

; Boot Menu Floppy Disk strings
;
; The following strings are used by BootMenuPrint_RefreshInformation
; To support optimizations in that code, these strings must start on the same 256 byte page,
; which is checked at assembly time below.
;
g_szFddStart:
g_szFddUnknown:	db	"Unknown",NULL
g_szFddSizeOr:	db	"5",ONE_QUARTER,QUOTATION_MARK," or 3",ONE_HALF,QUOTATION_MARK," DD",NULL
g_szFddSize:	db	"%s",QUOTATION_MARK,", %u kiB",NULL	; 3½", 1440 kiB
g_szFddThreeHalf:		db  "3",ONE_HALF,NULL
g_szFddEnd:
g_szFddFiveQuarter:		db  "5",ONE_QUARTER,NULL

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if ((g_szFddStart-$$) & 0xff00) <> ((g_szFddEnd-$$) & 0xff00)
		%error "g_szFdd* strings must start on the same 256 byte page, required by the BootMenuPrint_RefreshInformation routines for floppy drives.  Please move this block up or down within strings.asm"
	%endif
%endif


g_szAddressingModes:
g_szNORMAL:		db	"NORMAL",NULL
g_szLARGE:		db	"LARGE ",NULL
g_szLBA:		db	"LBA   ",NULL
wantToRemoveThis:	db	"4",NULL	; String compression want '4' somewhere
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
g_szDeviceTypeValues_16bit:		db		" 16",NULL
g_szDeviceTypeValues_32bit:		db		" 32",NULL
g_szDeviceTypeValues_8bit:		db		"  8",NULL
g_szDeviceTypeValues_XTIDEr1:	db		"D8 ",NULL	; Dual 8-bit
g_szDeviceTypeValues_XTIDEr2:	db		"X8 ",NULL	; A0<->A3 swapped 8-bit
g_szDeviceTypeValues_XTCFpio8:	db		"T8 ",NULL	; True 8-bit
g_szDeviceTypeValues_XTCFdma:	db		"8MA",NULL	; DMA 8-bit
g_szDeviceTypeValues_XTCFmem:	db		"M8 ",NULL	; Memory Mapped 8-bit
g_szDeviceTypeValues_JrIde:		db		"M8 ",NULL
g_szDeviceTypeValues_Serial:	db		"SER",NULL

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
		%error "g_szDeviceTypeValues Displacement Incorrect 2"
	%endif
	%if g_szDeviceTypeValues_XTIDEr1 <> g_szDeviceTypeValues_8bit + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 3"
	%endif
	%if g_szDeviceTypeValues_XTIDEr2 <> g_szDeviceTypeValues_XTIDEr1 + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 4"
	%endif
	%if g_szDeviceTypeValues_XTCFpio8 <> g_szDeviceTypeValues_XTIDEr2 + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 5"
	%endif
	%if g_szDeviceTypeValues_XTCFdma <> g_szDeviceTypeValues_XTCFpio8 + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 6"
	%endif
	%if g_szDeviceTypeValues_XTCFmem <> g_szDeviceTypeValues_XTCFdma + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 7"
	%endif
	%if g_szDeviceTypeValues_JrIde <> g_szDeviceTypeValues_XTCFmem + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 8"
	%endif
	%if g_szDeviceTypeValues_Serial <> g_szDeviceTypeValues_JrIde + g_szDeviceTypeValues_Displacement
		%error "g_szDeviceTypeValues Displacement Incorrect 9"
	%endif
%endif

g_szSelectionTimeout:	db		DOUBLE_BOTTOM_LEFT_CORNER,DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL,"%ASelection in %2-u s",NULL




; Boot Menu information strings
g_szCapacity:			db	"Capacity : %s",NULL
g_szCapacityNum:		db	"%5-u.%u %ciB",NULL
g_szInformation:		db	"%s",LF,CR
	db	"Addr. ",SINGLE_VERTICAL,"Block",SINGLE_VERTICAL,"Bus",SINGLE_VERTICAL,  "IRQ",SINGLE_VERTICAL,"Reset",LF,CR
	db	   "%s",SINGLE_VERTICAL, "%5-u",SINGLE_VERTICAL, "%s",SINGLE_VERTICAL," %2-I",SINGLE_VERTICAL,"%5-x" ,NULL


; Boot Menu menuitem strings
;
; The following strings are used by BootMenuPrint_* routines.
; To support optimizations in that code, these strings must start on the same 256 byte page,
; which is checked at assembly time below.
;
g_szBootMenuPrintStart:
g_szDriveNum:			db	"%x %s",NULL
g_szDriveNumBOOTNFO:	db	"%x %z",NULL
g_szFloppyDrv:			db	"Floppy Drive %c",NULL
g_szBootMenuPrintEnd:
g_szForeignHD:			db	"Foreign Hard Disk",NULL

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if ((g_szBootMenuPrintStart-$$) & 0xff00) <> ((g_szBootMenuPrintEnd-$$) & 0xff00)
		%error "g_szBootMenuPrint* strings must start on the same 256 byte page, required by the BootMenuPrint_* routines.  Please move this block up or down within strings.asm"
	%endif
%endif

%endif ; MODULE_BOOT_MENU
%endif ; MODULE_HOTKEYS


;------------------------------------------------------------------------------------------
;
; Tables for StringsCompress.pl
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
;$translate{ord('4')} = 14;	; Not used at the moment
;$translate{ord('5')} = 15;
;$translate{ord('6')} = 16;
;$translate{ord('8')} = 17;
;$translate{200}      = 18;    # DOUBLE_BOTTOM_LEFT_CORNER
;$translate{181}      = 19;    # DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL
;$translate{ord('0')} = 20;
;
; Formats begin immediately after the last Translated character (they are in the same table)
;
;$format_begin = 21;
;
;$format{"c"}   = 21;        # n/a
;$format{"2-I"} = 22;        # must be even
;$format{"u"}   = 23;        # must be odd
;$format{"5-u"} = 24;        # must be even
;$format{"x"}   = 25;        # must be odd
;$format{"5-x"} = 26;        # must be even
;$format{"nl"}  = 27;        # n/a
;$format{"2-u"} = 28;        # must be even
;$format{"A"}   = 29;        # n/a
;$format{"s"}   = 30;        # n/a, normal string from DS
;$format{"z"}   = 31;        # n/a, boot string from BDA
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
