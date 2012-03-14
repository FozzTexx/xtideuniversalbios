; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for creating Disk Parameter Table.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Creates new Disk Parameter Table for detected hard disk.
; Drive is then fully accessible using any BIOS function.
;
; CreateDPT_FromAtaInformation
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;		DS:		RAMVARS segment
;		ES:		BDA Segment
;	Returns:
;		DL:		Drive number for new drive
;		DS:DI:	Ptr to Disk Parameter Table (if successful)
;		CF:		Cleared if DPT created successfully
;				Set if any error
;	Corrupts registers:
;		AX, BX, CX, DH
;--------------------------------------------------------------------
CreateDPT_FromAtaInformation:
	call	FindDPT_ForNewDriveToDSDI
	; Fall to .InitializeDPT

;--------------------------------------------------------------------
; .InitializeDPT
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.InitializeDPT:
	mov		[di+DPT.bIdevarsOffset], bp	; IDEVARS must start in first 256 bytes of ROM
	; Fall to .StoreDriveSelectAndDriveControlByte

;--------------------------------------------------------------------
; .StoreDriveSelectAndDriveControlByte
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.StoreDriveSelectAndDriveControlByte:
	mov		al, bh
	and		ax, BYTE FLG_DRVNHEAD_DRV		; AL now has Master/Slave bit
	cmp		[cs:bp+IDEVARS.bIRQ], ah		; Interrupts enabled?
	jz		SHORT .StoreFlags				;  If not, do not set interrupt flag
	or		al, FLGL_DPT_ENABLE_IRQ
.StoreFlags:
	mov		[di+DPT.wFlags], ax
	; Fall to .StoreAddressing

;--------------------------------------------------------------------
; .StoreAddressing
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
.StoreAddressing:
	; Check if CHS defined in ROMVARS
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	test	byte [cs:bx+DRVPARAMS.wFlags], FLG_DRVPARAMS_USERCHS    ; User specified CHS?
	jnz		SHORT .StoreUserDefinedPCHS

	; Check if LBA supported
	call	AtaID_GetPCHStoAXBLBHfromAtaInfoInESSI
	test	BYTE [es:si+ATA1.wCaps+1], A1_wCaps_LBA>>8
	jz		SHORT .StoreCHSfromAXBHBL		; Small old drive with CHS addressing only

	; Store LBA 28/48 addressing and total sector count
	call	AtaID_GetTotalSectorCountToBXDXAXfromAtaInfoInESSI
	call	StoreLbaAddressingAndTotalSectorCountFromBXDXAX

	; Replace sector count with user defined if necessary
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	test	BYTE [cs:bx+DRVPARAMS.wFlags], FLG_DRVPARAMS_USERLBA
	jz		SHORT .KeepTotalSectorsFromAtaID
	mov		ax, [cs:bx+DRVPARAMS.dwMaximumLBA]
	mov		dx, [cs:bx+DRVPARAMS.dwMaximumLBA+2]
	xor		bx, bx

	; Compare user defined and ATA-ID sector count and select smaller
	cmp		bx, [di+DPT.twLbaSectors+4]
	jb		SHORT .StoreUserDefinedSectorCountToDPT
	cmp		dx, [di+DPT.twLbaSectors+2]
	jb		SHORT .StoreUserDefinedSectorCountToDPT
	ja		SHORT .KeepTotalSectorsFromAtaID
	cmp		ax, [di+DPT.twLbaSectors]
	jae		SHORT .KeepTotalSectorsFromAtaID
.StoreUserDefinedSectorCountToDPT:
	call	StoreLbaAddressingAndTotalSectorCountFromBXDXAX

	; Calculate L-CHS for old INT 13h
.KeepTotalSectorsFromAtaID:
	mov		bx, [di+DPT.twLbaSectors+4]		; Restore BX
	call	AccessDPT_ConvertSectorCountFromBXDXAXtoLbaAssistedCHSinDXAXBLBH
	mov		[di+DPT.bLbaHeads], bl
	jmp		SHORT .StoreBlockMode

;--------------------------------------------------------------------
; .StoreUserDefinedPCHS
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		AX:		Number of P-CHS cylinders
;		BH:		Number of P-CHS sectors per track
;		BL:		Number of P-CHS heads
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StoreUserDefinedPCHS:
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	mov		ax, [cs:bx+DRVPARAMS.wCylinders]
	mov		bx, [cs:bx+DRVPARAMS.wHeadsAndSectors]
	; Fall to .StoreCHSfromAXBHBL

