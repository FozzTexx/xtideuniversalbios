; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessing DPT data.

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
; AccessDPT_GetDriveSelectByteForOldInt13hToAL
; AccessDPT_GetDriveSelectByteForEbiosToAL
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AL:		Drive Select Byte
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AccessDPT_GetDriveSelectByteForOldInt13hToAL:
	mov		al, [di+DPT.bFlagsLow]
	test	al, FLGL_DPT_ASSISTED_LBA
	jnz		SHORT GetDriveSelectByteForAssistedLBAtoAL

	and		al, FLG_DRVNHEAD_DRV	; Clear all but drive select bit
	or		al, MASK_DRVNHEAD_SET	; Bits set to 1 for old drives
	ret

%ifdef MODULE_EBIOS
ALIGN JUMP_ALIGN
AccessDPT_GetDriveSelectByteForEbiosToAL:
	mov		al, [di+DPT.bFlagsLow]
	; Fall to GetDriveSelectByteForAssistedLBAtoAL
%endif ; MODULE_EBIOS

ALIGN JUMP_ALIGN
GetDriveSelectByteForAssistedLBAtoAL:
	and		al, FLG_DRVNHEAD_DRV	; Master / Slave select
	or		al, FLG_DRVNHEAD_LBA | MASK_DRVNHEAD_SET
	ret


;--------------------------------------------------------------------
; AccessDPT_GetDeviceControlByteToAL
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AL:		Device Control Byte
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AccessDPT_GetDeviceControlByteToAL:
%ifdef MODULE_IRQ

%ifndef USE_UNDOC_INTEL
	xor		al, al
%endif

	test	BYTE [di+DPT.bFlagsLow], FLGL_DPT_ENABLE_IRQ	; Clears CF

%ifdef USE_UNDOC_INTEL
	eSALC	; Clears AL using CF while preserving flags
%endif

	jnz		SHORT .EnableDeviceIrq
	or		al, FLG_DEVCONTROL_nIEN	; Disable IRQ
.EnableDeviceIrq:
%else
	mov		al, FLG_DEVCONTROL_nIEN	; Disable IRQ
%endif ; MODULE_IRQ
	ret


;--------------------------------------------------------------------
; AccessDPT_GetLCHStoAXBLBH
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AX:		Number of L-CHS cylinders
;		BL:		Number of L-CHS heads
;		BH:		Number of L-CHS sectors per track
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AccessDPT_GetLCHStoAXBLBH:
	mov		ax, [di+DPT.wLchsCylinders]
	mov		bx, [di+DPT.wLchsHeadsAndSectors]
	ret


%ifdef MODULE_8BIT_IDE
;--------------------------------------------------------------------
; AccessDPT_IsThisDeviceXTCF
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AH:		Device Type
;		ZF:		Set if XTCF
;				Cleared if some other device
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AccessDPT_IsThisDeviceXTCF:
	mov		ah, [di+DPT_ATA.bDevice]
	cmp		ah, DEVICE_8BIT_XTCF_PIO8
	je		SHORT .DeviceIsXTCF
	cmp		ah, DEVICE_8BIT_XTCF_DMA
	je		SHORT .DeviceIsXTCF
	cmp		ah, DEVICE_8BIT_XTCF_MEMMAP
.DeviceIsXTCF:
	ret
%endif ; MODULE_8BIT_IDE


%ifdef MODULE_EBIOS
;--------------------------------------------------------------------
; AccessDPT_GetLbaSectorCountToBXDXAX
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AccessDPT_GetLbaSectorCountToBXDXAX:
	mov		ax, [di+DPT.twLbaSectors]
	mov		dx, [di+DPT.twLbaSectors+2]
	mov		bx, [di+DPT.twLbaSectors+4]
	ret
%endif ; MODULE_EBIOS


;--------------------------------------------------------------------
; Returns pointer to DRVPARAMS for master or slave drive.
;
; AccessDPT_GetPointerToDRVPARAMStoCSBX
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		CS:BX:	Ptr to DRVPARAMS
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AccessDPT_GetPointerToDRVPARAMStoCSBX:
	call	AccessDPT_GetIdevarsToCSBX
	add		bx, BYTE IDEVARS.drvParamsMaster	; CS:BX points to Master Drive DRVPARAMS
	test	BYTE [di+DPT.bFlagsLow], FLGL_DPT_SLAVE
	jz		SHORT .ReturnPointerToDRVPARAMS
	add		bx, BYTE DRVPARAMS_size				; CS:BX points to Slave Drive DRVPARAMS
.ReturnPointerToDRVPARAMS:
	ret


;--------------------------------------------------------------------
; Needed many times during initialization so it is better to
; make it as a function to save bytes.
;
; AccessDPT_GetIdevarsToCSBX
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		CS:BX:	Ptr to IDEVARS for the drive
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AccessDPT_GetIdevarsToCSBX:
	eMOVZX	bx, BYTE [di+DPT.bIdevarsOffset]
	ret


;--------------------------------------------------------------------
; ACCESSDPT__GET_UNSHIFTED_TRANSLATE_MODE_TO_AXZF
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AX:		Translate Mode (TRANSLATEMODE_NORMAL, TRANSLATEMODE_LARGE or TRANSLATEMODE_ASSISTED_LBA)
;               unshifted (still shifted where it is in bFlagsLow)
;       ZF:     Set based on value in AL
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
;
; Converted to a macro since only called in two places, and the call/ret overhead
; is not worth it for these two instructions (4 bytes total)
;
%macro ACCESSDPT__GET_UNSHIFTED_TRANSLATE_MODE_TO_AXZF 0
	mov		al, [di+DPT.bFlagsLow]
	and		ax, BYTE MASKL_DPT_TRANSLATEMODE
%endmacro
