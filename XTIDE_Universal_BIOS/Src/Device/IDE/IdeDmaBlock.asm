; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Read/Write functions for transferring
;					block using DMA.
;					These functions should only be called from IdeTransfer.asm.

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
; IdeDmaBlock_WriteToXTCF
;	Parameters:
;		CX:		Block size in 512 byte sectors
;		DX:		XTCF Base Port Address
;		ES:SI:	Physical address to buffer to receive data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeDmaBlock_WriteToXTCF:
	xchg	si, di
	mov		bl, CHANNEL_3 | READ | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE
	call	TransferBlockToOrFromXTCF
	xchg	di, si
	ret


;--------------------------------------------------------------------
; IdeDmaBlock_ReadFromXTCF
;	Parameters:
;		CX:		Block size in 512 byte sectors
;		DX:		XTCF Base Port Address
;		ES:DI:	Physical address to buffer to receive data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeDmaBlock_ReadFromXTCF:
	mov		bl, CHANNEL_3 | WRITE | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE
	; Fall to TransferBlockToOrFromXTCF


;--------------------------------------------------------------------
; TransferBlockToOrFromXTCF
;	Parameters:
;		BL:		Mode byte for DMA Mode Register
;		CX:		Block size in 512 byte sectors
;		DX:		XTCF Base Port Address
;		ES:DI:	Physical address to buffer to receive data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
TransferBlockToOrFromXTCF:
	; 8-bit DMA transfers must be done withing 64k physical page.
	; We support maximum of 128 sectors (65536 bytes) per one INT 13h call
	; so we might need to separate transfer to 2 separate DMA operations.

	; Load XT-CF Control Register port to DX
	add		dl, XTCF_CONTROL_REGISTER

	; Calculate bytes for first page
	mov		ax, di
	neg		ax										; AX = Max BYTEs for first page
%ifdef USE_186
	shl		cx, 9									; CX = Block size in BYTEs
%else
	xchg	cl, ch
	shl		cx, 1
%endif
	cmp		cx, ax
	jbe		SHORT .TransferLastDmaPageWithSizeInCX

	; Push size for second DMA page
	xchg	cx, ax									; CX = BYTEs for first page
	sub		ax, cx									; AX = BYTEs for second page
	push	ax

	; Transfer first DMA page
	call	StartDMAtransferForXTCFwithDmaModeInBL
	pop		cx										; Pop size for second DMA page

.TransferLastDmaPageWithSizeInCX:
	; Fall to StartDMAtransferForXTCFwithDmaModeInBL


;--------------------------------------------------------------------
; StartDMAtransferForXTCFwithDmaModeInBL
;	Parameters:
;		CX:		Number of BYTEs to transfer
;		BL:		Byte for DMA Mode Register
;		DX:		XTCF Control Register
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
StartDMAtransferForXTCFwithDmaModeInBL:
	; Program 8-bit DMA Controller
	; Disable Interrupts and DMA Channel 3 during DMA setup
	mov		al, SET_CH3_MASK_BIT
	cli										; Disable interrupts
	out		MASK_REGISTER_DMA8_out, al		; Disable DMA Channel 3

	; Set DMA Mode (read or write using channel 3)
	mov		al, bl
	out		MODE_REGISTER_DMA8_out, al

	; Set address to DMA controller
	out		CLEAR_FLIPFLOP_DMA8_out, al		; Reset flip-flop to low byte
	mov		ax, es
	out		PAGE_DMA8_CH_3, al
	mov		ax, di
	out		BASE_AND_CURRENT_ADDRESS_REGISTER_DMA8_CH3_out, al	; Low byte
	mov		al, ah
	out		BASE_AND_CURRENT_ADDRESS_REGISTER_DMA8_CH3_out, al	; High byte

	; Set number of bytes to transfer (DMA controller must be programmed number of bytes - 1)
	mov		ax, cx
	dec		ax								; DMA controller is programmed for one byte less
	out		BASE_AND_CURRENT_COUNT_REGISTER_DMA8_CH3_out, al	; Low byte
	mov		al, ah
	out		BASE_AND_CURRENT_COUNT_REGISTER_DMA8_CH3_out, al	; High byte

	; Enable DMA Channel 3
	mov		al, CLEAR_CH3_MASK_BIT
	out		MASK_REGISTER_DMA8_out, al		; Enable DMA Channel 3
	sti										; Enable interrupts


	; XT-CF transfers 16 bytes at a time. We need to manually
	; start transfer for every block.
ALIGN JUMP_ALIGN
.TransferNextBlock:
	mov		al, RAISE_DRQ_AND_CLEAR_XTCF_XFER_COUNTER
	cli									; We want no ISR to read DMA Status Register before we do
	out		dx, al						; Transfer up to 16 bytes to/from XT-CF card
	; * Here XT-CF sets CPU to wait states during transfer *
	in		al, STATUS_REGISTER_DMA8_in
	sti
	test	al, FLG_CH3_HAS_REACHED_TERMINAL_COUNT
	jz		SHORT .TransferNextBlock	; All bytes transferred?

	; Restore XT-CF to normal operation
	mov		al, XTCF_DMA_MODE
	out		dx, al

	; Increment physical address in ES:DI
	mov		ax, es
	add		di, cx
	adc		al, ah
	mov		es, ax
	ret
