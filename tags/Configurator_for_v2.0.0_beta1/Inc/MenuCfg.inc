; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	Menu configuration.
%ifndef MENUCFG_INC
%define MENUCFG_INC

TITLE_LINES_IN_MENU			EQU		3
INFO_LINES_IN_MENU			EQU		6
MENU_WIDTH					EQU		40
MAX_VALUE_STRING_LENGTH		EQU		12


KEY_BACK_TO_PREVIOUS_MENU	EQU		ESC
KEY_DISPLAY_ITEM_HELP		EQU		3Bh		; F1


%endif ; MENUCFG_INC
