; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=48h, Get Extended Drive Parameters.

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
; Int 13h function AH=48h, Get Extended Drive Parameters.
;
; It is not completely clear what this function should return as total sector count in some cases.
; What is certain is that:
; A) Phoenix Enhanced Disk Drive Specification v3.0 says that P-CHS values
;    are never returned for drives with more than 15,482,880 sectors (16384*15*63).
;    For those drives we can simply return total sector count from
;    ATA ID WORDs 60 and 61 (LBA28) or WORDs 100-103 (LBA48).
; B) IBM PC DOS 7.1 fdisk32 displays warning message if P-CHS values multiplied
;    together are different than total sector count. Therefore for drives with less
;    than or equal 15,482,880 sectors we MUST NOT return total sector count from
;    ATA ID WORDs 60 and 61.
;
;    Lets take an example. 6 GB Hitachi microdrive reports following values in ATA ID:
;    Sector count from WORDs 60 and 61	: 12,000,556
;    Cylinders							: 11905
;    Heads								:    16
;    Sectors per track					:    63
;
;    When multiplying C*H*S we get		: 12,000,240
;    So the CHS size is a little bit less than LBA size. But we must use
;    the smaller value since C*H*S must equal total sector count!
;
; Now we get to the uncertain area where I could not find any information.
; Award BIOS from 1997 Pentium motherboard returns following values:
;    AH=08h L-CHS:   745, 255, 63 (exactly the same as what we return)
;    => Total Sector Count:		  745*255*63 = 11,968,425
;    AH=48h P-CHS: 11873,  16, 63
;    AH=48h Total Sector Count: 11873* 16*63 = 11,967,984
;
; Notice how AH=48h returns lesser total sector count than AH=8h! The only
; way I could think of to get 11873 cylinders is to divide AH=08h sector
; count with P-CHS heads and sectors: (745*255*63) / (16*63) = 11873
;
; I have no idea what is the reasoning behind it but at least there is one
; BIOS that does just that.
;
; Since I don't have any better knowledge, I decided that when RESERVE_DIAGNOSTIC_CYLINDER
; is defined, we do what the Award BIOS does. When it is not defined, we multiply
; P-CHS values together and use that as total sector count.
;
;
; AH48h_GetExtendedDriveParameters
;	Parameters:
;		SI:		Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		DS:SI:	Ptr to Extended Drive Information Table to fill
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		DS:SI:	Ptr to Extended Drive Information Table
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
AH48h_HandlerForGetExtendedDriveParameters:
	call	AccessDPT_GetLbaSectorCountToBXDXAX

	; Point DS:SI to Extended Drive Information Table to fill
	push	ds
	pop		es			; DPT now in ES:DI
	mov		ds, [bp+IDEPACK.intpack+INTPACK.ds]
	mov		cx, MINIMUM_EDRIVEINFO_SIZE
	cmp		[si+EDRIVE_INFO.wSize], cx
	jb		Prepare_ReturnFromInt13hWithInvalidFunctionError
	je		SHORT .SkipEddConfigurationParameters

	; We do not support EDD Configuration Parameters so set to FFFF:FFFFh
	sub		cx, BYTE MINIMUM_EDRIVEINFO_SIZE+1	; CX => FFFFh
	mov		[si+EDRIVE_INFO.fpEDDparams], cx
	mov		[si+EDRIVE_INFO.fpEDDparams+2], cx
	mov		cx, EDRIVE_INFO_size

	; Fill Extended Drive Information Table in DS:SI
.SkipEddConfigurationParameters:
	mov		[si+EDRIVE_INFO.wSize], cx
	mov		WORD [si+EDRIVE_INFO.wFlags], FLG_DMA_BOUNDARY_ERRORS_HANDLED_BY_BIOS

	; Store total sector count
	mov		[si+EDRIVE_INFO.qwTotalSectors], ax
	mov		[si+EDRIVE_INFO.qwTotalSectors+2], dx
	mov		[si+EDRIVE_INFO.qwTotalSectors+4], bx
	xor		cx, cx
	mov		[si+EDRIVE_INFO.qwTotalSectors+6], cx	; Always zero
	mov		WORD [si+EDRIVE_INFO.wSectorSize], 512

	; Store P-CHS. Based on phoenix specification this is returned only if
	; total sector count is 15,482,880 or less.
	sub		ax, 4001h
	sbb		dx, 0ECh
	sbb		bx, cx		; Zero
	jnc		SHORT .ReturnWithSuccess	; More than EC4000h
	or		WORD [si+EDRIVE_INFO.wFlags], FLG_CHS_INFORMATION_IS_VALID

	eMOVZX	dx, BYTE [es:di+DPT.bPchsHeads]
	mov		[si+EDRIVE_INFO.dwHeads], dx
	mov		[si+EDRIVE_INFO.dwHeads+2], cx

	mov		dl, [es:di+DPT.bPchsSectorsPerTrack]
	mov		[si+EDRIVE_INFO.dwSectorsPerTrack], dx
	mov		[si+EDRIVE_INFO.dwSectorsPerTrack+2], cx

	mov		dx, [es:di+DPT.wPchsCylinders]
	mov		[si+EDRIVE_INFO.dwCylinders], dx
	mov		[si+EDRIVE_INFO.dwCylinders+2], cx

.ReturnWithSuccess:
	xor		ax, ax
.ReturnWithError:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
