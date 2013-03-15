; Project name	:	Assembly Library
; Description	:	Functions for splitting menu lines during character output.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
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
; CharOutLineSplitter_PrepareForPrintingTextLines
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, DI
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
CharOutLineSplitter_PrepareForPrintingTextLines:
	; Get first text line column offset to DX
	call	CharOutLineSplitter_GetFirstBorderLineColumnOffsetToAX
	add		al, MENU_TEXT_COLUMN_OFFSET<<1
	xchg	dx, ax

	; Get last text line column offset to AX
	call	MenuLocation_GetMaxTextLineLengthToAX
	eSHL_IM	ax, 1			; Characters to BYTEs
	add		ax, dx

	xchg	ax, dx			; AL = First text line column offset
	mov		ah, dl			; AH = Last text line column offset
	JMP_DISPLAY_LIBRARY SetCharacterOutputParameterFromAX


;--------------------------------------------------------------------
; CharOutLineSplitter_GetFirstBorderLineColumnOffsetToAX
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Offset to end of text line (first border area character)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
CharOutLineSplitter_GetFirstBorderLineColumnOffsetToAX:
	call	MenuLocation_GetTitleBordersTopLeftCoordinatesToAX
	xor		ah, ah
	eSHL_IM	ax, 1
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
ALIGN MENU_JUMP_ALIGN
CharOutLineSplitter_IsCursorAtTheEndOfTextLine:
	push	ax

	mov		dl, [VIDEO_BDA.wColumns]
	eSHL_IM	dl, 1			; DX = bytes per row
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
ALIGN MENU_JUMP_ALIGN
CharOutLineSplitter_MovePartialWordToNewTextLine:
	push	si
	push	cx
	push	ax
	; Fall to .GetOffsetToPartialWordToSIandSizeToCX

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
.GetOffsetToPartialWordToSIandSizeToCX:
	mov		cx, di
	mov		si, di
ALIGN MENU_JUMP_ALIGN
.ScanNextCharacter:		; Space will always be found since one comes after border
	dec		si
	dec		si
	cmp		BYTE [es:si], ' '
	jne		SHORT .ScanNextCharacter
	inc		si
	inc		si			; SI now points one past space
	sub		cx, si
	; Fall to .ChangeLine

;--------------------------------------------------------------------
; .ChangeLine
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
.ChangeLine:
	call	MenuCharOut_PrintLFCRandAdjustOffsetForStartOfLine
	jcxz	.ReturnFromMovePartialWordToNewTextLine
	; Fall to .MovePartialWordFromPreviousLineInESSItoNewLineInESDIwithSizeInCX

;--------------------------------------------------------------------
; .MovePartialWordFromPreviousLineInESSItoNewLineInESDIwithSizeInCX
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

.ReturnFromMovePartialWordToNewTextLine:
	pop		ax
	pop		cx
	pop		si
	ret
