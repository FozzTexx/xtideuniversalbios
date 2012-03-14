; Project name	:	Assembly Library
; Description	:	Functions for outputting characters to video memory.
;					These functions are meant to be called by Display_CharacterFromAL
;					and Display_RepeatCharacterFromAL using function pointer
;					stored in DISPLAY_CONTEXT.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DisplayCharOut_TeletypeOutputWithAttribute
; DisplayCharOut_TeletypeOutput
;	Parameters:
;		AL:		Character to output
;		AH:		Attribute to output
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayCharOut_TeletypeOutputWithAttribute:
	cmp		al, ' '							; Printable character?
	jb		SHORT DisplayCharOut_BiosTeletypeOutput
	WAIT_RETRACE_IF_NECESSARY_THEN stosw
	ret

ALIGN JUMP_ALIGN
DisplayCharOut_TeletypeOutput:
	cmp		al, ' '							; Printable character?
	jae		SHORT DisplayCharOut_Character
	; Fall to DisplayCharOut_BiosTeletypeOutput

;--------------------------------------------------------------------
; DisplayCharOut_BiosTeletypeOutput
;	Parameters:
;		AL:		Control character
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayCharOut_BiosTeletypeOutput:
	push	ax
	call	DisplayCursor_SynchronizeCoordinatesToHardware
	pop		ax

	; Output character with BIOS
	push	bx
	mov		ah, TELETYPE_OUTPUT
	mov		bh, [VIDEO_BDA.bActivePage]
	int		BIOS_VIDEO_INTERRUPT_10h
	pop		bx

	call	DisplayCursor_GetHardwareCoordinatesToAX
	jmp		DisplayCursor_SetCoordinatesFromAX


;--------------------------------------------------------------------
; DisplayCharOut_Attribute
; DisplayCharOut_Character
; DisplayCharOut_CharacterWithAttribute
;	Parameters:
;		AL:		Character to output
;		AH:		Attribute to output
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayCharOut_Attribute:
	xchg	al, ah				; Swap character and attribute
	inc		di					; Skip character
	WAIT_RETRACE_IF_NECESSARY_THEN stosb
	ret

ALIGN JUMP_ALIGN
DisplayCharOut_Character:
	WAIT_RETRACE_IF_NECESSARY_THEN stosb
	inc		di					; Skip attribute
	ret

ALIGN JUMP_ALIGN
DisplayCharOut_CharacterWithAttribute:
	WAIT_RETRACE_IF_NECESSARY_THEN stosw
	ret


;--------------------------------------------------------------------
; DisplayCharOut_WriteCharacterToBuffer
;	Parameters:
;		AL:		Character to output
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to destination string buffer
;		DISPLAY_CONTEXT.wCharOutParam:	Characters left in buffer
;	Returns:
;		ES:DI:	Updated for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayCharOut_WriteCharacterToBuffer:
	cmp		WORD [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam], BYTE 0
	je		SHORT .BufferFull
	stosb
	dec		WORD [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam]
.BufferFull:
	ret
