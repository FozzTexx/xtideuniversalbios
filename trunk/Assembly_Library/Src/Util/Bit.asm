; Project name	:	Assembly Library
; Description	:	Functions for bit handling.

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

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Bit_GetSetCountToCXfromDXAX
;	Parameters
;		DX:AX:		Source DWORD
;	Returns:
;		CX:		Number of bits set in DX:AX
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Bit_GetSetCountToCXfromDXAX:
	push	bx

	call	Bit_GetSetCountToCXfromAX
	mov		bx, cx
	xchg	ax, dx
	call	Bit_GetSetCountToCXfromAX
	xchg	ax, dx
	add		cx, bx

	pop		bx
	ret


;--------------------------------------------------------------------
; Bit_GetSetCountToCXfromAX
;	Parameters
;		AX:		Source WORD
;	Returns:
;		CX:		Number of bits set in AX
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Bit_GetSetCountToCXfromAX:
	push	ax

	xor		cx, cx
ALIGN JUMP_ALIGN
.BitScanLoop:
	shr		ax, 1
	jz		SHORT .LastBitInCF
	adc		cl, ch
	jmp		SHORT .BitScanLoop
ALIGN JUMP_ALIGN
.LastBitInCF:
	adc		cl, ch

	pop		ax
	ret


;--------------------------------------------------------------------
; Bit_SetToDXAXfromIndexInCL
;	Parameters:
;		CL:		Index of bit to set (0...31)
;		DX:AX:	Destination DWORD with flag to be set
;	Returns:
;		DX:AX:	DWORD with wanted bit set
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Bit_SetToDXAXfromIndexInCL:
	cmp		cl, 16
	jb		SHORT Bit_SetToAXfromIndexInCL

	sub		cl, 16
	xchg	ax, dx
	call	Bit_SetToAXfromIndexInCL
	xchg	dx, ax
	add		cl, 16
	ret

;--------------------------------------------------------------------
; Bit_SetToAXfromIndexInCL
;	Parameters:
;		CL:		Index of bit to set (0...15)
;		AX:		Destination WORD with flag to be set
;	Returns:
;		AX:		WORD with wanted bit set
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Bit_SetToAXfromIndexInCL:
	push	dx

	mov		dx, 1
	shl		dx, cl
	or		ax, dx

	pop		dx
	ret
