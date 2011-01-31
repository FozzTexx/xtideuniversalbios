; Project name	:	Assembly Library
; Description	:	Display Library functions for CALL_DISPLAY_LIBRARY macro
;					that users should use to make library call.

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
ALIGN JUMP_ALIGN
Display_FunctionFromDI:
	push	es
	push	ds
	push	dx

	cld
	LOAD_BDA_SEGMENT_TO	ds, dx
	mov		dx, [cs:di+.rgfnDisplayLibraryFunctions]
	les		di, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition]
	call	dx
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition], di

	pop		dx
	pop		ds
	pop		es
	ret

;--------------------------------------------------------------------
; .FormatNullTerminatedStringFromCSSI
;	Parameters:
;		Same as DisplayPrint_FormattedNullTerminatedStringFromCSSI
;	Returns:
;		Stack variables will be cleaned
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.FormatNullTerminatedStringFromCSSI:
	pop		ax					; Discard return address to inside Display_FunctionFromDI
	call	DisplayPrint_FormattedNullTerminatedStringFromCSSI
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition], di

	pop		dx
	pop		ds
	pop		es

	pop		ax					; Pop return address
	mov		sp, bp				; Clean stack variables
	jmp		ax


ALIGN WORD_ALIGN
.rgfnDisplayLibraryFunctions:
istruc DISPLAY_LIB
	at	DISPLAY_LIB.InitializeDisplayContext,						dw	DisplayContext_Initialize

	at	DISPLAY_LIB.SetCharacterPointerFromBXAX,					dw	DisplayContext_SetCharacterPointerFromBXAX
	at	DISPLAY_LIB.SetCharOutputFunctionFromAXwithAttribFlagInBL,	dw	DisplayContext_SetCharOutputFunctionFromAXwithAttribFlagInBL
	at	DISPLAY_LIB.SetCharacterOutputParameterFromAX,				dw	DisplayContext_SetCharacterOutputParameterFromAX
	at	DISPLAY_LIB.SetCharacterAttributeFromAL,					dw	DisplayContext_SetCharacterAttributeFromAL
	at	DISPLAY_LIB.SetCursorShapeFromAX,							dw	DisplayCursor_SetShapeFromAX
	at	DISPLAY_LIB.SetCursorCoordinatesFromAX,						dw	DisplayCursor_SetCoordinatesFromAX
	at	DISPLAY_LIB.SetNewPageFromAL,								dw	DisplayPage_SetFromAL
	at	DISPLAY_LIB.SynchronizeDisplayContextToHardware,			dw	DisplayContext_SynchronizeToHardware

	at	DISPLAY_LIB.GetCharacterPointerToBXAX,						dw	DisplayContext_GetCharacterPointerToBXAX
	at	DISPLAY_LIB.GetSoftwareCoordinatesToAX,						dw	DisplayCursor_GetSoftwareCoordinatesToAX
	at	DISPLAY_LIB.GetColumnsToALandRowsToAH,						dw	DisplayPage_GetColumnsToALandRowsToAH

	at	DISPLAY_LIB.FormatNullTerminatedStringFromCSSI,				dw	.FormatNullTerminatedStringFromCSSI
	at	DISPLAY_LIB.PrintSignedWordFromAXWithBaseInBX,				dw	DisplayPrint_SignedWordFromAXWithBaseInBX
	at	DISPLAY_LIB.PrintWordFromAXwithBaseInBX,					dw	DisplayPrint_WordFromAXWithBaseInBX
	at	DISPLAY_LIB.PrintCharBufferFromBXSIwithLengthInCX,			dw	DisplayPrint_CharacterBufferFromBXSIwithLengthInCX
	at	DISPLAY_LIB.PrintNullTerminatedStringFromBXSI,				dw	DisplayPrint_NullTerminatedStringFromBXSI
	at	DISPLAY_LIB.PrintNullTerminatedStringFromCSSI,				dw	DisplayPrint_NullTerminatedStringFromCSSI
	at	DISPLAY_LIB.PrintRepeatedCharacterFromALwithCountInCX,		dw	DisplayPrint_RepeatCharacterFromALwithCountInCX
	at	DISPLAY_LIB.PrintCharacterFromAL,							dw	DisplayPrint_CharacterFromAL
	at	DISPLAY_LIB.PrintNewlineCharacters,							dw	DisplayPrint_Newline
	at	DISPLAY_LIB.ClearAreaWithHeightInAHandWidthInAL,			dw	DisplayPrint_ClearAreaWithHeightInAHandWidthInAL
	at	DISPLAY_LIB.ClearScreenWithCharInALandAttrInAH,				dw	DisplayPrint_ClearScreenWithCharInALandAttributeInAH
iend
