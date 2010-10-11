; File name		:	MenuCharOut.asm
; Project name	:	Assembly Library
; Created date	:	15.7.2010
; Last update	:	10.10.2010
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
	call	DisplayCharOut_BiosTeletypeOutput
	xor		ax, ax					; No offset, cursor to start of border
	jmp		SHORT SetCursorToNextMenuLine


;--------------------------------------------------------------------
; MenuCharOut_MenuTextTeletypeOutputWithAttributeAndAutomaticLineChange
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
MenuCharOut_MenuTextTeletypeOutputWithAttributeAndAutomaticLineChange:
	push	di
	push	ax
	mov		al, DOUBLE_VERTICAL
	add		di, BYTE MENU_TEXT_COLUMN_OFFSET	; Border char comes after space
	WAIT_RETRACE_IF_NECESSARY_THEN scasb
	pop		ax
	pop		di
	je		SHORT MovePartialWordToNewTextLineAndPrintCharacterFromAX
	; Fall to MenuCharOut_MenuTextTeletypeOutputWithAttribute

ALIGN JUMP_ALIGN
MenuCharOut_MenuTextTeletypeOutputWithAttribute:
	cmp		al, CR						; Carriage return?
	je		SHORT PrintCRfromALandAdjustColumnToMenuText
	jmp		DisplayCharOut_TeletypeOutputWithAttribute


;--------------------------------------------------------------------
; MovePartialWordToNewTextLineAndPrintCharacterFromAX
;	Parameters:
;		AL:		Character to output
;		AH:		Attribute to output
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to end of text line in video memory
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MovePartialWordToNewTextLineAndPrintCharacterFromAX:
	cmp		al, ' '		; Space or any control character
	jb		SHORT .MoveCursorInDItoBeginningOfNextLine
	push	si
	push	cx
	push	ax

	call	.GetOffsetToPartialWordToSIandSizeToCX
	call	.MoveCursorInDItoBeginningOfNextLine
	jcxz	.NothingToMove
	call	.MovePartialWordFromPreviousLineInESSItoNewLineInESDIwithSizeInCX
.NothingToMove:
	pop		ax
	pop		cx
	pop		si
	jmp		DisplayCharOut_TeletypeOutputWithAttribute

;--------------------------------------------------------------------
; .GetOffsetToPartialWordToSIandSizeToCX
;	Parameters:
;		ES:DI:	Ptr to space before border character
;	Returns:
;		CX:		Number of bytes that needs to be moved
;		ES:SI:	Ptr to beginning of partial word that needs to be moved to new line
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetOffsetToPartialWordToSIandSizeToCX:
	xor		cx, cx
	mov		si, di
ALIGN JUMP_ALIGN
.ScanNextCharacter:		; Space will always be found since one comes after border
	dec		si
	dec		si
	cmp		BYTE [es:si], ' '
	je		SHORT .PartialWordFound
	inc		cx
	jmp		SHORT .ScanNextCharacter
ALIGN JUMP_ALIGN
.PartialWordFound:
	inc		si
	inc		si			; SI now points one past space
	shl		cx, 1		; Characters to bytes
	ret

;--------------------------------------------------------------------
; .MovePartialWordFromPreviousLineInESSItoNewLineInESDIwithSizeInCX
;	Parameters:
;		CX:		Number of bytes in partial word
;		DS:		BDA segment (zero)
;		ES:SI:	Ptr to partial word on previous line
;		ES:DI:	Ptr to new empty line
;	Returns:
;		ES:DI:	Ptr where to store next character
;	Corrupts registers:
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.MovePartialWordFromPreviousLineInESSItoNewLineInESDIwithSizeInCX:
	push	si
	push	cx
	WAIT_RETRACE_IF_NECESSARY_THEN rep movsb
	pop		cx
	pop		si
	xchg	di, si
	shr		cx, 1		; Bytes to characters
	mov		al, ' '
	call	DisplayPrint_RepeatCharacterFromALwithCountInCX
	mov		di, si
	ret

;--------------------------------------------------------------------
; .MoveCursorInDItoBeginningOfNextLine
;	Parameters:
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location
;	Returns:
;		ES:DI:	Ptr to beginning of new line
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.MoveCursorInDItoBeginningOfNextLine:
	mov		al, LF
	call	DisplayCharOut_BiosTeletypeOutput
	mov		al, CR
	; Fall to PrintCRfromALandAdjustColumnToMenuText


;--------------------------------------------------------------------
; PrintCRfromALandAdjustColumnToMenuText
;	Parameters:
;		AL:		Character to output (CR)
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;	Returns:
;		DI:		Incremented for next text line
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PrintCRfromALandAdjustColumnToMenuText:
	call	DisplayCharOut_BiosTeletypeOutput
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
