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
	call	UpdateVariablesForSecondPageIfRequired
	jc		SHORT ReturnNumberOfSectorsXferred		; Second page not needed

	; Transfer second DMA page if necessary (always less than 64k)
	mov		ah, CHANNEL_3 | WRITE | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE
	call	StartDMAtransferForXTCFwithDmaModeInAH
	; Fall to BothDmaPagesTransferred

BothDmaPagesTransferred:
	inc		cx			; Never overflows since second page always less than 64k
	shr		cx, 1		; BYTEs to WORDs
	add		[bp+DMAVARS.wTotalWordsXferred], cx
ReturnNumberOfSectorsXferred:
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_BSY)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
	jc		SHORT .ErrorInTransfer
	mov		cx, [bp+DMAVARS.wTotalWordsXferred]
	xchg	cl, ch		; WORDs to sectors
	ret

.ErrorInTransfer:
	mov		cx, 0		; No way to know how many bytes got xferred
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
ALIGN JUMP_ALIGN
WriteBlockToXTCF:
	; Transfer first DMA page
	mov		ah, CHANNEL_3 | READ | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE
	call	StartDMAtransferForXTCFwithDmaModeInAH
	call	UpdateVariablesForSecondPageIfRequired
	jc		SHORT ReturnNumberOfSectorsXferred		; Second page not needed

	; Transfer second DMA page if necessary (always less than 64k)
	mov		ah, CHANNEL_3 | READ | AUTOINIT_DISABLE | ADDRESS_INCREMENT | DEMAND_MODE
	call	StartDMAtransferForXTCFwithDmaModeInAH
	jmp		SHORT BothDmaPagesTransferred


;--------------------------------------------------------------------
; StartDMAtransferForXTCFwithDmaModeInAH
;	Parameters:
;		AH:		Byte for DMA Mode Register
;		CX:		Number of BYTEs to transfer - 1
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
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
	add		cx, BYTE 1 + 15		; Number of BYTEs to xfer + 15 (bit 16 in CF)
	rcr		cx, 1
	eSHR_IM	cx, 3				; CX = Number of 16 byte blocks
	mov		dx, [di+DPT.wBasePort]
	add		dl, XTCF_CONTROL_REGISTER

.MoreToDo:						; at this point, cx must be >0
	mov		al, 40h				; 0x40 = Raise DRQ and clear XT-CFv2 transfer counter
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
	mov		al, 10h				; 
	out		dx, al				; set back to DMA enabled status
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
ALIGN JUMP_ALIGN
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




%if 0
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadBlockFromXTCF:
;	Parameters:
;		CX:		Block size in 512 byte sectors (1..64)
;		DX:		IDE Data port address
;		ES:DI:		Normalized ptr to buffer to receive data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX

	; use config register to see what we're doing:
	; < A0 = DMA via ch.3
	; > A0 = mem-mapped IO (word-length)
	; 
	
	or		dl, 0x1f	; XT-CF board control register address (base + 1fh)
	in		al, dx		; get control register
	cmp		al, 0xA0	; test al against 0xA0:
	jae	.MemMapIO		; - use memory-mapped IO if >=A0h
	or		al, al		; test al against 0 (quicker than cmp):
	jz	.PortIO			; - use port-based IO (the default) if it was zero
					; otherwise, 0 < al < A0h, so fall to DMA mode

.DMAIO:
	; work out how much we're transferring.  We can't cross a physical 64KB boundary
	; but since the max transfer size is 64KB, we only ever need to do one or two DMA operations
	
	; first, normalise the pointer - we need ES to be a physical page address 
	
	mov		ax, es
	mov		ch, cl			; max sectors is 128; also sectors << 8 = words, and we need cl...
	mov		cl, 4			; ... for the rotate parameter
	rol		ax, cl			; ax = es rol 4
	mov		bx, ax			; bx = ax = es rol 4
	and		al, 0xf0		; ax (15..4) now has es (11..0)
	and		bx, 0x000f		; bx (3..0) now has es (15..12)
	add		di, ax			; add offset portion of es (in ax) to di...
	adc		bl, 0			; ... and if it overflowed, increment bl
	mov		es, bx			; es now has physical segment address >> 12

	; now check how much we can transfer without crossing a physical page boundary
	mov		bx, di			; 
	not		bx			; 65535 - di = number of bytes we could transfer -1 now in bx
	xor		cl, cl			; zero cl; cx now has transfer size in words
	shl		cx, 1			; words to bytes; CX has total byte count
	dec		cx			; calling DMA with 0 implies 1 byte transferred (so max is 64k exactly)
	cmp		bx, cx			; can we do it in one hit?
	jae	.LastDMA

	; at this point, the (bytes-1) for this transfer are in bx, total byte count -1 in cx
	; and we need to do 2 DMA operations as the buffer straddles a physical 64k boundary
	
	sub		cx, bx			; cx has bytes for 2nd transfer (as (x-1)-(y-1) = x-y)
	dec		cx			; cx has bytes-1 for 2nd transfer
	xchg		bx, cx			; bx = bytes-1 for 2nd transfer; cx = bytes-1 for this transfer
	mov		ah, 0x07		; request a read DMA transfer
	call	DemandBasedTransferWithBytesInCX

	; DMA 1 of 2 done - set up registers for second transfer
	mov		cx, bx			; bytes-1 for the 2nd transfer back in cx
	; 1st transfer is done, now for the second
