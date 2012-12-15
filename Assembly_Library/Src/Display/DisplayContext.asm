; Project name	:	Assembly Library
; Description	:	Functions for managing display context.

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
; DisplayContext_Initialize
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, DI
;--------------------------------------------------------------------
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_Initialize:
	mov		WORD [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fnCharOut], DEFAULT_CHARACTER_OUTPUT
	mov		BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute], SCREEN_BACKGROUND_ATTRIBUTE
	call	DisplayCursor_GetDefaultCursorShapeToAX
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCursorShape], ax
	; Fall to .DetectAndSetDisplaySegment

;--------------------------------------------------------------------
; .DetectAndSetDisplaySegment
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
.DetectAndSetDisplaySegment:
	mov		ax, COLOR_TEXT_SEGMENT
	cmp		BYTE [VIDEO_BDA.bMode], MDA_TEXT_MODE
	eCMOVE	ah, MONO_TEXT_SEGMENT >> 8
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition+2], ax
	; Fall to .InitializeFlags

;--------------------------------------------------------------------
; .InitializeFlags
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
.InitializeFlags:
	mov		dl, FLG_CONTEXT_ATTRIBUTES
	call	CgaSnow_IsCgaPresent
	jnc		SHORT .DoNotSetCgaFlag
	or		dl, FLG_CONTEXT_CGA
.DoNotSetCgaFlag:
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], dl
	; Fall to .InitializeCursor

;--------------------------------------------------------------------
; .InitializeCursor
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
.InitializeCursor:
	call	DisplayCursor_GetHardwareCoordinatesToAX	; Coordinates before init
	call	DisplayCursor_SetCoordinatesFromAX			; Cursor to Display Context
	; Fall to DisplayContext_SynchronizeToHardware

;--------------------------------------------------------------------
; DisplayContext_SynchronizeToHardware
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_SynchronizeToHardware:
	call	DisplayPage_SynchronizeToHardware
	call	DisplayCursor_SynchronizeShapeToHardware
	jmp		DisplayCursor_SynchronizeCoordinatesToHardware


;--------------------------------------------------------------------
; DisplayContext_Push
; DisplayContext_Pop
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
%ifdef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%ifndef MODULE_BOOT_MENU
		%define EXCLUDE
	%endif
%endif

%ifndef EXCLUDE
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_Push:
	mov		di, ds					; Backup DS
	LOAD_BDA_SEGMENT_TO	ds, ax
	pop		ax						; Pop return address

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%assign i 0
	%rep DISPLAY_CONTEXT_size / 2
		push	WORD [VIDEO_BDA.displayContext + i]
	%assign i i+2
	%endrep
%endif

	mov		ds, di					; Restore DS
	jmp		ax


ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_Pop:
	mov		di, ds					; Backup DS
	LOAD_BDA_SEGMENT_TO	ds, ax
	pop		ax						; Pop return address

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%assign i DISPLAY_CONTEXT_size-2
	%rep DISPLAY_CONTEXT_size / 2
		pop		WORD [VIDEO_BDA.displayContext + i]
	%assign i i-2
	%endrep
%endif

	push	ax						; Push return address
	push	dx
	call	DisplayContext_SynchronizeToHardware
	pop		dx
	mov		ds, di					; Restore DS
	ret
%endif ; EXCLUDE
%undef EXCLUDE


;--------------------------------------------------------------------
; DisplayContext_PrepareOffScreenBufferInESBXwithLengthInCX
;	Parameters:
;		CX:		Off screen buffer length in characters
;		ES:BX:	Ptr to off screen buffer
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_PrepareOffScreenBufferInESBXwithLengthInCX:
	push	ds

	LOAD_BDA_SEGMENT_TO	ds, di
	xchg	ax, bx
	mov		bx, es
	call	DisplayContext_SetCharacterPointerFromBXAX	; ES:DI now has the pointer

	mov		bl, ATTRIBUTES_NOT_USED
	mov		ax, BUFFER_OUTPUT_WITH_CHAR_ONLY
	call	DisplayContext_SetCharOutputFunctionFromAXwithAttribFlagInBL
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam], cx

	mov		bx, di
	pop		ds
	ret
