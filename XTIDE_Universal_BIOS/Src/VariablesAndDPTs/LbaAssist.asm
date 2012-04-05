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
; total LBAs (as obtained by words 60+61)
; divided by 63 (sectors per track) (save as value A)
; Sub 1 from A
; divide A by 1024 + truncate.
; == total number of heads to use.
; add 1
; this value must be either 16, 32, 64, 128, or 256 (round up)
; then take the value A above and divide by # of heads
; to get the # of cylinders to use.
;
;
; so a LBA28 drive will have 268,435,456 as maximum LBAs
;
; 10000000h / 63   = 410410h (total cylinders or tracks)
;   410410h / 1024 = 1041h, which is way more than 256 heads, but 256 is max.
;   410410h / 256  = 4104h cylinders
;
; there's a wealth of information at: http://www.mossywell.com/boot-sequence
; they show a slightly different approach to LBA assist calulations, but
; the method here provides compatibility with phoenix BIOS
;
; we're using the values from 60+61 here because we're topping out at 8.4G
; anyway, so there's no need to use the 48bit LBA values.
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

	; Value A = Total sector count / 63
	xor		cx, cx
	push	cx		; Push zero for bits 48...63
	push	bx
	push	dx
	push	ax						; 64-bit sector count now in stack
	mov		cl, LBA_ASSIST_SPT
	mov		bp, sp					; SS:BP now points sector count
	call	Math_DivQWatSSBPbyCX	; Temporary value A now in stack

	; BX = Number of heads =  A / 1024
	mov		ax, [bp]
	mov		dx, [bp+2]
	mov		bx, [bp+4]
	call	Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX

	; Heads must be 16, 32, 64, 128 or 256 (round up)
	mov		bx, 256						; Max number of heads
	test	dx, dx						; 65536 or more heads?
	jnz		SHORT .GetNumberOfCylinders
	mov		cx, 128						; Half BX for rounding up
.FindMostSignificantBitForHeadSize:
	cmp		ax, cx
	jae		SHORT .GetNumberOfCylinders
	shr		cx, 1
	shr		bx, 1						; Halve number of heads
	jmp		SHORT .FindMostSignificantBitForHeadSize

	; DX:AX = Number of cylinders = A / number of heads
.GetNumberOfCylinders:
	mov		cx, bx
	call	Math_DivQWatSSBPbyCX
	mov		ax, [bp]
	mov		dx, [bp+2]					; Cylinders now in DX:AX

	; Return LBA assisted CHS
	add		sp, BYTE 8					; Clean stack
	sub		bl, bh						; Limit heads to 255
	mov		bh, LBA_ASSIST_SPT
	pop		si
	pop		bp
	ret
