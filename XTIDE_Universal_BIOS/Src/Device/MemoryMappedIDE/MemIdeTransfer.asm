; Project name	:	XTIDE Universal BIOS
; Description	:	Memory mapped IDE Device transfer functions.

; Structure containing variables for PIO transfer functions.
; This struct must not be larger than IDEPACK without INTPACK.
struc MEMPIOVARS
	.wWordsInBlock			resb	2	; 0, Block size in WORDs
	.wWordsLeft				resb	2	; 2, WORDs left to transfer
	.wWordsDone				resb	2	; 4, Number of sectors xferred
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
	; Initialize MEMPIOVARS
	xchg	cx, ax								; IDE command to CL
	xor		al, al
	mov		ah, [bp+IDEPACK.bSectorCount]
	mov		[bp+MEMPIOVARS.wWordsLeft], ax
	cbw
	mov		[bp+MEMPIOVARS.wWordsDone], ax		; Zero
	mov		ah, [di+DPT_ATA.bSetBlock]
	mov		[bp+MEMPIOVARS.wWordsInBlock], ax
	mov		[bp+MEMPIOVARS.fpDPT], di
	mov		[bp+MEMPIOVARS.fpDPT+2], ds

	; Are we reading or writing?
	test	cl, 16	; Bit 4 is cleared on all the read commands but set on 3 of the 4 write commands
	jnz		SHORT .PrepareToWriteDataFromESSI
	cmp		cl, COMMAND_WRITE_MULTIPLE
	je		SHORT .PrepareToWriteDataFromESSI

	; Prepare to read data to ES:DI
	mov		di, si
	push	cs
	pop		ds
	mov		si, JRIDE_SECTOR_ACCESS_WINDOW_OFFSET
	jmp		SHORT ReadFromSectorAccessWindowInDSSItoESDI

ALIGN JUMP_ALIGN
.PrepareToWriteDataFromESSI:
	push	es
	pop		ds
	push	cs
	pop		es
	mov		di, JRIDE_SECTOR_ACCESS_WINDOW_OFFSET
	; Fall to WriteToSectorAccessWindowInESDIfromDSSI


;--------------------------------------------------------------------
; WriteToSectorAccessWindowInESDIfromDSSI
;	Parameters:
;		DS:SI:	Normalized ptr to buffer containing data
;		ES:DI:	Ptr to Sector Access Window
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
WriteToSectorAccessWindowInESDIfromDSSI:
	; Always poll when writing first block (IRQs are generated for following blocks)
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

ALIGN JUMP_ALIGN
.WriteNextBlockToDrive:
	mov		cx, [bp+PIOVARS.wWordsInBlock]
	cmp		[bp+PIOVARS.wWordsLeft], cx
	jbe		SHORT .WriteLastBlockToDrive
	eMOVZX	dx, ch								; DX = Sectors in block
	call	WriteSingleBlockFromDSSIToSectorAccessWindowInESDI
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	; Increment number of successfully written WORDs
	mov		ax, [bp+PIOVARS.wWordsInBlock]
	sub		[bp+PIOVARS.wWordsLeft], ax
	add		[bp+PIOVARS.wWordsDone], ax
	jmp		SHORT .WriteNextBlockToDrive

ALIGN JUMP_ALIGN
.WriteLastBlockToDrive:
	eMOVZX	dx, BYTE [bp+PIOVARS.wWordsLeft+1]	; Sectors left
%ifdef USE_186
	push	CheckErrorsAfterTransferringLastMemoryMappedBlock
	jmp		WriteSingleBlockFromDSSIToSectorAccessWindowInESDI
%else
	call	WriteSingleBlockFromDSSIToSectorAccessWindowInESDI
	jmp		SHORT CheckErrorsAfterTransferringLastMemoryMappedBlock
%endif


;--------------------------------------------------------------------
; WriteSingleBlockFromDSSIToSectorAccessWindowInESDI
;	Parameters:
;		DX:		Number of sectors in block
;		DS:SI:	Normalized ptr to source buffer
;		ES:DI:	Ptr to Sector Access Window
;	Returns:
;		CX, DX:	Zero
;		SI:		Updated
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteSingleBlockFromDSSIToSectorAccessWindowInESDI:
	mov		cx, JRIDE_SECTOR_ACCESS_WINDOW_SIZE / 2
	rep movsw
	sub		di, JRIDE_SECTOR_ACCESS_WINDOW_SIZE	; Reset for next sector
	dec		dx
	jnz		SHORT WriteSingleBlockFromDSSIToSectorAccessWindowInESDI
	ret


;--------------------------------------------------------------------
; ReadFromSectorAccessWindowInDSSItoESDI
;	Parameters:
;		ES:DI:	Normalized ptr to buffer to recieve data
;		DS:SI:	Ptr to Sector Access Window
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
ReadFromSectorAccessWindowInDSSItoESDI:
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

ALIGN JUMP_ALIGN
.ReadNextBlockFromDrive:
	mov		cx, [bp+PIOVARS.wWordsInBlock]
	cmp		[bp+PIOVARS.wWordsLeft], cx
	jbe		SHORT .ReadLastBlockFromDrive
	eMOVZX	dx, ch								; DX = Sectors in block
	call	ReadSingleBlockFromSectorAccessWindowInDSSItoESDI
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	; Increment number of successfully read WORDs
	mov		ax, [bp+PIOVARS.wWordsInBlock]
	sub		[bp+PIOVARS.wWordsLeft], ax
	add		[bp+PIOVARS.wWordsDone], ax
	jmp		SHORT .ReadNextBlockFromDrive

ALIGN JUMP_ALIGN
.ReadLastBlockFromDrive:
	eMOVZX	dx, BYTE [bp+PIOVARS.wWordsLeft+1]	; Sectors left
	call	ReadSingleBlockFromSectorAccessWindowInDSSItoESDI

	; Check for errors in last block
CheckErrorsAfterTransferringLastMemoryMappedBlock:
	lds		di, [bp+MEMPIOVARS.fpDPT]			; DPT now in DS:DI
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRDY)
	call	IDEDEVICE%+Wait_PollStatusFlagInBLwithTimeoutInBH

	; Return number of successfully read sectors
ReturnWithMemoryIOtransferErrorInAH:
	lds		di, [bp+MEMPIOVARS.fpDPT]			; DPT now in DS:DI
	mov		cx, [bp+PIOVARS.wWordsDone]
	jc		SHORT .ConvertTransferredWordsInCXtoSectors
	add		cx, [bp+PIOVARS.wWordsLeft]			; Never sets CF
.ConvertTransferredWordsInCXtoSectors:
	xchg	cl, ch
	ret


;--------------------------------------------------------------------
; ReadSingleBlockFromSectorAccessWindowInDSSItoESDI
;	Parameters:
;		DX:		Number of sectors in block
;		ES:DI:	Normalized ptr to buffer to recieve data (destination)
;		DS:SI:	Ptr to Sector Access Window (source)
;	Returns:
;		CX, DX:	Zero
;		DI:		Updated
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadSingleBlockFromSectorAccessWindowInDSSItoESDI:
	mov		cx, JRIDE_SECTOR_ACCESS_WINDOW_SIZE / 2
	rep movsw
	sub		si, JRIDE_SECTOR_ACCESS_WINDOW_SIZE	; Reset for next sector
	dec		dx
	jnz		SHORT ReadSingleBlockFromSectorAccessWindowInDSSItoESDI
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
