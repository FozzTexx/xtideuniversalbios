; File name		:	string.asm
; Project name	:	String library
; Created date	:	7.10.2009
; Last update	:	20.12.2009
; Author		:	Tomi Tilli,
;				:	Krille (optimizations)
; Description	:	ASM library to work as Standard C String and Character.

;--------------- Equates -----------------------------

; String library function to include
;%define USE_STR_ISCHAR
;%define USE_STR_ISBASECHAR
;%define USE_STR_BUFFHASCHAR
;%define USE_STR_BUFFCMP
;%define USE_STR_TOUINT
;%define USE_STR_LEN
;%define USE_STR_TOKEN
;%define USE_STR_WITHIN
;%define USE_STR_TOLOWER
;%define USE_STR_TOUPPER

; Special characters for strings
STOP				EQU		0	; String ending character
BELL				EQU		7	; Bell
BS					EQU		8	; Backspace
TAB					EQU		9	; Horizontal tab
LF					EQU		10	; Line feed       \ Combine to...
CR					EQU		13	; Carriage return / ...get a newline
ESC					EQU		27	; ESC

; Misc characters
UARROW				EQU		24	; Up arrow
DARROW				EQU		25	; Down arrow
RARROW				EQU		26	; Right arrow
LARROW				EQU		27	; Left arrow

; Characters for printing boxes
B_V					EQU		186	; Bold vertical border (Y-axis)
B_H					EQU		205	; Bold horizontal border (X-axis)
B_TL				EQU		201	; Bold top left border
B_TR				EQU		187	; Bold top right border
B_LR				EQU		188	; Bold lower right border
B_LL				EQU		200	; Bold lower left border

T_V					EQU		179	; Thin vertical border (Y-axis)
T_H					EQU		196	; Thin horizontal border (X-axis)
T_TL				EQU		218	; Thin top left border
T_TR				EQU		191	; Thin top right border
T_LR				EQU		217	; Thin lower right border
T_LL				EQU		192	; Thin lower left border

BVL_THR				EQU		199	; Bold vert on left, Thin horiz on right (||-)
THL_BVR				EQU		182	; Thin horiz on left, Bold vert on right (-||)
TVL_BHR				EQU		198	; Thin vert on left, Bold horiz on right (|=)
BHL_TVR				EQU		181	; Bold horiz on left, Thin vert on right (=|)

; Blocks
MIN_BLCK			EQU		176	; Few character pixels set
FULL_BLCK			EQU		219	; All character pixels set


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data


;-------------- Public functions ---------------------
; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Checks if character is some type of character.
; 
; String_IsAlphaNum (checks if alphanumeric letter, isalnum on C)
; String_IsAlpha (checks if alphabetic letter, isalpha on C)
; String_IsDigit (checks if decimal digit, isdigit on C)
; String_IsLower (checks if lowercase letter, islower on C)
; String_IsSpace (checks if any space character, isspace on C)
; String_IsUpper (checks if uppercase letter, isupper on C)
; String_IsHexDigit (checks if hexadecimal digit, isxdigit on C)
;	Parameters:
;		AL:		Character to check
;	Returns:
;		CF:		Set if character is the type to check
;				Cleared if character is not the type to check
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_ISCHAR
ALIGN JUMP_ALIGN
String_IsAlphaNum:
	call	String_IsAlpha
	jnc		SHORT String_IsDigit
	ret

ALIGN JUMP_ALIGN
String_IsAlpha:
	call	String_IsLower
	jnc		SHORT String_IsUpper
	ret

ALIGN JUMP_ALIGN
String_IsDigit:
	cmp		al, '0'				; At least first dec digit?
	jb		_String_IsRetFalse	;  If not, return FALSE
	cmp		al, '9'+1			; At most last dec digit?
	ret

ALIGN JUMP_ALIGN
String_IsLower:
	cmp		al, 'a'				; At least first lower case letter?
	jb		_String_IsRetFalse	;  If not, return FALSE
	cmp		al, 'z'+1			; At most last lower case letter?
	ret

ALIGN JUMP_ALIGN
String_IsSpace:
	cmp		al, ' '+1			; Space or non-visible character?
	ret

