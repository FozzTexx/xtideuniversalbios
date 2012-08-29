; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for generating L-CHS parameters for
;					drives with more than 1024 cylinders.
;
; 					These algorithms are taken from: http://www.mossywell.com/boot-sequence
; 					Take a look at it for more detailed information.
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

%ifdef MODULE_EBIOS
;--------------------------------------------------------------------
; AtaGeometry_GetLbaSectorCountToBXDXAXfromAtaInfoInESSI
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		BX:DX:AX:	48-bit sector count
;		CL:			FLGL_DPT_LBA48 if LBA48 supported
;					Zero if only LBA28 is supported
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AtaGeometry_GetLbaSectorCountToBXDXAXfromAtaInfoInESSI:
	mov		bx, Registers_ExchangeDSSIwithESDI
	call	bx	; ATA info now in DS:DI
	push	bx	; We will return via Registers_ExchangeDSSIwithESDI

	; Check if LBA48 supported
	test	BYTE [di+ATA6.wSetSup83+1], A6_wSetSup83_LBA48>>8
	jz		SHORT .GetLba28SectorCount

	; Get LBA48 sector count
	mov		cl, FLGL_DPT_LBA48
	mov		ax, [di+ATA6.qwLBACnt]
	mov		dx, [di+ATA6.qwLBACnt+2]
	mov		bx, [di+ATA6.qwLBACnt+4]
	ret

.GetLba28SectorCount:
	xor		cl, cl
	xor		bx, bx
	mov		ax, [di+ATA1.dwLBACnt]
	mov		dx, [di+ATA1.dwLBACnt+2]
	ret
%endif	; MODULE_EBIOS


;--------------------------------------------------------------------
; AtaGeometry_GetLCHStoAXBLBHfromAtaInfoInESSIandTranslateModeInDX
; AtaGeometry_GetLCHStoAXBLBHfromPCHSinAXBLBHandTranslateModeInDX
;	Parameters:
;		DX:		Wanted translate mode or TRANSLATEMODE_AUTO to autodetect
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		AX:		Number of L-CHS cylinders (1...1027, yes 1027)
;		BL:		Number of L-CHS heads (1...255)
;		BH:		Number of L-CHS sectors per track (1...63)
;		CX:		Number of bits shifted (0...3)
;		DL:		CHS Translate Mode
;	Corrupts registers:
;		DH
;--------------------------------------------------------------------
AtaGeometry_GetLCHStoAXBLBHfromAtaInfoInESSIandTranslateModeInDX:
	call	AtaGeometry_GetPCHStoAXBLBHfromAtaInfoInESSI
	; Fall to AtaGeometry_GetLCHStoAXBLBHfromPCHSinAXBLBH

AtaGeometry_GetLCHStoAXBLBHfromPCHSinAXBLBHandTranslateModeInDX:
	; Check if user defined translate mode
	test	dx, dx
	jnz		SHORT .CheckIfLargeTranslationWanted
	MIN_U	ax, MAX_LCHS_CYLINDERS	; TRANSLATEMODE_NORMAL maximum cylinders
	inc		dx
.CheckIfLargeTranslationWanted:
	dec		dx						; Set ZF if TRANSLATEMODE_LARGE
	jz		SHORT ConvertPCHfromAXBLtoRevisedEnhancedCHinAXBL
	dec		dx						; Set ZF if TRANSLATEMODE_ASSISTED_LBA
	jz		SHORT .UseAssistedLBA
	; TRANSLATEMODE_AUTO set

	; Generate L-CHS using simple bit shift algorithm (ECHS) if
	; 8192 or less cylinders.
	cmp		ax, 8192
	jbe		SHORT ConvertPCHfromAXBLtoEnhancedCHinAXBL

	; We have 8193 or more cylinders so two algorithms are available:
	; Revised ECHS or Assisted LBA. The Assisted LBA provides larger
	; capacity but requires LBA support from drive (drives this large
	; always support LBA but user might have unintentionally set LBA).
.UseAssistedLBA:
	test	BYTE [es:si+ATA1.wCaps+1], A1_wCaps_LBA>>8
	jz		SHORT ConvertPCHfromAXBLtoRevisedEnhancedCHinAXBL

	; Drive supports LBA
	call	GetSectorCountToDXAXfromCHSinAXBLBH
	call	ConvertChsSectorCountFromDXAXtoLbaAssistedLCHSinAXBLBH
	xor		cx, cx		; No bits to shift
	mov		dl, TRANSLATEMODE_ASSISTED_LBA
	ret


