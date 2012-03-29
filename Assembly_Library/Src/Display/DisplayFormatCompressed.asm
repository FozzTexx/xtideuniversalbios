; Project name	:	Assembly Library
; Description	:	Functions for displaying formatted strings.
;					** Compressed Strings edition **
;					This is a plug replacement for DisplayFormat.asm,
;					working instead with precompiled and slightly compressed strings.
;
; Strings are compressed in a simple manner:
;	1. The two most common characters, space and null, are removed
;	2. Format specifiers are reduced to a single byte, including length information
;
; Format of bytes in the string are:
;     01 xxxxxx     Character in x plus StringsCompressed_NormalBase
;     10 xxxxxx     Character in x plus StringsCompressed_NormalBase, followed by a null (last character)
;     11 xxxxxx     Character in x plus StringsCompressed_NormalBase, followed by a space
;     00 1 yyyyy    Character/Format in lookup table StringsCopmressed_TranslatesAndFormats
;     00 0 yyyyy    Character/Format in lookup table StringsCompressed_TranslatesAndFormats, followed by a null
;
; StringsCompressed_NormalBase is defined by the compressor, but is usually around 0x40,
; which gives a range of 0x40 to 0x7f, or roughly the upper and lower case letters.
;
; StringsCompressed_TranslatesAndFormats is a lookup table with the first few bytes being translation
; characters, and the last few bytes being format jump offsets from DisplayFormatCompressed_BaseFormatOffset.
; The dividing line is defined by StringsCompressed_FormatsBegin
;
; The assignments of the first two bits above is not by accident.  The translates/format branch is 00
; which is easy to test for.  The '01' for "normal" (no null or space) and '001' for translates/format "normal"
; match, allowing the translates/format codes to be shifted left by 1 and then tested with the same instructions.
;
; It is always possible to say that a null character follows the current character - thus there is
; no way (nor need) to specify a zero character.
;
; Note that this code is optimized for size, not speed.  Since this code is used only during initialization
; and only for the user interface, small performance hits should not be noticed.  It will seem odd to do so
; much "preload", just in case a branch is taken, but that is cheaper (in size) than adding additional branches.
;

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Format Handlers
;
; Names of format handlers are DisplayFormatCompressed_Format_* where * is
; replaced with the format code after the '%' in the original string,
; with '-' replaced with '_'.
;
;	Parameters:
;		DS:		BDA segment (zero)
;		AX:     Parameter to Format
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, BX, CX, DX, SI
;--------------------------------------------------------------------

;
; The following routines do not need any pre or post processing and can be jumped to directly.
; Note that they need to be within 256 bytes of DisplayFormatCompressed_BaseFormatOffset
;
%define DisplayFormatCompressed_Format_c DisplayPrint_CharacterFromAL
%define DisplayFormatCompressed_Format_nl DisplayPrint_Newline_FormatAdjustBP
%define DisplayFormatCompressed_Format_s DisplayFormat_ParseCharacters_FromAX

DisplayFormatCompressed_Format_A:
	mov		[VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bAttribute], al
DisplayFormatCompressed_ret:			; jump target for other routines who need a "ret"
	ret

DisplayFormatCompressed_Format_z:
	xor		bx, bx
	xchg	si, ax
	jmp		short DisplayPrint_NullTerminatedStringFromBXSI

DisplayFormatCompressed_Format_x:
DisplayFormatCompressed_Format_5_x:
	mov		si,16						; hex output, change base to 16
	mov		bx,(04<<8) + 'h'	        ; 4 bytes, with postfix character 'h' to emit
										; (note that the count includes the 'h')
	jmp		DisplayFormatCompressed_Format_u

DisplayFormatCompressed_Format_2_I:
	mov		si,g_szDashForZero			; preload dash string in case we jump
	test	ax,ax						; if parameter equals zero, emit dash string instead
	jz		DisplayFormat_ParseCharacters
	; fall through

DisplayFormatCompressed_Format_2_u:
	mov		bh,2						; only two characters (instead of the default 5)
	; fall through

DisplayFormatCompressed_Format_u:
DisplayFormatCompressed_Format_5_u:
	push	bx							; push postfix character - either a zero (default) or a 'h'
	mov		bl,bh						; preserve character count for .PrintLoop

.DivLoop:
	xor		dx, dx						; Zero DX for division
	div		si							; DX:AX / 10 => AX=quot, DX=rem
 	push	dx							; Push digit

	dec		bh
	jnz		.DivLoop

