; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessing ATA information read with
;					IDENTIFY DEVICE command.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; AtaID_GetPCHS
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		AX:		Number of user specified P-CHS cylinders
;		BH:		Number of user specified P-CHS sectors per track
;		BL:		Number of user specified P-CHS heads
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AtaID_GetPCHS:
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
	push	ds

	push	es
	pop		ds
	xor		bx, bx
	test	WORD [si+ATA1.wCaps], A1_wCaps_LBA
	jz		SHORT .GetChsSectorCount
	; Fall to .GetLbaSectorCount

;--------------------------------------------------------------------
; .GetLbaSectorCount
;	Parameters:
;		BX:		Zero
;		DS:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.GetLbaSectorCount:
	test	WORD [si+ATA6.wSetSup83], A6_wSetSup83_LBA48
	jz		SHORT .GetLba28SectorCount
	mov		ax, [si+ATA6.qwLBACnt]
	mov		dx, [si+ATA6.qwLBACnt+2]
	mov		bx, [si+ATA6.qwLBACnt+4]
	pop		ds
	ret
.GetLba28SectorCount:
	mov		ax, [si+ATA1.dwLBACnt]
	mov		dx, [si+ATA1.dwLBACnt+2]
	pop		ds
	ret

;--------------------------------------------------------------------
; .GetChsSectorCount
;	Parameters:
;		DS:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		DX:AX:	24-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.GetChsSectorCount:
	mov		al, [si+ATA1.wSPT]		; AL=Sectors per track
	mul		BYTE [si+ATA1.wHeadCnt]	; AX=Sectors per track * number of heads
	mul		WORD [si+ATA1.wCylCnt]	; DX:AX=Sectors per track * number of heads * number of cylinders
	pop		ds
	ret
