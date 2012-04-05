; Project name	:	Assembly Library
; Description	:	Assembly Library main file. This is the only file that
;					needs to be included.

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

%ifdef INCLUDE_DISPLAY_LIBRARY
  %ifndef DISPLAY_JUMP_ALIGN
	%define DISPLAY_JUMP_ALIGN 1
  %endif
	%include "CgaSnow.asm"
	%include "Display.asm"
	%include "DisplayCharOut.asm"
	%include "DisplayContext.asm"
	%include "DisplayCursor.asm"
	%include "DisplayPage.asm"
	%include "DisplayPrint.asm"					; must come before DisplayFormat/DisplayFormatCompressed
%ifdef MODULE_STRINGS_COMPRESSED
	%include "DisplayFormatCompressed.asm"
%else
	%include "DisplayFormat.asm"
%endif
%endif

%ifdef INCLUDE_FILE_LIBRARY
	%include "Directory.asm"
	%include "DosCritical.asm"
	%include "Drive.asm"
	%include "FileIO.asm"
%endif

%ifdef INCLUDE_KEYBOARD_LIBRARY
  %ifndef KEYBOARD_JUMP_ALIGN
	%define KEYBOARD_JUMP_ALIGN 1
  %endif
	%include "Keyboard.asm"
%endif

%ifdef INCLUDE_MENU_LIBRARY
  %ifndef MENU_JUMP_ALIGN
	%define MENU_JUMP_ALIGN 1
  %endif
	%include "CharOutLineSplitter.asm"
	%include "Menu.asm"
	%include "MenuAttributes.asm"
	%include "MenuBorders.asm"
	%include "MenuCharOut.asm"
	%include "MenuEvent.asm"
	%include "MenuInit.asm"
	%include "MenuLocation.asm"
	%include "MenuLoop.asm"
	%include "MenuScrollbars.asm"
	%include "MenuText.asm"
	%include "MenuTime.asm"

	%ifdef INCLUDE_MENU_DIALOGS
		%include "Dialog.asm"
		%include "DialogDrive.asm"
		%include "DialogFile.asm"
		%include "DialogMessage.asm"
		%include "DialogProgress.asm"
		%include "DialogSelection.asm"
		%include "DialogString.asm"
		%include "DialogWord.asm"
		%include "ItemLineSplitter.asm"
		%include "StringsForDialogs.asm"
	%endif
%endif

%ifdef INCLUDE_STRING_LIBRARY
  %ifndef STRING_JUMP_ALIGN
	%define STRING_JUMP_ALIGN 1
  %endif
	%include "Char.asm"
	%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
		%include "String.asm"
		%include "StringProcess.asm"
	%endif
%endif

%ifdef INCLUDE_SERIAL_LIBRARY
	%include "Serial.inc"
%endif
%ifdef INCLUDE_SERIALSERVER_LIBRARY
	%include "SerialServer.asm"
	%include "SerialServerScan.asm"
	%define INCLUDE_TIME_LIBRARY
%endif

%ifdef INCLUDE_TIME_LIBRARY
	%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
		%include "Delay.asm"
		%ifndef EXCLUDE_FROM_XTIDECFG
			%include "SystemTimer.asm"
		%endif
	%endif
	%include "TimerTicks.asm"
%endif

%ifdef INCLUDE_UTIL_LIBRARY
  %ifndef UTIL_SIZE_JUMP_ALIGN
	%define UTIL_SIZE_JUMP_ALIGN 1
  %endif
	%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
		%include "Bit.asm"
	%endif
	%include "Math.asm"
	%include "Registers.asm"
	%include "Reboot.asm"
	%include "Memory.asm"
	%include "Size.asm"
	%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
		%include "Sort.asm"
	%endif
%endif

