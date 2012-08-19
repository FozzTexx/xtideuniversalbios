; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessing ATA information read with
;					IDENTIFY DEVICE command.

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
; AtaID_VerifyFromESSI
;	Parameters:
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		CF:		Set if failed to verify ATA-ID
;				Cleared if ATA-ID verified succesfully
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
AtaID_VerifyFromESSI:
	; We cannot start by reading ATA version since the ID might be
	; corrupted. We start by making sure P-CHS values are valid.
	; If they are, we assume the ATA ID to be valid. Fortunately we can do
	; futher checking for ATA-5 and later since they contain signature and
	; checksum bytes. Those are not available for ATA-4 and older.

	; Verify P-CHS cylinders
	mov		bx, ATA1.wCylCnt
	mov		cx, MAX_VALID_PCHS_CYLINDERS
	call	.CompareCHorSfromOffsetBXtoMaxValueInCX

	add		bx, BYTE ATA1.wHeadCnt - ATA1.wCylCnt
	mov		cl, MAX_VALID_PCHS_HEADS
	call	.CompareCHorSfromOffsetBXtoMaxValueInCX

	add		bx, BYTE ATA1.wSPT - ATA1.wHeadCnt
	mov		cl, MAX_VALID_PCHS_SECTORS_PER_TRACK
	call	.CompareCHorSfromOffsetBXtoMaxValueInCX

	; We now verified P-CHS parameters so we assume ATA ID to be valid
	; for ATA-4 and older. For ATA-5 and later we check signature
	; and checksum.
	mov		ax, [es:si+ATA6.wMajorVer]			; ATA-3 and later have this word
	inc		ax
	jz		SHORT .AtaIDverifiedSuccessfully	; FFFFh means no version info available
	dec		ax
	jz		SHORT .AtaIDverifiedSuccessfully	; Zero means no version info available
	cmp		ax, A6_wMajorVer_ATA5
	jb		SHORT .AtaIDverifiedSuccessfully	; ATA-3 and ATA-4 do not have checksum

	; Check signature byte
	cmp		BYTE [es:si+ATA6.bSignature], A6_wIntegrity_SIGNATURE
	jne		SHORT .FailedToVerifyAtaID

	; Check checksum byte
	mov		cx, ATA6_size
	call	Memory_SumCXbytesFromESSItoAL
	test	al, al
	jnz		SHORT .FailedToVerifyAtaID

	; ATA-ID is now verified to be valid
.AtaIDverifiedSuccessfully:
	clc
	ret

;--------------------------------------------------------------------
; .CompareCHorSfromOffsetBXtoMaxValueInCX
;	Parameters:
;		BX:		C, H or S offset to ATA-ID
;		CX:		Maximum valid C, H or S value
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Exits from AtaID_VerifyFromESSI with CF set if invalid value
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.CompareCHorSfromOffsetBXtoMaxValueInCX:
	mov		ax, [es:bx+si]
	test	ax, ax
	jz		SHORT .InvalidPCHorSinOffsetBX
	cmp		ax, cx			; Compare to max valid value
	jbe		SHORT .ValidPCHorSinOffsetBX
.InvalidPCHorSinOffsetBX:
	add		sp, 2			; Clear return address for this function
.FailedToVerifyAtaID:
	stc						; Set carry to indicate invalid ATA-ID
.ValidPCHorSinOffsetBX:
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
	mov		ax, bx					; AH = 0, AL = PIO mode 0, 1 or 2
	shl		bx, 1					; Shift for WORD lookup
	mov		cx, [cs:bx+.rgwPio0to2CycleTimeInNanosecs]

	; Check if IORDY is supported
	test	BYTE [es:si+ATA2.wCaps+1], A2_wCaps_IORDY >> 8
	jz		SHORT .ReturnPioTimings	; No PIO 3 or higher if no IORDY
	mov		ah, FLGH_DPT_IORDY

	; Check if Advanced PIO modes are supported (3 and above)
	test	BYTE [es:si+ATA2.wFields], A2_wFields_64to70
	jz		SHORT .ReturnPioTimings

	; Get Advanced PIO mode
	; (Hard Disks supports up to 4 but CF cards can support 5 and 6)
	mov		bl, [es:si+ATA2.bPIOSupp]
.CheckNextFlag:
	inc		ax
	shr		bl, 1
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
