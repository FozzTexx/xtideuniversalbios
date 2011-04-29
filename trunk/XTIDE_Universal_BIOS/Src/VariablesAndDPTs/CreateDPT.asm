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
;		DS:DI:	Ptr to Disk Parameter Table (if succesfull)
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
	or		al, FLG_DPT_ENABLE_IRQ
.StoreFlags:
	mov		[di+DPT.wFlags], ax
	; Fall to .StorePCHS

;--------------------------------------------------------------------
; .StorePCHS
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		AX:		P-CHS cylinders
;		BL:		P-CHS heads
;		BH:		P-CHS sectors
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StorePCHS:
	mov		al, FLG_DRVPARAMS_USERCHS	; User specified CHS?
	call	AccessDPT_TestIdeVarsFlagsForMasterOrSlaveDrive
	jnz		SHORT .GetUserSpecifiedPCHS
	call	AtaID_GetPCHS				; Get from ATA information
	jmp		SHORT .StorePCHStoDPT

.GetUserSpecifiedPCHS:
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	mov		ax, [cs:bx+DRVPARAMS.wCylinders]
	mov		bx, [cs:bx+DRVPARAMS.wHeadsAndSectors]

.StorePCHStoDPT:
	mov		[di+DPT.wPchsCylinders], ax
	mov		[di+DPT.wPchsHeadsAndSectors], bx
	; Fall to .StoreLCHS

;--------------------------------------------------------------------
; .StoreLCHS
;	Parameters:
;		AX:		P-CHS cylinders
;		BL:		P-CHS heads
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
.StoreLCHS:
	xor		bh, bh						; BX = P-CHS Heads (1...16)
	xor		cx, cx
.ShiftLoop:
	cmp		ax, 1024					; Need to shift?
	jbe		SHORT .LimitHeadsTo255		;  If not, return
	inc		cx							; Increment shift count
	shr		ax, 1						; Halve cylinders
	shl		bx, 1						; Double heads
	jmp		SHORT .ShiftLoop

.LimitHeadsTo255:						; DOS does not support drives with 256 heads
	rcr		bh, 1						; Set CF if 256 heads
	sbb		bl, 0						; Decrement to 255 if 256 heads
	or		[di+DPT.wFlags], cl
	mov		[di+DPT.bLchsHeads], bl
	; Fall to .StoreAddressing

;--------------------------------------------------------------------
; .StoreAddressing
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
.StoreAddressing:
	; Check if L-CHS addressing should be used
	cmp		WORD [di+DPT.wPchsCylinders], 1024	; L-CHS possible? (no translation needed)
	jbe		SHORT .StoreBlockMode				;  If so, nothing needs to be changed

	; Check if P-CHS addressing should be used
	mov		al, FLG_DRVPARAMS_USERCHS			; User specified CHS?
	call	AccessDPT_TestIdeVarsFlagsForMasterOrSlaveDrive
	jnz		SHORT .StorePCHSaddressing
	test	WORD [es:si+ATA1.wCaps], A2_wCaps_LBA
	jz		SHORT .StorePCHSaddressing			; Use P-CHS since LBA not supported

	; LBA needs to be used. Check if 48-bit LBA is supported
	test	WORD [es:si+ATA6.wSetSup83], A6_wSetSup83_LBA48
	jz		SHORT .StoreLBA28addressing			; Use LBA-28 since LBA-48 not supported
	or		BYTE [di+DPT.wFlags], ADDRESSING_MODE_LBA48<<ADDRESSING_MODE_FIELD_POSITION
.StoreLBA28addressing:
	or		BYTE [di+DPT.wFlags], ADDRESSING_MODE_LBA28<<ADDRESSING_MODE_FIELD_POSITION
	jmp		SHORT .StoreBlockMode
.StorePCHSaddressing:
	or		BYTE [di+DPT.wFlags], ADDRESSING_MODE_PCHS<<ADDRESSING_MODE_FIELD_POSITION
	; Fall to .StoreBlockMode

;--------------------------------------------------------------------
; .StoreBlockMode
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StoreBlockMode:
	cmp		BYTE [es:si+ATA1.bBlckSize], 1	; Max block size in sectors
	jbe		SHORT .BlockModeTransfersNotSupported
	or		WORD [di+DPT.wFlags], FLG_DPT_BLOCK_MODE_SUPPORTED
.BlockModeTransfersNotSupported:
	; Fall to .StoreDeviceSpecificParameters

;--------------------------------------------------------------------
; .StoreDeviceSpecificParameters
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
.StoreDeviceSpecificParameters:
	call	Device_FinalizeDPT
	; Fall to .StoreDriveNumberAndUpdateDriveCount

;--------------------------------------------------------------------
; .StoreDriveNumberAndUpdateDriveCount
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		ES:		BDA Segment
;	Returns:
;		DL:		Drive number for new drive
;		CF:		Cleared if DPT parameters stored successfully
;				Set if any error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StoreDriveNumberAndUpdateDriveCount:
	mov		dl, [es:BDA.bHDCount]
	or		dl, 80h						; Set bit 7 since hard disk

	inc		BYTE [RAMVARS.bDrvCnt]		; Increment drive count to RAMVARS
	inc		BYTE [es:BDA.bHDCount]		; Increment drive count to BDA

	cmp		BYTE [RAMVARS.bFirstDrv], 0	; First drive set?
	ja		SHORT .AllDone				;  If so, return
	mov		[RAMVARS.bFirstDrv], dl		; Store first drive number
.AllDone:
	clc
	ret