;--------------------------------------------------------------------
; AtaGeometry_GetPCHStoAXBLBHfromAtaInfoInESSI
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		AX:		Number of P-CHS cylinders (1...16383)
;		BL:		Number of P-CHS heads (1...16)
;		BH:		Number of P-CHS sectors per track (1...63)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AtaGeometry_GetPCHStoAXBLBHfromAtaInfoInESSI:
	mov		ax, [es:si+ATA1.wCylCnt]	; Cylinders (1...16383)
	mov		bl, [es:si+ATA1.wHeadCnt]	; Heads (1...16)
	mov		bh, [es:si+ATA1.wSPT]		; Sectors per Track (1...63)
	ret


;--------------------------------------------------------------------
; GetSectorCountToDXAXfromCHSinAXBLBH
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		AX:		Number of cylinders (1...16383)
;		BL:		Number of heads (1...255)
;		BH:		Number of sectors per track (1...63)
;	Returns:
;		DX:AX:	Total number of CHS addressable sectors
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
GetSectorCountToDXAXfromCHSinAXBLBH:
	xchg	ax, bx
	mul		ah			; AX = Heads * Sectors per track
	mul		bx
	ret


;--------------------------------------------------------------------
; Revised Enhanced CHS calculation (Revised ECHS)
;
; This algorithm translates P-CHS sector count to L-CHS sector count
; with bit shift algorithm. Since 256 heads are not allowed
; (DOS limit), this algorithm makes translations so that maximum of
; 240 L-CHS heads can be used. This makes the maximum addressable capacity
; to 7,927,234,560 bytes ~ 7.38 GiB. LBA addressing needs to be used to
; get more capacity.
;
; L-CHS parameters generated here require the drive to use CHS addressing.
;
; Here is the algorithm:
; If cylinders > 8192 and heads = 16
;  Heads = 15
;  Cylinders = cylinders * 16 / 15 (losing the fraction component)
;  Do a standard ECHS translation
;
; ConvertPCHfromAXBLtoRevisedEnhancedCHinAXBL:
;	Parameters:
;		AX:		Number of P-CHS cylinders (8193...16383)
;		BL:		Number of P-CHS heads (1...16)
;	Returns:
;		AX:		Number of L-CHS cylinders (?...1024)
;		BL:		Number of L-CHS heads (?...240)
;		CX:		Number of bits shifted (0...3)
;		DL:		ADDRESSING_MODE_NORMAL or ADDRESSING_MODE_LARGE
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ConvertPCHfromAXBLtoRevisedEnhancedCHinAXBL:
	; Generate L-CHS using simple bit shift algorithm (ECHS) if
	; 8192 or less cylinders
	cmp		ax, 8192
	jbe		SHORT ConvertPCHfromAXBLtoEnhancedCHinAXBL
	cmp		bl, 16	; Drives with 8193 or more cylinders can report 15 heads
	jb		SHORT ConvertPCHfromAXBLtoEnhancedCHinAXBL

	eMOVZX	cx, bl	; CX = 16
	dec		bx		; Heads = 15
	mul		cx		; DX:AX = Cylinders * 16
	dec		cx		; CX = 15
	div		cx		; AX = (Cylinders * 16) / 15
	; Fall to ConvertPCHfromAXBXtoEnhancedCHinAXBX


