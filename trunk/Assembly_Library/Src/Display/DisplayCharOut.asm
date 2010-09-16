; File name		:	DisplayCharOut.asm
; Project name	:	Assembly Library
; Created date	:	26.6.2010
; Last update	:	13.8.2010
; Author		:	Tomi Tilli
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
	stosw
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
	call	.OutputCharacterWithBIOS
	call	DisplayCursor_GetHardwareCoordinatesToAX
	jmp		DisplayCursor_SetCoordinatesFromAX

;--------------------------------------------------------------------
; .OutputCharacterWithBIOS
;	Parameters:
;		AL:		Character to output
;		DS:		BDA segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.OutputCharacterWithBIOS:
	push	bx
	mov		ah, TELETYPE_OUTPUT
	mov		bh, [VIDEO_BDA.bActivePage]
	int		BIOS_VIDEO_INTERRUPT_10h
	pop		bx
	ret


;--------------------------------------------------------------------
; DisplayCharOut_Attribute
; DisplayCharOut_Character
; DisplayCharOut_CharacterWithAttribute
;	Parameters:
;		AL:		Character to output
;		AH:		Attribute to output
;		ES:DI:	Ptr to video memory where to output
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayCharOut_Attribute:
	xchg	al, ah				; Swap character and attribute
	inc		di					; Skip character
	stosb
	ret

ALIGN JUMP_ALIGN
DisplayCharOut_Character:
	stosb
	inc		di					; Skip attribute
	ret

ALIGN JUMP_ALIGN
DisplayCharOut_CharacterWithAttribute:
	stosw
	ret


;--------------------------------------------------------------------
; DisplayCharOut_WriteCharacterToBuffer
;	Parameters:
;		AL:		Character to output
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to destination string buffer
;		DISPLAY_CONTEXT.wCharOutParam:	Offset to end of buffer (one past last)
;	Returns:
;		ES:DI:	Updated for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayCharOut_WriteCharacterToBuffer:
	cmp		di, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam]
	jae		SHORT .BufferFull
	stosb
.BufferFull:
	ret
