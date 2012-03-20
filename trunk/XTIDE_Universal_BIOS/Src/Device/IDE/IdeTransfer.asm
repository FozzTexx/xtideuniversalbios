; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device transfer functions.

; Structure containing variables for PIO transfer functions.
; This struct must not be larger than IDEPACK without INTPACK.
struc PIOVARS
	.wWordsInBlock			resb	2	; 0, Block size in WORDs
	.wWordsLeft				resb	2	; 2, WORDs left to transfer
	.wWordsDone				resb	2	; 4, Number of sectors xferred
							resb	1	; 6,
							resb	1	; 7, IDEPACK.bDeviceControl
	.wDataPort				resb	2	; 8, IDE Data Port
	.fnXfer					resb	2	; 10, Offset to transfer function
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeTransfer_StartWithCommandInAL
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
IdeTransfer_StartWithCommandInAL:
	; Are we reading or writing?
	test	al, 16	; Bit 4 is cleared on all the read commands but set on 3 of the 4 write commands
	mov		ah, [bp+IDEPACK.bSectorCount]
	jnz		SHORT WriteToDrive
	cmp		al, COMMAND_WRITE_MULTIPLE
	je		SHORT WriteToDrive
	; Fall to ReadFromDrive

;--------------------------------------------------------------------
; ReadFromDrive
;	Parameters:
;		AH:		Number of sectors to transfer (1...128)
;		ES:SI:	Normalized ptr to buffer to receive data
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		AH:		BIOS Error code
;		CX:		Number of successfully transferred sectors
;		CF:		0 if transfer successful
;				1 if any error
;	Corrupts registers:
;		AL, BX, DX, SI, ES
;--------------------------------------------------------------------
ReadFromDrive:
	; Prepare to read data to ESSI
	mov		bx, g_rgfnPioRead
	call	InitializePiovarsInSSBPwithSectorCountInAH

	; Wait until drive is ready to transfer
	call	IdeWait_IRQorDRQ					; Wait until ready to transfer
	jc		SHORT ReturnWithTransferErrorInAH
	xchg	si, di								; ES:DI now points buffer

	mov		cx, [bp+PIOVARS.wWordsInBlock]

ALIGN JUMP_ALIGN
.ReadNextBlockFromDrive:
	mov		dx, [bp+PIOVARS.wDataPort]
	cmp		[bp+PIOVARS.wWordsLeft], cx
	jbe		SHORT .ReadLastBlockFromDrive
	call	[bp+PIOVARS.fnXfer]

	; Wait until ready for next block and check for errors
	xchg	di, si								; DS:DI now points DPT
	call	IdeWait_IRQorDRQ					; Wait until ready to transfer
	jc		SHORT ReturnWithTransferErrorInAH
	xchg	si, di								; ES:DI now points buffer

	; Increment number of successfully read WORDs
	mov		cx, [bp+PIOVARS.wWordsInBlock]
	sub		[bp+PIOVARS.wWordsLeft], cx
	add		[bp+PIOVARS.wWordsDone], cx
	jmp		SHORT .ReadNextBlockFromDrive

ALIGN JUMP_ALIGN
.ReadLastBlockFromDrive:
	mov		cx, [bp+PIOVARS.wWordsLeft]
	call	[bp+PIOVARS.fnXfer]					; Transfer possibly partial block

	; Check for errors in last block
	mov		di, si								; DS:DI now points DPT
CheckErrorsAfterTransferringLastBlock:
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRDY)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH

	; Return number of successfully read sectors
ReturnWithTransferErrorInAH:
	mov		cx, [bp+PIOVARS.wWordsDone]
	jc		SHORT .ConvertTransferredWordsInCXtoSectors
	add		cx, [bp+PIOVARS.wWordsLeft]			; Never sets CF
.ConvertTransferredWordsInCXtoSectors:
	xchg	cl, ch
	ret


;--------------------------------------------------------------------
; WriteToDrive
;	Parameters:
;		AH:		Number of sectors to transfer (1...128)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		ES:SI:	Normalized ptr to buffer containing data
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		AH:		BIOS Error code
;		CX:		Number of successfully transferred sectors
;		CF:		0 if transfer successful
;				1 if any error
;	Corrupts registers:
;		AL, BX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteToDrive:
	; Prepare to write data from ESSI
	mov		bx, g_rgfnPioWrite
	call	InitializePiovarsInSSBPwithSectorCountInAH

	; Always poll when writing first block (IRQs are generated for following blocks)
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
	jc		SHORT ReturnWithTransferErrorInAH

	mov		cx, [bp+PIOVARS.wWordsInBlock]

