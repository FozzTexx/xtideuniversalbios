; Project name	:	Assembly Library
; Description	:	Finds suitable character attribute for
;					color, B/W and monochrome displays.

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
ALIGN JUMP_ALIGN
MenuAttribute_SetToDisplayContextFromTypeInSI:
	call	MenuAttribute_GetToAXfromTypeInSI
	CALL_DISPLAY_LIBRARY SetCharacterAttributeFromAL
	ret


;--------------------------------------------------------------------
; MenuAttribute_GetToAXfromTypeInSI
;	Parameters
;		SI:		Attribute type (from ATTRIBUTE_CHARS)
;	Returns:
;		AX:		Wanted attribute
;	Corrupts registers:
;		SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuAttribute_GetToAXfromTypeInSI:
	push	ds

	LOAD_BDA_SEGMENT_TO	ds, ax
	mov		al, [VIDEO_BDA.bMode]		; Load BIOS display mode (0, 1, 2, 3 or 7)
	cmp		al, 7
	je		SHORT .LoadMonoAttribute
	test	al, 1						; Even modes (0 and 2) are B/W
	jnz		SHORT .LoadColorAttribute

.LoadBlackAndWhiteAttribute:
	add		si, .rgcBlackAndWhiteAttributes
	jmp		SHORT .LoadAttributeAndReturn

ALIGN JUMP_ALIGN
.LoadMonoAttribute:
	add		si, .rgcMonochromeAttributes
	jmp		SHORT .LoadAttributeAndReturn

ALIGN JUMP_ALIGN
.LoadColorAttribute:
	add		si, .rgcColorAttributes
.LoadAttributeAndReturn:
	eSEG	cs
	lodsb								; Load from [CS:SI] to AL

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