ALIGN JUMP_ALIGN
String_IsUpper:
	cmp		al, 'A'				; At least first upper case letter?
	jb		_String_IsRetFalse	;  If not, return FALSE
	cmp		al, 'Z'+1			; At most last upper case letter?
	ret

ALIGN JUMP_ALIGN
String_IsHexDigit:
	call	String_IsAlphaNum	; Is alphabetic letter or digit?
	jc		.CheckHex			;  If so, jump to check A...F
	ret
.CheckHex:
	push	ax					; Store character
	call	String_ToLower		; Convert to lower case letter
	cmp		al, 'f'+1			; Last valid hex alphanumeric?
	pop		ax					; Restore character
	ret

ALIGN JUMP_ALIGN
_String_IsRetFalse:
	clc							; Clear CF since false
	ret
%endif ; USE_STR_ISCHAR


;--------------------------------------------------------------------
; Checks if character belongs to specified numeric base.
; 
; String_IsBaseChar
;	Parameters:
;		AL:		Character to check
;		CL:		Numeric base (10=dec, 16=hex etc.)
;	Returns:
;		AH:		Integer value for character
;		CF:		Set if character belongs to base
;				Set if character does not belong to base
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_ISBASECHAR
ALIGN JUMP_ALIGN
String_IsBaseChar:
	mov		ah, al				; Copy char to AH
	call	String_IsDigit		; Is '0'...'9'?
	jc		.ConvertDigit		;  If so, jump to convert
	call	String_IsAlpha		; Is alphabetic letter?
	jnc		.RetFalse			;  If not, return FALSE
	call	String_ToLower		; Convert to lower case
	xchg	al, ah				; Converted char to AH
	sub		ah, 'a'-10			; From char to integer: a=10, b=11...
	cmp		ah, cl				; Belongs to base?
	jae		.RetFalse			; If not, return FALSE
	stc							; Set CF since belongs to base
	ret
ALIGN JUMP_ALIGN
.ConvertDigit:
	sub		ah, '0'				; Convert char to integer
	cmp		ah, cl				; Belongs to base?
	jae		.RetFalse			; If not, return FALSE
	stc							; Set CF since belongs to base
	ret
ALIGN JUMP_ALIGN
.RetFalse:
	clc							; Clear CF since char doesn't belong to b
	ret
%endif


;--------------------------------------------------------------------
; Finds first occurrence of character from buffer (memchr on C).
; 
; String_BuffHasChar
;	Parameters:
;		AL:		Character to check
;		CX:		Buffer length in bytes (1...65535, 0 clears CF)
;		ES:DI:	Pointer to buffer
;	Returns:
;		AX:		Index of character in buffer (if char found)
;		ES:BX:	Pointer to character location (if char found)
;		CF:		Set if character found
;				Cleared if character not found
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_BUFFHASCHAR
ALIGN JUMP_ALIGN
String_BuffHasChar:
	jcxz	.Return				; Check length so no need to initialise ZF
	push	di					; Store offset to buffer
times 2 push	cx				; Store CX			
	cld							; Set SCASB to increment DI
	repne scasb					; Compare bytes to AL until found or CX=0
	jne		.CharNotFound		; Character not found, return FALSE

	; Character found
	pop		ax					; Pop buffer length
	sub		ax, cx				; Subtract number of chars left
	dec		ax					; Number of chars scanned to found index
	lea		bx, [di-1]			; Load character offset to BX
	pop		cx					; Restore CX
	pop		di					; Restore DI
	stc							; Set CF since char found
	ret
.CharNotFound:
times 2 pop	cx					; Restore CX
	pop		di					; Restore DI
.Return:
	clc							; Clear CF since char not found
	ret
%endif


;--------------------------------------------------------------------
; Compares two buffers (memcmp on C).
; 
; String_BuffCmp
;	Parameters:
;		CX:		Buffer length in bytes (1...65535, 0 clears ZF)
;		DS:SI:	Pointer to buffer 1
;		ES:DI:	Pointer to buffer 2
;	Returns:
;		AX:		Index of unequal character (if buffers are not equal)
;		ZF:		Set if buffers are equal
;				Cleared if buffers are not equal
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_BUFFCMP
ALIGN JUMP_ALIGN
String_BuffCmp:
	jcxz	.ReturnUnequal		; Check length so no need to initialise ZF
	push	di					; Store offset to buffer 2
	push	si					; Store offset to buffer 1
