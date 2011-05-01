; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device transfer functions.

; Structure containing variables for PIO transfer functions.
; This struct must not be larger than IDEPACK without INTPACK.
struc PIOVARS
	.wBlocksLeft			resb	2
	.wBlockSize				resb	2	; Block size in WORDs (256...32768)
	.wDataPort				resb	2
	.bSectorsInLastBlock:	resb	1
							resb	1	; Offset 7 = IDEPACK.bDeviceControl
	.fnXfer					resb	2	; Offset to transfer function
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeTransfer_StartWithCommandInAL
;	Parameters:
;		AL:		IDE command that was used to start the transfer
;		ES:SI:	Ptr to destination buffer or source data
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeTransfer_StartWithCommandInAL:
	mov		ah, [bp+IDEPACK.bSectorCountHighExt]

	; Are we reading or writing
	cmp		al, COMMAND_WRITE_MULTIPLE
	je		SHORT .PrepareToWriteDataFromESSI
	cmp		al, COMMAND_WRITE_MULTIPLE_EXT
	je		SHORT .PrepareToWriteDataFromESSI
	cmp		al, COMMAND_WRITE_SECTORS
	je		SHORT .PrepareToWriteDataFromESSI
	cmp		al, COMMAND_WRITE_SECTORS_EXT
	je		SHORT .PrepareToWriteDataFromESSI

	; Prepare to read data to ESSI
	mov		bx, g_rgfnPioRead
	mov		al, [bp+IDEPACK.bSectorCount]
	call	InitializePiovarsInSSBPwithSectorCountInAX
	xchg	si, di
	call	Registers_NormalizeESDI
	jmp		SHORT ReadFromDrive

ALIGN JUMP_ALIGN
.PrepareToWriteDataFromESSI:
	mov		bx, g_rgfnPioWrite
	mov		al, [bp+IDEPACK.bSectorCount]
	call	InitializePiovarsInSSBPwithSectorCountInAX
	call	Registers_NormalizeESSI
	; Fall to WriteToDrive


;--------------------------------------------------------------------
; WriteToDrive
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		ES:SI:	Normalized ptr to buffer containing data
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if transfer succesfull
;				1 if any error
;	Corrupts registers:
;		AL, BX, CX, DX, SI, ES
;--------------------------------------------------------------------
WriteToDrive:
	; Always poll when writing first block (IRQs are generated for following blocks)
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
	jc		SHORT .ReturnWithTransferErrorInAH
ALIGN JUMP_ALIGN
.WriteNextBlock:
	mov		dx, [bp+PIOVARS.wDataPort]
	dec		WORD [bp+PIOVARS.wBlocksLeft]		; Transferring last (possibly partial) block?
	jz		SHORT .XferLastBlock				;  If so, jump to transfer
	mov		cx, [bp+PIOVARS.wBlockSize]			; Load block size in WORDs
	call	[bp+PIOVARS.fnXfer]					; Transfer full block

	; Normalize pointer when necessary
	mov		ax, si
	shr		ax, 1								; WORD offset
	add		ax, [bp+PIOVARS.wBlockSize]
	jns		SHORT .WaitUntilReadyToTransferNextBlock
	call	Registers_NormalizeESSI

ALIGN JUMP_ALIGN
.WaitUntilReadyToTransferNextBlock:
%ifdef USE_186
	push	.WriteNextBlock
	jmp		IdeWait_IRQorDRQ
%else
	call	IdeWait_IRQorDRQ
	jnc		SHORT .WriteNextBlock
%endif
.ReturnWithTransferErrorInAH:
	ret

ALIGN JUMP_ALIGN
.XferLastBlock:
	xor		cx, cx
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRDY)
	mov		ch, [bp+PIOVARS.bSectorsInLastBlock]; CX = Partial block size in WORDs
%ifdef USE_186
	push	IdeWait_IRQorStatusFlagInBLwithTimeoutInBH
	jmp		[bp+PIOVARS.fnXfer]
%else
	call	[bp+PIOVARS.fnXfer]					; Transfer possibly partial block
	jmp		IdeWait_IRQorStatusFlagInBLwithTimeoutInBH	; Check for errors
%endif


