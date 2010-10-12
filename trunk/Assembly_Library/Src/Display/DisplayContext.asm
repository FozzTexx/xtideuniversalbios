; File name		:	DisplayContext.asm
; Project name	:	Assembly Library
; Created date	:	25.6.2010
; Last update	:	11.10.2010
; Author		:	Tomi Tilli
; Description	:	Functions for managing display context.

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
ALIGN JUMP_ALIGN
DisplayContext_Initialize:
	call	.DetectAndSetDisplaySegment	; and .InitializeFlags
	mov		WORD [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fnCharOut], DEFAULT_CHARACTER_OUTPUT
	mov		WORD [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCursorShape], CURSOR_NORMAL
	mov		BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute], SCREEN_BACKGROUND_ATTRIBUTE
	xor		ax, ax
	call	DisplayCursor_SetCoordinatesFromAX
	jmp		DisplayContext_SynchronizeToHardware

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
	jne		SHORT .StoreSegmentToDisplayContext
	mov		ax, MONO_TEXT_SEGMENT
.StoreSegmentToDisplayContext:
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition+2], ax
	; Fall to InitializeFlags

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
	ret


;--------------------------------------------------------------------
; DisplayContext_Push
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayContext_Push:
	mov		di, ds					; Backup DS
	LOAD_BDA_SEGMENT_TO	ds, ax
	pop		ax						; Pop return address

	%assign i 0
	%rep DISPLAY_CONTEXT_size / 2
		push	WORD [VIDEO_BDA.displayContext + i]
	%assign i i+2
	%endrep

	mov		ds, di					; Restore DS
	jmp		ax

;--------------------------------------------------------------------
; DisplayContext_Pop
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayContext_Pop:
	mov		di, ds					; Backup DS
	LOAD_BDA_SEGMENT_TO	ds, ax
	pop		ax						; Pop return address

	%assign i DISPLAY_CONTEXT_size-2
	%rep DISPLAY_CONTEXT_size / 2
		pop		WORD [VIDEO_BDA.displayContext + i]
	%assign i i-2
	%endrep

	push	ax						; Push return address
	push	dx
	call	DisplayContext_SynchronizeToHardware
	pop		dx
	mov		ds, di					; Restore DS
	ret


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
ALIGN JUMP_ALIGN
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


;--------------------------------------------------------------------
; DisplayContext_SynchronizeToHardware
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayContext_SynchronizeToHardware:
	call	DisplayPage_SynchronizeToHardware
	call	DisplayCursor_SynchronizeShapeToHardware
	jmp		DisplayCursor_SynchronizeCoordinatesToHardware


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
ALIGN JUMP_ALIGN
DisplayContext_SetCharacterPointerFromBXAX:
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition], ax
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition+2], bx
	xchg	di, ax
	mov		es, bx
	ret


;--------------------------------------------------------------------
; DisplayContext_GetCharacterPointerToBXAX
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		BX:AX:	Ptr to destination for next character to output
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayContext_GetCharacterPointerToBXAX:
	mov		ax, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition]
	mov		bx, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fpCursorPosition+2]
	ret


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
ALIGN JUMP_ALIGN
DisplayContext_SetCharOutputFunctionFromAXwithAttribFlagInBL:
	and		bl, FLG_CONTEXT_ATTRIBUTES
	and		BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], ~FLG_CONTEXT_ATTRIBUTES
	or		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], bl
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.fnCharOut], ax
	ret


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
ALIGN JUMP_ALIGN
DisplayContext_SetCharacterAttributeFromAL:
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute], al
	ret


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
ALIGN JUMP_ALIGN
DisplayContext_SetCharacterOutputParameterFromAX:
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam], ax
	ret

;--------------------------------------------------------------------
; DisplayContext_GetCharacterOutputParameterToDX
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		DX:		User parameter for Character Output function
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
DisplayContext_GetCharacterOutputParameterToDX:
	mov		dx, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam]
	ret


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
ALIGN JUMP_ALIGN
DisplayContext_GetCharacterOffsetToAXfromByteOffsetInAX:
	test	BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], FLG_CONTEXT_ATTRIBUTES
	jz		SHORT ReturnOffsetInAX
	sar		ax, 1		; BYTE count to WORD count
	ret

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
ALIGN JUMP_ALIGN
DisplayContext_GetByteOffsetToAXfromCharacterOffsetInAX:
	test	BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], FLG_CONTEXT_ATTRIBUTES
	jz		SHORT ReturnOffsetInAX
	sal		ax, 1		; WORD count to BYTE count
ALIGN JUMP_ALIGN, ret
ReturnOffsetInAX:
	ret