;--------------------------------------------------------------------
; .StoreCHSfromAXBHBL
;	Parameters:
;		AX:		Number of P-CHS cylinders
;		BH:		Number of P-CHS sectors per track
;		BL:		Number of P-CHS heads
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		AX:		Number of P-CHS cylinders
;		BH:		Number of P-CHS sectors per track
;		BL:		Number of P-CHS heads
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
.StoreCHSfromAXBHBL:
	push	ax
	push	bx
	call	AccessDPT_ShiftPCHinAXBLtoLCH	; Get number of bits to shift
	pop		bx
	pop		ax
	jcxz	.StorePCHSfromAXDX				; Small drive so use L-CHS addressing

	; Store P-CHS addressing mode and number of bits to shift in L-CHS to P-CHS translation
	or		cl, ADDRESSING_MODE_PCHS<<ADDRESSING_MODE_FIELD_POSITION
	or		[di+DPT.bFlagsLow], cl
	; Fall to .StoreChsFromAXBLBH

;--------------------------------------------------------------------
; .StoreChsFromAXBLBH
;	Parameters:
;		AX:		Number of P-CHS cylinders
;		BH:		Number of P-CHS sectors per track
;		BL:		Number of P-CHS heads
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StorePCHSfromAXDX:
	mov		[di+DPT.wPchsCylinders], ax
	mov		[di+DPT.wPchsHeadsAndSectors], bx
	; Fall to .StoreBlockMode

;--------------------------------------------------------------------
; .StoreBlockMode
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StoreBlockMode:
	cmp		BYTE [es:si+ATA1.bBlckSize], 1	; Max block size in sectors
	jbe		SHORT .BlockModeTransfersNotSupported
	or		BYTE [di+DPT.bFlagsHigh], FLGH_DPT_BLOCK_MODE_SUPPORTED
.BlockModeTransfersNotSupported:
	; Fall to .StoreDeviceSpecificParameters

;--------------------------------------------------------------------
; .StoreDeviceSpecificParameters
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
.StoreDeviceSpecificParameters:
	call	Device_FinalizeDPT

;----------------------------------------------------------------------
; Update drive counts (hard and floppy)
;----------------------------------------------------------------------

%ifdef MODULE_SERIAL_FLOPPY
;
; These two instructions serve two purposes:
; 1. If the drive is a floppy drive (CF set), then we effectively increment the counter.
; 2. If this is a hard disk, and there have been any floppy drives previously added, then the hard disk is
;    effectively discarded.  This is more of a safety check then code that should ever normally be hit (see below).
;    Since the floppy DPT's come after the hard disk DPT's, without expensive (code size) code to relocate a DPT,
;    this was necessary.  Now, this situation shouldn't happen in normal operation, for a couple of reasons:
; 		A. xtidecfg always puts configured serial ports at the end of the IDEVARS list
;       B. the auto serial code is always executed last
;       C. the serial server always returns floppy drives last
;
	adc		byte [RAMVARS.xlateVars+XLATEVARS.bFlopCreateCnt], 0
	jnz		.AllDone
%else
;
; Even without floppy support enabled, we shouldn't try to mount a floppy image as a hard disk, which
; could lead to unpredictable results since no MBR will be present, etc.  The server doesn't know that
; floppies are supported, so it is important to still fail here if a floppy is seen during the drive scan.
;
	jc		.AllDone
%endif

	inc		BYTE [RAMVARS.bDrvCnt]		; Increment drive count to RAMVARS

.AllDone:
	clc
	ret


;--------------------------------------------------------------------
; StoreLbaAddressingAndTotalSectorCountFromBXDXAX
;	Parameters:
;		BX:DX:AX:	Total Sector Count
;		DS:DI:		Ptr to Disk Parameter Table
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
StoreLbaAddressingAndTotalSectorCountFromBXDXAX:
	mov		[di+DPT.twLbaSectors], ax
	mov		[di+DPT.twLbaSectors+2], dx
	mov		[di+DPT.twLbaSectors+4], bx

	and		BYTE [di+DPT.bFlagsLow], ~MASKL_DPT_ADDRESSING_MODE
	test	bx, bx
	jnz		SHORT .SetLba48AddressingToDPT	; Must be LBA48

	; Drives can report at most 0FFF FFFFh LBA28 sectors according to ATA specification.
	; That is (2^28)-1 so we can simply check if DH is zero or not.
	test	dh, dh
	jz		SHORT .SetLba28AddressingToDPT
.SetLba48AddressingToDPT:
	or		BYTE [di+DPT.bFlagsLow], ADDRESSING_MODE_LBA48<<ADDRESSING_MODE_FIELD_POSITION
.SetLba28AddressingToDPT:
	or		BYTE [di+DPT.bFlagsLow], ADDRESSING_MODE_LBA28<<ADDRESSING_MODE_FIELD_POSITION
	ret
