; File name		:	Menu.asm
; Project name	:	Assembly Library
; Created date	:	3.8.2010
; Last update	:	22.11.2010
; Author		:	Tomi Tilli
; Description	:	Menu Library functions for CALL_MENU_LIBRARY macro
;					that users should use to make library call.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuFunctionFromDI
;	Parameters:
;		DI:		Function to call (MENU_LIB.functionName)
;		BP:		Menu handle
;		Others:	Depends on function to call
;	Returns:
;		Depends on function to call
;	Corrupts registers:
;		AX (unless used as a return register), DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_FunctionFromDI:
	push	si
	push	dx
	push	cx
	push	bx
	call	[cs:di+.rgfnMenuLibraryFunctions]
	pop		bx
	pop		cx
	pop		dx
	pop		si
	ret


ALIGN WORD_ALIGN
.rgfnMenuLibraryFunctions:
istruc MENU_LIB
	at	MENU_LIB.DisplayWithHandlerInBXandUserDataInDXAX,	dw	MenuInit_DisplayMenuWithHandlerInBXandUserDataInDXAX
	;at	MENU_LIB.Close,							dw	MenuInit_CloseMenuWindow				; Special case in CALL_MENU_LIBRARY
	at	MENU_LIB.RefreshWindow,					dw	MenuInit_RefreshMenuWindow

	;at	MENU_LIB.SetUserDataFromDSSI,			dw	MenuInit_SetUserDataFromDSSI			; Special case in CALL_MENU_LIBRARY
	;at	MENU_LIB.GetUserDataToDSSI,				dw	MenuInit_GetUserDataToDSSI				; Special case in CALL_MENU_LIBRARY

	;at	MENU_LIB.SetTitleHeightFromAL,			dw	MenuInit_SetTitleHeightFromAL			; Special case in CALL_MENU_LIBRARY
	at	MENU_LIB.ClearTitleArea,				dw	MenuText_ClearTitleArea
	at	MENU_LIB.RefreshTitle,					dw	MenuText_RefreshTitle

	at	MENU_LIB.HighlightItemFromAX,			dw	MenuInit_HighlightItemFromAX
	;at	MENU_LIB.SetTotalItemsFromAX,			dw	MenuInit_SetTotalItemsFromAX			; Special case in CALL_MENU_LIBRARY
	at	MENU_LIB.RefreshItemFromAX,				dw	MenuText_RefreshItemFromAX

	;at	MENU_LIB.SetInformationHeightFromAL,	dw	MenuInit_SetInformationHeightFromAL		; Special case in CALL_MENU_LIBRARY
	at	MENU_LIB.ClearInformationArea,			dw	MenuText_ClearInformationArea
	at	MENU_LIB.RefreshInformation,			dw	MenuText_RefreshInformation

	at	MENU_LIB.StartSelectionTimeoutWithTicksInAX,	dw	MenuTime_StartSelectionTimeoutWithTicksInAX

%ifdef INCLUDE_MENU_DIALOGS
	at	MENU_LIB.StartProgressTaskWithIoInDSSIandParamInDXAX,	dw	DialogProgress_StartProgressTaskWithIoInDSSIandParamInDXAX
	at	MENU_LIB.SetProgressValueFromAX,						dw	DialogProgress_SetProgressValueFromAX

	at	MENU_LIB.DisplayMessageWithInputInDSSI,					dw	DialogMessage_DisplayMessageWithInputInDSSI
	at	MENU_LIB.GetSelectionToAXwithInputInDSSI,				dw	DialogSelection_GetSelectionToAXwithInputInDSSI
	at	MENU_LIB.GetWordWithIoInDSSI,							dw	DialogWord_GetWordWithIoInDSSI
	at	MENU_LIB.GetStringWithIoInDSSI,							dw	DialogString_GetStringWithIoInDSSI
	at	MENU_LIB.GetFileNameWithIoInDSSI,						dw	DialogFile_GetFileNameWithIoInDSSI
	at	MENU_LIB.GetDriveWithIoInDSSI,							dw	DialogDrive_GetDriveWithIoInDSSI
%endif
iend
