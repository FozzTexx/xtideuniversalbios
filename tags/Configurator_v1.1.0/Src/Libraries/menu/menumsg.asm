; File name		:	menumsg.asm
; Project name	:	Menu library
; Created date	:	13.11.2009
; Last update	:	10.1.2010
; Author		:	Tomi Tilli
; Description	:	ASM library to menu system.
;					Contains functions for displaying messages.

;--------------- Equates -----------------------------

; Control characters for Menu Message string.
; Normal control characters cannot be used since message string
; will be tokenized and converted to menuitems.
%define MNU_NL			" |n "	; Menu newline defined as token string
W_MNU_NL			EQU	"|n"	; Menu newline defined as WORD

; Total border chars on left and right side of string menuitem
SIZE_MSG_HBRDR		EQU		4	; Horizontal border size

; Message variables. This is an expanded MENUVARS struct.
struc MSGVARS
	.menuVars	resb	MENUVARS_size
	.dwStrPtr:					; Far pointer to string to display
	.wStrOff:	resb	2		; Offset to string to display
	.wStrSeg:	resb	2		; Segment to string to display
endstruc


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data


;-------------- Public functions ---------------------
; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Displays message string.
;
; MenuMsg_ShowMessage
;	Parameters:
;		BL:		Dialog width with borders included
;		SS:BP:	Ptr to MENUVARS
;		ES:DI:	Ptr to STOP terminated string to display
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuMsg_ShowMessage:
	; Create stack frame
	eENTER	MSGVARS_size, 0
	sub		bp, MSGVARS_size				; Point to MSGVARS

	; Initialize menu variables
	mov		[bp+MENUVARS.bWidth], bl		; Menu size
	mov		WORD [bp+MENUVARS.wTopDwnH], 0	; Title and Info size
	mov		WORD [bp+MENUVARS.fnEvent], MenuMsg_MsgEvent
	mov		[bp+MSGVARS.wStrOff], di		; Store far ptr...
	mov		[bp+MSGVARS.wStrSeg], es		; ...to string to display

	; Enter menu
	call	MenuMsg_GetLineCnt				; Get message line count to CX
	mov		ax, CNT_SCRN_ROW-2				; Load max line rows to AX
	MIN_U	ax, cx							; String lines to display to AX
	times 2	inc ax							; Include borders for dlg height
	mov		[bp+MENUVARS.bHeight], al		; Store dialog height
	call	MenuCrsr_GetCenter				; Get X and Y coordinates to DX
	xor		ax, ax							; Selection timeout (disable)
	mov		bl, FLG_MNU_NOARRW				; Menu flags
	call	Menu_Init						; Returns only after dlg closed

	; Return
	add		bp, MSGVARS_size				; Point to old BP
	eLEAVE									; Destroy stack frame
	ret


;-------------- Private functions ---------------------

;--------------------------------------------------------------------
; Calculates number of string lines needed by string to display.
;
; MenuMsg_GetLineCnt
;	Parameters:
;		SS:BP:	Ptr to MSGVARS
;		ES:DI:	Ptr to STOP terminated string to display
;	Returns:
;		CX:		Number of lines needed
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuMsg_GetLineCnt:
	push	di

	; Get index for last line
	mov		cx, -1					; Get last possible line
	call	MenuMsg_GetTokenForLine
	inc		cx						; Last index to line count

	; Return
	pop		di
	ret


;--------------------------------------------------------------------
; Check if line has space for token.
;
; MenuMsg_HasLineSpace
;	Parameters:
;		AX:		Token length in characters
;		DX:		Characters left on line
;		ES:DI:	Ptr to token string (not terminated!)
;	Returns:
;		DX:		Chars left after token + space at the end
;		CF:		Set if space left for token
;				Cleared if not enough space
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuMsg_HasLineSpace:
	sub		dx, ax
	jl		.NoSpace
	cmp		WORD [es:di], W_MNU_NL	; Newline token?
	je		.NoSpace				;  If so, end line
	dec		dx						; Decrement for space after token
	stc								; Set CF since space left
	ret
ALIGN JUMP_ALIGN
.NoSpace:
	xor		dx, dx					; Clear space left and CF
	ret


;--------------------------------------------------------------------
; Return pointer to first token for wanted message line.
;
; MenuMsg_GetTokenForLine
;	Parameters:
;		CX:		Line index
;		ES:DI:	Ptr to STOP terminated string to display
;		SS:BP:	Ptr to MSGVARS
;	Returns:
;		AX:		Length of first token in characters
;		CX:		Index of last line found (if wanted line not found)
;		ES:DI:	Ptr to token
;		CF:		Set if message line found
;				Cleared if message line not found
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuMsg_GetTokenForLine:
	test	cx, cx				; Line 0 wanted?
	jz		.GetFirst			;  If so, just get token length
	push	bp
	push	si

	; Prepare to scan tokens
	eMOVZX	si, [bp+MENUVARS.bWidth]
	sub		si, SIZE_MSG_HBRDR	; Max number of chars per line
	mov		dx, si				; Initialize chars left on line
	mov		bp, cx				; Copy line index to BP
	xor		bx, bx				; Zero line index counter
	xor		ax, ax				; Zero token length

	; Scan all tokens to calculate lines needed
