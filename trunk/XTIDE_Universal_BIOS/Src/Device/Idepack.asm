; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for managing IDEPACK struct.

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
; Idepack_FakeToSSBP
;	Parameters:
;		Nothing
;	Returns:
;		SS:BP:	Ptr to IDEPACK
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
Idepack_FakeToSSBP:
	pop		ax
	sub		sp, BYTE EXTRA_BYTES_FOR_INTPACK
	mov		bp, sp
	jmp		ax


;--------------------------------------------------------------------
; Idepack_ConvertDapToIdepackAndIssueCommandFromAH
;	Parameters:
;		AH:		IDE command to issue
;		BH:		Timeout ticks
;		BL:		IDE Status Register flag to wait after command
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		ES:SI:	Ptr to DAP (EBIOS Disk Address Packet)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CX:		Number of successfully transferred sectors (for transfer commands)
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, (CX), DX, SI, ES
;--------------------------------------------------------------------
%ifdef MODULE_EBIOS
ALIGN JUMP_ALIGN
Idepack_ConvertDapToIdepackAndIssueCommandFromAH:
	mov		al, [es:si+DAP.wSectorCount]
	mov		[bp+IDEPACK.bSectorCount], al
	mov		[bp+IDEPACK.bCommand], ah

	mov		al, [es:si+DAP.qwLBA]		; LBA byte 0
	mov		[bp+IDEPACK.bLbaLow], al
	mov		ax, [es:si+DAP.qwLBA+1]		; LBA bytes 1 and 2
	mov		[bp+IDEPACK.wLbaMiddleAndHigh], ax
	mov		ah, [es:si+DAP.qwLBA+3]		; LBA byte 3, LBA28 bits 24...27
	mov		[bp+IDEPACK.bLbaLowExt], ah
	mov		cx, [es:si+DAP.qwLBA+4]		; LBA bytes 4 and 5
	mov		[bp+IDEPACK.wLbaMiddleAndHighExt], cx

	and		ah, 0Fh						; Limit bits for LBA28
	call	AccessDPT_GetDriveSelectByteToAL
	or		al, ah
	mov		[bp+IDEPACK.bDrvAndHead], al

	; Normalize data buffer pointer to ES:SI
	mov		ax, [es:si+DAP.wOffset]
	mov		cx, ax
	eSHR_IM	ax, 4								; Divide offset by 16
	add		ax, [es:si+DAP.wSegment]			; Add segment
	mov		es, ax								; Segment normalized
	mov		si, cx
	and		si, BYTE 0Fh						; Offset normalized
	jmp		SHORT GetDeviceControlByteToIdepackAndStartTransfer
%endif


;--------------------------------------------------------------------
; Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
;	Parameters:
;		AH:		IDE command to issue
;		AL:		Number of sectors to transfer (for xfer commands)
;		BH:		Timeout ticks
;		BL:		IDE Status Register flag to wait after command
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		ES:SI:	Ptr to normalized data buffer (for xfer commands)
;		SS:BP:	Ptr to IDEPACK (containing INTPACK)
;	Returns:
;		AH:		INT 13h Error Code
;		CX:		Number of successfully transferred sectors (for transfer commands)
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, (CX), DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH:
	mov		[bp+IDEPACK.bSectorCount], al
	mov		[bp+IDEPACK.bCommand], ah

	push	bx
	call	Address_OldInt13hAddressToIdeAddress
	call	AccessDPT_GetDriveSelectByteToAL
	or		al, bh			; AL now has Drive and Head Select Byte
	mov		[bp+IDEPACK.bDrvAndHead], al
	mov		[bp+IDEPACK.bLbaLow], bl
	mov		[bp+IDEPACK.wLbaMiddleAndHigh], cx
	pop		bx

GetDeviceControlByteToIdepackAndStartTransfer:
	call	AccessDPT_GetDeviceControlByteToAL
	mov		[bp+IDEPACK.bDeviceControl], al
	jmp		Device_OutputCommandWithParameters


;--------------------------------------------------------------------
; Idepack_StoreNonExtParametersAndIssueCommandFromAL
;	Parameters:
;		BH:		Timeout ticks
;		BL:		IDE Status Register flag to wait after command
;		AL:		IDE command to issue
;		AH:		Parameter to Drive and Head Select Register (Head bits only)
;		DL:		Parameter to Sector Count Register
;		DH:		Parameter to LBA Low / Sector Number Register
;		CL:		Parameter to LBA Middle / Cylinder Low Register
;		CH:		Parameter to LBA High / Cylinder High Register
;		SI:		Parameter to Features Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Idepack_StoreNonExtParametersAndIssueCommandFromAL:
	mov		[bp+IDEPACK.bFeatures], si
	mov		[bp+IDEPACK.bCommand], al
	mov		[bp+IDEPACK.wSectorCountAndLbaLow], dx
	mov		[bp+IDEPACK.wLbaMiddleAndHigh], cx

	; Drive and Head select byte
	and		ah, MASK_DRVNHEAD_HEAD		; Keep head bits only
	call	AccessDPT_GetDriveSelectByteToAL
	or		al, ah
	mov		[bp+IDEPACK.bDrvAndHead], al

	; Device Control byte with interrupts disabled
	call	AccessDPT_GetDeviceControlByteToAL
	or		al, FLG_DEVCONTROL_nIEN		; Disable interrupt
	mov		[bp+IDEPACK.bDeviceControl], al

	jmp		Device_OutputCommandWithParameters