ALIGN JUMP_ALIGN
.LastDMA:
	; at this point, (bytes-1) for this transfer are in CX
	mov		ah, 0x07		; request a read DMA transfer
	call	DemandBasedTransferWithBytesInCX

	; transfer is done, set ES back to a physical segment address
	mov		ax, es			; 
	mov		cl, 4			; 
	ror		ax, cl			; ax = es ror 4.  Since ES was >> 12 (for DMA controller) so
	mov		es, ax			; now it's back to normal format
	
	; pointer format restored - we're done
	and		dl, 0xE0		; restore register values
	ret


;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteBlockToXTCF:
	; use config register to see what we're doing:
	; 0 = not set; use byte-length port-IO
	; < A0 = DMA via ch.3
	; > A0 = mem-mapped IO (word-length)
	; 
	
	or		dl, 0x1f	; XT-CF board control register address (base + 1fh)
	in		al, dx		; get control register
	cmp		al, 0xA0	; test al against 0xA0:
	jae	.MemMapIO		; - use memory-mapped IO if >=A0h
	or		al, al		; test al against 0 (quicker than cmp):
	jz	.PortIO			; - use port-based IO (the default) if it was zero
					; otherwise, 0 < al < A0h, so fall to DMA mode

.DMAIO:
	; work out how much we're transferring.  We can't cross a physical 64KB boundary
	; but since the max transfer size is 64KB, we only ever need to do one or two DMA operations

	push		di			; save di...
	mov		di, si			; ...and move si to di (for DMA routine)
	
	; first, normalise the pointer - we need ES to be a physical page address 
	
	mov		ax, es
	mov		ch, cl			; max sectors is 64; also sectors << 8 = words, and we need cl...
	mov		cl, 4			; ... for the rotate parameter
	rol		ax, cl			; ax = es rol 4
	mov		bx, ax			; bx = ax = es rol 4
	and		al, 0xf0		; ax (15..4) now has es (11..0)
	and		bx, 0x000f		; bx (3..0) now has es (15..12)
	add		di, ax			; add offset portion of es (in ax) to si...
	adc		bl, 0			; ... and if it overflowed, increment bl
	mov		es, bx			; es now has physical segment address >> 12

	; now check how much we can transfer without crossing a physical page boundary
	mov		bx, di			; 
	not		bx			; 65535 - di = number of bytes we could transfer -1 now in bx
	xor		cl, cl			; zero cl; cx now has transfer size in words
	shl		cx, 1			; words to bytes; CX has total byte count
	dec		cx			; calling DMA with 0 implies 1 byte transferred (so max is 64k exactly)
	cmp		bx, cx			; can we do it in one hit?
	jae	.LastDMA

	; at this point, the (bytes-1) for this transfer are in bx, total byte count -1 in cx
	; and we need to do 2 DMA operations as the buffer straddles a physical 64k boundary
	
	sub		cx, bx			; cx has bytes for 2nd transfer (as (x-1)-(y-1) = x-y)
	dec		cx			; cx has bytes-1 for 2nd transfer
	xchg		bx, cx			; bx = bytes-1 for 2nd transfer; cx = bytes-1 for this transfer
	mov		ah, 0x0b		; request a write DMA transfer
	call	DemandBasedTransferWithBytesInCX

	; DMA 1 of 2 done - set up registers for second transfer
	mov		cx, bx			; bytes-1 for the 2nd transfer back in cx
	; 1st transfer is done, now for the second
