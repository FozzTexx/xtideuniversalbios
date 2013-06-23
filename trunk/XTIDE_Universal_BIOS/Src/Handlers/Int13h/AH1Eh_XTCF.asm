; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=1Eh, Lo-tech XT-CF features
;
; More information at http://www.lo-tech.co.uk/XT-CF

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

; Modified by JJP for XT-CFv3 support, Mar-13

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=1Eh, Lo-tech XT-CF features.
; This function is supported only by XTIDE Universal BIOS.
;
; AH1Eh_HandlerForXTCFfeatures
;	Parameters:
;		AL, CX:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		AL:		XT-CF subcommand (see XTCF.inc for more info)
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;		DX:		Command return values (see XTCF.inc)
;--------------------------------------------------------------------
AH1Eh_HandlerForXTCFfeatures:
%ifndef USE_186
	call	ProcessXTCFsubcommandFromAL
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%else
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall to ProcessXTCFsubcommandFromAL
%endif


;--------------------------------------------------------------------
; ProcessXTCFsubcommandFromAL
;	Parameters:
;		AL:		XT-CF subcommand (see XTCF.inc for more info)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX, SI
;--------------------------------------------------------------------
ProcessXTCFsubcommandFromAL:
	; IS_THIS_DRIVE_XTCF. We check this for all commands.
	call	AccessDPT_IsThisDeviceXTCF
	jne		SHORT .XTCFnotFound
	and		ax, 0FFh					; Subcommand now in AX (clears AH and CF)
	jz		SHORT .XTCFfound			; Sub-function IS_THIS_DRIVE_XTCF (=0)

	dec		ax							; Test subcommand...
	jz		SHORT .SetXTCFtransferMode	; ...for value 1 (SET_XTCF_TRANSFER_MODE)

	dec		ax							; Test subcommand for value 2 (GET_XTCF_TRANSFER_MODE)
	jnz		SHORT .AH1Eh_LoadInvalidCommandToAHandSetCF

	; GET_XTCF_TRANSFER_MODE
	call	AH1Eh_GetCurrentXTCFmodeToAX
	mov		dh, al
	mov		dl, [di+DPT_ATA.bBlockSize]
	mov		[bp+IDEPACK.intpack+INTPACK.dx], dx	; Return mode value (DH) and block size (DL) via INTPACK
.XTCFfound:
	ret		; With AH and CF cleared

.XTCFnotFound:
.AH1Eh_LoadInvalidCommandToAHandSetCF:
	stc		; Set carry flag since XT-CF not found or invalid subcommand
	mov		ah, RET_HD_INVALID
	ret

.SetXTCFtransferMode:
	mov		al, [bp+IDEPACK.intpack+INTPACK.dh]	; Get specified mode (eg XTCF_DMA_MODE)
	; Fall to AH1Eh_ChangeXTCFmodeBasedOnModeInAL


;--------------------------------------------------------------------
; AH1Eh_ChangeXTCFmodeBasedOnModeInAL
;	Parameters:
;		AL:		XT-CF Mode (see XTCF.inc)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX, SI
;--------------------------------------------------------------------
AH1Eh_ChangeXTCFmodeBasedOnModeInAL:
	; Note: Control register (as of XT-CFv3) is now a write-only register,
	;       whose purpose is *only* to raise DRQ.  The register cannot be read.
	;       Selected transfer mode is stored in BIOS variable (DPT_ATA.bDevice).

	; Note that when selecting 'DEVICE_8BIT_PIO_MODE_WITH_BIU_OFFLOAD' mode,
	; the ATA device (i.e. CompactFlash card) will operate in 8-bit mode, but
	; data will be transferred from its data register using 16-bit CPU instructions
	; like REP INSW.  This works because XT-CF adapters are 8-bit cards, and
	; the BIU in the machine splits each WORD requested by the CPU into two 8-bit
	; ISA cycles at base+0h and base+1h.  The XT-CF cards do not decode A0, hence
	; both accesses appear the same to the card and the BIU then re-constructs
	; the data for presentation to the CPU.
	;
	; Also note that some machines, noteably the Olivetti M24 (also known as
	; the AT&T PC6300 and Xerox 6060), have hardware errors in the BIU logic,
	; resulting in reversed byte ordering.  Therefore, mode DEVICE_8BIT_PIO is
	; the default transfer mode for best system compatibility.

	; We always need to enable 8-bit mode since 16-bit mode is restored
	; when controller is reset (AH=00h or 0Dh)
	ePUSH_T	bx, AH23h_Enable8bitPioMode

	; Convert mode to device type (see XTCF.inc for full details)
	and		ax, 3
	jz		SHORT .Set8bitPioMode	; XTCF_8BIT_PIO_MODE = 0
	dec		ax						; XTCF_8BIT_PIO_MODE_WITH_BIU_OFFLOAD = 1
	jz		SHORT .Set8bitPioModeWithBIUOffload

	; XTCF_DMA_MODE = 2 (allow 3 as well for more optimized code)
	mov		BYTE [di+DPT_ATA.bDevice], DEVICE_8BIT_XTCF_DMA

	; DMA transfers have limited block size
	mov		al, [di+DPT_ATA.bBlockSize]
	cmp		al, XTCF_DMA_MODE_MAX_BLOCK_SIZE
	jbe		SHORT AH24h_SetBlockSize
	mov		al, XTCF_DMA_MODE_MAX_BLOCK_SIZE
	jmp		SHORT AH24h_SetBlockSize

.Set8bitPioMode:
	mov		al, DEVICE_8BIT_XTCF_PIO8
	SKIP2B	bx

.Set8bitPioModeWithBIUOffload:
	mov		al, DEVICE_8BIT_XTCF_PIO8_WITH_BIU_OFFLOAD
	mov		[di+DPT_ATA.bDevice], al
	ret


;--------------------------------------------------------------------
; AH1Eh_GetCurrentXTCFmodeToAX
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AX:		XT-CF mode (XTCF_8BIT_PIO_MODE, XTCF_8BIT_PIO_MODE_WITH_BIU_OFFLOAD or XTCF_DMA_MODE)
;		CF:		Clear
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AH1Eh_GetCurrentXTCFmodeToAX:
	mov		al, [di+DPT_ATA.bDevice]
	shr		al, 1
	cbw
	sub		al, DEVICE_8BIT_XTCF_PIO8 >> 1
	ret