times 2 push	cx				; Store CX			
	cld							; Set CMPSB to increment SI and DI
	repe cmpsb					; Compare bytes until not equal or CX=0
	jne		.BuffersUnequal		; Unequal byte found, return FALSE
	times 2 pop	cx				; Restore CX
	pop		si					; Restore SI
	pop		di					; Restore DI
	ret
.BuffersUnequal:
	pop		ax					; Pop buffer length
	sub		ax, cx				; Subtrack number of chars left
	dec		ax					; Number of chars compared to unequal idx
	xor		cx, cx				; Zero CX
	dec		cx					; ZF=0
	pop		cx					; Restore CX
	pop		si					; Restore SI
	pop		di					; Restore DI
	ret
.ReturnUnequal:
	xor		ax, ax				; Zero AX
	dec		ax					; AX = FFFFh, ZF=0
	ret
%endif


;--------------------------------------------------------------------
; Converts a string buffer to unsigned 32-bit integer.
; 
; String_BuffToUInt
;	Parameters:
;		ES:DI:	Pointer to string buffer to convert
;		CX:		Base (10=dec, 16=hex etc.)
;		SI:		Buffer length in characters
;	Returns:
;		DX:AX:	32-bit unsigned integer
;		CF:		Set if converted successfully
;				Cleared if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_TOUINT
ALIGN JUMP_ALIGN
String_BuffToUInt:
	; Copy ES:DI to DS:SI
	push	ds					; Store DS
	push	si					; Store SI
	push	di					; Store DI
	push	bx					; Store BX
	xchg	si, di				; Offset to SI, lenght to DI
	push	es
	pop		ds

	; Prepare to read chars
	xor		dx, dx				; Zero DX (HIWORD)
	xor		bx, bx				; Zero BX (LOWORD)
ALIGN JUMP_ALIGN
.CharLoop:
	lodsb						; Load char to AL
	call	String_IsBaseChar	; Is valid character? (AH=digit)
	jnc		.RetFalse			;  If not, return FALSE
	xchg	ax, bx				; AX=LOWORD, BX=digit and char
	call	Math_MulDWbyW		; DX:AX *= CX
	xchg	ax, bx				; AX=digit and char, BX=LOWORD
	mov		al, ah				; Copy digit to AL
	xor		ah, ah				; Zero AH, AX=digit
	add		bx, ax				; Add digit to LOWORD
	adc		dx, 0				; Add carry to HIWORD
	dec		di					; Decrement characters left
	jnz		.CharLoop			; Loop while characters left

	mov		ax, bx				; Copy loword to AX
	pop		bx					; Restore BX
	pop		di					; Restore DI
	pop		si					; Restore SI
	pop		ds					; Restore DS
	stc							; Set CF since success
	ret
ALIGN JUMP_ALIGN
.RetFalse:
	mov		ax, bx				; Copy (likely incomplete) loword to AX
	pop		bx					; Restore BX
	pop		di					; Restore DI
	pop		si					; Restore SI
	pop		ds					; Restore DS
	clc							; Clear CF since error
	ret
%endif


;--------------------------------------------------------------------
; Returns string lenght. Strings must end to STOP character (strlen on C).
; 
; String_StrLen
;	Parameters:
;		ES:DI:	Pointer to string
;	Returns:
;		AX:		String length in characters excluding STOP char
;		CF:		Set if STOP character was found
;				Cleared if STOP character was not found
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_LEN
ALIGN JUMP_ALIGN
String_StrLen:
	push	cx					; Store CX
	mov		al, STOP			; Load string end char to AL
	mov		cx, -1				; Scan for maximum string length
	call	String_BuffHasChar	; Find offset for string ending char
	pop		cx					; Restore CX
	ret
%endif