ALIGN JUMP_ALIGN
.LastDMA:
	; at this point, (bytes-1) for this transfer are in CX
	mov		ah, 0x0b		; request a write DMA transfer
	call	DemandBasedTransferWithBytesInCX

	; transfer is done, set ES back to a physical segment address
	mov		ax, es			; 
	mov		cl, 4			; 
	ror		ax, cl			; ax = es ror 4.  Since ES was >> 12 (for DMA controller) so
	mov		es, ax			; now it's back to normal format

	mov		si, di			; move di (used by DMA routine) back to si
	
	; pointers updated - we're done
	pop		di			; 
	and		dl, 0xE0		; restore register values
	ret


; -------------------------------------------------------------------------------------------------------------
; 
; DemandBasedTransferWithBytesInCX
; ================================
; 
; DMA Transfer function:
; - AH = 0x07 for read from media - demand/inc/non-auto-init/write(to memory)/ch3
; - AH = 0x0b for write to media  - demand/inc/non-auto-init/read(from memory)/ch3
; - byte count -1 in CX
; - XT-CF control register in DX
; - physical segment address in ES *but* high four bits in low four bits (i.e. shr 12)
; - buffer offset (from physical segment) in DI
;
; Note - cannot cross a physical segment boundary, but ES will be updated (maintaining the >>12
;        format) if after the last byte has been transferred the pointer needs to be updated to
;        the next physical segment.
; 
; Preserves:	BX, DX
; Corrupts: 	AX, CX
; Updates: 	ES, DI
; 
; -------------------------------------------------------------------------------------------------------------

ALIGN JUMP_ALIGN
DemandBasedTransferWithBytesInCX:
	cli					; clear interrupts while we set up the actual DMA transfer
	mov		al, 0x07		; mask (4) + channel (3)
	out		0x0a, al		; send to DMA mask register
	mov		al, ah			; retrieve the transfer mode passed in...
	out		0x0b, al		; and send mode to DMA mode register
	out		0x0c, al		; clear DMA byte-order flip-flop (write any value)
	mov		ax, di			; di has buffer offset
	out		0x06, al		; 
	mov		al, ah			; 
	out		0x06, al		; send offset to DMA controller address port for ch.3
	mov		ax, es			; es has physical segment address >> 12
	out		0x82, al		; send the relavent 4-bits to DMA controller page for ch.3
	out		0x0c, al		; clear DMA byte-order flip-flop (write any value)
	mov		ax, cx			; byte count to AX
	out		0x07, al		; send low-byte of transfer size in bytes...
	mov		al, ah			; mov high byte to low byte...
	out		0x07, al		; ...and high byte to DMA controller count port for ch.3
	mov		al, 0x03		; clear bit mask (0) + channel (3)
	out		0x0a, al		; send to DMA mask register - enable the DMA!
	sti					; enable interrutps; let the CPU see to anything outstanding

	mov		ax, es			; update ES:DI (values have been loaded into DMA controller)
	inc		cx			; CX back to actual bytes
	add		di, cx			; add bytes to DI...
	adc		ax, 0			; ...and if it overflowed, increment...
	mov		es, ax			; ...ES

	add		cx, 15			; XT-CFv2 will present data in 16-byte blocks, but byte count may not
	shr		cx, 1			; be divisable by 16 due to boundary crossing.  So catch any < 16-byte
	shr		cx, 1			; block by adding 15, then dividing bytes (in CX) by 16 to get the
	shr		cx, 1			; total block requests.  The 8237 is programmed with the actual byte
	shr		cx, 1			; count and will end the transfer by asserting TC when done.

.MoreToDo:					; at this point, cx must be >0
	mov		al, 0x40		; 0x40 = Raise DRQ and clear XT-CFv2 transfer counter
.NextDemandBlock:
	out		dx, al			; get up to 16 bytes from XT-CF card
	loop	.NextDemandBlock		; decrement CX and loop if <> 0
						; (Loop provides a wait-state between 16-byte blocks; do not unroll)
.CleanUp:
	; check the transfer is actually done - in case another DMA operation messed things up
	inc		cx			; set up CX, in case we need to do an extra iteration
	in		al, 0x08		; get DMA status register
	and		al, 0x08		; test DMA ch.3 TC bit
	jz	.MoreToDo			; it wasn't set so get more bytes
.EndDMA:
	mov		al, 0x10		; 
	out		dx, al			; set back to DMA enabled status
	ret
	
%endif ; 0



