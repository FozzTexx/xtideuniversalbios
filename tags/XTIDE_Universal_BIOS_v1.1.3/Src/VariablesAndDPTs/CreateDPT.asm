; File name		:	CreateDPT.asm
; Project name	:	IDE BIOS
; Created date	:	12.3.2010
; Last update	:	26.4.2010
; Author		:	Tomi Tilli
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
;		AX, CX, BX, DH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_FromAtaInformation:
	call	FindDPT_ForNewDrive		; Get new DPT to DS:DI
	call	CreateDPT_Initialize
	call	CreateDPT_StoreDriveControlByte
	call	CreateDPT_StorePCHS
	call	CreateDPT_StoreLCHS
	call	CreateDPT_StoreAddressing
	call	CreateDPT_StoreBlockMode
	call	CreateDPT_StoreEBIOSSupport
	jmp		CreateDPT_StoreDriveNumberAndUpdateDriveCount


;--------------------------------------------------------------------
; Initializes empty DPT by storing initial values that are not
; read from ATA information.
;
; CreateDPT_Initialize
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		CF:		Cleared if DPT parameters stored successfully
;				Set if any error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_Initialize:
	xor		ax, ax						; Clear AX and CF
	mov		BYTE [di+DPT.bSize], DPT_size
	mov		BYTE [di+DPT.bDrvNum], al
	mov		BYTE [di+DPT.bFlags], al
	mov		BYTE [di+DPT.bReset], MASK_RESET_ALL
	mov		WORD [di+DPT.bIdeOff], bp
	mov		BYTE [di+DPT.bDrvSel], bh
	ret


;--------------------------------------------------------------------
; Stores Drive Control Byte for Device Control Register.
;
; CreateDPT_StoreDriveControlByte
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		CF:		Cleared if DPT parameters stored successfully
;				Set if any error
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_StoreDriveControlByte:
	xor		ax, ax							; Zero AX
	cmp		BYTE [cs:bp+IDEVARS.bIRQ], 0	; Interrupts enabled?
	jne		SHORT .CheckHeadCount
	or		al, FLG_IDE_CTRL_nIEN			; Disable interrupts
ALIGN JUMP_ALIGN
.CheckHeadCount:
	cmp		BYTE [es:si+ATA1.wHeadCnt], 8	; 1...8 heads?
	jbe		SHORT .StoreDriveControlByte
	or		al, FLG_IDE_CTRL_O8H			; Over 8 heads (pre-ATA)
ALIGN JUMP_ALIGN
.StoreDriveControlByte:
	mov		[di+DPT.bDrvCtrl], al
	clc
	ret


;--------------------------------------------------------------------
; Stores P-CHS values from ATA information or user specified values to DPT.
;
; CreateDPT_StorePCHS
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		CF:		Cleared if DPT parameters stored successfully
;				Set if any error
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_StorePCHS:
	call	CreateDPT_GetUserOrAtaPCHS
	mov		[di+DPT.wPCyls], ax
	mov		[di+DPT.bPHeads], bh
	mov		[di+DPT.bPSect], bl
	clc
	ret

;--------------------------------------------------------------------
; Returns user specified P-CHS or values read from ATA information.
;
; CreateDPT_GetUserOrAtaPCHS
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		AX:		Number of P-CHS cylinders
;		BL:		Number of P-CHS sectors per track
;		BH:		Number of P-CHS heads
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_GetUserOrAtaPCHS:
	mov		ax, FLG_DRVPARAMS_USERCHS	; User specified CHS?
	call	AccessDPT_TestIdeVarsFlagsForMasterOrSlaveDrive
	jnz		SHORT CreateDPT_GetUserSpecifiedPCHS
	jmp		AtaID_GetPCHS

;--------------------------------------------------------------------
; Returns user specified P-CHS values from ROMVARS.
;
; CreateDPT_GetUserSpecifiedPCHS
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		AX:		Number of user specified P-CHS cylinders
;		BL:		Number of user specified P-CHS sectors per track
;		BH:		Number of user specified P-CHS heads
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_GetUserSpecifiedPCHS:
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	mov		ax, [cs:bx+DRVPARAMS.wCylinders]
	mov		bx, [cs:bx+DRVPARAMS.wSectAndHeads]
	or		BYTE [di+DPT.bFlags], FLG_DPT_USERCHS
	ret


;--------------------------------------------------------------------
; Stores L-CHS values by converting from P-CHS values if necessary.
;
; CreateDPT_StoreLCHS
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		CF:		Cleared if DPT parameters stored successfully
;				Set if any error
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_StoreLCHS:
	mov		cx, [di+DPT.wPCyls]			; P-CHS Cylinders (1...16383)
	eMOVZX	dx, BYTE [di+DPT.bPHeads]	; P-CHS Heads (1...16)
	call	CreateDPT_ShiftPCHtoLCH
	test	dh, dh						; 256 heads?
	jz		SHORT .StoreToDPT			;  If less, no correction needed
	dec		dx							; Limit to 255 heads since DOS does not support 256 heads
ALIGN JUMP_ALIGN
.StoreToDPT:
	mov		[di+DPT.bShLtoP], al
	mov		[di+DPT.wLHeads], dx
	clc
	ret

;--------------------------------------------------------------------
; Returns L-CHS values from P-CHS values.
; Sectors per track is always the same for both addressing modes.
;
; CreateDPT_ShiftPCHtoLCH:
;	Parameters:
;		CX:		Number of P-CHS cylinders (1...16383)
;		DX:		Number of P-CHS heads (1...16)
;	Returns:
;		AL:		Number of bits shifted
;		CX:		Number of L-CHS cylinders (1...1024)
;		DX:		Number of L-CHS heads (1...256)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_ShiftPCHtoLCH:
	xor		al, al				; Zero AL
