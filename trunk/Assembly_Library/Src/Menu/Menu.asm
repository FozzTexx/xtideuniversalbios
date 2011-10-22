; Project name	:	Assembly Library
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
	call	di
	pop		bx
	pop		cx
	pop		dx
	pop		si
	ret


%define DisplayWithHandlerInBXandUserDataInDXAX		MenuInit_DisplayMenuWithHandlerInBXandUserDataInDXAX
;%define Close										MenuInit_CloseMenuWindow				; Special case in CALL_MENU_LIBRARY
%define RefreshWindow						MenuInit_RefreshMenuWindow

;%define SetUserDataFromDSSI				MenuInit_SetUserDataFromDSSI			; Special case in CALL_MENU_LIBRARY
;%define GetUserDataToDSSI					MenuInit_GetUserDataToDSSI				; Special case in CALL_MENU_LIBRARY

;%define SetTitleHeightFromAL				MenuInit_SetTitleHeightFromAL			; Special case in CALL_MENU_LIBRARY
%define ClearTitleArea						MenuText_ClearTitleArea
%define RefreshTitle						MenuText_RefreshTitle

%define HighlightItemFromAX					MenuInit_HighlightItemFromAX
;%define SetTotalItemsFromAX				MenuInit_SetTotalItemsFromAX			; Special case in CALL_MENU_LIBRARY
%define RefreshItemFromAX					MenuText_RefreshItemFromAX

;%define SetInformationHeightFromAL						MenuInit_SetInformationHeightFromAL		; Special case in CALL_MENU_LIBRARY
%define ClearInformationArea							MenuText_ClearInformationArea
%define RefreshInformation								MenuText_RefreshInformation

%define StartSelectionTimeoutWithTicksInAX				MenuTime_StartSelectionTimeoutWithTicksInAX

%ifdef INCLUDE_MENU_DIALOGS
%define StartProgressTaskWithIoInDSSIandParamInDXAX		DialogProgress_StartProgressTaskWithIoInDSSIandParamInDXAX
%define SetProgressValueFromAX							DialogProgress_SetProgressValueFromAX

%define DisplayMessageWithInputInDSSI					DialogMessage_DisplayMessageWithInputInDSSI
%define GetSelectionToAXwithInputInDSSI					DialogSelection_GetSelectionToAXwithInputInDSSI
%define GetWordWithIoInDSSI								DialogWord_GetWordWithIoInDSSI
%define GetStringWithIoInDSSI							DialogString_GetStringWithIoInDSSI
%define GetFileNameWithIoInDSSI							DialogFile_GetFileNameWithIoInDSSI
%define GetDriveWithIoInDSSI							DialogDrive_GetDriveWithIoInDSSI
%endif

