; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Read/Write functions for transferring block using DMA.
;					These functions should only be called from IdeTransfer.asm.

; Modified JJP 05-Jun-13

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
	; 8-bit DMA transfers must be done within 64k physical page.
	; XT-CF support maximum of 64 sector (32768 bytes) blocks in DMA mode
	; so we never need to separate transfer to more than 2 separate DMA operations.

	; Load XT-CFv3 Control Register port to DX
	add		dl, XTCF_CONTROL_REGISTER

	; convert sectors in CX to BYTES
%ifdef USE_186
	shl		cx, 9									; CX = Block size in BYTEs
%else
	xchg	cl, ch
	shl		cx, 1
%endif

	; Calculate bytes for first page
	mov		ax, di
	neg		ax			; 2s compliment

	; If DI was zero carry flag will be cleared (and set otherwise)
	; When DI is zero only one transfer is required since we've limited the
	; XT-CFv3 block size to 32k
	jnc		SHORT .TransferLastDmaPageWithSizeInCX

	; CF was set, so DI != 0 and we might need one or two transfers
	cmp		cx, ax									; if we won't cross a physical page boundary...
	jbe		SHORT .TransferLastDmaPageWithSizeInCX	; ...perform the transfer in one operation

	; Calculate how much we can transfer on first and second rounds
	xchg	cx, ax		; CX = BYTEs for first page
	sub		ax, cx		; AX = BYTEs for second page
	push	ax			; Save bytes for second transfer on stack

	; Transfer first DMA page
	call	StartDMAtransferForXTCFwithDmaModeInBL
	pop		cx										; Pop size for second DMA page

.TransferLastDmaPageWithSizeInCX:
	; Fall to StartDMAtransferForXTCFwithDmaModeInBL


;--------------------------------------------------------------------
; StartDMAtransferForXTCFwithDmaModeInBL
; Updated for XT-CFv3, 11-Apr-13
;	Parameters:
;		BL:		Byte for DMA Mode Register
;		CX:		Number of BYTEs to transfer (1...32768 since max block size is limited to 64)
;		DX:		XT-CFv3 Control Register
;		ES:		Bits 3..0 have physical address bits 19..16
;		DI:		Physical address bits 15..0
;	Returns:
;		ES:DI updated (CX is added)
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
StartDMAtransferForXTCFwithDmaModeInBL:
	; Program 8-bit DMA Controller
	; Disable Interrupts and DMA Channel 3 during DMA setup
	mov		al, SET_CH3_MASK_BIT
	cli									; Disable interrupts - programming must be atomic
	out		MASK_REGISTER_DMA8_out, al	; Disable DMA Channel 3

	; Set DMA Mode (read or write using channel 3)
	mov		al, bl
	out		MODE_REGISTER_DMA8_out, al

	; Send start address to DMA controller
	mov		ax, es
	out		PAGE_DMA8_CH_3, al
	mov		ax, di
	out		CLEAR_FLIPFLOP_DMA8_out, al							; Reset flip-flop to low byte
	out		BASE_AND_CURRENT_ADDRESS_REGISTER_DMA8_CH3_out, al	; Low byte
	mov		al, ah
	out		BASE_AND_CURRENT_ADDRESS_REGISTER_DMA8_CH3_out, al	; High byte

	; Set number of bytes to transfer (DMA controller must be programmed number of bytes - 1)
	mov		ax, cx
	dec		ax													; DMA controller is programmed for one byte less
	out		BASE_AND_CURRENT_COUNT_REGISTER_DMA8_CH3_out, al	; Low byte
	mov		al, ah
	out		BASE_AND_CURRENT_COUNT_REGISTER_DMA8_CH3_out, al	; High byte

	; Enable DMA Channel 3
	mov		al, CLEAR_CH3_MASK_BIT
	out		MASK_REGISTER_DMA8_out, al							; Enable DMA Channel 3
	sti															; Enable interrupts

	; Update physical address in ES:DI - since IO might need several calls through this function either from here
	; if crossing a physical page boundary, or from IdeTransfer.asm if requested sectors was > PIOVARS.wSectorsInBlock
	; We update the pointer here (before the actual transfer) to avoid having to save the byte count on the stack
	mov		ax, es						; copy physical page address to ax
	add		di, cx						; add requested bytes to di
	adc		al, 0						; and increment physical page address, if required
	mov		es, ax						; and save it back in es

	; XT-CF transfers 16 bytes at a time. We need to manually start transfer for every block by writing (anything)
	; to the XT-CFv3 Control Register, which raises DRQ thereby passing system control to the 8237 DMA controller.
	; The XT-CFv3 logic releases DRQ after 16 transfers, thereby handing control back to the CPU and allowing any other IRQs or
	; DRQs to be serviced (which, on the PC and PC/XT will include DRAM refresh via DMA channel 0).  The 16-byte transfers can
	; also be interrupted by the DMA controller raising TC (i.e. when done).  Each transfer cannot be otherwise interrupted
	; and is therefore atomic (and hence fast).

%if 0	; Slow DMA code - works by checking 8237 status register after each 16-byte transfer, until it reports TC has been raised.
ALIGN JUMP_ALIGN
.TransferNextBlock:
	cli									; We want no ISR to read DMA Status Register before we do
	out		dx, al						; Transfer up to 16 bytes to/from XT-CF card
	in		al, STATUS_REGISTER_DMA8_in
	sti
	test	al, FLG_CH3_HAS_REACHED_TERMINAL_COUNT
	jz		SHORT .TransferNextBlock	; All bytes transferred?
%else	; Fast DMA code - perform computed number of transfers, then check DMA status register to be sure
	add		cx, BYTE 15					; We'll divide transfers in 16-byte atomic transfers,
	eSHR_IM	cx, 4						; so include any partial block, which will be terminated
ALIGN JUMP_ALIGN						; by the DMA controller raising T/C
.TransferNextDmaBlock:
	out		dx, al						; Transfer up to 16 bytes to/from XT-CF card
	loop	.TransferNextDmaBlock		; dec CX and loop if CX > 0, also adds required wait-state
	inc		cx							; set up CX, in case we need to do an extra iteration
	in		al, STATUS_REGISTER_DMA8_in	; check 8237 DMA controller status flags...
	test	al, FLG_CH3_HAS_REACHED_TERMINAL_COUNT	; ... for channel 3 terminal count
	jz		SHORT .TransferNextDmaBlock	; If not set, get more bytes
%endif

	ret
