; Project name	:	XTIDE Universal BIOS
; Description	:	Lo-tech XT-CFv2 board specifications.
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


%ifndef XTCF_INC
%define XTCF_INC

; XT-CF requires that block must be less than 128 sectors (64 kiB) for DMA transfers.
;
; Note: XT-CFv3 DMA will not interfere with PC & PC/XT memory refresh,
; since the XT-CFv3 detaches itself from the bus every 16 bytes transferred.
;
XTCF_DMA_MODE_MAX_BLOCK_SIZE		EQU		64		; Sectors

; Possible base addresses. Note that all XT-CF IDE registers are SHL 1 compared
; to standard IDE registers.
XTCF_BASE_PORT_1					EQU		200h
XTCF_BASE_PORT_2					EQU		240h
XTCF_BASE_PORT_3					EQU		300h	; Default setting
XTCF_BASE_PORT_4					EQU		340h


; XT-CF Control Register (do not SHL 1 these!)
; Note: XT-CFv3 control register is used *only* to raise DRQ.  The register cannot be read.
;
XTCF_CONTROL_REGISTER				EQU		1Eh

; Transfer Mode Constants
;
; Available transfer modes depend on the controller.  All XT-CF controllers
; support 8-bit PIO, either with 8-bit or 16-bit instructions (i.e., data
; can be fetched from the controller with REP INSW or REP INSB since A0 is
; not decoded).  However, errors in the implementation of the BIU on some
; machines will prevent 16-bit instructions delivering data correctly.
;
; For XT-CFv3 adapter, DMA transfers are also supported via channel 3.
;
; XT-CFv3 cannot be distinguised by software, so user must decide and set
; the mode via a call to Int 13h function 1Eh accordingly (see AH1E_XTCF.asm).
;
XTCF_8BIT_PIO_MODE					EQU		00h
XTCF_8BIT_PIO_MODE_WITH_BIU_OFFLOAD	EQU		01h
XTCF_DMA_MODE						EQU		02h

; Subcommands for AH=1Eh, Lo-tech XT-CF features.
; Return values common for all subcommands:
;		AH:		RET_HD_SUCCESS if drive is XT-CF
;				RET_HD_INVALID if drive is not XT-CF
;		CF:		0 if successful, 1 if error

;--------------------------------------------------------------------
; IS_THIS_DRIVE_XTCF
;	Parameters:
;		DL:		Drive Number
;--------------------------------------------------------------------
IS_THIS_DRIVE_XTCF					EQU		0

;--------------------------------------------------------------------
; SET_XTCF_TRANSFER_MODE
;	Parameters:
;		DH:		Mode to select, i.e. XTCF_8BIT_PIO_MODE
;				Note there's no way to know if an XT-CF adapter
;				supports DMA, so the user should enable DMA
;				only if a DMA-enabled XT-CFv3 is fitted.
;		DL:		Drive Number
;--------------------------------------------------------------------
SET_XTCF_TRANSFER_MODE				EQU		1

;--------------------------------------------------------------------
; GET_XTCF_TRANSFER_MODE
;	Parameters:
;		DL:		Drive Number
;	Returns:
;		DH:		One of the mode values listed above,
;				i.e. XTCF_8BIT_PIO_MODE
;		DL:		Block mode sectors per block configured
;--------------------------------------------------------------------
GET_XTCF_TRANSFER_MODE				EQU		2


%endif ; XTCF_INC