ALIGN JUMP_ALIGN
.WriteNextBlockToDrive:
	mov		dx, [bp+PIOVARS.wDataPort]
	cmp		[bp+PIOVARS.wWordsLeft], cx
	jbe		SHORT .WriteLastBlockToDrive
	call	[bp+PIOVARS.fnXfer]

	; Wait until ready for next block and check for errors
	call	IdeWait_IRQorDRQ					; Wait until ready to transfer
	jc		SHORT ReturnWithTransferErrorInAH

	; Increment number of successfully written WORDs
	mov		cx, [bp+PIOVARS.wWordsInBlock]
	sub		[bp+PIOVARS.wWordsLeft], cx
	add		[bp+PIOVARS.wWordsDone], cx
	jmp		SHORT .WriteNextBlockToDrive

ALIGN JUMP_ALIGN
.WriteLastBlockToDrive:
	mov		cx, [bp+PIOVARS.wWordsLeft]
%ifdef USE_186
	push	CheckErrorsAfterTransferringLastBlock
	jmp		[bp+PIOVARS.fnXfer]					; Transfer possibly partial block
%else
	call	[bp+PIOVARS.fnXfer]					; Transfer possibly partial block
	jmp		SHORT CheckErrorsAfterTransferringLastBlock
%endif


;--------------------------------------------------------------------
; InitializePiovarsInSSBPwithSectorCountInAH
;	Parameters:
;		AH:		Number of sectors to transfer (1...128)
;		BX:		Offset to transfer function lookup table
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
InitializePiovarsInSSBPwithSectorCountInAH:
	; Store sizes
	xor		al, al
	mov		[bp+PIOVARS.wWordsLeft], ax
	mov		ah, [di+DPT_ATA.bSetBlock]
	mov		[bp+PIOVARS.wWordsInBlock], ax
	cbw
	mov		[bp+PIOVARS.wWordsDone], ax			; Zero

	; Get transfer function based on bus type
	xchg	ax, bx								; Lookup table offset to AX
	mov		bl, [di+DPT.bIdevarsOffset]			; CS:BX now points to IDEVARS
	mov		dx, [cs:bx+IDEVARS.wPort]			; Load IDE Data port address
	mov		bl, [cs:bx+IDEVARS.bDevice]			; Load device type to BX
	add		bx, ax
	mov		[bp+PIOVARS.wDataPort], dx
	mov		ax, [cs:bx]							; Load offset to transfer function
	mov		[bp+PIOVARS.fnXfer], ax
	ret


;--------------------------------------------------------------------
; ReadBlockFromXtideRev1		XTIDE rev 1
; ReadBlockFromXtideRev2		XTIDE rev 2 or rev 1 with swapped A0 and A3 (chuck-mod)
; ReadBlockFrom16bitDataPort	Normal 16-bit IDE
; ReadBlockFrom32bitDataPort	VLB/PCI 32-bit IDE
;	Parameters:
;		CX:		Block size in WORDs
;		DX:		IDE Data port address
;		ES:DI:	Normalized ptr to buffer to receive data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadBlockFromXtideRev1:
	eSHR_IM	cx, 2		; Loop unrolling
	mov		bx, 8		; Bit mask for toggling data low/high reg
ALIGN JUMP_ALIGN
.InswLoop:
	XTIDE_INSW
	XTIDE_INSW
	XTIDE_INSW
	XTIDE_INSW
	loop	.InswLoop
	ret

;--------------------------------------------------------------------
%ifndef USE_186			; 8086/8088 compatible WORD read
ALIGN JUMP_ALIGN
ReadBlockFromXtideRev2:
	times 2 shr	cx, 1	; WORD count to QWORD count
ALIGN JUMP_ALIGN
.ReadNextQword:
	in		ax, dx		; Read 1st WORD
	stosw				; Store 1st WORD to [ES:DI]
	in		ax, dx
	stosw				; 2nd
	in		ax, dx
	stosw				; 3rd
	in		ax, dx
	stosw				; 4th
	loop	.ReadNextQword
	ret
%endif

;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadBlockFrom16bitDataPort:
	rep
	db		6Dh			; INSW (we want this in XT build)
	ret