;--------------------------------------------------------------------
; Enhanced CHS calculation (ECHS)
;
; This algorithm translates P-CHS sector count to L-CHS sector count
; with simple bit shift algorithm. Since 256 heads are not allowed
; (DOS limit), this algorithm require that there are at most 8192
; P-CHS cylinders. This makes the maximum addressable capacity
; to 4,227,858,432 bytes ~ 3.94 GiB. Use Revised ECHS or Assisted LBA
; algorithms if there are more than 8192 P-CHS cylinders.
;
; L-CHS parameters generated here require the drive to use CHS addressing.
;
; Here is the algorithm:
;  Multiplier = 1
;  Cylinder = Cylinder - 1
;  Is Cylinder < 1024? If not:
;  Do a right bitwise rotation on the cylinder (i.e., divide by 2)
;  Do a left bitwise rotation on the multiplier (i.e., multiply by 2)
;  Use the multiplier on the Cylinder and Head values to obtain the translated values.
;
; ConvertPCHfromAXBLtoEnhancedCHinAXBL:
;	Parameters:
;		AX:		Number of P-CHS cylinders (1...8192)
;		BL:		Number of P-CHS heads (1...16)
;	Returns:
;		AX:		Number of L-CHS cylinders (?...1024)
;		BL:		Number of L-CHS heads (?...128)
;		CX:		Number of bits shifted (0...3)
;		DL:		TRANSLATEMODE_NORMAL or TRANSLATEMODE_LARGE
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ConvertPCHfromAXBLtoEnhancedCHinAXBL:
	xor		cx, cx		; No bits to shift initially
	xor		dl, dl		; Assume TRANSLATEMODE_NORMAL
.ShiftIfMoreThan1024Cylinder:
	cmp		ax, MAX_LCHS_CYLINDERS
	jbe		SHORT ReturnLCHSinAXBLBH
	shr		ax, 1		; Halve cylinders
	eSHL_IM	bl, 1		; Double heads
	inc		cx			; Increment bit shift count
	mov		dl, TRANSLATEMODE_LARGE
	jmp		SHORT .ShiftIfMoreThan1024Cylinder


;--------------------------------------------------------------------
; LBA assist calculation (or Assisted LBA)
;
; This algorithm translates P-CHS sector count up to largest possible
; L-CHS sector count (1024, 255, 63). Note that INT 13h interface allows
; 256 heads but DOS supports up to 255 head. That is why BIOSes never
; use 256 heads.
;
; L-CHS parameters generated here require the drive to use LBA addressing.
;
; Here is the algorithm:
; If cylinders > 8192
;  Variable CH = Total CHS Sectors / 63
;  Divide (CH – 1) by 1024 and add 1
;  Round the result up to the nearest of 16, 32, 64, 128 and 255. This is the value to be used for the number of heads.
;  Divide CH by the number of heads. This is the value to be used for the number of cylinders.
;
; ConvertChsSectorCountFromDXAXtoLbaAssistedLCHSinAXBLBH:
;	Parameters:
;		DX:AX:	Total number of P-CHS sectors for CHS addressing
;				(max = 16383 * 16 * 63 = 16,514,064)
;	Returns:
;		AX:		Number of cylinders (?...1027)
;		BL:		Number of heads (16, 32, 64, 128 or 255)
;		BH:		Number of sectors per track (always 63)
;	Corrupts registers:
;		CX, DX
;--------------------------------------------------------------------
ConvertChsSectorCountFromDXAXtoLbaAssistedLCHSinAXBLBH:
	; Value CH = Total sector count / 63
	; Max = 16,514,064 / 63 = 262128
	mov		cx, LBA_ASSIST_SPT			; CX = 63
	call	Math_DivDXAXbyCX
	push	dx
	push	ax							; Value CH stored for later use

	; BX:DX:AX = Value CH - 1
	; Max = 262128 - 1 = 262127
	xor		bx, bx
	sub		ax, BYTE 1
	sbb		dx, bx

	; AX = Number of heads = ((Value CH - 1) / 1024) + 1
	; Max = (262127 / 1024) + 1 = 256
	push	si
	call	Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX
	pop		si
	inc		ax							; + 1

	; Heads must be 16, 32, 64, 128 or 255 (round up to the nearest)
	; Max = 255
	mov		cx, 16						; Min number of heads
.CompareNextValidNumberOfHeads:
	cmp		ax, cx
	jbe		SHORT .NumberOfHeadsNowInCX
	eSHL_IM	cl, 1						; Double number of heads
	jnz		SHORT .CompareNextValidNumberOfHeads	; Reached 256 heads?
	dec		cl							;  If so, limit heads to 255
.NumberOfHeadsNowInCX:
	mov		bx, cx						; Number of heads are returned in BL
	mov		bh, LBA_ASSIST_SPT			; Sectors per Track

	; DX:AX = Number of cylinders = Value CH (without - 1) / number of heads
	; Max = 262128 / 255 = 1027
	pop		ax
	pop		dx							; Value CH back to DX:AX
	div		cx

	; Return L-CHS
ReturnLCHSinAXBLBH:
	ret