.PrintLoop:
	pop		ax							; Pop digit, postfix character on last iteration

	dec		bl							; on second to last iteration, emit digit whether it is zero or not
	jz		.PrintDigit

	js		short DisplayPrint_CharacterFromAL	; on last iteration, emit postfix character
												; if it is zero, DisplayPrint_CharacterFromAL will not emit

	or		bh, al						; skip leading zeros, bh keeps track if we have emitted anything non-zero
	jnz		.PrintDigit					; note that bh starts at zero, from the loop above

	test	ch,2						; are we padding with leading spaces?
	jnz		.PrintLoop					; test the even/odd of the format byte in the string

	mov		al, 89h						; emit space

.PrintDigit:
	add		al, 90h						; Convert binary digit in AL to ASCII hex digit (0 - 9 or A - F)
	daa
	adc		al, 40h
	daa

	call	DisplayPrint_CharacterFromAL

	jmp		.PrintLoop


;--------------------------------------------------------------------
; DisplayFormat_ParseCharacters
;	Parameters:
;		DS:		BDA segment (zero)
;		SS:BP:	Pointer to first format parameter (-=2 updates to next parameter)
;		CS:SI:	Pointer to string to format
;		ES:DI:	Ptr to cursor location in video RAM
;	Returns:
;		CS:SI:	Ptr to end of format string (ptr to one past NULL)
;		DI:		Updated offset to video RAM
;	Corrupts registers:
;		AX, BX, CX, DX, BP
;--------------------------------------------------------------------

DisplayFormatCompressed_BaseFormatOffset:

DisplayFormat_ParseCharacters_FromAX:
	mov		si,ax
	; fall through to DisplayFormat_ParseCharacters

ALIGN DISPLAY_JUMP_ALIGN
DisplayFormat_ParseCharacters:
;
; This routine is used to output all strings from the ROM.  The strings in ROMVARS are not compressed,
; and must be handled differently.
;
	cmp		si,byte 07fh		; well within the boundaries of ROMVARS_size
	mov		bx,cs				; preload bx with cs in case we take the following jump
	jb		short DisplayPrint_NullTerminatedStringFromBXSI

.decode:
	cs lodsb					; load next byte of the string

	mov		ch,al				; save a copy for later processing of high order bits

	test	al,0c0h				; check for translation/format character
	jz		DisplayFormatCompressed_TranslatesAndFormats

	and		al,03fh								; "Normal" character, mask off high order bits
	add		al,StringsCompressed_NormalBase		; and add character offset (usually around 0x40)

.output:
	call 	DisplayPrint_CharacterFromAL

.process_after_output:
	shl		ch,1								; check high order bits for end of string or space
	jns		short DisplayFormatCompressed_ret
	jnc		.decode
	mov		al,' '
	call	DisplayPrint_CharacterFromAL
	jmp		.decode


ALIGN DISPLAY_JUMP_ALIGN
DisplayFormatCompressed_TranslatesAndFormats:
;
; This routine is here (above DisplayFormat_ParseCharacters) to reduce the amount of code between
; DisplayFormatCompressed_BaseFormatOffset and jump targets (must fit in 256 bytes)
;
	shl		ch,1				; setup ch for later testing of null in .process_after_output
	and		ax,0001fh			; also clears AH for addition with BX and DX below

	mov		bx,StringsCompressed_TranslatesAndFormats	; calculate offset of translation/formats offset byte
	add		bx,ax

	cmp		al,StringsCompressed_FormatsBegin			; determine if this is a translation or a format

	mov		al,[cs:bx]									; fetch translation/formats byte

	jb		DisplayFormat_ParseCharacters.output		; check if this a translation or a format
														; if it is translation, output and postprocess for eos
														; note that the flags for this conditional jump were
														; set with the cmp al,StringsCompressed_FormatsBegin

	mov		dx,DisplayFormatCompressed_BaseFormatOffset   ; calculate address to jump to for format handler
	sub		dx,ax

	mov		ax,[bp]				; preload ax with parameter
	dec		bp					; if no parameter is needed (format 'nl' for example),
	dec		bp					; the format handler can reincrement bp

	mov		bx,0500h			; preload bh with 5 decimal places for numeric output
								; bl is zero, indicating not to output a 'h' (default base 10)

	push	si					; preserve si and cx, in the case of outputing a string
	push	cx

	mov		si,10				; preload si with 10 for numeric output (default base 10)

	call	dx					; call the format routine

	pop		cx					; restore cx and si
	pop		si

	jmp		DisplayFormat_ParseCharacters.process_after_output	; continue postprocessing, check for end of string

