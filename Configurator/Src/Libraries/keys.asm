; File name		:	keys.asm
; Project name	:	Keyboard library
; Created date	:	17.11.2009
; Last update	:	31.12.2009
; Author		:	Tomi Tilli
; Description	:	ASM library to for keyboard related functions.		

;--------------- Equates -----------------------------

; String library function to include
%define USE_KEYS_STROKE			; Keys_GetStroke, Keys_IsStroke and Keys_WaitStroke
%define USE_KEYS_PRNTGETUINT	; Keys_PrintGetUint
%define USE_KEYS_PRNTGETYN		; Keys_PrintGetYN
%define USE_KEYS_CLRBUFFER		; Keys_ClrBuffer

; Some BIOS Scan Codes
KEY_BSC_F1		EQU		3Bh
KEY_BSC_F2		EQU		3Ch
KEY_BSC_F3		EQU		3Dh
KEY_BSC_F4		EQU		3Eh
KEY_BSC_F5		EQU		3Fh
KEY_BSC_F6		EQU		40h
KEY_BSC_F7		EQU		41h
KEY_BSC_F8		EQU		42h
KEY_BSC_F9		EQU		43h
KEY_BSC_F10		EQU		44h
KEY_BSC_F11		EQU		57h
KEY_BSC_F12		EQU		58h


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data


;-------------- Public functions ---------------------
; Section containing code
SECTION .text


;--------------------------------------------------------------------
; Checks is keystroke available in keyboard buffer.
; 
; Keys_GetStroke	Removes key from buffer if keystroke available
; Keys_IsStroke		Does not remove key from buffer
; Keys_WaitStroke	Waits until keystroke is available and removes it from buffer
;	Parameters:
;		Nothing
;	Returns:
;		AL:		ASCII character (if keystroke available)
;		AH:		BIOS scan code (if keystroke available)
;		ZF:		Set if no keystroke available
;				Cleared if keystroke available
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_KEYS_STROKE
ALIGN JUMP_ALIGN
Keys_GetStroke:
	call	Keys_IsStroke
	jnz		Keys_WaitStroke
	ret
ALIGN JUMP_ALIGN
Keys_IsStroke:
	mov		ah, 01h				; Check for Keystroke
	int		16h
	ret
ALIGN JUMP_ALIGN
Keys_WaitStroke:
	xor		ah, ah				; Get Keystroke
	int		16h
	test	ax, ax				; Clear ZF
	ret
%endif


;--------------------------------------------------------------------
; Reads keystokes, prints them and converts them to unsigned WORD
; after user has pressed ENTER. Returned value is always valid unless
; user has cancelled by pressing ESC.
; 
; Keys_PrintGetUint
;	Parameters:
;		CX:		Base (10=dec, 16=hex etc.)
;		DX:		Max number of characters wanted
;	Returns:
;		DX:AX:	Unsigned DWORD that the user has entered
;		CF:		Set if unsigned DWORD read successfully
;				Cleared is user has cancelled
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
%ifdef USE_KEYS_PRNTGETUINT
ALIGN JUMP_ALIGN
Keys_PrintGetUint:
	push	es
	push	di
	push	si

	; Reserve stack for buffer
	inc		dx					; Increment for STOP char
	push	ss					; Copy SS...
	pop		es					; ...to ES
	mov		si, sp				; Backup SP
	sub		sp, dx				; Reserve buffer from stack
	mov		di, sp				; ES:DI now points to buffer

	; Get user inputted string
	mov		bx, String_IsBaseChar
	call	Keys_GetStrToBuffer
	jnc		.Return				; Return if user cancellation

	; Convert string to DWORD
	call	String_StrToUInt	; Get DWORD to DX:AX
	
	; Return
ALIGN JUMP_ALIGN
.Return:
	mov		sp, si				; Destroy stack buffer
	pop		si
	pop		di
	pop		es
	ret
%endif


;--------------------------------------------------------------------
; Reads keystokes until Y or N is pressed.
; CF will be set to match selection.
; 
; Keys_PrintGetYN
;	Parameters:
;		Nothing
;	Returns:
;		AX:		'Y' if Y pressed
;				'N' if N pressed
;				Zero if ESC pressed
;		CF:		Set if Y pressed
;				Cleared if N or ESC pressed
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_KEYS_PRNTGETYN
ALIGN JUMP_ALIGN
Keys_PrintGetYN:
	call	Keys_WaitStroke		; Wait until keystroke
	call	String_ToLower		; Char in AL to lower case
	cmp		al, 'y'				; Y pressed?
	je		.RetY				;  If so, return
	cmp		al, 'n'				; N pressed?
	je		.RetN				;  If so, return
	cmp		al, ESC				; ESC pressed?
	je		.RetEsc				;  If so, return N
	call	Keys_Bell			; Play error sound
	jmp		Keys_PrintGetYN		; Loop until right key pressed
