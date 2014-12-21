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
;		DS:DI:	Ptr to Disk Parameter Table
;		CF:		Cleared
;	Corrupts registers:
;		AX, BX, CX, DX
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
	; Apply any user limited values to ATA ID
	call	AtaID_ModifyESSIforUserDefinedLimitsAndReturnTranslateModeInDX

	; Translate P-CHS to L-CHS
	call	AtaGeometry_GetLCHStoAXBLBHfromAtaInfoInESSIwithTranslateModeInDX
	mov		[di+DPT.wLchsCylinders], ax
	mov		[di+DPT.wLchsHeadsAndSectors], bx
	mov		al, dl
	eSHL_IM	al, TRANSLATEMODE_FIELD_POSITION
	or		cl, al

	; Store P-CHS and flags
	call	AtaGeometry_GetPCHStoAXBLBHfromAtaInfoInESSI
	dec		dl						; Set ZF if TRANSLATEMODE_LARGE, SF if TRANSLATEMODE_NORMAL
	jle		SHORT .JumpOverSetBitForAssistedLBA

	; Set LBA bit for Assisted LBA
	or		cl, FLGL_DPT_LBA
.JumpOverSetBitForAssistedLBA:
	jnz		SHORT .NothingToChange

	; We cannot have 16 P-Heads heads in Revised ECHS mode (8193 or more cylinders)
	; but 16 heads are allowed when there are 8192 or less cylinders (ECHS).
	; Both of these are LARGE modes so do not confuse with NORMAL mode.
	call	AtaGeometry_IsDriveSmallEnoughForECHS
	adc		bx, -1					; Adjust 16 P-Heads to 15 if needed

.NothingToChange:
	or		[di+DPT.bFlagsLow], cl	; Shift count and addressing mode
	mov		[di+DPT.wPchsHeadsAndSectors], bx
%ifdef MODULE_COMPATIBLE_TABLES OR MODULE_EBIOS
	; Store P-Cylinders here for Compatible DPTs when FLGL_DPT_LBA is not set
	; or when drive has over 15,482,880 sectors
	mov		[di+DPT.wPchsCylinders], ax
%endif

%ifdef MODULE_EBIOS
	test	cl, FLGL_DPT_LBA
	jz		SHORT .NoLbaSoNoEBIOS

	; Store P-Cylinders but only if we have 15,482,880 or less sectors since
	; we only need P-Cylinders so we can return it from AH=48h
	call	AtaGeometry_GetLbaSectorCountToBXDXAXfromAtaInfoInESSI
	sub		ax, (MAX_SECTOR_COUNT_TO_RETURN_PCHS+1) & 0FFFFh
	sbb		dx, (MAX_SECTOR_COUNT_TO_RETURN_PCHS+1) >> 16
	sbb		bx, BYTE 0
	jnc		SHORT .StoreNumberOfLbaSectors

	; Since we might have altered the default P-CHS parameters to be
	; presented to the drive (AH=09h), we need to calculate new
	; P-Cylinders. It could be read from the ATA ID after
	; COMMAND_INITIALIZE_DEVICE_PARAMETERS but that is too much trouble.
	; P-Cyls = MIN(16383*16*63, LBA sector count) / (P-Heads * P-Sectors per track)
	call	AtaGeometry_GetLbaSectorCountToBXDXAXfromAtaInfoInESSI
	xchg	cx, ax							; Sector count to DX:CX
	mov		al, [di+DPT.bPchsHeads]
	mul		BYTE [di+DPT.bPchsSectorsPerTrack]
	xchg	cx, ax
	div		cx								; AX = new P-Cylinders

	; We could remove wPchsCylinders from DPT if we calculate it on AH=48h
	; (and for compatible DPTs) but that would require extra code so we save ROM space instead.
	mov		[di+DPT.wPchsCylinders], ax

	; Store CHS sector count as total sector count. We must not use
	; LBA sector count if it is 15,482,880 or less.
	mul		cx
	xor		bx, bx
	jmp		SHORT .StoreTotalSectorsFromBXDXAX


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
.StoreNumberOfLbaSectors:
	; Store LBA 28/48 total sector count
	call	AtaGeometry_GetLbaSectorCountToBXDXAXfromAtaInfoInESSI
	or		[di+DPT.bFlagsLow], cl		; LBA48 flag
.StoreTotalSectorsFromBXDXAX:
	mov		[di+DPT.twLbaSectors], ax
	mov		[di+DPT.twLbaSectors+2], dx
	mov		[di+DPT.twLbaSectors+4], bx
.NoLbaSoNoEBIOS:
%endif ; MODULE_EBIOS
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
%ifdef MODULE_SERIAL
; Device_FinalizeDPT returns with CF set only when a floppy was found which can't happen without MODULE_SERIAL
%ifdef MODULE_SERIAL_FLOPPY
;
; These two instructions serve two purposes:
; 1. If the drive is a floppy drive (CF set), then we effectively increment the counter.
; 2. If this is a hard disk, and there have been any floppy drives previously added, then the hard disk is
;    effectively discarded.  This is more of a safety check then code that should ever normally be hit (see below).
;    Since the floppy DPT's come after the hard disk DPT's, without expensive (code size) code to relocate a DPT,
;    this was necessary.  Now, this situation shouldn't happen in normal operation, for a couple of reasons:
;		A. xtidecfg always puts configured serial ports at the end of the IDEVARS list
;		B. the auto serial code is always executed last
;		C. the serial server always returns floppy drives last
;
	adc		byte [RAMVARS.xlateVars+XLATEVARS.bFlopCreateCnt], 0
	jnz		.AllDone
%else ; ~MODULE_SERIAL_FLOPPY
;
; Even without floppy support enabled, we shouldn't try to mount a floppy image as a hard disk, which
; could lead to unpredictable results since no MBR will be present, etc.  The server doesn't know that
; floppies are supported, so it is important to still fail here if a floppy is seen during the drive scan.
;
	jc		.AllDone
%endif ; MODULE_SERIAL_FLOPPY
%endif ; MODULE_SERIAL

	inc		BYTE [RAMVARS.bDrvCnt]		; Increment drive count to RAMVARS

%ifdef MODULE_SERIAL
.AllDone:
	clc
%endif

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
	mov		ax, [cs:bp+IDEVARS.wBasePort]
	mov		[di+DPT.wBasePort], ax
	ret
