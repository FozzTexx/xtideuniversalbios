; Project name	:	Assembly Library
; Description	:	Functions for splitting strings to item lines.

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

struc ITEM_LINE_SPLITTER
	.wMaxTextLineLength	resb	2
	.wLineToFind		resb	2
	.wStartOfLine		resb	2
endstruc

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; ItemLineSplitter_GetLinesToAXforStringInDSSI
;	Parameters:
;		DS:SI:	Ptr to string
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Number of lines on string
;	Corrupts registers:
;		BX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ItemLineSplitter_GetLinesToAXforStringInDSSI:
	push	di

	call	MenuLocation_GetMaxTextLineLengthToAX
	eENTER_STRUCT	ITEM_LINE_SPLITTER_size
	mov		[bp+ITEM_LINE_SPLITTER.wMaxTextLineLength], ax
	mov		WORD [bp+ITEM_LINE_SPLITTER.wLineToFind], -1

	xor		bx, bx		; Line index
	mov		di, si		; Start of first word
	mov		dx, ProcessCharacterFromStringToSplit
	call	StringProcess_DSSIwithFunctionInDX

	lea		ax, [bx+1]
	eLEAVE_STRUCT	ITEM_LINE_SPLITTER_size
	pop		di
	ret


;--------------------------------------------------------------------
; ItemLineSplitter_GetLineToDSSIandLengthToCXfromStringInDSSIwithIndexInCX
;	Parameters:
;		CX:		Index of line to search for
;		DS:SI:	Ptr to string
;		SS:BP:	Ptr to MENU
;	Returns:
;		CX:		Line length
;		DS:SI:	Ptr to beginning of line
;		CF:		Set if wanted line was found
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ItemLineSplitter_GetLineToDSSIandLengthToCXfromStringInDSSIwithIndexInCX:
	push	di

	call	MenuLocation_GetMaxTextLineLengthToAX
	eENTER_STRUCT	ITEM_LINE_SPLITTER_size
	mov		[bp+ITEM_LINE_SPLITTER.wMaxTextLineLength], ax
	mov		[bp+ITEM_LINE_SPLITTER.wLineToFind], cx
	mov		[bp+ITEM_LINE_SPLITTER.wStartOfLine], si

	xor		bx, bx		; Line index
	mov		di, si		; Start of first word
	mov		dx, ProcessCharacterFromStringToSplit
	call	StringProcess_DSSIwithFunctionInDX

	mov		si, [bp+ITEM_LINE_SPLITTER.wStartOfLine]
	jc		SHORT .ReturnLineInDSSIandLengthInCX
	call	String_GetLengthFromDSSItoCX	; Last or invalid line. Just return last line.

ALIGN JUMP_ALIGN
.ReturnLineInDSSIandLengthInCX:
	eLEAVE_STRUCT	ITEM_LINE_SPLITTER_size
	pop		di
	stc
	ret


;--------------------------------------------------------------------
; Character processing callback function prototype for StringProcess_DSSIwithFunctionInBX.
; ProcessCharacterFromStringToSplit
;	Parameters:
;		AL:			Character to process
;		BX:			Line index
;		CX:			Number of characters processed (Characters on line so far)
;		DS:SI:		Ptr to next character
;		DS:DI:		Start of current word
;		SS:BP:		Ptr to ITEM_LINE_SPLITTER
;	Returns:
;		CF:			Clear to continue with next character
;					Set to stop processing
;		BX:			Line index
;		CX:			Characters on line so far
;		DS:DI:		Start of current word
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ProcessCharacterFromStringToSplit:
	cmp		al, ' '
	ja		SHORT .CheckLineLength
	mov		di, si				; DS:DI now points start of new word
	je		SHORT .CheckLineLength

	cmp		al, LF
	je		SHORT .ChangeToNextLine
	cmp		al, CR
	jne		SHORT .IgnoreUnsupportedControlCharacter
	xor		cx, cx				; Carriage return so reset line length so far

ALIGN JUMP_ALIGN
.CheckLineLength:
	cmp		[bp+ITEM_LINE_SPLITTER.wMaxTextLineLength], cx
	jb		SHORT .ChangeToNextLine
	ret		; With CF cleared

ALIGN JUMP_ALIGN
.ChangeToNextLine:
	cmp		bx, [bp+ITEM_LINE_SPLITTER.wLineToFind]
	je		SHORT .WantedLineFound

	inc		bx					; Increment line
	xor		cx, cx				; Zero character counter (and clear CF)
	mov		si, di				; Start from complete word
	mov		[bp+ITEM_LINE_SPLITTER.wStartOfLine], di
	ret

ALIGN JUMP_ALIGN
.IgnoreUnsupportedControlCharacter:
	dec		cx
	clc
	ret

ALIGN JUMP_ALIGN
.WantedLineFound:
	lea		cx, [di-1]
	sub		cx, [bp+ITEM_LINE_SPLITTER.wStartOfLine]
	stc
	ret
