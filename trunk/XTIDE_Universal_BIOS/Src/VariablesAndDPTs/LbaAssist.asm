; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for generating L-CHS parameters for
;					LBA drives.
;
;					This file is shared with BIOS Drive Information Tool.

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
; LBA assist calculation:
; this is how to fit a big drive into INT13's skimpy size requirements,
; with a maximum of 8.4G available.
;
; If cylinders > 8192
;  Variable CH = Total Sectors / 63
;  Divide (CH – 1) by 1024 (as an assembler bitwise right shift) and add 1
;  Round the result up to the nearest of 16, 32, 64, 128 and 255. This is the value to be used for the number of heads.
;  Divide CH by the number of heads. This is the value to be used for the number of cylinders.
;
; There's a wealth of information at: http://www.mossywell.com/boot-sequence
; they show a slightly different approach to LBA assist calulations, but
; the method here provides compatibility with phoenix BIOS.
;
; LbaAssist_ConvertSectorCountFromBXDXAXtoLbaAssistedCHSinDXAXBLBH:
;	Parameters:
;		BX:DX:AX:	Total number of sectors
;	Returns:
;		DX:AX:	Number of cylinders
;		BH:		Number of sectors per track (always 63)
;		BL:		Number of heads (16, 32, 64, 128 or 255)
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
LbaAssist_ConvertSectorCountFromBXDXAXtoLbaAssistedCHSinDXAXBLBH:
	push	bp
	push	si

	; Value CH = Total sector count / 63
	xor		cx, cx
	push	cx							; Push zero for bits 48...63
	push	bx
	push	dx
	push	ax							; 64-bit sector count now in stack
	mov		cl, LBA_ASSIST_SPT
	mov		bp, sp						; SS:BP now points sector count
	call	Math_DivQWatSSBPbyCX		; Temporary value A now in stack

	; BX:DX:AX = Value CH - 1
	mov		ax, [bp]
	mov		dx, [bp+2]
	mov		bx, [bp+4]
	sub		ax, BYTE 1					; Subtract 1
	sbb		dx, BYTE 0
	sbb		bx, BYTE 0

	; DX:AX = Number of heads = ((Value CH - 1) / 1024) + 1
	call	Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX
	add		ax, BYTE 1					; Add 1
	adc		dx, bx						; BX = 0

	; Heads must be 16, 32, 64, 128 or 255 (round up to the nearest)
	test	dx, dx						; 65536 or more heads?
	jnz		SHORT .LimitHeadsTo255
	mov		cx, 16						; Min number of heads
.CompareNextValidNumberOfHeads:
	cmp		ax, cx
	jbe		SHORT .NumberOfHeadsNowInCX
	shl		cx, 1						; Double number of heads
	test	ch, ch						; Reached 256 heads?
	jnz		SHORT .CompareNextValidNumberOfHeads
.LimitHeadsTo255:
	mov		cx, 255
.NumberOfHeadsNowInCX:
	mov		bx, cx						; Number of heads are returned in BL
	mov		bh, LBA_ASSIST_SPT			; Sectors per Track

	; DX:AX = Number of cylinders = Value CH (without - 1) / number of heads
	call	Math_DivQWatSSBPbyCX
	mov		ax, [bp]
	mov		dx, [bp+2]					; Cylinders now in DX:AX

	; Return LBA assisted CHS
	add		sp, BYTE 8					; Clean stack
	pop		si
	pop		bp
	ret
