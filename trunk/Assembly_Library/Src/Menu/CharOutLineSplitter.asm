; File name		:	CharOutLineSplitter.asm
; Project name	:	Assembly Library
; Created date	:	11.10.2010
; Last update	:	12.10.2010
; Author		:	Tomi Tilli
; Description	:	Functions for splitting menu lines during character output.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; CharOutLineSplitter_PrepareForPrintingTextLines
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CharOutLineSplitter_PrepareForPrintingTextLines:
	call	.GetLastTextLineColumnOffsetToDX
	call	CharOutLineSplitter_GetFirstTextLineColumnOffsetToAX
	mov		ah, dl			; AL = Text line first column, AH = Text line last column
	CALL_DISPLAY_LIBRARY SetCharacterOutputParameterFromAX
	ret

;--------------------------------------------------------------------
; .GetLastTextLineColumnOffsetToDX
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		DX:		Offset to last (allowed) character in text line
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetLastTextLineColumnOffsetToDX:
	call	CharOutLineSplitter_GetFirstTextLineColumnOffsetToAX
	xchg	dx, ax
	call	MenuLocation_GetMaxTextLineLengthToAX
	shl		ax, 1
	add		dx, ax
	ret


;--------------------------------------------------------------------
; CharOutLineSplitter_GetFirstTextLineColumnOffsetToAX
; CharOutLineSplitter_GetFirstBorderLineColumnOffsetToAX
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Offset to end of text line (first border area character)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CharOutLineSplitter_GetFirstTextLineColumnOffsetToAX:
	call	CharOutLineSplitter_GetFirstBorderLineColumnOffsetToAX
	add		al, MENU_TEXT_COLUMN_OFFSET<<1
	ret

ALIGN JUMP_ALIGN
CharOutLineSplitter_GetFirstBorderLineColumnOffsetToAX:
	call	MenuLocation_GetTitleBordersTopLeftCoordinatesToAX
	xor		ah, ah
	shl		ax, 1
	ret


;--------------------------------------------------------------------
; CharOutLineSplitter_IsCursorAtTheEndOfTextLine
;	Parameters:
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location in video memory
;	Returns:
;		CF:		Set if end of text line
;				Clear if more characters fit on current text line
;	Corrupts registers:
;		DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CharOutLineSplitter_IsCursorAtTheEndOfTextLine:
	push	ax

	mov		dl, [VIDEO_BDA.wColumns]
	shl		dl, 1			; DX = bytes per row
	mov		ax, di
	div		dl				; AL = row index, AH = column index
	cmp		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam+1], ah

	pop		ax
	ret


;--------------------------------------------------------------------
; CharOutLineSplitter_MovePartialWordToNewTextLine
;	Parameters:
;		AL:		Character to output
;		AH:		Attribute to output
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to end of text line in video memory
;	Returns:
;		DI:		Updated to next character for new text line
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CharOutLineSplitter_MovePartialWordToNewTextLine:
	push	si
	push	cx
	push	ax

	call	GetOffsetToPartialWordToSIandSizeToCX
	call	MenuCharOut_PrintLFCRandAdjustOffsetForStartOfLine
	jcxz	.NothingToMove
	call	MovePartialWordFromPreviousLineInESSItoNewLineInESDIwithSizeInCX
.NothingToMove:
	pop		ax
	pop		cx
	pop		si
	ret


;--------------------------------------------------------------------
; GetOffsetToPartialWordToSIandSizeToCX
;	Parameters:
;		ES:DI:	Ptr to space before border character
;	Returns:
;		CX:		Number of bytes that needs to be moved
;		ES:SI:	Ptr to beginning of partial word that needs to be moved to new line
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetOffsetToPartialWordToSIandSizeToCX:
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
; MovePartialWordFromPreviousLineInESSItoNewLineInESDIwithSizeInCX
;	Parameters:
;		CX:		Number of BYTEs in partial word
;		DS:		BDA segment (zero)
;		ES:SI:	Ptr to partial word on previous line
;		ES:DI:	Ptr to new empty line
;	Returns:
;		ES:DI:	Ptr where to store next character
;	Corrupts registers:
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MovePartialWordFromPreviousLineInESSItoNewLineInESDIwithSizeInCX:
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
