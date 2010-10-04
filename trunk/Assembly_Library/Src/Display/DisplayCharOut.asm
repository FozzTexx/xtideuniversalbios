; File name		:	DisplayCharOut.asm
; Project name	:	Assembly Library
; Created date	:	26.6.2010
; Last update	:	4.10.2010
; Author		:	Tomi Tilli
; Description	:	Functions for outputting characters to video memory.
;					These functions are meant to be called by Display_CharacterFromAL
;					and Display_RepeatCharacterFromAL using function pointer
;					stored in DISPLAY_CONTEXT.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; WAIT_RETRACE_IF_NECESSARY_THEN
;	Parameters:
;		AL:		Character to output
;		AH:		Attribute to output (stosw only)
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
%macro WAIT_RETRACE_IF_NECESSARY_THEN 1
%ifdef ELIMINATE_CGA_SNOW
	%ifidn %1, stosb
		call	StosbWithoutCgaSnow
	%else
		call	StoswWithoutCgaSnow
	%endif
%else
	%1			; STOSB or STOSW
%endif
%endmacro


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


; STOSB and STOSW replacement functions to prevent CGA snow. These will slow
; drawing a lot so use them only if it is necessary to eliminate CGA snow.
%ifdef ELIMINATE_CGA_SNOW

OFFSET_TO_CGA_STATUS_REGISTER	EQU		6		; Base port 3D4h + 6 = 3DAh
CGA_STATUS_REGISTER				EQU		3DAh

;--------------------------------------------------------------------
; WAIT_UNTIL_SAFE_CGA_WRITE
;	Parameters:
;		DX:		CGA Status Register Address (3DAh)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
%macro WAIT_UNTIL_SAFE_CGA_WRITE 0
%%WaitUntilNotInRetrace:
	in		al, dx
	shr		al, 1	; 1 = Bit 0: A 1 indicates that regen-buffer memory access can be
					; made without interfering with the display. (H or V retrace)
	jc		SHORT %%WaitUntilNotInRetrace
%%WaitUntilNextRetraceStarts:
	in		al, dx
	shr		al, 1
	jnc		SHORT %%WaitUntilNextRetraceStarts
%endmacro

;--------------------------------------------------------------------
; StosbWithoutCgaSnow
; StoswWithoutCgaSnow
;	Parameters:
;		AL:		Character to output
;		AH:		Attribute to output (StoswWithoutCgaSnow only)
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
StosbWithoutCgaSnow:
	call	DisplayCharOut_LoadAndVerifyStatusRegisterFromBDA
	jne		SHORT .StosbWithoutWaitSinceUnknownPort

	mov		ah, al
	cli				; Interrupt request would mess up timing
	WAIT_UNTIL_SAFE_CGA_WRITE
	mov		al, ah
.StosbWithoutWaitSinceUnknownPort:
	stosb
	sti
	ret

ALIGN JUMP_ALIGN
StoswWithoutCgaSnow:
	push	bx
	call	DisplayCharOut_LoadAndVerifyStatusRegisterFromBDA
	jne		SHORT .StoswWithoutWaitSinceUnknownPort

	xchg	bx, ax
	cli				; Interrupt request would mess up timing
	WAIT_UNTIL_SAFE_CGA_WRITE
	xchg	ax, bx
.StoswWithoutWaitSinceUnknownPort:
	stosw
	pop		bx
	sti
	ret


;--------------------------------------------------------------------
; DisplayCharOut_LoadAndVerifyStatusRegisterFromBDA
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		DX:		CGA Status Register Address
;		ZF:		Set if CGA Base Port found in BDA
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DisplayCharOut_LoadAndVerifyStatusRegisterFromBDA:
	mov		dx, [BDA.wVidPort]
	add		dl, OFFSET_TO_CGA_STATUS_REGISTER
	cmp		dx, CGA_STATUS_REGISTER
	ret

%endif ; ELIMINATE_CGA_SNOW
