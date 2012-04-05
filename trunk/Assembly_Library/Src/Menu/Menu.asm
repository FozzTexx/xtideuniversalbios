; Project name	:	Assembly Library
; Description	:	Menu Library functions for CALL_MENU_LIBRARY macro
;					that users should use to make library call.

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.		
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;
		

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
ALIGN MENU_JUMP_ALIGN
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


	%define DisplayWithHandlerInBXandUserDataInDXAX			MenuInit_DisplayMenuWithHandlerInBXandUserDataInDXAX
	;%define Close											MenuInit_CloseMenuWindow				; Special case in CALL_MENU_LIBRARY
	%define RefreshWindow									MenuInit_RefreshMenuWindow

	;%define SetUserDataFromDSSI							MenuInit_SetUserDataFromDSSI			; Special case in CALL_MENU_LIBRARY
	;%define GetUserDataToDSSI								MenuInit_GetUserDataToDSSI				; Special case in CALL_MENU_LIBRARY

	;%define SetTitleHeightFromAL							MenuInit_SetTitleHeightFromAL			; Special case in CALL_MENU_LIBRARY
	%define ClearTitleArea									MenuText_ClearTitleArea
	%define RefreshTitle									MenuText_RefreshTitle

	%define HighlightItemFromAX								MenuInit_HighlightItemFromAX
	;%define SetTotalItemsFromAX							MenuInit_SetTotalItemsFromAX			; Special case in CALL_MENU_LIBRARY
	%define RefreshItemFromAX								MenuText_RefreshItemFromAX

	;%define SetInformationHeightFromAL						MenuInit_SetInformationHeightFromAL		; Special case in CALL_MENU_LIBRARY
	%define ClearInformationArea							MenuText_ClearInformationArea
	%define RefreshInformation								MenuText_RefreshInformation

%ifndef EXCLUDE_FROM_XTIDECFG
	%define StartSelectionTimeoutWithTicksInAX				MenuTime_StartSelectionTimeoutWithTicksInAX
%endif

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

