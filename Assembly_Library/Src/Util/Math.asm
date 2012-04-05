; Project name	:	Assembly Library
; Description	:	Functions for register operations.

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
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
; Math_DivQWatSSBPbyCX
;	Parameters:
;		[SS:BP]:	64-bit unsigned divident
;		CX:			16-bit unsigned divisor
;	Returns:
;		[SS:BP]:	64-bit unsigned quotient
;		DX:			16-bit unsigned remainder
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDECFG	; Not used in XTIDECFG
ALIGN JUMP_ALIGN
Math_DivQWatSSBPbyCX:
	xor		dx, dx
	mov		ax, [bp+6]		; Load highest divident WORD to DX:AX
	div		cx
	mov		[bp+6], ax		; Store quotient

	mov		ax, [bp+4]
	div		cx
	mov		[bp+4], ax

	mov		ax, [bp+2]
	div		cx
	mov		[bp+2], ax

	mov		ax, [bp]
	div		cx
	mov		[bp], ax
	ret
%endif


;--------------------------------------------------------------------
; Math_DivDXAXbyCX
;	Parameters:
;		DX:AX:	32-bit unsigned divident
;		CX:		16-bit unsigned divisor
;	Returns:
;		DX:AX:	32-bit unsigned quotient
;		BX:		16-bit unsigned remainder
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS OR EXCLUDE_FROM_XTIDECFG
ALIGN JUMP_ALIGN
Math_DivDXAXbyCX:	; This is currently unused (dead code)
	xor		bx, bx
	xchg	bx, ax
	xchg	dx, ax
	div		cx
	xchg	ax, bx
	div		cx
	xchg	dx, bx
	ret
%endif
