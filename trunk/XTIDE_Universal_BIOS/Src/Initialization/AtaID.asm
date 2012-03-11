; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessing ATA information read with
;					IDENTIFY DEVICE command.

; Section containing code
SECTION .text

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
	mov		bx, Registers_ExchangeDSSIwithESDI
	call	bx	; ATA info now in DS:DI
	push	bx	; We will return via Registers_ExchangeDSSIwithESDI
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
;		DS:DI:	Ptr to 512-byte ATA information read from the drive
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
	ret

.GetLba28SectorCount:
	mov		ax, [di+ATA1.dwLBACnt]
	mov		dx, [di+ATA1.dwLBACnt+2]
	ret

.GetChsSectorCount:
	mov		al, [di+ATA1.wSPT]		; AL=Sectors per track
	mul		BYTE [di+ATA1.wHeadCnt]	; AX=Sectors per track * number of heads
	mul		WORD [di+ATA1.wCylCnt]	; DX:AX=Sectors per track * number of heads * number of cylinders
	ret
