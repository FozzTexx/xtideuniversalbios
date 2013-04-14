; Project name	:	XTIDE Universal BIOS
; Description	:	Functions to handle DPT structs to present drive geometry
;					to ill behaving applications that want
;					to read DPT from interrupt vectors 41h and 46h.

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
; CompatibleDPT_CreateToAXSIforDriveDL
;	Parameters:
;		DL:		Drive number (80h or 81h)
;		DS:DI:	Ptr to DPT
;	Returns:
;		AX:SI	Ptr to destination buffer
;	Corrupts registers:
;		CX, DX
;--------------------------------------------------------------------
CompatibleDPT_CreateToAXSIforDriveDL:
	push	es

	call	AccessDPT_GetDeviceControlByteToAL
	xchg	cx, ax							; Device control byte to CL
	mov		si, di							; DPT now in DS:SI
	call	GetBufferForDrive80hToESDI
	shr		dx, 1
	jnc		SHORT .BufferLoadedToESDI
	add		di, BYTE TRANSLATED_DPT_size	; For drive 81h
.BufferLoadedToESDI:

	call	FillToESDIusingDPTfromDSSI
	xchg	di, si
	mov		ax, es

	pop		es
	ret


;--------------------------------------------------------------------
; GetTemporaryBufferForDPTEtoESDI
; GetBufferForDrive80hToESDI
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		ES:DI:	Ptr to buffer (in RAMVARS segment)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
GetTemporaryBufferForDPTEtoESDI:
	call	GetBufferForDrive80hToESDI
	add		di, BYTE TRANSLATED_DPT_size * 2
	ret

GetBufferForDrive80hToESDI:
	push	ds
	pop		es
	mov		di, [cs:ROMVARS.bStealSize]	; No harm to read WORD
	eSHL_IM	di, 10						; DI = RAMVARS size in bytes
	sub		di, BYTE (TRANSLATED_DPT_size * 2) + DPTE_size
	ret


;--------------------------------------------------------------------
; FillToESDIusingDPTfromDSSI
;	Parameters:
;		CL:		Device Control Byte
;		DS:SI:	Ptr to DPT
;		ES:DI	Ptr to destination buffer
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
FillToESDIusingDPTfromDSSI:
	test	BYTE [si+DPT.bFlagsLow], MASKL_DPT_TRANSLATEMODE
	jz		SHORT FillStandardDPTtoESDIfromDPTinDSSI
	; Fall to FillTranslatedDPTtoESDIfromDPTinDSSI

;--------------------------------------------------------------------
; FillTranslatedDPTtoESDIfromDPTinDSSI
;	Parameters:
;		CL:		Device Control Byte
;		DS:SI:	Ptr to DPT
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
FillTranslatedDPTtoESDIfromDPTinDSSI:
	xor		dx, dx						; Clear for checksum
	mov		ax, [si+DPT.wLchsCylinders]
	MIN_U	ax, MAX_LCHS_CYLINDERS		; Our DPT can have up to 1027
	call	StoswThenAddALandAHtoDL		; Bytes 0 and 1 (Logical number of cylinders)

	mov		al, BYTE [si+DPT.bLchsHeads]
	mov		ah, TRANSLATED_DPT_SIGNATURE
	call	StoswThenAddALandAHtoDL		; Bytes 2 (Logical number of heads) and 3 (Axh signature to indicate Translated DPT)

	eMOVZX	ax, BYTE [si+DPT.bPchsSectorsPerTrack]
	call	StoswThenAddALandAHtoDL		; Bytes 4 (Physical sectors per track) and 5 (Write Precompensation Cylinder low)

	mov		al, ah
	call	StoswThenAddALandAHtoDL		; Bytes 6 (Write Precompensation Cylinder high) and 7

	xchg	ax, cx						; Device Control byte to AL
	mov		ah, [si+DPT.wPchsCylinders]
	call	StoswThenAddALandAHtoDL		; Bytes 8 (Drive Control Byte) and 9 (Physical number of cylinders low)

	mov		al, [si+DPT.wPchsCylinders+1]
	mov		ah, [si+DPT.bPchsHeads]
	call	StoswThenAddALandAHtoDL		; Bytes 10 (Physical number of cylinders high) and 11 (Physical number of heads)

	xor		ax, ax
	call	StoswThenAddALandAHtoDL		; Bytes 12 and 13 (Landing Zone Cylinder)

	mov		al, [si+DPT.bLchsSectorsPerTrack]
%ifdef USE_186
	push	FillStandardDPTtoESDIfromDPTinDSSI.RestoreOffsetsAndReturn
	jmp		StoswALandChecksumFromDL	; Bytes 14 (Logical sectors per track) and 15 (Checksum)
%else
	call	StoswALandChecksumFromDL
	jmp		SHORT FillStandardDPTtoESDIfromDPTinDSSI.RestoreOffsetsAndReturn
%endif


;--------------------------------------------------------------------
; FillStandardDPTtoESDIfromDPTinDSSI
;	Parameters:
;		CL:		Device Control Byte
;		DS:SI:	Ptr to DPT
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
FillStandardDPTtoESDIfromDPTinDSSI:
	mov		ax, [si+DPT.wLchsCylinders]
	stosw				; Bytes 0 and 1 (Physical number of cylinders)
	eMOVZX	ax, BYTE [si+DPT.bLchsHeads]
	stosw				; Bytes 2 (Physical number of heads) and 3
	mov		al, ah		; Zero AX
	stosw				; Bytes 4 and 5 (Write Precompensation Cylinder low)
	stosw				; Bytes 6 (Write Precompensation Cylinder high) and 7
	mov		al, cl		; Device control byte to AL
	stosw				; Bytes 8 (Drive Control Byte) and 9
	mov		al, ah		; Zero AX
	stosw				; Bytes 10 and 11
	stosw				; Bytes 12 and 13 (Landing Zone Cylinder)
	mov		al, [si+DPT.bLchsSectorsPerTrack]
	stosw				; Bytes 14 (Physical sectors per track) and 15

