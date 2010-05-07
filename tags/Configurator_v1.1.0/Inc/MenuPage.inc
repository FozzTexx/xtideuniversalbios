; File name		:	MenuPage.inc
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	16.4.2010
; Last update	:	25.4.2010
; Author		:	Tomi Tilli
; Description	:	Structs for menu pages and items.
%ifndef MENUPAGE_INC
%define MENUPAGE_INC

; Variables for menu page (main menu and submenus)
struc MENUPAGE
	.bItemCnt			resb	1	; Number of MENUPAGEITEM structs
						resb	1
	.prgbItemToVal		resb	2	; Ptr to menuitem index to value lookup table
	.rgMenuPageItem:				; MENUPAGEITEM structs (variable number)
endstruc


; Variables for single menuitem
struc MENUPAGEITEM
	.fnActivate			resb	2	; Offset to Menuitem activation function
	.fnNameFormat		resb	2	; Offset to Menuitem name formatting function
	.pValue				resb	2	; Offset to Menuitem value

	.pSubMenuPage:					; Ptr to MENUPAGE for new submenu
	.wValueMin			resb	2	; Minimum integer value

	.rgszLookup:					; Ptr to lookup table for string values
	.wValueMax:						; Maximum integer value
	.wValueMask			resb	2	; Bitmask for Menuitem value flag

	.szName				resb	2	; Offset to Menuitem name string
	.szInfo				resb	2	; Offset to Menuitem information string
	.szHelp				resb	2	; Offset to Menuitem help string
	.szDialog			resb	2	; Offset to new value or other dialog string
	.bFlags				resb	1	; Menuitem flags
	.bType				resb	1	; Menuitem type
endstruc

; Bit defines for MENUPAGEITEM.bFlags
FLG_MENUPAGEITEM_VISIBLE		EQU	(1<<0)	; Item is visible

; Values for MENUPAGEITEM.bType
TYPE_MENUPAGEITEM_BACK			EQU	(0<<1)	; Back to previous submenu
TYPE_MENUPAGEITEM_NEXT			EQU	(1<<1)	; Open next submenu
TYPE_MENUPAGEITEM_SPECIAL		EQU	(2<<1)	; Special menuitem without value
TYPE_MENUPAGEITEM_UNSIGNED_BYTE	EQU	(3<<1)	; Menuitem with unsigned byte value
TYPE_MENUPAGEITEM_UNSIGNED_WORD	EQU	(4<<1)	; Menuitem with unsigned word value
TYPE_MENUPAGEITEM_HEX_BYTE		EQU	(5<<1)	; Menuitem with hexadecimal byte value
TYPE_MENUPAGEITEM_HEX_WORD		EQU	(6<<1)	; Menuitem with hexadecimal word value
TYPE_MENUPAGEITEM_FLAG			EQU	(7<<1)	; Menuitem with boolean flag value


%endif ; MENUPAGE_INC
