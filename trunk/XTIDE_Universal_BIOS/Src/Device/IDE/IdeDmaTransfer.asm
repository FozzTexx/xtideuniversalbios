; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device DMA transfer functions.

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

; Structure containing variables for DMA transfer functions.
; This struct must not be larger than IDEPACK without INTPACK.
struc DMAVARS	; Must not be larger than 9 bytes! See IDEPACK in RamVars.inc.
	.wTotalBytesXferred			resb	2	; 0-1, 
	.wBytesLeftToXfer			resb	2	; 2-3, 0 = 65536
	.bbbPhysicalAddress			resb	3	; 4-6, 
								resb	1	; 7, IDEPACK.bDeviceControl
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeDmaTransfer_StartWithCommandInAL
;	Parameters:
;		AL:		IDE command that was used to start the transfer
;				(all PIO read and write commands including Identify Device)
;		ES:SI:	Ptr to data buffer (not normalized)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CX:		Number of successfully transferred sectors
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeDmaTransfer_StartWithCommandInAL:
	; Initialize DMAVARS
	xor		cx, cx
	mov		[bp+DMAVARS.wTotalBytesXferred], cx
	mov		ch, [bp+IDEPACK.bSectorCount]	; CX = WORDs to transfer
	shl		cx, 1							; WORDs to BYTEs, 0 = 65536
	mov		[bp+DMAVARS.wBytesLeftToXfer], cx

	; Convert Segment:Offset type pointer to physical address
	xor		bx, bx
	mov		cx, es
%rep 4
	shl		cx, 1
	rcl		bx, 1
%endrep
	add		cx, si
	adc		bl, bh
	mov		[bp+DMAVARS.bbbPhysicalAddress], cx
	mov		[bp+DMAVARS.bbbPhysicalAddress+2], bl

	; Calculate bytes for first page
	neg		cx	; Max number of bytes for first page, 0 = 65536
	MIN_U	cx, [bp+DMAVARS.wBytesLeftToXfer]

	; Are we reading or writing?
	mov		bl, CHANNEL_3 | READ | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE	; Assume write command
	test	al, 16	; Bit 4 is cleared on all the read commands but set on 3 of the 4 write commands
	jnz		SHORT TransferBlockToOrFromXTCF
	cmp		al, COMMAND_WRITE_MULTIPLE
	je		SHORT TransferBlockToOrFromXTCF

	; Read command
	mov		bl, CHANNEL_3 | WRITE | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE
	; Fall to TransferBlockToOrFromXTCF


;--------------------------------------------------------------------
; TransferBlockToOrFromXTCF
;	Parameters:
;		BX:		Mode byte for DMA Mode Register
;		CX:		Bytes in first page
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to DMAVARS
;	Returns:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		AH:		BIOS Error code
;		CX:		Number of successfully transferred sectors
;		CF:		0 if transfer successful
;				1 if any error
;	Corrupts registers:
;		AL, BX, DX
;--------------------------------------------------------------------
TransferBlockToOrFromXTCF:
	; 8-bit DMA transfers must be done withing 64k physical page.
	; We support maximum of 128 sectors (65536 bytes) per one INT 13h call
	; so we might need to separate transfer to 2 separate DMA operations.

	; Transfer first DMA page
	call	StartDMAtransferForXTCFwithDmaModeInBL
	jcxz	.ReturnNumberOfSectorsXferred			; One page was enough (128 sectors)
	mov		[bp+DMAVARS.wTotalBytesXferred], cx		; Store total BYTEs transferred so far

	; Get bytes left to transfer for second DMA page
	mov		ax, [bp+DMAVARS.wBytesLeftToXfer]
	sub		ax, cx
	jz		SHORT .ReturnNumberOfSectorsXferred		; Transfer was within 64k page

	; Increment address
	xchg	cx, ax
	add		[bp+DMAVARS.bbbPhysicalAddress], ax
	adc		[bp+DMAVARS.bbbPhysicalAddress+2], bh	; Never sets CF

	; Transfer second DMA page if necessary (always less than 64k)
	call	StartDMAtransferForXTCFwithDmaModeInBL
	add		[bp+DMAVARS.wTotalBytesXferred], cx

.ReturnNumberOfSectorsXferred:
	; Check errors
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_BSY)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
	jc		SHORT .ErrorInTransfer

	; Return number of sectors transferred
	mov		cx, [bp+DMAVARS.wTotalBytesXferred]
	jcxz	.FullPageOf128SectorsXferred
%ifdef USE_186
	shr		cx, 9		; BYTEs to sectors
%else
	xchg	cl, ch		; BYTEs to WORDs
	shr		cx, 1		; WORDs to sectors
%endif
	clc
	ret

.FullPageOf128SectorsXferred:
	mov		cx, 128
	ret

.ErrorInTransfer:
	mov		cx, 0		; No way to know how many sectors got transferred
	ret


;--------------------------------------------------------------------
; StartDMAtransferForXTCFwithDmaModeInBL
;	Parameters:
;		BL:		Byte for DMA Mode Register
;		CX:		Number of BYTEs to transfer
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to DMAVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
StartDMAtransferForXTCFwithDmaModeInBL:
	; Program 8-bit DMA Controller
	; Disable Interrupts and DMA Channel 3 during DMA setup
	cli										; Disable interrupts
	mov		al, SET_CH3_MASK_BIT
	out		MASK_REGISTER_DMA8_out, al		; Disable DMA Channel 3

	; Set DMA Mode (read or write using channel 3)
	mov		al, bl
	out		MODE_REGISTER_DMA8_out, al

	; Set address to DMA controller
	out		CLEAR_FLIPFLOP_DMA8_out, al		; Reset flip-flop to low byte
	mov		ax, [bp+DMAVARS.bbbPhysicalAddress]
	out		BASE_AND_CURRENT_ADDRESS_REGISTER_DMA8_CH3_out, al	; Low byte
	mov		al, ah
	out		BASE_AND_CURRENT_ADDRESS_REGISTER_DMA8_CH3_out, al	; High byte
	mov		al, [bp+DMAVARS.bbbPhysicalAddress+2]
	out		PAGE_DMA8_CH_3, al

	; Set number of bytes to transfer (DMA controller must be programmed number of bytes - 1)
	out		CLEAR_FLIPFLOP_DMA8_out, al		; Reset flip-flop to low byte
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
	mov		dx, [di+DPT.wBasePort]
	add		dl, XTCF_CONTROL_REGISTER
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
	ret