ALIGN JUMP_ALIGN
.ShiftLoop:
	cmp		cx, 1024			; Need to shift?
	jbe		SHORT .Return		;  If not, return
	inc		ax					; Increment shift count
	shr		cx, 1				; Halve cylinders
	shl		dx, 1				; Double heads
	jmp		SHORT .ShiftLoop
ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; Stores addressing information (L-CHS, P-CHS, LBA28 or LBA48).
;
; CreateDPT_StoreAddressing
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		CF:		Cleared if DPT parameters stored successfully
;				Set if any error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_StoreAddressing:
	cmp		WORD [di+DPT.wPCyls], 1024		; L-CHS possible? (no translation needed)
	jbe		SHORT .Return					;  If so, nothing needs to be changed
	test	BYTE [di+DPT.bFlags], FLG_DPT_USERCHS
	jnz		SHORT .StorePCHS				; Use user defined P-CHS
	test	WORD [es:si+ATA1.wCaps], A2_wCaps_LBA
	jz		SHORT .StorePCHS				; Use P-CHS since LBA not supported
	test	WORD [es:si+ATA6.wSetSup83], A6_wSetSup83_LBA48
	jz		SHORT .StoreLBA28				; Use LBA-28 since LBA-48 not supported
	or		BYTE [di+DPT.bFlags], ADDR_DPT_LBA48<<1
ALIGN JUMP_ALIGN
.StoreLBA28:
	or		BYTE [di+DPT.bFlags], ADDR_DPT_LBA28<<1
	or		BYTE [di+DPT.bDrvSel], FLG_IDE_DRVHD_LBA
	ret
ALIGN JUMP_ALIGN
.StorePCHS:
	or		BYTE [di+DPT.bFlags], ADDR_DPT_PCHS<<1
ALIGN JUMP_ALIGN
.Return:
	clc
	ret


;--------------------------------------------------------------------
; Stores Block Mode information.
;
; CreateDPT_StoreBlockMode
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		CF:		Cleared if DPT parameters stored successfully
;				Set if any error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_StoreBlockMode:
	mov		al, 1						; Minimum block size is 1 sector
	mov		ah, [es:si+ATA1.bBlckSize]	; Load max block size in sectors
	mov		[di+DPT.wSetAndMaxBlock], ax
	ret


;--------------------------------------------------------------------
; Stores variables required by EBIOS functions.
;
; CreateDPT_StoreEBIOSSupport
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		CF:		Cleared if DPT parameters stored successfully
;				Set if any error
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CreateDPT_StoreEBIOSSupport:
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE	; (clears CF)
	jz		SHORT .DoNotSupportEBIOS	; No EBIOS support since small DPTs needed
	mov		bl, [di+DPT.bFlags]
	and		bx, BYTE MASK_DPT_ADDR		; Addressing mode (clears CF)
	jmp		[cs:bx+.rgwAddrJmp]			; Jump to handle addressing mode
ALIGN WORD_ALIGN
.rgwAddrJmp:
	dw		.DoNotSupportEBIOS			; ADDR_DPT_LCHS
	dw		.DoNotSupportEBIOS			; ADDR_DPT_PCHS
	dw		.SupportForLBA28			; ADDR_DPT_LBA28
	dw		.SupportForLBA48			; ADDR_DPT_LBA48
ALIGN JUMP_ALIGN
.DoNotSupportEBIOS:
	ret
ALIGN JUMP_ALIGN
.SupportForLBA28:
	sub		BYTE [di+DPT.bSize], 2		; Only 4 bytes for sector count
ALIGN JUMP_ALIGN
.SupportForLBA48:
	add		BYTE [di+DPT.bSize], EBDPT_size - DPT_size
	or		BYTE [di+DPT.bFlags], FLG_DPT_EBIOS
	; Fall to CreateDPT_StoreEbiosSectorCount

;--------------------------------------------------------------------
; Stores EBIOS total sector count for LBA addressing.
;
; CreateDPT_StoreEbiosSectorCount
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		CF:		Cleared if DPT parameters stored successfully
;				Set if any error
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
CreateDPT_StoreEbiosSectorCount:
	call	AtaID_GetTotalSectorCount
	mov		[di+EBDPT.twCapacity], ax
	mov		[di+EBDPT.twCapacity+2], dx
	mov		[di+EBDPT.twCapacity+4], bx
	clc
	ret


;--------------------------------------------------------------------
; Stores number for drive and updates drive count.
;
; CreateDPT_StoreDriveNumberAndUpdateDriveCount
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
ALIGN JUMP_ALIGN
CreateDPT_StoreDriveNumberAndUpdateDriveCount:
	; Make sure that more drives can be accepted
	mov		dl, [es:BDA.bHDCount]	; Load number of hard disks
	test	dl, 80h					; Hard disks at maximum?
	stc								; Assume error
	jnz		SHORT .TooManyDrives	;  If so, return

	; Store drive number to DPT
	or		dl, 80h					; Set bit 7 since hard disk
	mov		[di+DPT.bDrvNum], dl	; Store drive number

	; Update BDA and RAMVARS
	inc		BYTE [es:BDA.bHDCount]	; Increment drive count to BDA
	call	RamVars_IncrementHardDiskCount
	clc
.TooManyDrives:
	ret