ALIGN JUMP_ALIGN
.RetY:
	mov		ax, 'Y'
	stc
	ret
ALIGN JUMP_ALIGN
.RetN:
	mov		ax, 'N'
	ret
ALIGN JUMP_ALIGN
.RetEsc:
	xor		ax, ax
	ret
%endif


;--------------------------------------------------------------------
; Clears BIOS keystroke buffer.
; 
; Keys_ClrBuffer
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_KEYS_CLRBUFFER
ALIGN JUMP_ALIGN
Keys_ClrBuffer:
	call	Keys_GetStroke		; Get keystroke
	jnz		Keys_ClrBuffer		; Loop if keystroke found in buffer
	ret
%endif


;-------------- Private functions ---------------------

;--------------------------------------------------------------------
; Reads user inputted string to buffer. Character verification is
; supported to ignore unwanted characters.
; Function returns when ENTER or ESC will be pressed.
; 
; Keys_GetStrToBuffer
;	Parameters:
;		DX:		Buffer length in characters with STOP included
;		ES:DI:	Ptr to buffer
;		CS:BX:	Ptr to char verification function:
;					Parameters:
;						AL:		Character to verify
;						CX:		Anything passed to Keys_GetStrToBuffer
;					Returns:
;						CF:		Set if character is wanted type
;								Cleared if character is not wanted
;					Corrupts registers:
;						Nothing
;	Returns:
;		AX:		String length in characters without STOP
;		CF:		Set if string has been read successfully
;				Cleared if user cancellation
;	Corrupts registers:
;		DX
;--------------------------------------------------------------------
%ifdef USE_KEYS_PRNTGETUINT
ALIGN JUMP_ALIGN
Keys_GetStrToBuffer:
	push	di
	push	si
	dec		dx					; Decrement for STOP char
	xor		si, si				; Zero char counter
	cld							; STOSB to increment DI
ALIGN JUMP_ALIGN
.CharLoop:
	call	Keys_WaitStroke		; Wait for keystroke
	cmp		al, CR				; Enter pressed?
	je		.End				;  If so, return (CF cleared)
	cmp		al, ESC				; Esc pressed?
	je		.Cancel				;  If so, jump to cancel
	cmp		al, BS				; Backspace pressed?
	je		.Backspace			;  If so, jump to process it
	call	bx					; Is wanted character?
	jnc		.Bell				;  If not, play error sound and wait next key

	; Limit char count
	cmp		si, dx				; Max number of chars entered?
	jae		.CharLoop			;  If so, wait for ENTER or BACKSPACE

	; Write base character in AL
	stosb						; Store char from AL to [ES:DI]
	inc		si					; Increment char count
	push	dx
	mov		dl, al				; Copy char to DL
	PRINT_CHAR					; Print character
	pop		dx
	jmp		.CharLoop			; Jump to wait next char
ALIGN JUMP_ALIGN
.Bell:
	call	Keys_Bell
	jmp		.CharLoop			; Jump to wait next char
ALIGN JUMP_ALIGN
.Backspace:
	call	Keys_Backspace
	jmp		.CharLoop			; Jump to wait next char
ALIGN JUMP_ALIGN
.Cancel:
	xor		si, si				; Zero string length (clear CF)
	jmp		.Return
ALIGN JUMP_ALIGN
.End:
	stc							; Set CF since success
.Return:
	mov		al, STOP			; End string
	stosb
	mov		ax, si				; String length
	pop		si
	pop		di
	ret
%endif


;--------------------------------------------------------------------
; Plays bell sound for invalid key presses.
; 
; Keys_Bell
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_KEYS_PRNTGETUINT or USE_KEYS_PRNTGETYN
ALIGN JUMP_ALIGN
Keys_Bell:
	push	dx
	mov		dl, BELL
	PRINT_CHAR
	pop		dx
	ret
%endif


;--------------------------------------------------------------------
; Handles backspace key by removing last written character.
; 
; Keys_Backspace
;	Parameters:
;		SI:		Character counter
;		ES:DI:	Ptr to buffer
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifdef USE_KEYS_PRNTGETUINT
ALIGN JUMP_ALIGN
Keys_Backspace:
	push	dx
	test	si, si				; At the beginning?
	jz		.Return				;  If so, return
	dec		si					; Decrement char counter
	dec		di					; Decrement offset to buffer
	mov		dl, BS				; Write backspace
	PRINT_CHAR
	mov		dl, ' '				; Write space
	PRINT_CHAR
	mov		dl, BS				; Back again
	PRINT_CHAR
ALIGN JUMP_ALIGN
.Return:
	pop		dx
	ret
%endif
