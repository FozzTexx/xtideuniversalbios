; Project name	:	XTIDE Universal BIOS
; Description	:	Macros for accessing data port(s) on 8-bit
;					IDE controllers.

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

%ifndef IDE_8BIT_INC
%define IDE_8BIT_INC

;--------------------------------------------------------------------
; UNROLL_SECTORS_IN_CX_TO_DWORDS
; UNROLL_SECTORS_IN_CX_TO_QWORDS
; UNROLL_SECTORS_IN_CX_TO_OWORDS
;	Parameters:
;		CX:		Number of sectors in block
;	Returns:
;		CX:		Number of DWORDs, QWORDs or OWORDs in block
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro UNROLL_SECTORS_IN_CX_TO_DWORDS 0
%ifdef USE_186
	shl		cx, 7
%else
	xchg	cl, ch		; Sectors to WORDs (SHL CX, 8)
	shr		cx, 1
%endif
%endmacro

%macro UNROLL_SECTORS_IN_CX_TO_QWORDS 0
%ifdef USE_186
	shl		cx, 6
%else
	UNROLL_SECTORS_IN_CX_TO_DWORDS
	shr		cx, 1
%endif
%endmacro

%macro UNROLL_SECTORS_IN_CX_TO_OWORDS 0
%ifdef USE_186
	shl		cx, 5
%else
;	UNROLL_SECTORS_IN_CX_TO_QWORDS
;	shr		cx, 1
	mov		ch, cl		; 2 bytes shorter but possibly slower
	mov		cl, 3
	shr		cx, cl
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates INSW for XTIDE.
;
; XTIDE_INSW
;	Parameters:
;		BL:		Bit mask for toggling XTIDE data low/high reg
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
	xor		dl, bl				; IDE Data Reg to XTIDE Data High Reg
	insb						; Load high byte from port DX to [ES:DI]
	xor		dl, bl				; Restore to IDE Data Register
%else	; If 8088/8086
	in		al, dx				; Load low byte from port
	xor		dl, bl				; IDE Data Reg to XTIDE Data High Reg
	stosb						; Store byte to [ES:DI]
	in		al, dx				; Load high byte from port
	xor		dl, bl				; Restore to IDE Data Register
	stosb						; Store byte to [ES:DI]
%endif
%endmacro


;--------------------------------------------------------------------
; Emulates OUTSW for XTIDE.
;
; XTIDE_OUTSW
;	Parameters:
;		BL:		Bit mask for toggling XTIDE data low/high reg
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
	xor		dl, bl				; IDE Data Reg to XTIDE Data High Reg
	outsb						; Output high byte from [DS:SI]
	xor		dl, bl				; XTIDE Data High Reg to Data Low Reg
	out		dx, al				; Output low byte from AL
%else	; If 8088/8086
	lodsw						; Load word from [DS:SI]
	xor		dl, bl				; IDE Data Reg to XTIDE Data High Reg
	xchg	al, ah				; => AL=high byte, AH=low byte
	out		dx, al				; Output high byte
	xor		dl, bl				; XTIDE Data High Reg to Data Low Reg
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