.RestoreOffsetsAndReturn:
	sub		di, BYTE STANDARD_DPT_size
	ret


;--------------------------------------------------------------------
; CompatibleDPT_CreateDeviceParameterTableExtensionToESBXfromDPTinDSSI
;	Parameters:
;		DS:SI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		ES:BX:	Ptr to Device Parameter Table Extension (DPTE)
;	Corrupts registers:
;		AX, CX, DX, DI
;--------------------------------------------------------------------
CompatibleDPT_CreateDeviceParameterTableExtensionToESBXfromDPTinDSSI:
	call	GetTemporaryBufferForDPTEtoESDI	; valid until next AH=48h call

	; Set 32-bit flag for 32-bit controllers
	mov		cx, FLG_LBA_TRANSLATION_ENABLED	; DPTE.wFlags
	cmp		BYTE [si+DPT_ATA.bDevice], DEVICE_32BIT_ATA
	eCMOVE	cl, FLG_LBA_TRANSLATION_ENABLED | FLG_32BIT_XFER_MODE

	; DPTE.wBasePort
	mov		ax, [si+DPT.wBasePort]
	call	StoswThenAddALandAHtoDL			; Bytes 0 and 1

	; DPTE.wControlBlockPort
	eMOVZX	bx, BYTE [si+DPT.bIdevarsOffset]
	mov		ax, [cs:bx+IDEVARS.wControlBlockPort]
	call	StoswThenAddALandAHtoDL			; Bytes 2 and 3

	; DPTE.bDrvnhead and DPTE.bBiosVendor
	xchg	di, si
	call	AccessDPT_GetDriveSelectByteForEbiosToAL
	xchg	si, di
	call	StoswThenAddALandAHtoDL			; Bytes 4 and 5

	; DPTE.bIRQ and DPTE.bBlockSize
	mov		al, [cs:bx+IDEVARS.bIRQ]		; No way to define that we might not use IRQ
	mov		ah, [si+DPT_ATA.bBlockSize]
	cmp		ah, 1
	jbe		SHORT .DoNotSetBlockModeFlag
	or		cl, FLG_BLOCK_MODE_ENABLED
.DoNotSetBlockModeFlag:
	call	StoswThenAddALandAHtoDL			; Bytes 6 and 7

	; DPTE.bDmaChannelAndType and DPTE.bPioMode
	xor		ax, ax
%ifdef MODULE_ADVANCED_ATA
	or		ah, [si+DPT_ADVANCED_ATA.bPioMode]
	jz		SHORT .NoDotSetFastPioFlag
	cmp		WORD [si+DPT_ADVANCED_ATA.wControllerID], BYTE 0
	je		SHORT .NoDotSetFastPioFlag
	inc		cx		; FLG_FAST_PIO_ENABLED
.NoDotSetFastPioFlag:
%endif
	call	StoswThenAddALandAHtoDL			; Bytes 8 and 9

	; Set CHS translation flags and store DPTE.wFlags
	mov		al, [si+DPT.bFlagsLow]
	and		al, MASKL_DPT_TRANSLATEMODE
	jz		SHORT .NoChsTranslationOrBitShiftTranslationSet
	or		cl, FLG_CHS_TRANSLATION_ENABLED
	test	al, FLGL_DPT_ASSISTED_LBA
	jz		SHORT .NoChsTranslationOrBitShiftTranslationSet
	or		cx, LBA_ASSISTED_TRANSLATION << TRANSLATION_TYPE_FIELD_POSITION
.NoChsTranslationOrBitShiftTranslationSet:
	xchg	ax, cx
	call	StoswThenAddALandAHtoDL			; Bytes 10 and 11

	; DPTE.wReserved (must be zero)
	xor		ax, ax
	call	StoswThenAddALandAHtoDL			; Bytes 12 and 13

	; DPTE.bRevision and DPTE.bChecksum
	mov		al, DPTE_REVISION
	call	StoswALandChecksumFromDL		; Bytes 14 and 15
	lea		bx, [di-DPTE_size]
	ret


;--------------------------------------------------------------------
; StoswThenAddALandAHtoDL
;	Parameters:
;		AX:		WORD to store
;		DL:		Sum of bytes so far
;		ES:DI:	Ptr to where to store AX
;	Returns:
;		DL:		Sum of bytes so far
;		DI:		Incremented by 2
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
StoswThenAddALandAHtoDL:
	stosw
	add		dl, al
	add		dl, ah
	ret


;--------------------------------------------------------------------
; StoswALandChecksumFromDL
;	Parameters:
;		AL:		Last byte to store before checksum byte
;		DL:		Sum of bytes so far
;		ES:DI:	Ptr to where to store AL and Checksum byte
;	Returns:
;		DL:		Sum of bytes so far
;		DI:		Incremented by 2
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
StoswALandChecksumFromDL:
	mov		ah, al
	add		ah, dl
	neg		ah
	stosw
	ret
