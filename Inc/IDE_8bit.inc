; Project name	:	XTIDE Universal BIOS
; Description	:	Macros for accessing data port(s) on 8-bit
;					IDE controllers.
%ifndef IDE_8BIT_INC
%define IDE_8BIT_INC

;--------------------------------------------------------------------
; Emulates INSW for XTIDE.
;
; XTIDE_INSW
;	Parameters:
;		BX:		Bit mask for toggling XTIDE data low/high reg
;		DX:		XTIDE Data Low Register address
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		ES:DI:	Incremented/decremented for next word
;	Corrupts registers:
;		AL, FLAGS
;--------------------------------------------------------------------
%macro XTIDE_INSW 0
%ifdef USE_186	; INS instruction available
	insb						; Load low byte from port DX to [ES:DI]
	xor		dx, bx				; IDE Data Reg to XTIDE Data High Reg
	insb						; Load high byte from port DX to [ES:DI]
	xor		dx, bx				; Restore to IDE Data Register
%else	; If 8088/8086
	in		al, dx				; Load low byte from port
	xor		dx, bx				; IDE Data Reg to XTIDE Data High Reg
	stosb						; Store byte to [ES:DI]
	in		al, dx				; Load high byte from port
	xor		dx, bx				; Restore to IDE Data Register
	stosb						; Store byte to [ES:DI]
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates OUTSW for XTIDE.
;
; XTIDE_OUTSW
;	Parameters:
;		BX:		Bit mask for toggling XTIDE data low/high reg
;		DX:		XTIDE Data Low Register address
;		DS:SI:	Ptr to source buffer
;	Returns:
;		SI:		Incremented/decremented for next word
;	Corrupts registers:
;		AX, FLAGS
;--------------------------------------------------------------------
%macro XTIDE_OUTSW 0
%ifdef USE_186	; OUTS instruction available
	lodsb						; Load low byte from [DS:SI] to AL
	xor		dx, bx				; IDE Data Reg to XTIDE Data High Reg
	outsb						; Output high byte from [DS:SI]
	xor		dx, bx				; XTIDE Data High Reg to Data Low Reg
	out		dx, al				; Output low byte from AL
%else	; If 8088/8086
	lodsw						; Load word from [DS:SI]
	xor		dx, bx				; IDE Data Reg to XTIDE Data High Reg
	xchg	al, ah				; => AL=high byte, AH=low byte
	out		dx, al				; Output high byte
	xor		dx, bx				; XTIDE Data High Reg to Data Low Reg
	mov		al, ah				; Copy low byte to AL
	out		dx, al				; Output low byte
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates OUTSW for modified XTIDE.
;
; XTIDE_MOD_OUTSW
;	Parameters:
;		DX:		XTIDE Data Low Register address
;		DS:SI:	Ptr to source buffer
;	Returns:
;		SI:		Incremented/decremented for next word
;	Corrupts registers:
;		AX, FLAGS
;--------------------------------------------------------------------
%macro XTIDE_MOD_OUTSW 0
%ifdef USE_186	; OUTS instruction available
	lodsb						; Load low byte from [DS:SI] to AL
	inc		dx					; IDE Data Reg to XTIDE MOD Data High Reg
	outsb						; Output high byte from [DS:SI]
	dec		dx					; XTIDE Data High Reg to Data Low Reg
	out		dx, al				; Output low byte from AL
%else	; If 8088/8086
	lodsw						; Load word from [DS:SI]
	inc		dx					; IDE Data Reg to XTIDE MOD Data High Reg
	xchg	al, ah				; => AL=high byte, AH=low byte
	out		dx, al				; Output high byte
	dec		dx					; XTIDE Data High Reg to Data Low Reg
	mov		al, ah				; Copy low byte to AL
	out		dx, al				; Output low byte
%endif
%endmacro


%endif ; IDE_8BIT_INC
