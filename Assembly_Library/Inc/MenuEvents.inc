; File name		:	MenuEvents.inc
; Project name	:	Assembly Library
; Created date	:	13.7.2010
; Last update	:	18.10.2010
; Author		:	Tomi Tilli
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
struc MENUEVENT
	; Parameters:
	;	DS:SI:		Ptr to MENUINIT struct to initialize
	; Returns:
	;	DS:SI:		Ptr to initialized MENUINIT struct
	.InitializeMenuinitFromDSSI		resb	2

	; Parameters:
	;	None
	; Returns:
	;	CF:			Set to exit menu
	;				Clear to cancel exit
	.ExitMenu						resb	2

	; Parameters:
	;	None
	.IdleProcessing					resb	2

	; Parameters:
	;	CX:			Index of new highlighted item
	;	DX:			Index of previously highlighted item or NO_ITEM_HIGHLIGHTED
	.ItemHighlightedFromCX			resb	2

	; Parameters:
	;	CX:			Index of selected item
	.ItemSelectedFromCX				resb	2

	; Parameters:
	;	AL:			ASCII character for the key
	;	AH:			Keyboard library scan code for the key
	.KeyStrokeInAX					resb	2

	; Parameters:
	;	CX:			Index of highlighted item
	;	Cursor has been positioned to the beginning of first line
	.RefreshTitle					resb	2
	.RefreshInformation				resb	2

	; Parameters:
	;	CX:			Index of item to refresh
	;	Cursor has been positioned to the beginning of item line
	.RefreshItemFromCX				resb	2
endstruc


%endif ; MENUEVENTS_INC
