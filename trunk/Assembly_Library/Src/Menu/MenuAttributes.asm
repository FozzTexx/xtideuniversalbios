; Project name	:	Assembly Library
; Description	:	Finds suitable character attribute for
;					color, B/W and monochrome displays.

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


; Struct containing border characters for different types of menu window lines
struc ATTRIBUTE_CHARS
	.cBordersAndBackground	resb	1
	.cShadow				resb	1
	.cTitle:
	.cInformation			resb	1
	.cItem					resb	1
	.cHighlightedItem		resb	1
	.cHurryTimeout			resb	1
	.cNormalTimeout			resb	1
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuAttribute_SetToDisplayContextFromTypeInSI
;	Parameters
;		SI:		Attribute type (from ATTRIBUTE_CHARS)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuAttribute_SetToDisplayContextFromTypeInSI:
	call	MenuAttribute_GetToAXfromTypeInSI
	JMP_DISPLAY_LIBRARY SetCharacterAttributeFromAL


;--------------------------------------------------------------------
; MenuAttribute_GetToAXfromTypeInSI
;	Parameters
;		SI:		Attribute type (from ATTRIBUTE_CHARS)
;	Returns:
;		AX:		Wanted attribute
;	Corrupts registers:
;		SI
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuAttribute_GetToAXfromTypeInSI:
	push	ds

	LOAD_BDA_SEGMENT_TO	ds, ax, !
	mov		al, [VIDEO_BDA.bMode]		; Load BIOS display mode (0, 1, 2, 3 or 7)
	cmp		al, 7
	je		SHORT .LoadMonoAttribute
	test	al, 1						; Even modes (0 and 2) are B/W
	jnz		SHORT .LoadColorAttribute

.LoadBlackAndWhiteAttribute:
	add		si, .rgcBlackAndWhiteAttributes
	jmp		SHORT .LoadAttributeAndReturn

ALIGN MENU_JUMP_ALIGN
.LoadMonoAttribute:
	add		si, .rgcMonochromeAttributes
	jmp		SHORT .LoadAttributeAndReturn

ALIGN MENU_JUMP_ALIGN
.LoadColorAttribute:
	add		si, .rgcColorAttributes
.LoadAttributeAndReturn:
	cs lodsb							; Load from [CS:SI] to AL

	pop		ds
	ret


.rgcColorAttributes:
istruc ATTRIBUTE_CHARS
	at	ATTRIBUTE_CHARS.cBordersAndBackground,	db	COLOR_ATTRIBUTE(COLOR_YELLOW, COLOR_BLUE)
	at	ATTRIBUTE_CHARS.cShadow,				db	COLOR_ATTRIBUTE(COLOR_GRAY, COLOR_BLACK)
	at	ATTRIBUTE_CHARS.cTitle,					db	COLOR_ATTRIBUTE(COLOR_BRIGHT_WHITE, COLOR_BLUE)
	at	ATTRIBUTE_CHARS.cItem,					db	COLOR_ATTRIBUTE(COLOR_WHITE, COLOR_BLUE)
	at	ATTRIBUTE_CHARS.cHighlightedItem,		db	COLOR_ATTRIBUTE(COLOR_BRIGHT_WHITE, COLOR_CYAN)
	at	ATTRIBUTE_CHARS.cHurryTimeout,			db	COLOR_ATTRIBUTE(COLOR_RED, COLOR_BLUE) | FLG_COLOR_BLINK
	at	ATTRIBUTE_CHARS.cNormalTimeout,			db	COLOR_ATTRIBUTE(COLOR_GREEN, COLOR_BLUE)
iend

.rgcBlackAndWhiteAttributes:	; Only COLOR_WHITE, COLOR_BRIGHT_WHITE and COLOR_BLACK should be used
istruc ATTRIBUTE_CHARS
	at	ATTRIBUTE_CHARS.cBordersAndBackground,	db	COLOR_ATTRIBUTE(COLOR_BRIGHT_WHITE, COLOR_BLACK)
	at	ATTRIBUTE_CHARS.cShadow,				db	COLOR_ATTRIBUTE(COLOR_GRAY, COLOR_BLACK)
	at	ATTRIBUTE_CHARS.cTitle,					db	COLOR_ATTRIBUTE(COLOR_BRIGHT_WHITE, COLOR_BLACK)
	at	ATTRIBUTE_CHARS.cItem,					db	COLOR_ATTRIBUTE(COLOR_WHITE, COLOR_BLACK)
	at	ATTRIBUTE_CHARS.cHighlightedItem,		db	COLOR_ATTRIBUTE(COLOR_BRIGHT_WHITE, COLOR_WHITE)
	at	ATTRIBUTE_CHARS.cHurryTimeout,			db	COLOR_ATTRIBUTE(COLOR_BRIGHT_WHITE, COLOR_BLACK) | FLG_COLOR_BLINK
	at	ATTRIBUTE_CHARS.cNormalTimeout,			db	COLOR_ATTRIBUTE(COLOR_WHITE, COLOR_BLACK)
iend

.rgcMonochromeAttributes:
istruc ATTRIBUTE_CHARS
	at	ATTRIBUTE_CHARS.cBordersAndBackground,	db	MONO_BRIGHT
	at	ATTRIBUTE_CHARS.cShadow,				db	MONO_REVERSE_DARK
	at	ATTRIBUTE_CHARS.cTitle,					db	MONO_BRIGHT
	at	ATTRIBUTE_CHARS.cItem,					db	MONO_NORMAL
	at	ATTRIBUTE_CHARS.cHighlightedItem,		db	MONO_REVERSE
	at	ATTRIBUTE_CHARS.cHurryTimeout,			db	MONO_BRIGHT_BLINK
	at	ATTRIBUTE_CHARS.cNormalTimeout,			db	MONO_NORMAL
iend