;--------------------------------------------------------------------
; Returns length for token string. Token strings ends to any whitespace
; character or to STOP.
; 
; String_TokenLen
;	Parameters:
;		ES:DI:	Pointer to token string
;	Returns:
;		AX:		Token length in characters
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_TOKEN
ALIGN JUMP_ALIGN
String_TokenLen:
	push	bx					; Store BX
	xor		bx, bx				; Zero BX for token length
ALIGN JUMP_ALIGN
.CharLoop:
	mov		al, [es:di+bx]		; Load character to AL
	cmp		al, STOP			; End of token?
	je		.Return				;  If so, return
	call	String_IsSpace		; End of token?
	jc		.Return				;  If so, return
	inc		bx					; Increment token length
	jmp		.CharLoop			; Loop while characters left
ALIGN JUMP_ALIGN
.Return:
	mov		ax, bx				; Copy string length to AX
	pop		bx					; Restore BX
	ret
%endif


;--------------------------------------------------------------------
; Returns index and ptr to first occurrence of
; string 2 in string 1 (strstr on C).
; Strings must be STOP terminated strings.
; 
; String_StrWithin
;	Parameters:
;		DS:SI:	Pointer to string 1
;		ES:DI:	Pointer to string 2
;	Returns:
;		AX:		Index to first occurrence of string 2 in string 1
;		DS:BX:	Pointer to first occurrence of string 2 in string 1
;		CF:		Set if string 2 was found in string 1
;				Cleared if string 2 was not found
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_WITHIN
ALIGN JUMP_ALIGN
String_StrWithin:
	push	cx					; Store CX
	push	si					; Store SI
	call	String_StrLen		; Load str2 length to AX
	mov		cx, ax				; Copy str2 length to CX

ALIGN JUMP_ALIGN
.Str1CharLoop:
	cmp		BYTE [si], STOP		; End of string?
	je		.Str2NotFound		;  If so, return FALSE
	call	String_BuffCmp		; str2 found in str1?
	je		.Str2Found			;  If so, break loop
	add		si, ax				; Add index to first unmatching char
	inc		si					; Increment str1 ptr
	jmp		.Str1CharLoop		; Loop while characters left

ALIGN JUMP_ALIGN
.Str2Found:
	mov		bx, si				; Copy ptr to BX
	mov		ax, si				; Copy ptr to AX
	pop		si					; Restore SI
	pop		cx					; Restore CX
	sub		ax, si				; Calculate index to str2 in str1
	stc							; Set CF since str2 found
	ret
ALIGN JUMP_ALIGN
.Str2NotFound:
	xor		bx, bx				; Zero BX
	pop		si					; Restore SI
	pop		cx					; Restore CX
	clc							; Clear CF since str2 was not found
	ret
%endif


;--------------------------------------------------------------------
; Returns pointer to wanted token inside STOP terminated string.
; Tokens are separated by any white space characters.
; 
; String_StrToken
;	Parameters:
;		CX:		Index of token to return
;		ES:DI:	Pointer to string
;	Returns:
;		AX:		Token string length (if token found)
;		ES:DI:	Pointer to token (if token found)
;		CF:		Set if token found
;				Cleared if token not found
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_TOKEN
ALIGN JUMP_ALIGN
String_StrToken:
	push	cx					; Store CX
	push	si					; Store SI
	push	ds					; Store DS
	push	es					; Copy ES:DI to DS:SI
	pop		ds
	mov		si, di
	inc		cx					; Increment to number of tokens to search
	cld							; LODSB to increment SI
ALIGN JUMP_ALIGN
.ConsumeWhite:
	lodsb						; Load char to AL from [DS:SI]
	cmp		al, STOP			; End of string?
	je		.NotFound			;  If so, token was not found
	call	String_IsSpace		; Any whitespace character?
	jc		.ConsumeWhite		;  If so, skip it
	dec		si					; Decrement SI to point first non-space
	mov		di, si				; Copy offset to token to DI
ALIGN JUMP_ALIGN
.TokenLoop:
	lodsb						; Load char to AL
	cmp		al, STOP			; End of string?
	je		.EndOfString		;  If so, end token
	call	String_IsSpace		; Any whitespace character?
	jnc		.TokenLoop			;  If not, loop
	loop	.ConsumeWhite		; Loop until wanted token found
