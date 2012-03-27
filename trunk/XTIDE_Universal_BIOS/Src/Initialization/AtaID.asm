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


%ifdef MODULE_ADVANCED_ATA
;--------------------------------------------------------------------
; AtaID_GetMaxPioModeToAXandMinCycleTimeToCX
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		AL:		Max supported PIO mode
;		AH:		FLGH_DPT_IORDY if IORDY supported, zero otherwise
;		CX:		Minimum Cycle Time in nanosecs
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
AtaID_GetMaxPioModeToAXandMinCycleTimeToCX:
	; Get PIO mode and cycle time for PIO 0...2
	mov		bx, [es:si+ATA1.bPioMode]
	shl		bx, 1					; Shift for WORD lookup
	mov		cx, [cs:bx+.rgwPio0to2CycleTimeInNanosecs]
	shr		bx, 1
	xchg	ax, bx					; AH = 0, AL = PIO mode 0, 1 or 2

	; Check if IORDY is supported
	test	BYTE [es:si+ATA2.wCaps+1], A2_wCaps_IORDY >> 8
	jz		SHORT .ReturnPioTimings	; No PIO 3 or higher if no IORDY
	mov		ah, FLGH_DPT_IORDY

	; Check if Advanced PIO modes are supported (3 and above)
	test	BYTE [es:si+ATA2.wFields], A2_wFields_64to70
	jz		SHORT .ReturnPioTimings

	; Get Advanced PIO mode
	; (Hard Disks supports up to 4 but CF cards can support 5 and 6)
	mov		bx, [es:si+ATA2.bPIOSupp]
.CheckNextFlag:
	inc		ax
	shr		bx, 1
	jnz		SHORT .CheckNextFlag
	MIN_U	al, 6						; Make sure not above lookup tables
	mov		cx, [es:si+ATA2.wPIOMinCyF]	; Advanced modes use IORDY
.ReturnPioTimings:
	ret

.rgwPio0to2CycleTimeInNanosecs:
	dw		PIO_0_MIN_CYCLE_TIME_NS
	dw		PIO_1_MIN_CYCLE_TIME_NS
	dw		PIO_2_MIN_CYCLE_TIME_NS


;--------------------------------------------------------------------
; AtaID_GetRecoveryTimeToAXfromPioModeInBXandCycleTimeInCX
;	Parameters:
;		BX:		PIO Mode
;		CX:		PIO Cycle Time in nanosecs
;	Returns:
;		AX:		Active Time in nanosecs
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
AtaID_GetRecoveryTimeToAXfromPioModeInBXandCycleTimeInCX:
	call	AtaID_GetActiveTimeToAXfromPioModeInBX
	mov		bl, [cs:bx+.rgbPioModeToAddressValidTimeNs]
	sub		cx, bx	; Cycle Time (t0) - Address Valid Time (t1)
	sub		cx, ax	; - Active Time (t2)
	xchg	ax, cx	; AX = Recovery Time (t2i)
	ret

.rgbPioModeToAddressValidTimeNs:
	db		PIO_0_MIN_ADDRESS_VALID_NS
	db		PIO_1_MIN_ADDRESS_VALID_NS
	db		PIO_2_MIN_ADDRESS_VALID_NS
	db		PIO_3_MIN_ADDRESS_VALID_NS
	db		PIO_4_MIN_ADDRESS_VALID_NS
	db		PIO_5_MIN_ADDRESS_VALID_NS
	db		PIO_6_MIN_ADDRESS_VALID_NS


;--------------------------------------------------------------------
; AtaID_GetActiveTimeToAXfromPioModeInBX
;	Parameters:
;		BX:		PIO Mode
;	Returns:
;		AX:		Active Time in nanosecs
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AtaID_GetActiveTimeToAXfromPioModeInBX:
	shl		bx, 1
	mov		ax, [cs:bx+.rgwPioModeToActiveTimeNs]
	shr		bx, 1
	ret

.rgwPioModeToActiveTimeNs:
	dw		PIO_0_MIN_ACTIVE_TIME_NS
	dw		PIO_1_MIN_ACTIVE_TIME_NS
	dw		PIO_2_MIN_ACTIVE_TIME_NS
	dw		PIO_3_MIN_ACTIVE_TIME_NS
	dw		PIO_4_MIN_ACTIVE_TIME_NS
	dw		PIO_5_MIN_ACTIVE_TIME_NS
	dw		PIO_6_MIN_ACTIVE_TIME_NS

%endif ; MODULE_ADVANCED_ATA
