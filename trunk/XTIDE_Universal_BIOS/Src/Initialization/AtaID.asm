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
; AtaID_GetMaxPioModeToAXandMinCycleTimeToDX
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		AX:		Max supported PIO mode
;		DX:		Minimum Cycle Time in nanosecs
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
AtaID_GetMaxPioModeToAXandMinCycleTimeToDX:
	; Get PIO mode and cycle time for PIO 0...2
	mov		bx, [es:si+ATA1.bPioMode]
	shl		bx, 1					; Shift for WORD lookup
	mov		dx, [cs:bx+.rgwPio0to2CycleTimeInNanosecs]
	shr		bx, 1
	xchg	ax, bx					; AL = PIO mode 0, 1 or 2

	; Check if Advanced PIO modes are supported (3 and above)
	test	BYTE [es:si+ATA2.wFields], A2_wFields_64to70
	jz		SHORT .ReturnPioTimings

	; Get Advanced PIO mode
	; (Hard Disks supports up to 4 but CF cards might support 5)
	mov		bx, [es:si+ATA2.bPIOSupp]
.CheckNextFlag:
	inc		ax
	shr		bx, 1
	jnz		SHORT .CheckNextFlag
	mov		dx, [es:si+ATA2.wPIOMinCyF]	; Advanced modes use IORDY
.ReturnPioTimings:
	ret


.rgwPio0to2CycleTimeInNanosecs:
	dw		PIO_0_MIN_CYCLE_TIME_NS
	dw		PIO_1_MIN_CYCLE_TIME_NS
	dw		PIO_2_MIN_CYCLE_TIME_NS


;--------------------------------------------------------------------
; AtaID_ConvertPioModeFromAXandMinCycleTimeFromDXtoActiveAndRecoveryTime
;	Parameters:
;		AX:		Max supported PIO mode
;		DX:		Minimum PIO Cycle Time in nanosecs
;	Returns:
;		CX:		Minimum Active time in nanosecs
;		DX:		Minimum Recovery time in nanosecs
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
AtaID_ConvertPioModeFromAXandMinCycleTimeFromDXtoActiveAndRecoveryTime:
	; Subtract Address Valid Time (t1) from Cycle Time (t0)
	mov		bx, ax
	eMOVZX	cx, BYTE [cs:bx+.rgbPioModeToAddressValidTimeNs]
	sub		dx, cx

	; Subtract Active Time (t2) from previous result to get Recovery Time (t2i)
	shl		bx, 1			; Shift PIO Mode for WORD lookup
	mov		cx, [cs:bx+.rgwPioModeToActiveTimeNs]
	sub		dx, cx
	ret


.rgbPioModeToAddressValidTimeNs:
	db		PIO_0_MIN_ADDRESS_VALID_NS
	db		PIO_1_MIN_ADDRESS_VALID_NS
	db		PIO_2_MIN_ADDRESS_VALID_NS
	db		PIO_3_MIN_ADDRESS_VALID_NS
	db		PIO_4_MIN_ADDRESS_VALID_NS

.rgwPioModeToActiveTimeNs:
	dw		PIO_0_MIN_ACTIVE_TIME_NS
	dw		PIO_1_MIN_ACTIVE_TIME_NS
	dw		PIO_2_MIN_ACTIVE_TIME_NS
	dw		PIO_3_MIN_ACTIVE_TIME_NS
	dw		PIO_4_MIN_ACTIVE_TIME_NS

%endif ; MODULE_ADVANCED_ATA
