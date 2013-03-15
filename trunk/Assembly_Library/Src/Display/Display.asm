; Project name	:	Assembly Library
; Description	:	Display Library functions for CALL_DISPLAY_LIBRARY macro
;					that users should use to make library call.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
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
; DisplayFunctionFromDI
;	Parameters:
;		DI:		Function to call (DISPLAY_LIB.functionName)
;		Others:	Depends on function to call (DX cannot be parameter)
;	Returns:
;		Depends on function to call
;	Corrupts registers:
;		AX (unless used as a return register), DI
;--------------------------------------------------------------------
ALIGN DISPLAY_JUMP_ALIGN
Display_FunctionFromDI:
	push	es
	push	ds
	push	dx

	cld
	LOAD_BDA_SEGMENT_TO	ds, dx
	mov		dx, di
	les		di, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition]
	call	dx
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition], di

	pop		dx
	pop		ds
	pop		es
	ret

;--------------------------------------------------------------------
; Display_FormatNullTerminatedStringFromCSSI
;	Parameters:
;		Same as DisplayPrint_FormattedNullTerminatedStringFromCSSI
;	Returns:
;		Stack variables will be cleaned
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN DISPLAY_JUMP_ALIGN
Display_FormatNullTerminatedStringFromCSSI:
	pop		ax					; Discard return address to inside Display_FunctionFromDI
	call	DisplayPrint_FormattedNullTerminatedStringFromCSSI
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition], di

	pop		dx
	pop		ds
	pop		es

	pop		ax					; Pop return address
	mov		sp, bp				; Clean stack variables
	jmp		ax


	%define InitializeDisplayContext						DisplayContext_Initialize

%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%define SetCharacterPointerFromBXAX						DisplayContext_SetCharacterPointerFromBXAX
%endif
	%define SetCharOutputFunctionFromAXwithAttribFlagInBL	DisplayContext_SetCharOutputFunctionFromAXwithAttribFlagInBL
	%define SetCharacterOutputParameterFromAX				DisplayContext_SetCharacterOutputParameterFromAX
	%define SetCharacterAttributeFromAL						DisplayContext_SetCharacterAttributeFromAL
	%define SetCursorShapeFromAX							DisplayCursor_SetShapeFromAX
	%define SetCursorCoordinatesFromAX						DisplayCursor_SetCoordinatesFromAX
%ifndef EXCLUDE_FROM_XTIDECFG
	%define SetNewPageFromAL								DisplayPage_SetFromAL
%endif
	%define SynchronizeDisplayContextToHardware				DisplayContext_SynchronizeToHardware

%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%define GetCharacterPointerToBXAX						DisplayContext_GetCharacterPointerToBXAX
%endif
	%define GetSoftwareCoordinatesToAX						DisplayCursor_GetSoftwareCoordinatesToAX
	%define GetColumnsToALandRowsToAH						DisplayPage_GetColumnsToALandRowsToAH

	%define FormatNullTerminatedStringFromCSSI				Display_FormatNullTerminatedStringFromCSSI
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%define PrintSignedWordFromAXWithBaseInBX				DisplayPrint_SignedWordFromAXWithBaseInBX
%endif
	%define PrintWordFromAXwithBaseInBX						DisplayPrint_WordFromAXWithBaseInBX
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS OR EXCLUDE_FROM_XTIDECFG
	%define PrintQWordFromSSBPwithBaseInBX					DisplayPrint_QWordFromSSBPwithBaseInBX
%endif
	%define PrintCharBufferFromBXSIwithLengthInCX			DisplayPrint_CharacterBufferFromBXSIwithLengthInCX
	%define PrintNullTerminatedStringFromBXSI				DisplayPrint_NullTerminatedStringFromBXSI
	%define PrintNullTerminatedStringFromCSSI				DisplayPrint_NullTerminatedStringFromCSSI
	%define PrintRepeatedCharacterFromALwithCountInCX		DisplayPrint_RepeatCharacterFromALwithCountInCX
	%define PrintCharacterFromAL							DisplayPrint_CharacterFromAL
	%define PrintNewlineCharacters							DisplayPrint_Newline
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%define ClearAreaWithHeightInAHandWidthInAL				DisplayPrint_ClearAreaWithHeightInAHandWidthInAL
%endif
	%define ClearScreenWithCharInALandAttrInAH				DisplayPrint_ClearScreenWithCharInALandAttributeInAH