.RetToken:
	pop		ds					; Restore DS
	pop		si					; Restore SI
	pop		cx					; Restore CX
	call	String_TokenLen		; Get token length to AX
	stc							; Set CF since token found
	ret
ALIGN JUMP_ALIGN
.EndOfString:
	dec		si					; Offset to STOP
	cmp		di, si				; STOP only char in token?
	je		.NotFound			;  If so, then it is not valid token
	loop	.NotFound			; If last token was not wanted
	jmp		.RetToken
ALIGN JUMP_ALIGN
.NotFound:
	pop		ds					; Restore DS
	pop		si					; Restore SI
	pop		cx					; Restore CX
	clc							; Clear CF since token not found
	ret
%endif


;--------------------------------------------------------------------
; Converts a STOP terminated string to unsigned 32-bit integer.
; 
; String_StrToUInt
;	Parameters:
;		ES:DI:	Pointer to string to convert
;		CX:		Base (10=dec, 16=hex etc.)
;	Returns:
;		DX:AX:	32-bit unsigned integer
;		CF:		Set if converted successfully
;				Cleared if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_TOUINT
ALIGN JUMP_ALIGN
String_StrToUInt:
	push	si
	call	String_StrLen		; Get string length to AX
	mov		si, ax				; Copy length to SI
	call	String_BuffToUInt	; Convert to integer in DX:AX
	pop		si
	ret
%endif
%if 0
String_StrToUInt:		; Faster but we want to minimize size
	; Copy ES:DI to DS:SI
	push	ds					; Store DS
	push	si					; Store SI
	push	bx					; Store BX
	mov		si, di				; Copy ES:DI to DS:SI
	push	es
	pop		ds

	; Prepare to read chars
	xor		dx, dx				; Zero DX (HIWORD)
	xor		bx, bx				; Zero BX (LOWORD)
ALIGN JUMP_ALIGN
.CharLoop:
	lodsb						; Load char to AL
	cmp		al, STOP			; End of string?
	je		.ConvComplete		;  If so, break loop
	call	String_IsBaseChar	; Is valid character? (AH=digit)
	jnc		.RetFalse			;  If not, return FALSE
	xchg	ax, bx				; AX=LOWORD, BX=digit and char
	call	Math_MulDWbyW		; DX:AX *= CX
	xchg	ax, bx				; AX=digit and char, BX=LOWORD
	mov		al, ah				; Copy digit to AL
	xor		ah, ah				; Zero AH, AX=digit
	add		bx, ax				; Add digit to LOWORD
	adc		dx, 0				; Add carry to HIWORD
	jmp		.CharLoop			; Loop while valid characters
ALIGN JUMP_ALIGN
.ConvComplete:
	mov		ax, bx				; Copy loword to AX
	pop		bx					; Restore BX
	pop		si					; Restore SI
	pop		ds					; Restore DS
	stc							; Set CF since success
	ret
ALIGN JUMP_ALIGN
.RetFalse:
	mov		ax, bx				; Copy (likely incomplete) loword to AX
	pop		bx					; Restore BX
	pop		si					; Restore SI
	pop		ds					; Restore DS
	clc							; Clear CF since error
	ret
%endif


;--------------------------------------------------------------------
; Converts upper case character to lower case character.
; 
; String_ToLower
;	Parameters:
;		AL:		Character to convert
;	Returns:
;		AL:		Character with possible conversion
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_TOLOWER
ALIGN JUMP_ALIGN
String_ToLower:
	call	String_IsUpper		; Is upper case character?
	jnc		.Return				;  If not, return
	add		al, 'a'-'A'			; Convert to lower case
.Return:
	ret
%endif


;--------------------------------------------------------------------
; Converts lower case character to upper case character.
; 
; String_ToUpper
;	Parameters:
;		AL:		Character to convert
;	Returns:
;		AL:		Character with possible conversion
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef USE_STR_TOUPPER
ALIGN JUMP_ALIGN
String_ToUpper:
	call	String_IsLower		; Is lower case character?
	jnc		.Return				;  If not, return
	sub		al, 'a'-'A'			; Convert to upper case
.Return:
	ret
%endif