%endif ; EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS


;--------------------------------------------------------------------
; DisplayContext_SetCharacterPointerFromBXAX
;	Parameters:
;		BX:AX:	Ptr to destination for next character to output
;		DS:		BDA segment (zero)
;	Returns:
;		ES:DI:	Pointer that was in BX:AX
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_SetCharacterPointerFromBXAX:
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition], ax
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition+2], bx
	xchg	di, ax
	mov		es, bx
	ret
%endif


;--------------------------------------------------------------------
; DisplayContext_GetCharacterPointerToBXAX
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		BX:AX:	Ptr to destination for next character to output
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_GetCharacterPointerToBXAX:
	mov		ax, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition]
	mov		bx, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition+2]
	ret
%endif


%ifdef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%ifndef MODULE_BOOT_MENU
		%define EXCLUDE
	%endif
%endif
;--------------------------------------------------------------------
; DisplayContext_SetCharOutputFunctionFromAXwithAttribFlagInBL
;	Parameters:
;		AX:		Offset to character output function
;		BL:		Attribute Flag
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BL
;--------------------------------------------------------------------
%ifndef EXCLUDE	; 1 of 3
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_SetCharOutputFunctionFromAXwithAttribFlagInBL:
	and		bl, FLG_CONTEXT_ATTRIBUTES
	and		BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], ~FLG_CONTEXT_ATTRIBUTES
	or		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], bl
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fnCharOut], ax
	ret
%endif


;--------------------------------------------------------------------
; DisplayContext_SetCharacterAttributeFromAL
;	Parameters:
;		AL:		Character attribute
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE	; 2 of 3
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_SetCharacterAttributeFromAL:
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute], al
	ret
%endif


;--------------------------------------------------------------------
; DisplayContext_SetCharacterOutputParameterFromAX
;	Parameters:
;		AX:		Parameter for Character Output function
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE	; 3 of 3
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_SetCharacterOutputParameterFromAX:
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam], ax
	ret
%endif

%undef EXCLUDE


;--------------------------------------------------------------------
; DisplayContext_GetCharacterOutputParameterToDX
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		DX:		User parameter for Character Output function
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS OR EXCLUDE_FROM_XTIDECFG
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_GetCharacterOutputParameterToDX:
	mov		dx, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam]
	ret
%endif


;--------------------------------------------------------------------
; DisplayContext_GetCharacterOffsetToAXfromByteOffsetInAX
;	Parameters:
;		AX:		Offset in bytes from some character to another
;		DS:		BDA segment (zero)
;	Returns:
;		AX:		Offset in characters from some character to another
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef MODULE_STRINGS_COMPRESSED
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_GetCharacterOffsetToAXfromByteOffsetInAX:
	test	BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], FLG_CONTEXT_ATTRIBUTES
	jz		SHORT ReturnOffsetInAX
	sar		ax, 1		; BYTE count to WORD count
	ret
%endif


;--------------------------------------------------------------------
; DisplayContext_GetByteOffsetToAXfromCharacterOffsetInAX
;	Parameters:
;		AX:		Offset in characters from some character to another
;		DS:		BDA segment (zero)
;	Returns:
;		AX:		Offset in bytes from some character to another
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef MODULE_STRINGS_COMPRESSED
ALIGN DISPLAY_JUMP_ALIGN
DisplayContext_GetByteOffsetToAXfromCharacterOffsetInAX:
	test	BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], FLG_CONTEXT_ATTRIBUTES
	jz		SHORT ReturnOffsetInAX
	sal		ax, 1		; WORD count to BYTE count
ALIGN DISPLAY_JUMP_ALIGN, ret
ReturnOffsetInAX:
	ret
%endif
