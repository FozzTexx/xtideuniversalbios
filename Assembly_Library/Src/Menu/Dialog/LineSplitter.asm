; File name		:	Line Splitter.asm
; Project name	:	Assembly Library
; Created date	:	8.8.2010
; Last update	:	15.9.2010
; Author		:	Tomi Tilli
; Description	:	Splits long strings to multiple lines.

struc LINE_SPLITTER
	.pLastWord			resb	2
	.wMaxLineLength		resb	2
	.wLines				resb	2
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; LineSplitter_SplitStringFromDSSIwithMaxLineLengthInAXandGetLineCountToAX
;	Parameters:
;		AX:		Maximum allowed length for a line
;		DS:SI:	Ptr to string to split
;	Returns:
;		AX:		Number of lines
;	Corrupts registers:
;		CX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
LineSplitter_SplitStringFromDSSIwithMaxLineLengthInAXandGetLineCountToAX:
	xor		cx, cx
	cmp		[si], cl						; String length zero?
	jne		SHORT .PrepareToSplit
	xchg	ax, cx
	ret

ALIGN JUMP_ALIGN
.PrepareToSplit:
	eENTER_STRUCT LINE_SPLITTER_size		; SS:BP now points to LINE_SPLITTER

	mov		[bp+LINE_SPLITTER.wLines], cx
	call	Memory_SetZFifNullPointerInDSSI
	jz		SHORT .ReturnNumberOfLinesInAX
	call	SplitStringFromDSSIusingLineSplitterInSSBP

.ReturnNumberOfLinesInAX:
	mov		ax, [bp+LINE_SPLITTER.wLines]
	eLEAVE_STRUCT LINE_SPLITTER_size
	ret

;--------------------------------------------------------------------
; SplitStringFromDSSIusingLineSplitterInSSBP
;	Parameters:
;		AX:		Maximum allowed length for a line
;		DS:SI:	Ptr to string to split
;		SS:BP:	Ptr to LINE_SPLITTER
;	Returns:
;		SS:BP:	Ptr to LINE_SPLITTER with number of lines
;	Corrupts registers:
;		AX, CX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SplitStringFromDSSIusingLineSplitterInSSBP:
	mov		[bp+LINE_SPLITTER.pLastWord], si
	mov		[bp+LINE_SPLITTER.wMaxLineLength], ax
	inc		WORD [bp+LINE_SPLITTER.wLines]		; Always at least one line
	xor		cx, cx								; Length of current line
	cld
ALIGN JUMP_ALIGN
.ScanNextCharacter:
	lodsb					; Load from [DS:SI] to AL, increment SI
	cmp		al, ' '			; Control character or space?
	je		SHORT .ProcessSpace
	jb		SHORT .ProcessControlCharacter
.IncrementCharacterCount:
	inc		cx				; Increment character count
	cmp		cx, [bp+LINE_SPLITTER.wMaxLineLength]
	jbe		SHORT .ScanNextCharacter

	mov		si, [bp+LINE_SPLITTER.pLastWord]	; Resume to beginning of last word
	mov		BYTE [si-1], STX					; STX marks start or new line
	; Fall to .StartNewLine

;--------------------------------------------------------------------
; .StartNewLine
;	Parameters:
;		CX:		Line length so far
;		DS:SI:	Ptr character that begins new line
;		SS:BP:	Ptr to LINE_SPLITTER
;	Returns:
;		CX:		Zero
;		SS:BP:	LINE_SPLITTER updated for number of lines
;		Jumps to .ScanNextCharacter
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StartNewLine:
	inc		WORD [bp+LINE_SPLITTER.wLines]		; Increment number of lines
	xor		cx, cx								; Zero line length
	jmp		SHORT .ScanNextCharacter

;--------------------------------------------------------------------
; .ProcessSpace
;	Parameters:
;		CX:		Line length so far
;		DS:SI:	Ptr first character after space
;		SS:BP:	Ptr to LINE_SPLITTER
;	Returns:
;		SS:BP:	LINE_SPLITTER updated to beginning of next word
;		Jumps to .IncrementCharacterCount
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ProcessSpace:
	mov		[bp+LINE_SPLITTER.pLastWord], si
	jmp		SHORT .IncrementCharacterCount

;--------------------------------------------------------------------
; .ProcessControlCharacter
;	Parameters:
;		AL:		Control character
;		CX:		Line length so far
;		DS:SI:	Ptr inside string to split
;		SS:BP:	Ptr to LINE_SPLITTER
;	Returns:
;		SS:BP:	LINE_SPLITTER updated to beginning of next line (LF control character)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ProcessControlCharacter:
	cmp		al, NULL			; End of string?
	je		SHORT .EndOfString
	cmp		al, LF				; Line feed?
	je		SHORT .NewlineCharacter
	cmp		al, SOH				; Previous newline character?
	je		SHORT .NewlineCharacter

	mov		BYTE [si-1], ' '	; Replace unhandled control characters with space
	jmp		SHORT .ProcessSpace

ALIGN JUMP_ALIGN
.NewlineCharacter:
	mov		BYTE [si-1], SOH					; SOH marks previous newline character
	mov		[bp+LINE_SPLITTER.pLastWord], si
	jmp		SHORT .StartNewLine

ALIGN JUMP_ALIGN
.EndOfString:
	ret


;--------------------------------------------------------------------
; LineSplitter_PrintLineInCXfromStringInESDI
;	Parameters:
;		CX:		Index of line to print
;		ES:DI:	Ptr to string containing the line
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
LineSplitter_PrintLineInCXfromStringInESDI:
	push	di
	push	cx

	call	LineSplitter_GetOffsetToSIforLineCXfromStringInESDI
	jnc		SHORT .LineNotFound
	mov		bx, es
	CALL_DISPLAY_LIBRARY PrintCharBufferFromBXSIwithLengthInCX
.LineNotFound:
	pop		cx
	pop		di
	ret


;--------------------------------------------------------------------
; LineSplitter_GetOffsetToSIforLineCXfromStringInESDI
;	Parameters:
;		CX:		Index of line to search for
;		ES:DI:	Ptr to string
;	Returns:
;		CX:		Line length
;		ES:SI:	Ptr to beginning of line
;		CF:		Set if wanted line was found
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
LineSplitter_GetOffsetToSIforLineCXfromStringInESDI:
	mov		si, di				; SI points to start of first line
	mov		al, STX				; Last control character to scan for
	inc		cx					; Increment CX to get length for first line
	cld
ALIGN JUMP_ALIGN
.LineScanLoop:
	scasb						; cmp al, [es:di]. Increment DI
	jb		SHORT .LineScanLoop	; Non control character

	; Our end of line characters or NULL character
	dec		cx					; Decrement lines to scan through
	jz		SHORT .WantedLineFound
	cmp		BYTE [es:di-1], NULL
	je		SHORT .EndOfString	; Jump with CF cleared
	mov		si, di				; SI points to start of new line
	jmp		SHORT .LineScanLoop

ALIGN JUMP_ALIGN
.WantedLineFound:
	stc							; Set CF since wanted line was found
.EndOfString:
	lahf						; Load FLAGS low to AH
	lea		cx, [di-1]			; We don't want control character to be printed
	sub		cx, si				; String length to CX
	sahf						; Store AH to FLAGS low
	ret
