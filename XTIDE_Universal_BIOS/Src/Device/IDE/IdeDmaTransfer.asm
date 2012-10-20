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
	.wTotalWordsXferred			resb	2	; 0-1, 
	.wBytesLeftToXferLessOne	resb	2	; 2-3, 
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
	mov		[bp+DMAVARS.wTotalWordsXferred], cx
	mov		ch, [bp+IDEPACK.bSectorCount]	; CX = WORDs to transfer
	shl		cx, 1							; WORDs to BYTEs, 0 = 65536
	dec		cx
	mov		[bp+DMAVARS.wBytesLeftToXferLessOne], cx

	; Convert Segment:Offset type pointer to physical address
	xor		bx, bx
	mov		cx, es
%rep 4
	shl	cx, 1
	rcl	bx, 1
%endrep
	add		cx, si
	adc		bl, bh
	mov		[bp+DMAVARS.bbbPhysicalAddress], cx
	mov		[bp+DMAVARS.bbbPhysicalAddress+2], bl

	; Calculate bytes for first page - 1
	neg		cx	; Max number of bytes for first page, 0 = 65536
	dec		cx
	MIN_U	cx, [bp+DMAVARS.wBytesLeftToXferLessOne]

	; Are we reading or writing?
	test	al, 16	; Bit 4 is cleared on all the read commands but set on 3 of the 4 write commands
	jnz		SHORT WriteBlockToXTCF
	cmp		al, COMMAND_WRITE_MULTIPLE
	je		SHORT WriteBlockToXTCF
	; Fall to ReadBlockFromXTCF


;--------------------------------------------------------------------
; ReadBlockFromXTCF
;	Parameters:
;		CX:		Bytes in first page - 1
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
ReadBlockFromXTCF:
	; 8-bit DMA transfers must be done withing 64k physical page.
	; We support maximum of 128 sectors (65536 bytes) per one INT 13h call
	; so we might need to separate transfer to 2 separate DMA operations.

	; Transfer first DMA page
	mov		ah, CHANNEL_3 | WRITE | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE
	call	StartDMAtransferForXTCFwithDmaModeInAH
	jc		SHORT ReturnNumberOfSectorsXferred

	; Transfer second DMA page if necessary (always less than 64k)
	call	UpdateVariablesForSecondPageIfRequired
	jc		SHORT SecondDmaPageIsNotRequired
	mov		ah, CHANNEL_3 | WRITE | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE
	call	StartDMAtransferForXTCFwithDmaModeInAH
	jc		SHORT ReturnNumberOfSectorsXferred
	; Fall to BothDmaPagesTransferredSuccessfully

BothDmaPagesTransferredSuccessfully:
	inc		cx			; Never overflows since second page always less than 64k
	shr		cx, 1		; BYTEs to WORDs
	add		[bp+DMAVARS.wTotalWordsXferred], cx
SecondDmaPageIsNotRequired:
	xor		ah, ah
ReturnNumberOfSectorsXferred:
	mov		cx, [bp+DMAVARS.wTotalWordsXferred]
	xchg	cl, ch		; WORDs to sectors
	ret


;--------------------------------------------------------------------
; WriteBlockToXTCF
;	Parameters:
;		CX:		Bytes in first page - 1
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
WriteBlockToXTCF:
	; Transfer first DMA page
	mov		ah, CHANNEL_3 | READ | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE
	call	StartDMAtransferForXTCFwithDmaModeInAH
	jc		SHORT ReturnNumberOfSectorsXferred

	; Transfer second DMA page if necessary (always less than 64k)
	call	UpdateVariablesForSecondPageIfRequired
	jc		SHORT SecondDmaPageIsNotRequired
	mov		ah, CHANNEL_3 | READ | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE
	call	StartDMAtransferForXTCFwithDmaModeInAH
	jc		SHORT ReturnNumberOfSectorsXferred
	jmp		SHORT BothDmaPagesTransferredSuccessfully