;--------------------------------------------------------------------
; ReadFromDrive
;	Parameters:
;		ES:DI:	Normalized ptr to buffer to recieve data
;		DS:SI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		AH:		BIOS Error code
;		CF:		0 if transfer succesfull
;				1 if any error
;	Corrupts registers:
;		AL, BX, CX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadFromDrive:
	; Wait until drive is ready to transfer
	xchg	di, si								; DS:DI now points DPT
	call	IdeWait_IRQorDRQ					; Wait until ready to transfer
	jc		SHORT WriteToDrive.ReturnWithTransferErrorInAH
	xchg	si, di								; ES:DI now points buffer

	; Transfer full or last (possible partial) block
	mov		dx, [bp+PIOVARS.wDataPort]
	dec		WORD [bp+PIOVARS.wBlocksLeft]
	jz		SHORT .XferLastBlock
	mov		cx, [bp+PIOVARS.wBlockSize]			; Load block size in WORDs
	call	[bp+PIOVARS.fnXfer]					; Transfer full block

	; Normalize pointer when necessary
	mov		ax, di
	shr		ax, 1								; WORD offset
	add		ax, [bp+PIOVARS.wBlockSize]
	jns		SHORT ReadFromDrive
	call	Registers_NormalizeESDI
	jmp		SHORT ReadFromDrive					; Loop while blocks left

ALIGN JUMP_ALIGN
.XferLastBlock:
	xor		cx, cx
	mov		ch, [bp+PIOVARS.bSectorsInLastBlock]; CX = Partial block size in WORDs
	call	[bp+PIOVARS.fnXfer]					; Transfer possibly partial block
	mov		di, si								; DS:DI now points DPT
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRDY)
	jmp		IdeWait_PollStatusFlagInBLwithTimeoutInBH


;--------------------------------------------------------------------
; InitializePiovarsInSSBPwithSectorCountInAX
;	Parameters:
;		AX:		Number of sectors to transfer (0=65536)
;		BX:		Offset to transfer function lookup table
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
InitializePiovarsInSSBPwithSectorCountInAX:
	; Store number of blocks to transfer
	eMOVZX	cx, BYTE [di+DPT_ATA.bSetBlock]		; Block size in sectors
	xor		dx, dx
	test	ax, ax
	eCMOVZ	dl, 1		; DX:AX = Sectors to transfer (1...65536)
	div		cx			; AX = Full blocks to transfer
	test	dx, dx
	mov		dh, cl		; DH = Full block size if no partial blocks to transfer
	jz		SHORT .NoPartialBlocksToTransfer
	inc		ax			; Partial block
	mov		dh, dl		; DH = Size of partial block in sectors
.NoPartialBlocksToTransfer:
	mov		[bp+PIOVARS.wBlocksLeft], ax
	mov		[bp+PIOVARS.bSectorsInLastBlock], dh

	; Store block size in WORDs
	xchg	ch, cl		; CX = Block size in WORDs
	mov		[bp+PIOVARS.wBlockSize], cx

	; Get transfer function based on bus type
	xchg	ax, bx
	eMOVZX	bx, BYTE [di+DPT.bIdevarsOffset]	; CS:BX now points to IDEVARS
	mov		dx, [cs:bx+IDEVARS.wPort]			; Load IDE Data port address
	mov		bl, [cs:bx+IDEVARS.bDevice]			; Load device type to BX
	add		bx, ax
	mov		ax, [cs:bx]							; Load offset to transfer function
	mov		[bp+PIOVARS.wDataPort], dx
	mov		[bp+PIOVARS.fnXfer], ax
	ret


;--------------------------------------------------------------------
; DualByteReadForXtide		Dual port 8-bit XTIDE PIO read transfer
; SingleByteRead			Single port 8-bit PIO read transfer
; WordReadForXTIDEmod		8088/8086 compatible 16-bit IDE PIO read transfer
; WordReadForXTplusAndAT	Normal 16-bit IDE PIO read transfer
; DWordRead					VLB/PCI 32-bit IDE PIO read transfer
;	Parameters:
;		CX:		Block size in WORDs
;		DX:		IDE Data port address
;		ES:DI:	Normalized ptr to buffer to recieve data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DualByteReadForXtide:
	times 2	shr	cx, 1	; Loop unrolling
	mov		bx, 8		; Bit mask for toggling data low/high reg
