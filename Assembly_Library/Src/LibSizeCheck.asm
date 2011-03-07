; Project name	:	Assembly Library
; Description	:	Tests for Assembly Library.
;					Builds wanted library functions to check their size.

; Include .inc files
;%define INCLUDE_DISPLAY_LIBRARY
;%define INCLUDE_FILE_LIBRARY
;%define INCLUDE_KEYBOARD_LIBRARY
%define INCLUDE_MENU_LIBRARY
;%define INCLUDE_MENU_DIALOGS
;%define INCLUDE_STRING_LIBRARY
;%define INCLUDE_TIME_LIBRARY
;%define INCLUDE_UTIL_LIBRARY

%include "AssemblyLibrary.inc"	; Assembly Library. Must be included first!


; Include library sources
%include "AssemblyLibrary.asm"
