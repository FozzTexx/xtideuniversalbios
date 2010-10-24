; File name		:	AssemblyLibrary.asm
; Project name	:	Assembly Library
; Created date	:	15.9.2010
; Last update	:	24.10.2010
; Author		:	Tomi Tilli
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
	%include "DisplayFormat.asm"
	%include "DisplayPage.asm"
	%include "DisplayPrint.asm"
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
	%include "Bit.asm"
	%include "Memory.asm"
	%include "Registers.asm"
	%include "Size.asm"
	%include "Sort.asm"
%endif
