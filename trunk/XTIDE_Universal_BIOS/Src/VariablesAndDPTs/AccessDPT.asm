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

%ifdef MODULE_ADVANCED_ATA
;--------------------------------------------------------------------
; AccessDPT_GetIdeBasePortToBX
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		BX:		IDE Base Port Address
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AccessDPT_GetIdeBasePortToBX:
	eMOVZX	bx, [di+DPT.bIdevarsOffset]			; CS:BX points to IDEVARS
	mov		bx, [cs:bx+IDEVARS.wPort]
	ret
%endif	; MODULE_ADVANCED_ATA


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
	mov		al, [di+DPT.wFlags]
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
	xor		al, al
	test	BYTE [di+DPT.bFlagsLow], FLGL_DPT_ENABLE_IRQ
	jnz		SHORT .EnableDeviceIrq
	or		al, FLG_DEVCONTROL_nIEN	; Disable IRQ
.EnableDeviceIrq:
%else
	mov		al, FLG_DEVCONTROL_nIEN	; Disable IRQ
%endif
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
ALIGN JUMP_ALIGN
AccessDPT_GetPointerToDRVPARAMStoCSBX:
	eMOVZX	bx, [di+DPT.bIdevarsOffset]			; CS:BX points to IDEVARS
	add		bx, BYTE IDEVARS.drvParamsMaster	; CS:BX points to Master Drive DRVPARAMS
	test	BYTE [di+DPT.bFlagsLow], FLGL_DPT_SLAVE
	jz		SHORT .ReturnPointerToDRVPARAMS
	add		bx, BYTE DRVPARAMS_size				; CS:BX points to Slave Drive DRVPARAMS
.ReturnPointerToDRVPARAMS:
	ret


;--------------------------------------------------------------------
; ACCESSDPT__GET_UNSHIFTED_ADDRESS_MODE_TO_AXZF
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AX:		Addressing Mode (ADDRESSING_MODE_NORMAL, ADDRESSING_MODE_LARGE or ADDRESSING_MODE_ASSISTED_LBA)
;               unshifted (still shifted where it is in bFlagsLow)
;       ZF:     Set based on value in AL
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
;
; Converted to a macro since only called in two places, and the call/ret overhead
; is not worth it for these two instructions (4 bytes total)
;
%macro ACCESSDPT__GET_UNSHIFTED_ADDRESS_MODE_TO_AXZF 0
	mov		al, [di+DPT.bFlagsLow]
	and		ax, BYTE MASKL_DPT_ADDRESSING_MODE
%endmacro
