; File name		:	AtaID.asm
; Project name	:	IDE BIOS
; Created date	:	6.4.2010
; Last update	:	9.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions for accessing ATA information read with
;					IDENTIFY DEVICE command.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Returns P-CHS values from ATA information.
;
; AtaID_GetPCHS
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		AX:		Number of user specified P-CHS cylinders
;		BL:		Number of user specified P-CHS sectors per track
;		BH:		Number of user specified P-CHS heads
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AtaID_GetPCHS:
	mov		ax, [es:si+ATA1.wCylCnt]	; Cylinders (1...16383)
	mov		bh, [es:si+ATA1.wHeadCnt]	; Heads (1...16)
	mov		bl, [es:si+ATA1.wSPT]		; Sectors per Track (1...63)
	ret


;--------------------------------------------------------------------
; Returns total number of available sectors from ATA information.
;
; AtaID_GetTotalSectorCount
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AtaID_GetTotalSectorCount:
	xor		bx, bx
	test	WORD [es:si+ATA1.wCaps], A1_wCaps_LBA
	jz		SHORT AtaID_GetChsSectorCount
	; Fall to AtaID_GetLbaSectorCount

;--------------------------------------------------------------------
; Returns total number of available sectors for LBA addressing.
;
; AtaID_GetLbaSectorCount
;	Parameters:
;		BX:		Zero
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
AtaID_GetLbaSectorCount:
	test	WORD [es:si+ATA6.wSetSup83], A6_wSetSup83_LBA48
	jz		SHORT .GetLba28SectorCount
	mov		ax, [es:si+ATA6.qwLBACnt]
	mov		dx, [es:si+ATA6.qwLBACnt+2]
	mov		bx, [es:si+ATA6.qwLBACnt+4]
	ret
ALIGN JUMP_ALIGN
.GetLba28SectorCount:
	mov		ax, [es:si+ATA1.dwLBACnt]
	mov		dx, [es:si+ATA1.dwLBACnt+2]
	ret

;--------------------------------------------------------------------
; Returns total number of available sectors for P-CHS addressing.
;
; AtaID_GetChsSectorCount
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		DX:AX:	24-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AtaID_GetChsSectorCount:
	mov		al, [es:si+ATA1.wSPT]		; AL=Sectors per track
	mul		BYTE [es:si+ATA1.wHeadCnt]	; AX=Sectors per track * number of heads
	mul		WORD [es:si+ATA1.wCylCnt]	; DX:AX=Sectors per track * number of heads * number of cylinders
	ret