ALIGN JUMP_ALIGN
.InswLoop:
	XTIDE_INSW
	XTIDE_INSW
	XTIDE_INSW
	XTIDE_INSW
	loop	.InswLoop
	ret

;----
ALIGN JUMP_ALIGN
SingleByteRead:
%ifdef USE_186	; INS instruction available
	shl		cx, 1		; WORD count to BYTE count
	rep insb
%else			; If 8088/8086
	shr		cx, 1		; WORD count to DWORD count
ALIGN JUMP_ALIGN
.InsdLoop:
	in		al, dx
	stosb				; Store to [ES:DI]
	in		al, dx
	stosb
	in		al, dx
	stosb
	in		al, dx
	stosb
	loop	.InsdLoop
%endif
	ret

;----
%ifndef USE_186
ALIGN JUMP_ALIGN
WordReadForXTIDEmod:
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

;----
ALIGN JUMP_ALIGN
WordReadForXTplusAndAT:
	rep
	db		6Dh			; INSW (we want this in XT build)
	ret

;----
ALIGN JUMP_ALIGN
DWordRead:
	shr		cx, 1		; WORD count to DWORD count
	rep
	db		66h			; Override operand size to 32-bit
	db		6Dh			; INSW/INSD
	ret


;--------------------------------------------------------------------
; DualByteWriteForXtide		Dual port 8-bit XTIDE PIO write transfer
; SingleByteWrite			Single port 8-bit PIO write transfer
; WordWriteForXTIDEmod		8088/8086 compatible 16-bit IDE PIO read transfer
; WordWrite					Normal 16-bit IDE PIO write transfer
; DWordWrite				VLB/PCI 32-bit IDE PIO write transfer
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
DualByteWriteForXtide:
	push	ds
	push	bx
	times 2	shr	cx, 1	; Loop unrolling
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

;----
ALIGN JUMP_ALIGN
SingleByteWrite:
%ifdef USE_186	; OUTS instruction available
	shl		cx, 1		; WORD count to BYTE count
	eSEG	es			; Source is ES segment
	rep outsb
%else			; If 8088/8086
	shr		cx, 1		; WORD count to DWORD count
	push	ds			; Store DS
	push	es			; Copy ES...
	pop		ds			; ...to DS
ALIGN JUMP_ALIGN
.OutsdLoop:
	lodsb				; Load from [DS:SI] to AL
	out		dx, al
	lodsb
	out		dx, al
	lodsb
	out		dx, al
	lodsb
	out		dx, al
	loop	.OutsdLoop
	pop		ds			; Restore DS
%endif
	ret

;---
ALIGN JUMP_ALIGN
WordWriteForXTIDEmod:
	push	ds
	times 2	shr	cx, 1	; Loop unrolling
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

;----
ALIGN JUMP_ALIGN
WordWrite:
	eSEG	es			; Source is ES segment
	rep
	db		6Fh			; OUTSW
	ret

ALIGN JUMP_ALIGN
DWordWrite:
	shr		cx, 1		; WORD count to DWORD count
	eSEG	es			; Source is ES segment
	rep
	db		66h			; Override operand size to 32-bit
	db		6Fh			; OUTSW/OUTSD
	ret



; Lookup tables to get transfer function based on bus type
ALIGN WORD_ALIGN
g_rgfnPioRead:
	dw		DualByteReadForXtide	; DEVICE_8BIT_DUAL_PORT_XTIDE
%ifdef USE_186
	dw		WordReadForXTplusAndAT	; DEVICE_XTIDE_WITH_REVERSED_A3_AND_A0
%else
	dw		WordReadForXTIDEmod
%endif
	dw		SingleByteRead			; DEVICE_8BIT_SINGLE_PORT
	dw		WordReadForXTplusAndAT	; DEVICE_16BIT_ATA
	dw		DWordRead				; DEVICE_32BIT_ATA

g_rgfnPioWrite:
	dw		DualByteWriteForXtide	; DEVICE_8BIT_DUAL_PORT_XTIDE
	dw		WordWriteForXTIDEmod	; DEVICE_XTIDE_WITH_REVERSED_A3_AND_A0
	dw		SingleByteWrite			; DEVICE_8BIT_SINGLE_PORT
	dw		WordWrite				; DEVICE_16BIT_ATA
	dw		DWordWrite				; DEVICE_32BIT_ATA
