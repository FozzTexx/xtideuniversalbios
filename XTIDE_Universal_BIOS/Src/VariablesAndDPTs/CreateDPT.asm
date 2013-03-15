; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for creating Disk Parameter Table.

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
; Creates new Disk Parameter Table for detected hard disk.
; Drive is then fully accessible using any BIOS function.
;
; CreateDPT_FromAtaInformation
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DX:		Autodetected port (for devices that support autodetection)
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;		DS:		RAMVARS segment
;		ES:		BDA Segment
;	Returns:
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
;		DX:		Autodetected port (for devices that support autodetection)
;		DS:DI:	Ptr to Disk Parameter Table
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.InitializeDPT:
	call	CreateDPT_StoreIdevarsOffsetAndBasePortFromCSBPtoDPTinDSDI
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
%ifdef MODULE_IRQ
	cmp		[cs:bp+IDEVARS.bIRQ], ah		; Interrupts enabled?
	jz		SHORT .StoreFlags				;  If not, do not set interrupt flag
	or		al, FLGL_DPT_ENABLE_IRQ
.StoreFlags:
%endif
	mov		[di+DPT.wFlags], ax
	; Fall to .StoreCHSparametersAndAddressingMode

;--------------------------------------------------------------------
; .StoreCHSparametersAndAddressingMode
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
.StoreCHSparametersAndAddressingMode:
	; Check if CHS defined in ROMVARS
	call	GetUserDefinedCapacityToBXAXandFlagsToCXandModeToDXfromROMVARS
	test	cl, FLG_DRVPARAMS_USERCHS
	jz		SHORT .AutodetectPCHSvalues

	; Translate P-CHS to L-CHS
	call	AtaGeometry_GetLCHStoAXBLBHfromPCHSinAXBLBHandTranslateModeInDX
	jmp		SHORT .StoreLCHStoDPT
.AutodetectPCHSvalues:
	call	AtaGeometry_GetLCHStoAXBLBHfromAtaInfoInESSIandTranslateModeInDX

.StoreLCHStoDPT:
	eSHL_IM	dl, TRANSLATEMODE_FIELD_POSITION
	or		cl, dl
	or		[di+DPT.bFlagsLow], cl		; Shift count and addressing mode
	mov		[di+DPT.wLchsCylinders], ax
	mov		[di+DPT.wLchsHeadsAndSectors], bx

	; Store P-CHS to DPT
	call	AtaGeometry_GetPCHStoAXBLBHfromAtaInfoInESSI
	mov		[di+DPT.bPchsHeads], bl
%ifdef MODULE_EBIOS
	mov		[di+DPT.wPchsCylinders], ax
	mov		[di+DPT.bPchsSectorsPerTrack], bh
	; Fall to .StoreNumberOfLbaSectors

;--------------------------------------------------------------------
; .StoreNumberOfLbaSectors
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
	; Check if LBA supported
	test	BYTE [es:si+ATA1.wCaps+1], A1_wCaps_LBA>>8
	jz		SHORT .NoLbaSupportedSoNoEBIOS

	; Store LBA 28/48 total sector count
	call	AtaGeometry_GetLbaSectorCountToBXDXAXfromAtaInfoInESSI
	call	StoreLba48AddressingFromCLandTotalSectorCountFromBXDXAX

	; Load user defined LBA
	call	GetUserDefinedCapacityToBXAXandFlagsToCXandModeToDXfromROMVARS
	test	cl, FLG_DRVPARAMS_USERLBA
	jz		SHORT .KeepTotalSectorsFromAtaID

	; Compare user defined and ATA-ID sector count and select smaller
	mov		dx, bx
	xor		bx, bx		; User defined LBA now in BX:DX:AX
	cmp		bx, [di+DPT.twLbaSectors+4]
	jb		SHORT .StoreUserDefinedSectorCountToDPT
	cmp		dx, [di+DPT.twLbaSectors+2]
	jb		SHORT .StoreUserDefinedSectorCountToDPT
	ja		SHORT .KeepTotalSectorsFromAtaID
	cmp		ax, [di+DPT.twLbaSectors]
	jae		SHORT .KeepTotalSectorsFromAtaID
