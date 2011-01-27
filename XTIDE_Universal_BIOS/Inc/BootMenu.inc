; Project name	:	XTIDE Universal BIOS
; Description	:	Equates used in Boot Menu.
%ifndef BOOTMENU_INC
%define BOOTMENU_INC

; Boot menu sizes
BOOT_MENU_TITLE_LINES			EQU	2	; Number of title lines
BOOT_MENU_INFO_LINES			EQU	3	; Number of info lines
BOOT_MENU_TITLE_AND_INFO_LINES	EQU	(BOOT_MENU_TITLE_LINES | (BOOT_MENU_INFO_LINES<<8))
BOOT_MENU_WIDTH					EQU	40	; Menu width in characters
BOOT_MENU_HEIGHT_WITHOUT_ITEMS	EQU	(BOOT_MENU_TITLE_LINES + BOOT_MENU_INFO_LINES + 4)

; Function IDs
ID_BOOTFUNC_ROMBOOT				EQU	0	; ROM boot


%endif ; BOOTMENU_INC
