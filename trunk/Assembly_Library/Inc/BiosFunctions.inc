; File name		:	BiosFunctions.inc
; Project name	:	AssemblyLibrary
; Created date	:	25.6.2010
; Last update	:	24.7.2010
; Author		:	Tomi Tilli
; Description	:	Defines for BIOS functions.
%ifndef BIOS_FUNCTIONS_INC
%define BIOS_FUNCTIONS_INC

; BIOS interrupts
BIOS_VIDEO_INTERRUPT_10h		EQU		10h
BIOS_SYSTEM_INTERRUPT_15h		EQU		15h
BIOS_KEYBOARD_INTERRUPT_16h		EQU		16h


; BIOS video functions
SET_TEXT_MODE_CURSOR_SHAPE		EQU		01h
SET_CURSOR_POSITION				EQU		02h
GET_CURSOR_POSITION_AND_SIZE	EQU		03h
SELECT_ACTIVE_DISPLAY_PAGE		EQU		05h
TELETYPE_OUTPUT					EQU		0Eh

; BIOS keyboard functions
GET_KEYSTROKE					EQU		00h
CHECK_FOR_KEYSTROKE				EQU		01h

; BIOS system functions
EVENT_WAIT						EQU		86h


%endif ; BIOS_FUNCTIONS_INC