ALIGN JUMP_ALIGN
.TokenLoop:
	; Get token and length
	xor		cx, cx				; Always read token at index 0
	add		di, ax				; Increment offset for next token
	call	String_StrToken		; Get token length to AX, ptr to ES:DI
	jnc		.Return				; Return if no more tokens (CF cleared)
	; Check does line have space left for token
	call	MenuMsg_HasLineSpace
	jc		.TokenLoop			; Space left, check next token
	; Change to next line
	mov		dx, si				; Copy max chars on line
	call	MenuMsg_HasLineSpace; Update chars left
	inc		bx					; Increment line index
	cmp		bx, bp				; Correct line found?
	jne		.TokenLoop			;  If not, check more tokens
	stc							; Set CF since line found
ALIGN JUMP_ALIGN
.Return:
	mov		cx, bx				; Copy idx of last line found to CX
	pop		si
	pop		bp
	ret
ALIGN JUMP_ALIGN
.GetFirst:
	jmp		String_StrToken		; Get token length to AX, ptr to ES:DI


;--------------------------------------------------------------------
; Message dialog menu event handler.
;
; MenuMsg_WriteLine
;	Parameters:
;		CX:		Index of line to display
;		ES:DI:	Ptr to STOP terminated string to display
;		SS:BP:	Ptr to MSGVARS
;	Returns:
;		CF:		Set if end of string
;				Cleared if string has unwritten tokens
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuMsg_WriteLine:
	push	di
	call	MenuMsg_GetTokenForLine			; Get ptr to first token, length to AX
	jnc		.EndOfString					; Return if no tokens
	eMOVZX	dx, BYTE [bp+MENUVARS.bWidth]	; Menu width
	sub		dl, SIZE_MSG_HBRDR				; To line length 
	mov		bl, ' '							; Space character
ALIGN JUMP_ALIGN
.PrintToken:
	; Check if space for token
	call	MenuMsg_HasLineSpace	; Space left on line?
	jnc		.PrintDone				;  If not, all done
	; Print token
	push	ax						; Store token length
	mov		cx, ax					; Copy token length to CX
	call	Print_CharBuffer		; Print token
	xchg	dx, bx					; Space char to DL
	PRINT_CHAR
	xchg	dx, bx					; Restore DX
	pop		ax						; Pop token length
	; Get next token
	add		di, ax					; Point to next token
	xor		cx, cx					; Get token at index 0
	call	String_StrToken			; Get next token to ES:DI, len to AX
	jc		.PrintToken				; Print while tokens left
ALIGN JUMP_ALIGN
.EndOfString:	; Last token written
	stc
ALIGN JUMP_ALIGN
.PrintDone:		; End of line but tokens left
	pop		di
	ret


;--------------------------------------------------------------------
; Message dialog menu event handler.
;
; MenuMsg_MsgEvent
;	Parameters:
;		BX:		Callback event
;		CX:		Selected menuitem index
;		DX:		Event parameter (event specific)
;		SS:BP:	Ptr to MSGVARS
;	Returns:
;		AH:		Event specific or unused
;		AL:		1=Event processed
;				0=Event not processed (default action if any)
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuMsg_MsgEvent:
	cmp		bx, EVNT_MMU_SELCHG		; Selection changed?
	je		.RetProcessed			;  If so, return
	cmp		bx, EVNT_MNU_SELSET		; Enter to close dialog?
	je		.CloseDialog			;  If so, jump to close dialog
	cmp		bx, EVNT_MNU_UPD		; Draw menuitem string?
	je		.DrawLine				;  If so, jump to draw
	cmp		bx, EVNT_MNU_KEY		; Any key pressed to close dialog?
	jne		.RetUnhandled			;  If not, ignore message

	; Close dialog since key pressed
ALIGN JUMP_ALIGN
.CloseDialog:
	or		BYTE [bp+MENUVARS.bFlags], FLG_MNU_EXIT	; Any key, exit
ALIGN JUMP_ALIGN
.RetUnhandled:
	xor		ax, ax
	ret

ALIGN JUMP_ALIGN
.DrawLine:
	push	es
	push	di

	; Print string line
	mov		di, [bp+MSGVARS.wStrOff]; Load string offset
	mov		es, [bp+MSGVARS.wStrSeg]; Load string segment
	call	MenuMsg_WriteLine
	pop		di
	pop		es
ALIGN JUMP_ALIGN
.RetProcessed:
	mov		ax, 1					; Event processed
	ret
