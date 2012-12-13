; Project name	:	Assembly Library
; Description	:	Functions for size calculations.

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

%ifdef INCLUDE_MENU_LIBRARY
struc BYTE_MULTIPLES
	.B			resb	1
	.kiB		resb	1
	.MiB		resb	1
	.GiB		resb	1
	.TiB		resb	1
endstruc

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Size_GetSizeToAXAndCharToDLfromBXDXAXwithMagnitudeInCX
;	Parameters:
;		BX:DX:AX:	Size in magnitude
;		CX:			Magnitude in BYTE_MULTIPLES
;	Returns:
;		AX:			Size in magnitude
;		CX:			Tenths
;		DL:			Magnitude character:
;						'k' = *1024   B = kiB
;						'M' = *1024 kiB = MiB
;						'G' = *1024 MiB = GiB
;						'T' = *1024 GiB = TiB
;						'P' = *1024 TiB = PiB
;	Corrupts registers:
;		BX, DH
;--------------------------------------------------------------------
ALIGN UTIL_SIZE_JUMP_ALIGN
Size_GetSizeToAXAndCharToDLfromBXDXAXwithMagnitudeInCX:
%ifndef USE_186		; If 8086/8088
	push	di
%endif
	push	si

ALIGN UTIL_SIZE_JUMP_ALIGN
.MagnitudeConversionLoop:
	ePUSH_T	di, .MagnitudeConversionLoop; DI corrupted only on 8086/8088 build
	test	bx, bx						; Bits 32...47 in use?
	jnz		SHORT Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX
	test	dx, dx						; Bits 16...31 in use?
	jnz		SHORT Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX
	cmp		ax, 10000					; 5 digits needed?
	jae		SHORT Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX
	add		sp, BYTE 2					; Clean return address from stack
	xchg	si, cx						; CX = Remainder (0...1023), SI = Magnitude

	; Convert remainder to tenths
	xchg	bx, ax						; Store AX
	mov		ax, 10
	mul		cx							; DX:AX = remainder * 10
	eSHR_IM	ax, 10						; Divide AX by 1024
	xchg	cx, ax						; CX = tenths
	xchg	ax, bx

	; Convert magnitude to character
	mov		dl, [cs:si+.rgbMagnitudeToChar]

	pop		si
%ifndef USE_186
	pop		di
%endif
	ret
.rgbMagnitudeToChar:	db	" kMGTP"
%endif

;--------------------------------------------------------------------
; Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX
;	Parameters:
;		BX:DX:AX:	Size
;		CX:			Magnitude in BYTE_MULTIPLES
;	Returns:
;		BX:DX:AX:	Size in magnitude
;		SI:			Remainder (0...1023)
;		CX:			Magnitude in BYTE_MULTIPLES
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN UTIL_SIZE_JUMP_ALIGN
Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX:
	push	cx
	xor		si, si					; Zero remainder
	mov		cl, 10					; Divide by 1024
ALIGN UTIL_SIZE_JUMP_ALIGN
.ShiftLoop:
	call	Size_DivideBXDXAXbyTwo
	rcr		si, 1					; Update remainder
	loop	.ShiftLoop
	eSHR_IM	si, 6					; Remainder to SI beginning
	pop		cx
	inc		cx						; Increment magnitude
	ret

;--------------------------------------------------------------------
; Size_ConvertSectorCountInBXDXAXtoKiB
; Size_DivideBXDXAXbyTwo
;	Parameters:
;		BX:DX:AX:	Total sector count
;	Returns:
;		BX:DX:AX:	Total size in kiB
;		CF:			Remainder from division
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN UTIL_SIZE_JUMP_ALIGN
Size_ConvertSectorCountInBXDXAXtoKiB:               ; unused entrypoint ok
Size_DivideBXDXAXbyTwo:
	shr		bx, 1					; Divide sector count by 2...
	rcr		dx, 1					; ...to get disk size in...
	rcr		ax, 1					; ...kiB
	ret
