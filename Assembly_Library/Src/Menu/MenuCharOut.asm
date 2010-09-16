; File name		:	MenuCharOut.asm
; Project name	:	Assembly Library
; Created date	:	15.7.2010
; Last update	:	4.8.2010
; Author		:	Tomi Tilli
; Description	:	Character out function for printing withing menu window.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuCharOut_MenuBorderTeletypeOutputWithAttribute
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
MenuCharOut_MenuBorderTeletypeOutputWithAttribute:
	cmp		al, CR					; Carriage return?
	je		SHORT .PrintCRandAdjustColumnToMenuBorders
	jmp		DisplayCharOut_TeletypeOutputWithAttribute

ALIGN JUMP_ALIGN
.PrintCRandAdjustColumnToMenuBorders:
	call	DisplayCharOut_TeletypeOutputWithAttribute
	xor		ax, ax					; No offset, cursor to start of border
	jmp		SHORT SetCursorToNextMenuLine


;--------------------------------------------------------------------
; MenuCharOut_MenuTextTeletypeOutputWithAttribute
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
MenuCharOut_MenuTextTeletypeOutputWithAttribute:
	cmp		al, CR						; Carriage return?
	je		SHORT .PrintCRandAdjustColumnToMenuText
	jmp		DisplayCharOut_TeletypeOutputWithAttribute

ALIGN JUMP_ALIGN
.PrintCRandAdjustColumnToMenuText:
	call	DisplayCharOut_TeletypeOutputWithAttribute
	mov		al, MENU_TEXT_COLUMN_OFFSET	; Offset to start of text
	; Fall to SetCursorToNextMenuLine

;--------------------------------------------------------------------
; SetCursorToNextMenuLine
;	Parameters:
;		AL:		Column offset from start of borders
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;	Returns:
;		DI:		Adjusted for next line
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SetCursorToNextMenuLine:
	push	bp

	mov		bp, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam]
	call	.AddCoordinatesForNewBorderLineToAX
	call	DisplayCursor_SetCoordinatesFromAX	; Updates DI

	pop		bp
	ret

;--------------------------------------------------------------------
; .AddCoordinatesForNewBorderLineToAX
;	Parameters:
;		AL:		Column offset from start of borders
;		DS:		BDA segment (zero)
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Coordinates for new line
;	Corrupts registers:
;		DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.AddCoordinatesForNewBorderLineToAX:
	call	MenuLocation_AddTitleBordersTopLeftCoordinatesToAX
	push	ax
	call	DisplayCursor_GetSoftwareCoordinatesToAX
	pop		dx
	mov		al, dl					; Adjust column to borders
	ret
