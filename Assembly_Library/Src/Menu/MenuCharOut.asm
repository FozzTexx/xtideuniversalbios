; File name		:	MenuCharOut.asm
; Project name	:	Assembly Library
; Created date	:	15.7.2010
; Last update	:	12.10.2010
; Author		:	Tomi Tilli
; Description	:	Character out function for printing withing menu window.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuCharOut_MenuTeletypeOutputWithAutomaticLineChange
; MenuCharOut_MenuTeletypeOutput
;	Parameters:
;		AL:		Character to output
;		AH:		Attribute to output
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;		[DISPLAY_CONTEXT.wCharOutParam]:
;				Low byte  = First column offset (after CR)
;				High byte = Last column offset (when using automatic line change)
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCharOut_MenuTeletypeOutputWithAutomaticLineChange:
	call	CharOutLineSplitter_IsCursorAtTheEndOfTextLine
	jnc		SHORT MenuCharOut_MenuTeletypeOutput
	cmp		al, ' '
	jb		SHORT ReturnSinceNoNeedToStartLineWithControlCharacter
	call	CharOutLineSplitter_MovePartialWordToNewTextLine
	; Fall to MenuCharOut_MenuTextTeletypeOutputWithAttribute

ALIGN JUMP_ALIGN
MenuCharOut_MenuTeletypeOutput:
	cmp		al, CR
	je		SHORT PrintCRandAdjustOffsetForStartOfLine
	jmp		DisplayCharOut_TeletypeOutputWithAttribute


;--------------------------------------------------------------------
; MenuCharOut_PrintLFCRandAdjustOffsetForStartOfLine
; PrintCRandAdjustOffsetForStartOfLine
;	Parameters:
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location
;		[DISPLAY_CONTEXT.wCharOutParam]:
;				Low byte  = First column offset (after CR)
;				High byte = Last column offset (when using automatic line change)
;	Returns:
;		ES:DI:	Ptr to beginning of new line
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCharOut_PrintLFCRandAdjustOffsetForStartOfLine:
	mov		al, LF
	call	DisplayCharOut_BiosTeletypeOutput
	; Fall to PrintCRandAdjustOffsetForStartOfLine

ALIGN JUMP_ALIGN
PrintCRandAdjustOffsetForStartOfLine:
	mov		al, CR
	call	DisplayCharOut_BiosTeletypeOutput
	eMOVZX	ax, BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam]
	add		di, ax
ReturnSinceNoNeedToStartLineWithControlCharacter:
	ret