.StoreUserDefinedSectorCountToDPT:
	; CL bit FLGL_DPT_LBA48 is clear at this point
	call	StoreLba48AddressingFromCLandTotalSectorCountFromBXDXAX

.KeepTotalSectorsFromAtaID:
.NoLbaSupportedSoNoEBIOS:
%endif ; MODULE_EBIOS
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
; CreateDPT_StoreIdevarsOffsetAndBasePortFromCSBPtoDPTinDSDI
;	Parameters:
;		DX:		Autodetected port (for devices that support autodetection)
;		DS:DI:	Ptr to Disk Parameter Table
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
CreateDPT_StoreIdevarsOffsetAndBasePortFromCSBPtoDPTinDSDI:
	mov		[di+DPT.bIdevarsOffset], bp		; IDEVARS must start in first 256 bytes of ROM

%ifdef MODULE_8BIT_IDE_ADVANCED
	call	DetectDrives_DoesIdevarsInCSBPbelongToXTCF
	jne		SHORT .DeviceUsesPortSpecifiedInIDEVARS
	mov		[di+DPT.wBasePort], dx
	ret
.DeviceUsesPortSpecifiedInIDEVARS:
%endif ; MODULE_8BIT_IDE_ADVANCED

	mov		ax, [cs:bp+IDEVARS.wBasePort]
	mov		[di+DPT.wBasePort], ax
	ret


;--------------------------------------------------------------------
; GetUserDefinedCapacityToBXAXandFlagsToCXandModeToDXfromROMVARS
;	Parameters:
;		DS:DI:		Ptr to Disk Parameter Table
;	Returns:
;		AX:			User defined P-CHS Cylinders or LBA low word
;		BX:			User defined P-CHS Heads and Sectors or LBA high word
;		DX:			Translate mode or TRANSLATEMODE_AUTO
;		CX:			FLG_DRVPARAMS_USERCHS if user defined CHS in BX:AX
;					FLG_DRVPARAMS_USERLBA if user defined LBA in BX:AX
;					Zero if user has not defined capacity
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
GetUserDefinedCapacityToBXAXandFlagsToCXandModeToDXfromROMVARS:
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX

	; Get settings
	mov		cx, [cs:bx+DRVPARAMS.wFlags]
	mov		dx, cx
	and		cx, BYTE FLG_DRVPARAMS_USERCHS | FLG_DRVPARAMS_USERLBA
	and		dx, BYTE MASK_DRVPARAMS_TRANSLATEMODE
	eSHR_IM	dx, TRANSLATEMODE_FIELD_POSITION

	; Get capacity
	mov		ax, [cs:bx+DRVPARAMS.wCylinders]		; Or .dwMaximumLBA
	mov		bx, [cs:bx+DRVPARAMS.wHeadsAndSectors]	; Or .dwMaximumLBA+2
	ret


%ifdef MODULE_EBIOS
;--------------------------------------------------------------------
; StoreLba48AddressingFromCLandTotalSectorCountFromBXDXAX
;	Parameters:
;		BX:DX:AX:	Total Sector Count
;		CL:			FLGL_DPT_LBA48 if LBA48 supported
;		DS:DI:		Ptr to Disk Parameter Table
;	Returns:
;		Nothing
;	Corrupts registers:
;		CL
;--------------------------------------------------------------------
StoreLba48AddressingFromCLandTotalSectorCountFromBXDXAX:
	or		cl, FLGL_DPT_LBA_AND_EBIOS_SUPPORTED
	and		BYTE [di+DPT.bFlagsLow], ~FLGL_DPT_LBA48
	or		[di+DPT.bFlagsLow], cl
	mov		[di+DPT.twLbaSectors], ax
	mov		[di+DPT.twLbaSectors+2], dx
	mov		[di+DPT.twLbaSectors+4], bx
	ret
%endif ; MODULE_EBIOS
