; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=48h, Get Extended Drive Parameters.

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
; Int 13h function AH=48h, Get Extended Drive Parameters.
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
	mov		WORD [si+EDRIVE_INFO.wFlags], FLG_DMA_BOUNDARY_ERRORS_HANDLED_BY_BIOS | FLG_CHS_INFORMATION_IS_VALID

	; Store total sector count
	mov		[si+EDRIVE_INFO.qwTotalSectors], ax
	xor		ax, ax									; Return with success
	mov		[si+EDRIVE_INFO.qwTotalSectors+2], dx
	mov		[si+EDRIVE_INFO.qwTotalSectors+4], bx
	mov		[si+EDRIVE_INFO.qwTotalSectors+6], ax	; Always zero
	mov		WORD [si+EDRIVE_INFO.wSectorSize], 512

	; Store P-CHS
	eMOVZX	dx, BYTE [es:di+DPT.bPchsHeads]
	xor		ax, ax									; Also a return code
	mov		[si+EDRIVE_INFO.dwHeads], dx
	mov		[si+EDRIVE_INFO.dwHeads+2], ax

	mov		dl, [es:di+DPT.bPchsSectorsPerTrack]
	mov		[si+EDRIVE_INFO.dwSectorsPerTrack], dx
	mov		[si+EDRIVE_INFO.dwSectorsPerTrack+2], ax

	mov		dx, [es:di+DPT.wPchsCylinders]
	mov		[si+EDRIVE_INFO.dwCylinders], dx
	mov		[si+EDRIVE_INFO.dwCylinders+2], ax

.ReturnWithError:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
