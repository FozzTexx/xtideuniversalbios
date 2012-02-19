; Project name	:	Assembly Library
; Description	:	Assembly Library main file. This is the only file that
;					needs to be included.

; Section containing code
SECTION .text

%ifdef INCLUDE_DISPLAY_LIBRARY
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
	%include "Keyboard.asm"
%endif

%ifdef INCLUDE_MENU_LIBRARY
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
	%include "Char.asm"
	%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
		%include "String.asm"
		%include "StringProcess.asm"
	%endif
%endif

%ifdef INCLUDE_TIME_LIBRARY
	%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
		%include "Delay.asm"
		%include "SystemTimer.asm"
	%endif
	%include "TimerTicks.asm"
%endif

%ifdef INCLUDE_UTIL_LIBRARY
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
