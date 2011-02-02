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
	%include "DisplayPrint.asm"
	%include "DisplayFormat.asm"
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
	%include "String.asm"
	%include "StringProcess.asm"
%endif

%ifdef INCLUDE_TIME_LIBRARY
	%include "Delay.asm"
	%include "TimerTicks.asm"
%endif

%ifdef INCLUDE_UTIL_LIBRARY
	%ifndef EXCLUDE_BIT_UTILS
		%include "Bit.asm"
	%endif
	%include "Registers.asm"
	%include "Memory.asm"
	%include "Size.asm"
	%ifndef EXCLUDE_SORT_UTILS
		%include "Sort.asm"
	%endif
%endif
