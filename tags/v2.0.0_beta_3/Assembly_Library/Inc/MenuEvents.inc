; Project name	:	Assembly Library
; Description	:	Defines for Menu events send to the user.
%ifndef MENUEVENTS_INC
%define MENUEVENTS_INC

;--------------------------------------------------------------------
; Events to be processed in user implemented handler.
;	Common parameters for all events:
;		BX:			Menu event (anything from MENUEVENT struct)
;		SS:BP:		Menu library handle
;	Common return values for all events:
;		CF:			Set if event processed
;					Cleared if event not processed
;	Corrupts registers:
;		All
;--------------------------------------------------------------------

;
; There are two ways to use MENUEVENT:
;
; 1. If the program needs two different menus, include the definition of the MENUEVENT structure below,
;    instantiate with members that point to the routines that make up the menu.
;
; 2. If the program needs only one menu, %define MENUEVENT_INLINE_OFFSETS before this include file,
;    and define (through EQU statements) each of the entry points as offsets from a base address.
;

;
; If user level idle processing is desired, %define this symbol and .IdleProcessing will be called.
; Otherwise, the code and structure entry will be omitted.  Note that INCLUDE_MENU_DIALOGS requires
; the idle processing (if that is the case, it is turned on here).
;
;%define MENUEVENT_IDLEPROCESSING_ENABLE
;

%ifdef INCLUDE_MENU_DIALOGS
%define MENUEVENT_IDLEPROCESSING_ENABLE
%endif

%ifndef MENUEVENT_INLINE_OFFSETS

struc MENUEVENT
	; Parameters:
	;	DS:SI:		Ptr to MENUINIT struct to initialize
	; Returns:
	;	DS:SI:		Ptr to initialized MENUINIT struct
	.InitializeMenuinitFromDSSI	resb	2
%define MENUEVENT_InitializeMenuinitFromDSSI	MENUEVENT.InitializeMenuinitFromDSSI

	; Parameters:
	;	None
	; Returns:
	;	CF:			Set to exit menu
	;				Clear to cancel exit
	.ExitMenu					resb	2
%define MENUEVENT_ExitMenu						MENUEVENT.ExitMenu

%ifdef MENUEVENT_IDLEPROCESSING_ENABLE
	; Parameters:
	;	None
	; See the definition of MENUEVENT_IDLEPROCESSING_ENABLE below.
	.IdleProcessing				resb	2
%define MENUEVENT_IdleProcessing				MENUEVENT.IdleProcessing
%endif

	; Parameters:
	;	CX:			Index of new highlighted item
	;	DX:			Index of previously highlighted item or NO_ITEM_HIGHLIGHTED
	.ItemHighlightedFromCX		resb	2
%define MENUEVENT_ItemHighlightedFromCX			MENUEVENT.ItemHighlightedFromCX

	; Parameters:
	;	CX:			Index of selected item
	.ItemSelectedFromCX			resb	2
%define MENUEVENT_ItemSelectedFromCX			MENUEVENT.ItemSelectedFromCX

	; Parameters:
	;	AL:			ASCII character for the key
	;	AH:			Keyboard library scan code for the key
	.KeyStrokeInAX				resb	2
%define MENUEVENT_KeyStrokeInAX					MENUEVENT.KeyStrokeInAX

	; Parameters:
	;	CX:			Index of highlighted item
	;	Cursor has been positioned to the beginning of first line
	.RefreshTitle				resb	2
	.RefreshInformation			resb	2
%define MENUEVENT_RefreshTitle					MENUEVENT.RefreshTitle
%define MENUEVENT_RefreshInformation			MENUEVENT.RefreshInformation

	; Parameters:
	;	CX:			Index of item to refresh
	;	Cursor has been positioned to the beginning of item line
	.RefreshItemFromCX			resb	2
%define MENUEVENT_RefreshItemFromCX				MENUEVENT.RefreshItemFromCX
endstruc

%endif ; MENUEVENT_INLINE_OFFSETS

%endif ; MENUEVENTS_INC
