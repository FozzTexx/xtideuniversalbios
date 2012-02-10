; Project name	:	XTIDE Universal BIOS
; Description	:	Memory mapped IDE Device transfer functions.

; Structure containing variables for PIO transfer functions.
; This struct must not be larger than IDEPACK without INTPACK.
struc MEMPIOVARS
	.wWordsInBlock			resb	2	; 0, Block size in WORDs
	.wWordsLeft				resb	2	; 2, WORDs left to transfer
	.wWordsDone				resb	2	; 4, Number of sectors xferred
	; TODO: The above word vars could just as well be byte vars?
							resb	1	; 6,
							resb	1	; 7, IDEPACK.bDeviceControl
	.fpDPT					resb	4	; 8, Far pointer to DPT
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MemIdeTransfer_StartWithCommandInAL
;	Parameters:
;		AL:		IDE command that was used to start the transfer
;				(all PIO read and write commands including Identify Device)
;		ES:SI:	Ptr to normalized data buffer
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CX:		Number of successfully transferred sectors
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MemIdeTransfer_StartWithCommandInAL:
	push	cs	; We push CS here (segment of SAW) and later pop it to DS (reads) or ES (writes)

	; Initialize MEMPIOVARS
	xor		cx, cx
	mov		[bp+MEMPIOVARS.wWordsDone], cx
	mov		ch, [bp+IDEPACK.bSectorCount]
	mov		[bp+MEMPIOVARS.wWordsLeft], cx
	mov		ch, [di+DPT_ATA.bSetBlock]
	mov		[bp+MEMPIOVARS.wWordsInBlock], cx
	mov		[bp+MEMPIOVARS.fpDPT], di
	mov		[bp+MEMPIOVARS.fpDPT+2], ds

	; Are we reading or writing?
	test	al, 16	; Bit 4 is cleared on all the read commands but set on 3 of the 4 write commands
	jnz		SHORT WriteToSectorAccessWindow
	cmp		al, COMMAND_WRITE_MULTIPLE
	je		SHORT WriteToSectorAccessWindow
	; Fall to ReadFromSectorAccessWindow

;--------------------------------------------------------------------
; ReadFromSectorAccessWindow
;	Parameters:
;		Stack:	Segment part of ptr to Sector Access Window
;		ES:SI:	Normalized ptr to buffer to receive data
;		SS:BP:	Ptr to MEMPIOVARS
;	Returns:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		AH:		BIOS Error code
;		CX:		Number of successfully transferred sectors
;		CF:		0 if transfer succesfull
;				1 if any error
;	Corrupts registers:
;		AL, BX, DX, SI, ES
;--------------------------------------------------------------------
ReadFromSectorAccessWindow:
	pop		ds	; CS -> DS
	mov		di, si
	mov		si, JRIDE_SECTOR_ACCESS_WINDOW_OFFSET

	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	mov		cx, [bp+PIOVARS.wWordsInBlock]

ALIGN JUMP_ALIGN
.ReadNextBlockFromDrive:
	cmp		[bp+PIOVARS.wWordsLeft], cx
	jbe		SHORT .ReadLastBlockFromDrive
	call	ReadSingleBlockFromSectorAccessWindowInDSSItoESDI
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	; Increment number of successfully read WORDs
	mov		cx, [bp+PIOVARS.wWordsInBlock]
	sub		[bp+PIOVARS.wWordsLeft], cx
	add		[bp+PIOVARS.wWordsDone], cx
	jmp		SHORT .ReadNextBlockFromDrive

ALIGN JUMP_ALIGN
.ReadLastBlockFromDrive:
	mov		ch, [bp+PIOVARS.wWordsLeft+1]		; Sectors left
	call	ReadSingleBlockFromSectorAccessWindowInDSSItoESDI

	; Check for errors in last block
CheckErrorsAfterTransferringLastMemoryMappedBlock:
	lds		di, [bp+MEMPIOVARS.fpDPT]			; DPT now in DS:DI
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRDY)
	call	IDEDEVICE%+Wait_PollStatusFlagInBLwithTimeoutInBH

	; Return number of successfully transferred sectors
ReturnWithMemoryIOtransferErrorInAH:
	lds		di, [bp+MEMPIOVARS.fpDPT]			; DPT now in DS:DI
	mov		cx, [bp+PIOVARS.wWordsDone]
	jc		SHORT .ConvertTransferredWordsInCXtoSectors
	add		cx, [bp+PIOVARS.wWordsLeft]			; Never sets CF
