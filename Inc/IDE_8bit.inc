; File name		:	IDE_8bit.inc
; Project name	:	IDE BIOS
; Created date	:	4.4.2010
; Last update	:	13.4.2010
; Author		:	Tomi Tilli
; Description	:	Macros for accessing data port(s) on 8-bit
;					IDE controllers.
%ifndef IDE_8BIT_INC
%define IDE_8BIT_INC

;--------------------------------------------------------------------
; Emulates REP INSW for XTIDE dual (8-bit) data port.
;
; eREP_DUAL_BYTE_PORT_INSW
;	Parameters:
;		CX:		Loop count
;		DX:		Port address (must be IDE Data Register)
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		CX:		Zero
;		DI:		Incremented/decremented
;	Corrupts registers:
;		AX, FLAGS
;--------------------------------------------------------------------
%macro eREP_DUAL_BYTE_PORT_INSW 0
	push	bx
	times 2	shr	cx, 1			; Loop unrolling
	mov		bx, 8				; Bit mask for toggling data low/high reg
ALIGN JUMP_ALIGN
%%InswLoop:
	eDUAL_BYTE_PORT_INSW
	eDUAL_BYTE_PORT_INSW
	eDUAL_BYTE_PORT_INSW
	eDUAL_BYTE_PORT_INSW
	loop	%%InswLoop
	pop		bx
%endmacro

;--------------------------------------------------------------------
; Emulates INSW for XTIDE dual (8-bit) data port.
;
; eDUAL_BYTE_PORT_INSW
;	Parameters:
;		BX:		Bit mask for toggling XTIDE data low/high reg
;		DX:		Port address (must be IDE Data Register)
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		ES:DI:	Incremented/decremented for next word
;	Corrupts registers:
;		AL, FLAGS
;--------------------------------------------------------------------
%macro eDUAL_BYTE_PORT_INSW 0
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
; Emulates REP OUTSW for XTIDE dual (8-bit) data port.
;
; eREP_DUAL_BYTE_PORT_OUTSW
;	Parameters:
;		CX:		Loop count
;		DX:		Port address (must be IDE Data Register)
;		ES:SI:	Ptr to source buffer
;	Returns:
;		SI:		Incremented/decremented
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
%macro eREP_DUAL_BYTE_PORT_OUTSW 0
	push	ds
	push	bx
	times 2	shr	cx, 1			; Loop unrolling
	mov		bx, 8				; Bit mask for toggling data low/high reg
	push	es					; Copy ES...
	pop		ds					; ...to DS
ALIGN JUMP_ALIGN
%%OutswLoop:
	eDUAL_BYTE_PORT_OUTSW
	eDUAL_BYTE_PORT_OUTSW
	eDUAL_BYTE_PORT_OUTSW
	eDUAL_BYTE_PORT_OUTSW
	loop	%%OutswLoop
	pop		bx
	pop		ds
%endmacro

;--------------------------------------------------------------------
; Emulates OUTSW for XTIDE dual (8-bit) data port.
;
; eDUAL_BYTE_PORT_OUTSW
;	Parameters:
;		BX:		Bit mask for toggling XTIDE data low/high reg
;		DX:		Port address (must be IDE Data Register)
;		DS:SI:	Ptr to source buffer
;	Returns:
;		SI:		Incremented/decremented for next word
;	Corrupts registers:
;		AX, FLAGS
;--------------------------------------------------------------------
%macro eDUAL_BYTE_PORT_OUTSW 0
%ifdef USE_186	; OUTS instruction available
	lodsb						; Load low byte from [DS:SI] to AL
	xor		dx, bx				; IDE Data Reg to XTIDE Data High Reg
	outsb						; Output high byte from [DS:SI]
	xor		dx, bx				; IDE Data Reg to XTIDE Data Low Reg
	out		dx, al				; Output low byte from AL
%else	; If 8088/8086
	lodsw						; Load word from [DS:SI]
	xor		dx, bx				; IDE Data Reg to XTIDE Data High Reg
	xchg	al, ah				; => AL=high byte, AH=low byte
	out		dx, al				; Output high byte
	xor		dx, bx				; XTIDE Data High Reg to IDE Data Reg
	mov		al, ah				; Copy low byte to AL
	out		dx, al				; Output low byte
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates REP INSW for IDE controllers with single 8-bit Data Port.
;
; eREP_SINGLE_BYTE_PORT_INSW
;	Parameters:
;		CX:		Number of WORDs to transfer
;		DX:		IDE Data Port address
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		DI:		Incremented/decremented
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
%macro eREP_SINGLE_BYTE_PORT_INSW 0
%ifdef USE_186	; INS instruction available
	shl		cx, 1				; WORD count to BYTE count
	rep insb
%else			; If 8088/8086
	shr		cx, 1				; WORD count to DWORD count
ALIGN JUMP_ALIGN
%%InsdLoop:
	in		al, dx
	stosb						; Store to [ES:DI]
	in		al, dx
	stosb
	in		al, dx
	stosb
	in		al, dx
	stosb
	loop	%%InsdLoop
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates REP OUTSW for IDE controllers with single 8-bit Data Port.
;
; eREP_SINGLE_BYTE_PORT_OUTSW
;	Parameters:
;		CX:		Number of WORDs to transfer
;		DX:		IDE Data Port address
;		ES:SI:	Ptr to source buffer
;	Returns:
;		SI:		Incremented/decremented
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
%macro eREP_SINGLE_BYTE_PORT_OUTSW 0
%ifdef USE_186	; OUTS instruction available
	shl		cx, 1				; WORD count to BYTE count
	eSEG	es					; Source is ES segment
	rep outsb
%else			; If 8088/8086
	shr		cx, 1				; WORD count to DWORD count
	push	ds					; Store DS
	push	es					; Copy ES...
	pop		ds					; ...to DS
ALIGN JUMP_ALIGN
%%OutsdLoop:
	lodsb						; Load from [DS:SI] to AL
	out		dx, al
	lodsb
	out		dx, al
	lodsb
	out		dx, al
	lodsb
	out		dx, al
	loop	%%OutsdLoop
	pop		ds					; Restore DS
%endif
%endmacro


%endif ; IDE_8BIT_INC
