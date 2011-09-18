; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessing ATA information read with
;					IDENTIFY DEVICE command.

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
; AtaID_GetLbaAssistedCHStoDXAXBLBH:
;	Parameters:
;		BX:DX:AX:	Total number of sectors
;	Returns:
;		DX:AX:	Number of cylinders
;		BH:		Number of sectors per track (always 63)
;		BL:		Number of heads (16, 32, 64, 128 or 255)
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
AtaID_GetLbaAssistedCHStoDXAXBLBH:
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


;--------------------------------------------------------------------
; AtaID_GetPCHStoAXBLBHfromAtaInfoInESSI
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		AX:		Number of user specified P-CHS cylinders
;		BH:		Number of user specified P-CHS sectors per track
;		BL:		Number of user specified P-CHS heads
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AtaID_GetPCHStoAXBLBHfromAtaInfoInESSI:
	mov		ax, [es:si+ATA1.wCylCnt]	; Cylinders (1...16383)
	mov		bl, [es:si+ATA1.wHeadCnt]	; Heads (1...16)
	mov		bh, [es:si+ATA1.wSPT]		; Sectors per Track (1...63)
	ret


;--------------------------------------------------------------------
; AtaID_GetTotalSectorCountToBXDXAXfromAtaInfoInESSI
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AtaID_GetTotalSectorCountToBXDXAXfromAtaInfoInESSI:
	call	Registers_ExchangeDSSIwithESDI	; ATA info now in DSDI
	xor		bx, bx
	test	BYTE [di+ATA1.wCaps+1], A1_wCaps_LBA>>8
	jz		SHORT .GetChsSectorCount
	; Fall to .GetLbaSectorCount

;--------------------------------------------------------------------
; .GetLbaSectorCount
; .GetLba28SectorCount
; .GetChsSectorCount
;	Parameters:
;		BX:		Zero
;		DS:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.GetLbaSectorCount:
	test	BYTE [di+ATA6.wSetSup83+1], A6_wSetSup83_LBA48>>8
	jz		SHORT .GetLba28SectorCount
	mov		ax, [di+ATA6.qwLBACnt]
	mov		dx, [di+ATA6.qwLBACnt+2]
	mov		bx, [di+ATA6.qwLBACnt+4]
	jmp		SHORT .ExchangePtrAndReturn

.GetLba28SectorCount:
	mov		ax, [di+ATA1.dwLBACnt]
	mov		dx, [di+ATA1.dwLBACnt+2]
	jmp		SHORT .ExchangePtrAndReturn

.GetChsSectorCount:
	mov		al, [di+ATA1.wSPT]		; AL=Sectors per track
	mul		BYTE [di+ATA1.wHeadCnt]	; AX=Sectors per track * number of heads
	mul		WORD [di+ATA1.wCylCnt]	; DX:AX=Sectors per track * number of heads * number of cylinders
.ExchangePtrAndReturn:
	jmp		Registers_ExchangeDSSIwithESDI
