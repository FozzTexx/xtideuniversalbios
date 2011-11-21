; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	Menu page and item structs.
%ifndef MENU_STRUCTS_INC
%define MENU_STRUCTS_INC

struc MENUPAGE
	.fnEnter			resb	2	; Function to initialize MENUPAGE
	.fnBack				resb	2	; Function to initialize previous MENUPAGE
	.wMenuitems			resb	2	; Number of MENUITEM structs
	.rgMenuitem:					; All MENUITEM structs in this MENUPAGE
endstruc

struc MENUITEM
	.fnActivate			resb	2	; Offset to item activation function
	.fnFormatValue		resb	2	; Offset to item value formatting function

	.szName				resb	2	; Offset to item name string
	.szQuickInfo		resb	2	; Offset to item quick information string
	.szHelp				resb	2	; Offset to item help string

	.bFlags				resb	1	; Item flags
	.bType				resb	1	; Item type
	.itemValue			resb	ITEM_VALUE_size		; ITEM_VALUE for automated item handling
endstruc

; Bit defines for MENUITEM.bFlags
FLG_MENUITEM_VISIBLE		EQU	(1<<0)	; Item is visible
FLG_MENUITEM_MODIFY_MENU	EQU	(1<<1)	; Item modifies visibility of other items
FLG_MENUITEM_FLAGVALUE		EQU	(1<<2)	; Item value is single bit
FLG_MENUITEM_BYTEVALUE		EQU	(1<<3)	; Item value is single byte
FLG_MENUITEM_PROGRAMVAR		EQU	(1<<4)	; Item is for configuring program, not BIOS

; Values for MENUITEM.bType
TYPE_MENUITEM_PAGEBACK		EQU	(0<<1)	; Item returns to previous MENUPAGE
TYPE_MENUITEM_PAGENEXT		EQU	(1<<1)	; Item changes to next MENUPAGE
TYPE_MENUITEM_ACTION		EQU	(2<<1)	; Non-configurable item
TYPE_MENUITEM_MULTICHOICE	EQU	(3<<1)	; Item with multiple predefined choices
TYPE_MENUITEM_UNSIGNED		EQU	(4<<1)	; Menuitem with user inputted unsigned decimal value
TYPE_MENUITEM_HEX			EQU	(5<<1)	; Menuitem with user inputted hexadecimal value


struc ITEM_VALUE
	.wRomvarsValueOffset	resb	2	; ROMVARS offset to actual value to be configured
	.szDialogTitle			resb	2	; Dialog title string

	.szMultichoice			resb	2	; Multiple choices in one string
	.rgwChoiceToValueLookup	resb	2	; Ptr to lookup table for translating selected choice to actual value
	.rgszValueToStringLookup:			; Ptr to lookup table for translating value to string
	.wMinValue				resb	2	; Minimum allowed integer value
	.wMaxValue:
	.wValueBitmask			resb	2	; Bitmask for item value flag
	.fnValueReader			resb	2	; Called just after ROMVARS is read, providing a hook for further action
	.fnValueWriter			resb	2	; Called just before ROMVARS is written, providing a hook for further action
endstruc


%endif ; MENU_STRUCTS_INC
