; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessing ATA information read with
;					IDENTIFY DEVICE command.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
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
;		ZF:		Set if ATA-ID verified successfully
;				Cleared if failed to verify ATA-ID
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
AtaID_VerifyFromESSI:
	; We cannot start by reading ATA version since the ID might be
	; corrupted. We start by making sure P-CHS values are valid.
	; If they are, we assume the ATA ID to be valid. Fortunately we can do
	; further checking for ATA-5 and later since they contain signature and
	; checksum bytes. Those are not available for ATA-4 and older.

	; Verify P-CHS cylinders
	mov		bx, ATA1.wCylCnt
	mov		ax, MAX_VALID_PCHS_CYLINDERS
	call	.CompareCHorSfromOffsetBXtoMaxValueInAX

	mov		bl, ATA1.wHeadCnt & 0FFh
	mov		ax, MAX_VALID_PCHS_HEADS
	call	.CompareCHorSfromOffsetBXtoMaxValueInAX

	mov		bl, ATA1.wSPT & 0FFh
	mov		al, MAX_VALID_PCHS_SECTORS_PER_TRACK
	call	.CompareCHorSfromOffsetBXtoMaxValueInAX

	; Check signature byte. It is only found on ATA-5 and later. It should be zero on
	; ATA-4 and older.
	mov		al, [es:si+ATA6.bSignature]
	test	al, al
	jz		SHORT .AtaIDverifiedSuccessfully	; Old ATA so Signature and Checksum is not available
	cmp		al, A6_wIntegrity_SIGNATURE
	jne		SHORT .FailedToVerifyAtaID

	; Check checksum byte since signature was present
	mov		cx, ATA6_size
	jmp		Memory_SumCXbytesFromESSItoAL		; Returns with ZF set according to result

;--------------------------------------------------------------------
; .CompareCHorSfromOffsetBXtoMaxValueInAX
;	Parameters:
;		AX:		Maximum valid C, H or S value
;		BX:		C, H or S offset to ATA-ID
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Exits from AtaID_VerifyFromESSI with ZF cleared if invalid value
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
.CompareCHorSfromOffsetBXtoMaxValueInAX:
	mov		cx, [es:bx+si]
	jcxz	.InvalidPCHorSinOffsetBX
	cmp		cx, ax			; Compare to max valid value
	jbe		SHORT .ValidPCHorSinOffsetBX
.InvalidPCHorSinOffsetBX:
	pop		cx				; Clear return address for this function
	inc		cx				; Clear ZF to indicate invalid ATA-ID (safe to do since return address in CX will never be FFFFh)
.AtaIDverifiedSuccessfully:
.FailedToVerifyAtaID:
.ValidPCHorSinOffsetBX:
	ret


;--------------------------------------------------------------------
; Writes user defined limits from ROMVARS to ATA ID read from the drive.
; Modifying the ATA ID reduces code and possibilities for bugs since
; only little further checks are needed elsewhere.
;
; AtaID_ModifyESSIforUserDefinedLimitsAndReturnTranslateModeInDX
;	Parameters:
;		DS:DI:	Ptr to incomplete Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		DX:		User defined P-CHS to L-CHS translate mode
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
AtaID_ModifyESSIforUserDefinedLimitsAndReturnTranslateModeInDX:
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	push	ds

	push	cs
	pop		ds

	; Load User Defined CHS or LBA to CX:AX
	mov		dx, [bx+DRVPARAMS.wFlags]
	mov		ax, [bx+DRVPARAMS.wCylinders]		; Or .dwMaximumLBA
	mov		cx, [bx+DRVPARAMS.wHeadsAndSectors]	; Or .dwMaximumLBA+2

	push	es
	pop		ds		; DS:SI now points to ATA information

	; * User defined CHS *
	test	dl, FLG_DRVPARAMS_USERCHS
	jz		SHORT .NoUserDefinedCHS

	; Apply new CHS and disable LBA (we also want to set CHS addressing)
	mov		[si+ATA1.wCylCnt], ax
	eMOVZX	ax, cl
	mov		[si+ATA1.wHeadCnt], ax
	mov		al, ch
	mov		[si+ATA1.wSPT], ax
	and		BYTE [si+ATA1.wCaps+1], ~(A1_wCaps_LBA>>8)
	and		BYTE [si+ATA6.wSetSup83+1], ~(A6_wSetSup83_LBA48>>8)
.NoUserDefinedCHS:

	; * User defined LBA *
	test	dl, FLG_DRVPARAMS_USERLBA
	jz		SHORT .NoUserDefinedLBA

	; Apply new LBA and disable LBA48
	cmp		cx, [si+ATA1.dwLBACnt+2]
	ja		SHORT .NoUserDefinedLBA		; Do not set larger than drive
	jb		SHORT .StoreNewLBA
	cmp		ax, [si+ATA1.dwLBACnt]
	ja		SHORT .NoUserDefinedLBA		; Allow same size to disable LBA48
.StoreNewLBA:
	mov		[si+ATA1.dwLBACnt], ax
	mov		[si+ATA1.dwLBACnt+2], cx
	and		BYTE [si+ATA6.wSetSup83+1], ~(A6_wSetSup83_LBA48>>8)
.NoUserDefinedLBA:

	; * Load P-CHS to L-CHS translate mode to DX *
	and		dx, BYTE MASK_DRVPARAMS_TRANSLATEMODE
	eSHR_IM	dx, TRANSLATEMODE_FIELD_POSITION

	pop		ds
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
	eSHL_IM	bx, 1					; Shift for WORD lookup
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
	eMOVZX	ax, [cs:bx+.rgbPioModeToActiveTimeNs]
	ret

.rgbPioModeToActiveTimeNs:
	db		PIO_0_MIN_ACTIVE_TIME_NS
	db		PIO_1_MIN_ACTIVE_TIME_NS
	db		PIO_2_MIN_ACTIVE_TIME_NS
	db		PIO_3_MIN_ACTIVE_TIME_NS
	db		PIO_4_MIN_ACTIVE_TIME_NS
	db		PIO_5_MIN_ACTIVE_TIME_NS
	db		PIO_6_MIN_ACTIVE_TIME_NS

%endif ; MODULE_ADVANCED_ATA