;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadBlockFrom32bitDataPort:
	shr		cx, 1		; WORD count to DWORD count
	rep
	db		66h			; Override operand size to 32-bit
	db		6Dh			; INSW/INSD
	ret


;--------------------------------------------------------------------
; WriteBlockToXtideRev1			XTIDE rev 1
; WriteBlockToXtideRev2			XTIDE rev 2 or rev 1 with swapped A0 and A3 (chuck-mod)
; WriteBlockToFastXtide			Fast XTIDE (CPLD v2 project)
; WriteBlockTo16bitDataPort		Normal 16-bit IDE
; WriteBlockTo32bitDataPort		VLB/PCI 32-bit IDE
;	Parameters:
;		CX:		Block size in WORDs
;		DX:		IDE Data port address
;		ES:SI:	Normalized ptr to buffer containing data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteBlockToXtideRev1:
	push	ds
	push	bx
	eSHR_IM	cx, 2		; Loop unrolling
	mov		bx, 8		; Bit mask for toggling data low/high reg
	push	es			; Copy ES...
	pop		ds			; ...to DS
ALIGN JUMP_ALIGN
.OutswLoop:
	XTIDE_OUTSW
	XTIDE_OUTSW
	XTIDE_OUTSW
	XTIDE_OUTSW
	loop	.OutswLoop
	pop		bx
	pop		ds
	ret

;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteBlockToXtideRev2:
	push	ds
	eSHR_IM	cx, 2		; Loop unrolling
	push	es			; Copy ES...
	pop		ds			; ...to DS
ALIGN JUMP_ALIGN
.WriteNextQword:
	XTIDE_MOD_OUTSW
	XTIDE_MOD_OUTSW
	XTIDE_MOD_OUTSW
	XTIDE_MOD_OUTSW
	loop	.WriteNextQword
	pop		ds
	ret

;--------------------------------------------------------------------
%ifndef USE_186			; 8086/8088 compatible WORD write
ALIGN JUMP_ALIGN
WriteBlockToFastXtide:
	times 2 shr	cx, 1	; WORD count to QWORD count
	push	ds
	push	es
	pop		ds
ALIGN JUMP_ALIGN
.ReadNextQword:
	lodsw				; Load 1st WORD from [DS:SI]
	out		dx, ax		; Write 1st WORD
	lodsw
	out		dx, ax		; 2nd
	lodsw
	out		dx, ax		; 3rd
	lodsw
	out		dx, ax		; 4th
	loop	.ReadNextQword
	pop		ds
	ret
%endif

;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteBlockTo16bitDataPort:
	es					; Source is ES segment
	rep
	db		6Fh			; OUTSW (we want this in XT build)
	ret

;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteBlockTo32bitDataPort:
	shr		cx, 1		; WORD count to DWORD count
	es					; Source is ES segment
	rep
	db		66h			; Override operand size to 32-bit
	db		6Fh			; OUTSW/OUTSD
	ret



; Lookup tables to get transfer function based on bus type
ALIGN WORD_ALIGN
g_rgfnPioRead:
	dw		ReadBlockFromXtideRev1		; DEVICE_XTIDE_REV1
%ifdef USE_186
	dw		ReadBlockFrom16bitDataPort	; DEVICE_XTIDE_REV2
	dw		ReadBlockFrom16bitDataPort	; DEVICE_FAST_XTIDE
%else
	dw		ReadBlockFromXtideRev2		; DEVICE_XTIDE_REV2
	dw		ReadBlockFromXtideRev2		; DEVICE_FAST_XTIDE
%endif
	dw		ReadBlockFrom16bitDataPort	; DEVICE_16BIT_ATA
	dw		ReadBlockFrom32bitDataPort	; DEVICE_32BIT_ATA

g_rgfnPioWrite:
	dw		WriteBlockToXtideRev1		; DEVICE_XTIDE_REV1
	dw		WriteBlockToXtideRev2		; DEVICE_XTIDE_REV2
%ifdef USE_186
	dw		WriteBlockTo16bitDataPort	; DEVICE_FAST_XTIDE
%else
	dw		WriteBlockToFastXtide		; DEVICE_FAST_XTIDE
%endif
	dw		WriteBlockTo16bitDataPort	; DEVICE_16BIT_ATA
	dw		WriteBlockTo32bitDataPort	; DEVICE_32BIT_ATA
