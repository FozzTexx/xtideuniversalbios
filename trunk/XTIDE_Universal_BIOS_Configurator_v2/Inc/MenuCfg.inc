; File name		:	MenuCfg.inc
; Project name	:	XTIDE Universal BIOS Configurator v2
; Created date	:	5.10.2010
; Last update	:	18.10.2010
; Author		:	Tomi Tilli
; Description	:	Menu configuration.
%ifndef MENUCFG_INC
%define MENUCFG_INC

TITLE_LINES_IN_MENU			EQU		3
INFO_LINES_IN_MENU			EQU		4
MENU_WIDTH					EQU		40
MAX_VALUE_STRING_LENGTH		EQU		12


KEY_BACK_TO_PREVIOUS_MENU	EQU		ESC
KEY_DISPLAY_ITEM_HELP		EQU		3Bh		; F1


%endif ; MENUCFG_INC