.ConvertTransferredWordsInCXtoSectors:
	xchg	cl, ch
	ret


;--------------------------------------------------------------------
; WriteToSectorAccessWindow
;	Parameters:
;		Stack:	Segment part of ptr to Sector Access Window
;		ES:SI:	Normalized ptr to buffer containing data
;		SS:BP:	Ptr to MEMPIOVARS
;	Returns:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		AH:		BIOS Error code
;		CX:		Number of successfully transferred sectors
;		CF:		0 if transfer succesfull
;				1 if any error
;	Corrupts registers:
;		AL, BX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteToSectorAccessWindow:
	push	es
	pop		ds
	pop		es	; CS -> ES
	mov		di, JRIDE_SECTOR_ACCESS_WINDOW_OFFSET

	; Always poll when writing first block (IRQs are generated for following blocks)
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	mov		cx, [bp+PIOVARS.wWordsInBlock]

ALIGN JUMP_ALIGN
.WriteNextBlockToDrive:
	cmp		[bp+PIOVARS.wWordsLeft], cx
	jbe		SHORT .WriteLastBlockToDrive
	call	WriteSingleBlockFromDSSIToSectorAccessWindowInESDI
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	; Increment number of successfully written WORDs
	mov		cx, [bp+PIOVARS.wWordsInBlock]
	sub		[bp+PIOVARS.wWordsLeft], cx
	add		[bp+PIOVARS.wWordsDone], cx
	jmp		SHORT .WriteNextBlockToDrive

ALIGN JUMP_ALIGN
.WriteLastBlockToDrive:
	mov		ch, [bp+PIOVARS.wWordsLeft+1]		; Sectors left
%ifndef USE_186
	mov		bx, CheckErrorsAfterTransferringLastMemoryMappedBlock
	push	bx
%else
	push	CheckErrorsAfterTransferringLastMemoryMappedBlock
%endif
	; Fall to WriteSingleBlockFromDSSIToSectorAccessWindowInESDI

;--------------------------------------------------------------------
; WriteSingleBlockFromDSSIToSectorAccessWindowInESDI
;	Parameters:
;		CH:		Number of sectors in block
;		DS:SI:	Normalized ptr to source buffer
;		ES:DI:	Ptr to Sector Access Window
;	Returns:
;		CX, DX:	Zero
;		SI:		Updated
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteSingleBlockFromDSSIToSectorAccessWindowInESDI:
	mov		bx, di
	eMOVZX	dx, ch
	xor		cl, cl
ALIGN JUMP_ALIGN
.WriteBlock:
	mov		ch, JRIDE_SECTOR_ACCESS_WINDOW_SIZE >> 9
	rep movsw
	mov		di, bx	; Reset for next sector
	dec		dx
	jnz		SHORT .WriteBlock
	ret


;--------------------------------------------------------------------
; ReadSingleBlockFromSectorAccessWindowInDSSItoESDI
;	Parameters:
;		CH:		Number of sectors in block
;		ES:DI:	Normalized ptr to buffer to receive data (destination)
;		DS:SI:	Ptr to Sector Access Window (source)
;	Returns:
;		CX, DX:	Zero
;		DI:		Updated
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadSingleBlockFromSectorAccessWindowInDSSItoESDI:
	mov		bx, si
	eMOVZX	dx, ch
	xor		cl, cl
ALIGN JUMP_ALIGN
.ReadBlock:
	mov		ch, JRIDE_SECTOR_ACCESS_WINDOW_SIZE >> 9
	rep movsw
	mov		si, bx	; Reset for next sector
	dec		dx
	jnz		SHORT .ReadBlock
	ret


;--------------------------------------------------------------------
; WaitUntilReadyToTransferNextBlock
;	Parameters:
;		SS:BP:	Ptr to MEMPIOVARS
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WaitUntilReadyToTransferNextBlock:
	push	ds
	push	di
	lds		di, [bp+MEMPIOVARS.fpDPT]			; DPT now in DS:DI
	call	IDEDEVICE%+Wait_IRQorDRQ			; Always polls
	pop		di
	pop		ds
	ret


%if JRIDE_SECTOR_ACCESS_WINDOW_SIZE <> 512
	%error "JRIDE_SECTOR_ACCESS_WINDOW_SIZE is no longer equal to 512. MemIdeTransfer.asm needs changes."
%endif

