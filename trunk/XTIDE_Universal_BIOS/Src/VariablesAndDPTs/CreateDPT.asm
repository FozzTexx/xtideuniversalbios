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
	call	FindDPT_ForNewDrive		; Get new DPT to DS:DI
	; Fall to .InitializeDPT

;--------------------------------------------------------------------
; .InitializeDPT
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		AX:		Zero
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.InitializeDPT:
	xor		ax, ax
	mov		BYTE [di+DPT.bSize], DPT_size
	mov		[di+DPT.wDrvNumAndFlags], ax
	mov		BYTE [di+DPT.bReset], MASK_RESET_ALL
	mov		[di+DPT.bIdeOff], bp
	mov		[di+DPT.bDrvSel], bh
	; Fall to .StoreDriveControlByte

;--------------------------------------------------------------------
; .StoreDriveControlByte
;	Parameters:
;		AX:		Zero
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.StoreDriveControlByte:
	cmp		BYTE [cs:bp+IDEVARS.bIRQ], al	; Interrupts enabled?
	jne		SHORT .CheckHeadCount
	or		al, FLG_IDE_CTRL_nIEN			; Disable interrupts
.CheckHeadCount:
	cmp		BYTE [es:si+ATA1.wHeadCnt], 8	; 1...8 heads?
	jbe		SHORT .StoreDrvCtrlByteToDPT
	or		al, FLG_IDE_CTRL_O8H			; Over 8 heads (pre-ATA)
.StoreDrvCtrlByteToDPT:
	mov		[di+DPT.bDrvCtrl], al
	; Fall to .StorePCHS

;--------------------------------------------------------------------
; .StorePCHS
;	Parameters:
;		AH:		Zero
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
	or		BYTE [di+DPT.bFlags], FLG_DPT_USERCHS

.StorePCHStoDPT:
	mov		[di+DPT.wPCyls], ax
	mov		[di+DPT.wHeadsAndSectors], bx
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

.LimitHeadsTo255:
	test	bh, bh						; 256 heads?
	jz		SHORT .StoreLCHStoDPT		;  If less, no correction needed
	dec		bx							; Limit to 255 heads since DOS does not support 256 heads
.StoreLCHStoDPT:
	mov		[di+DPT.bShLtoP], cl
	mov		[di+DPT.wLHeads], bx
	; Fall to .StoreAddressing

;--------------------------------------------------------------------
; .StoreAddressing
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StoreAddressing:
	cmp		WORD [di+DPT.wPCyls], 1024		; L-CHS possible? (no translation needed)
	jbe		SHORT .StoreBlockMode			;  If so, nothing needs to be changed
	test	BYTE [di+DPT.bFlags], FLG_DPT_USERCHS
	jnz		SHORT .StorePCHSaddressing		; Use user defined P-CHS
	test	WORD [es:si+ATA1.wCaps], A2_wCaps_LBA
	jz		SHORT .StorePCHSaddressing		; Use P-CHS since LBA not supported
	test	WORD [es:si+ATA6.wSetSup83], A6_wSetSup83_LBA48
	jz		SHORT .StoreLBA28addressing		; Use LBA-28 since LBA-48 not supported
	or		BYTE [di+DPT.bFlags], ADDR_DPT_LBA48<<1
.StoreLBA28addressing:
	or		BYTE [di+DPT.bFlags], ADDR_DPT_LBA28<<1
	or		BYTE [di+DPT.bDrvSel], FLG_IDE_DRVHD_LBA
	jmp		SHORT .StoreBlockMode
.StorePCHSaddressing:
	or		BYTE [di+DPT.bFlags], ADDR_DPT_PCHS<<1
	; Fall to .StoreBlockMode

;--------------------------------------------------------------------
; .StoreBlockMode
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.StoreBlockMode:
	mov		al, 1						; Minimum block size is 1 sector
	mov		ah, [es:si+ATA1.bBlckSize]	; Load max block size in sectors
	mov		[di+DPT.wSetAndMaxBlock], ax
	; Fall to .StoreEBIOSSupport

;--------------------------------------------------------------------
; .StoreEBIOSSupport
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
.StoreEBIOSSupport:
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .StoreDriveNumberAndUpdateDriveCount	; No EBIOS support since small DPTs needed

	mov		bl, [di+DPT.bFlags]
	and		bx, BYTE MASK_DPT_ADDR						; Addressing mode
	jmp		[cs:bx+.rgwAddrJmp]							; Jump to handle addressing mode
.rgwAddrJmp:
	dw		.StoreDriveNumberAndUpdateDriveCount		; ADDR_DPT_LCHS
	dw		.StoreDriveNumberAndUpdateDriveCount		; ADDR_DPT_PCHS
	dw		.SupportForLBA28							; ADDR_DPT_LBA28
	dw		.SupportForLBA48							; ADDR_DPT_LBA48

.SupportForLBA28:
	sub		BYTE [di+DPT.bSize], 2		; Only 4 bytes for sector count
.SupportForLBA48:
	add		BYTE [di+DPT.bSize], EBDPT_size - DPT_size
	or		BYTE [di+DPT.bFlags], FLG_DPT_EBIOS
	call	AtaID_GetTotalSectorCount
	mov		[di+EBDPT.twCapacity], ax
	mov		[di+EBDPT.twCapacity+2], dx
	mov		[di+EBDPT.twCapacity+4], bx
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
	; Make sure that more drives can be accepted
	mov		dl, [es:BDA.bHDCount]	; Load number of hard disks
	test	dl, dl					; Hard disks at maximum?
	stc								; Assume error
	js		SHORT .TooManyDrives	;  If so, return

	; Store drive number to DPT
	or		dl, 80h					; Set bit 7 since hard disk
	mov		[di+DPT.bDrvNum], dl	; Store drive number

	; Update BDA and RAMVARS
	inc		BYTE [es:BDA.bHDCount]	; Increment drive count to BDA
	call	RamVars_IncrementHardDiskCount
	clc
.TooManyDrives:
	ret