;--------------------------------------------------------------------
; StartDMAtransferForXTCFwithDmaModeInAH
;	Parameters:
;		AH:		Byte for DMA Mode Register
;		CX:		Number of BYTEs to transfer - 1
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if transfer successful
;				1 if any error
;	Corrupts registers:
;		AL, BX, DX
;--------------------------------------------------------------------
StartDMAtransferForXTCFwithDmaModeInAH:
	push	cx

	; Program 8-bit DMA Controller

	; Disable Interrupts and DMA Channel 3 during DMA setup
	cli										; Disable interrupts
	mov		al, SET_CH3_MASK_BIT
	out		MASK_REGISTER_DMA8_out, al		; Disable DMA Channel 3

	; Set DMA Mode (read or write using channel 3)
	mov		al, ah
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
	out		BASE_AND_CURRENT_COUNT_REGISTER_DMA8_CH3_out, al	; Low byte
	mov		al, ah
	out		BASE_AND_CURRENT_COUNT_REGISTER_DMA8_CH3_out, al	; High byte

	; Enable DMA Channel 3
	mov		al, CLEAR_CH3_MASK_BIT
	out		MASK_REGISTER_DMA8_out, al		; Enable DMA Channel 3
	sti										; Enable interrupts


	; XT-CFv2 will present data in 16-byte blocks, but byte count may not
	; be divisable by 16 due to boundary crossing.  So catch any < 16-byte
	; block by adding 15, then dividing bytes (in CX) by 16 to get the
	; total block requests.  The 8237 is programmed with the actual byte
	; count and will end the transfer by asserting TC when done.
	xor		ax, ax
	add		cx, BYTE 1 + 15		; Number of BYTEs to xfer + 15
	adc		al, ah
	shr		ax, 1
	rcr		cx, 1
	eSHR_IM	cx, 3				; CX = Number of 16 byte blocks
	mov		dx, [di+DPT.wBasePort]
	add		dl, XTCF_CONTROL_REGISTER

.MoreToDo:						; at this point, cx must be >0
	mov		al, 0x40			; 0x40 = Raise DRQ and clear XT-CFv2 transfer counter
.NextDemandBlock:
	out		dx, al				; get up to 16 bytes from XT-CF card
	loop	.NextDemandBlock	; decrement CX and loop if <> 0
								; (Loop provides a wait-state between 16-byte blocks; do not unroll)

.CleanUp:
	; check the transfer is actually done - in case another DMA operation messed things up
	inc		cx										; set up CX, in case we need to do an extra iteration
	in		al, STATUS_REGISTER_DMA8_in				; get DMA status register
	test	al, FLG_CH3_HAS_REACHED_TERMINAL_COUNT	; test DMA ch.3 TC bit
	jz		SHORT .MoreToDo							; it wasn't set so get more bytes

.EndDMA:
	mov		al, 0x10			; 
	out		dx, al				; set back to DMA enabled status

	; Check IDE Status Register for errors
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_BSY)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
	pop		cx
	ret


;--------------------------------------------------------------------
; UpdateVariablesForSecondPageIfRequired
;	Parameters:
;		CX:		Number of BYTEs in first page - 1
;		SS:BP:	Ptr to DMAVARS
;	Returns:
;		CX:		Bytes left to transfer - 1 (if CF = 0)
;		CF:		0 if second DMA transfer required
;				1 if one DMA transfer was enough
;	Corrupts registers:
;		AX, (CX)
;--------------------------------------------------------------------
UpdateVariablesForSecondPageIfRequired:
	inc		cx							; BYTEs in first page
	jcxz	.FullPageXferred			; 0 = 65536

	; Store total WORDs transferred so far
	mov		ax, cx
	shr		ax, 1						; BYTEs to WORDs
	mov		[bp+DMAVARS.wTotalWordsXferred], ax

	; Get bytes left to transfer for second DMA page
	mov		ax, [bp+DMAVARS.wBytesLeftToXferLessOne]
	sub		ax, cx
	jb		SHORT .OnePageWasEnough

	; Increment address
	add		[bp+DMAVARS.bbbPhysicalAddress], cx
	adc		BYTE [bp+DMAVARS.bbbPhysicalAddress+2], 0	; Never sets CF
	xchg	cx, ax
	ret

.FullPageXferred:
	mov		WORD [bp+DMAVARS.wTotalWordsXferred], 65536 / 2
	stc
.OnePageWasEnough:
	ret
