; File name		:	Menu.inc
; Project name	:	Assembly Library
; Created date	:	13.7.2010
; Last update	:	23.10.2010
; Author		:	Tomi Tilli
; Description	:	Defines for Menu library.
%ifndef MENU_INC
%define MENU_INC

;--------------------------------------------------------------------
; Menu Library users need to use this macro since it will provide
; compatibility with future library versions.
;
; CALL_MENU_LIBRARY
;	Parameters:
;		%1:			Function to call (functionName from MENU_LIB)
;		BP:			Menu handle
;		Registers:	Depends on function to call
;	Returns:
;		Depends on function to call
;	Corrupts registers:
;		AX (unless used as a return register), DI
;--------------------------------------------------------------------
%macro CALL_MENU_LIBRARY 1
	%ifidn %1, Close
		call	MenuInit_CloseMenuWindow

	%elifidn %1, SetUserDataFromDSSI
		call	MenuInit_SetUserDataFromDSSI

	%elifidn %1, GetUserDataToDSSI
		call	MenuInit_GetUserDataToDSSI

	%elifidn %1, SetTitleHeightFromAL
		call	MenuInit_SetTitleHeightFromAL

	%elifidn %1, GetHighlightedItemToAX
		call	MenuInit_GetHighlightedItemToAX

	%elifidn %1, SetTotalItemsFromAX
		call	MenuInit_SetTotalItemsFromAX

	%elifidn %1, SetInformationHeightFromAL
		call	MenuInit_SetInformationHeightFromAL

	%elifidn %1, SetTimeoutValueFromAX
		call	MenuTime_SetSelectionTimeoutValueFromAX

	%else
		mov		di, MENU_LIB.%1
		call	Menu_FunctionFromDI
	%endif
%endmacro

; Menu library functions
struc MENU_LIB
	.DisplayWithHandlerInBXandUserDataInDXAX	resb	2
	.Close:
	.RefreshWindow								resb	2

	.SetUserDataFromDSSI:
	.GetUserDataToDSSI:

	.SetTitleHeightFromAL:
	.ClearTitleArea								resb	2
	.RefreshTitle								resb	2

	.GetHighlightedItemToAX:
	.HighlightItemFromAX						resb	2
	.SetTotalItemsFromAX:
	.RefreshItemFromAX							resb	2

	.SetInformationHeightFromAL:
	.ClearInformationArea						resb	2
	.RefreshInformation							resb	2

	.RestartTimeout								resb	2
	.SetTimeoutValueFromAX:

%ifdef INCLUDE_MENU_DIALOGS
	.StartProgressTaskWithIoInDSSIandParamInDXAX	resb	2
	.SetProgressValueFromAX							resb	2

	.DisplayMessageWithInputInDSSI					resb	2
	.GetSelectionToAXwithInputInDSSI				resb	2
	.GetWordWithIoInDSSI							resb	2
	.GetStringWithIoInDSSI							resb	2
	.GetFileNameWithIoInDSSI						resb	2
	.GetDriveWithIoInDSSI							resb	2
%endif
endstruc


; Menu initialization parameters
struc MENUINIT
	.wTimeoutTicks					resb	2	; Selection timeout in system timer ticks
	.wItems							resb	2	; Number of items in menu
	.wHighlightedItem				resb	2	; Index for highlighted item

	.wTitleAndInfoLines:
	.bTitleLines					resb	1	; Number of title lines
	.bInfoLines						resb	1	; Number of information lines

	.wWidthAndHeight:
	.bWidth							resb	1	; Menu width in characters
	.bHeight						resb	1	; Menu height in characters
endstruc


; All menu parameters
struc MENU
	.menuInit						resb	MENUINIT_size	; Must be first
	.fnEventHandler					resb	2	; Offset to Menu event handler
	.dwUserData						resb	4	; User specified data

	.bFlags							resb	1	; Menu flags
									resb	1
	.wTimeoutCounter				resb	2
	.wFirstVisibleItem				resb	2	; Index for first visible item on the menu
endstruc

; Flags for MENU.wFlags
FLG_MENU_EXIT						EQU		(1<<0)	; Close and exit menu
FLG_MENU_NOHIGHLIGHT				EQU		(1<<1)	; Never highlight items
FLG_MENU_USER_HANDLES_SCROLLING		EQU		(1<<2)


MENU_VERTICAL_BORDER_LINES			EQU		5	; Title top and bottom + Info top and bottom + bottom shadow
MENU_HORIZONTAL_BORDER_LINES		EQU		3	; Left + Right borders + Right shadow
MENU_TEXT_ROW_OFFSET				EQU		1
MENU_TEXT_COLUMN_OFFSET				EQU		2

SCROLL_TRACK_CHARACTER				EQU		BLOCK_EVEN_BACKGROUND_AND_FOREGROUND
SCROLL_THUMB_CHARACTER				EQU		BLOCK_FULL_FOREGROUND

NO_ITEM_SELECTED					EQU		-1
NO_ITEM_HIGHLIGHTED					EQU		-1
NO_TIMEOUT_USED						EQU		0


; Keyboard keys (scan codes) used by menu library
MENU_KEY_ENTER		EQU		1Ch
MENU_KEY_ESC		EQU		01h
MENU_KEY_UP			EQU		48h
MENU_KEY_DOWN		EQU		50h
MENU_KEY_PGUP		EQU		49h
MENU_KEY_PGDN		EQU		51h
MENU_KEY_HOME		EQU		47h
MENU_KEY_END		EQU		4Fh


%endif ; MENU_INC
