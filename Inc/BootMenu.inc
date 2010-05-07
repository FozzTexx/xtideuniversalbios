; File name		:	BootMenu.inc
; Project name	:	IDE BIOS
; Created date	:	26.3.2010
; Last update	:	26.3.2010
; Author		:	Tomi Tilli
; Description	:	Equates used in Boot Menu.
%ifndef BOOTMENU_INC
%define BOOTMENU_INC

; Boot menu sizes
MENU_TITLE_LINE_CNT		EQU	3		; Number of title lines
MENU_INFO_LINE_CNT		EQU	3		; Number of info lines
MENU_WIDTH_IN_CHARS		EQU	38		; Menu width in characters
MENU_HEIGHT_IN_CHARS_WITH_INFO		EQU	(MENU_TITLE_LINE_CNT + MENU_INFO_LINE_CNT + 4)
MENU_HEIGHT_IN_CHARS_WITHOUT_INFO	EQU	(MENU_TITLE_LINE_CNT + 3)

; Function IDs
ID_BOOTFUNC_ROMBOOT		EQU	0		; ROM boot


%endif ; BOOTMENU_INC
