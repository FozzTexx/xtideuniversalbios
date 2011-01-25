; Project name	:	IDE BIOS
; Description	:	PIO transfer functions.

; Structure containing variables for PIO transfer functions
struc PIOVARS, -6
	.fnXfer			resb	2	; Offset to transfer function
	.wBlockSize		resb	2	; Block size in WORDs
	.wWordsLeft		resb	2	; Number of WORDs left to transfer
								; (full sectors, can be partial block)
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Normalizes far pointer to that offset overflows won't happen
; when transferring data using PIO.
;
; HPIO_NORMALIZE_PTR
;	Parameters:
;		%1:%2:		Far pointer to normalize
;		%3:			Scratch register
;		%4:			Scratch register
;	Returns:
;		%1:%2:		Normalized far pointer
;	Corrupts registers:
;		%3, %4
;--------------------------------------------------------------------
%macro HPIO_NORMALIZE_PTR 4
	mov		%4, %2				; Copy offset to scratch reg
	and		%2, BYTE 0Fh		; Clear offset bits 15...4
	eSHR_IM	%4, 4				; Divide offset by 16
	mov		%3, %1				; Copy segment to scratch reg
	add		%3, %4				; Add shifted offset to segment
	mov		%1, %3				; Set normalized segment
%endmacro


;--------------------------------------------------------------------
; Reads sectors from hard disk using PIO transfer mode.
;
; HPIO_ReadBlock
;	Parameters:
;		AL:		Number of sectors to read (1...255)
;		ES:BX:	Pointer to buffer to recieve data
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if transfer succesfull
;				1 if any error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HPIO_ReadBlock:
	push	es

	; Create PIOVARS to stack
	eENTER	PIOVARS_size, 0

	push	si
	mov		si, g_rgfnPioRead				; Offset to read function lookup
	call	HPIO_InitializePIOVARS			; Store word count and block size
	pop		si

	; Start to read data
	xchg	bx, di							; DS:BX points DPT, ES:DI points buffer
	mov		dx, [RAMVARS.wIdeBase]			; Load IDE Base Port address
	call	HPIO_ReadFromDrive

	; Destroy stack frame
	eLEAVE
	mov		di, bx							; Restore DI
	pop		es
	ret


;--------------------------------------------------------------------
; Initializes PIOVARS members.
;
; HPIO_InitializePIOVARS
;	Parameters:
;		AL:		Number of sectors to transfer (1...255)
;		SI:		Offset to transfer function lookup table
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:BX:	Ptr to source or destination data buffer
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		ES:BX:	Normalized pointer to data buffer
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HPIO_InitializePIOVARS:
	; Store number of WORDs to transfer
	mov		ah, al								; Number of WORDs to transfer...
	xor		al, al								; ...to AX
	mov		[bp+PIOVARS.wWordsLeft], ax			; Store WORD count

	; Store block size in WORDs
	mov		ah, [di+DPT.bSetBlock]				; AX = block size in WORDs
	mov		[bp+PIOVARS.wBlockSize], ax			; Store block size

	; Get transfer function based on bus type
	xchg	ax, bx								; Backup BX
	eMOVZX	bx, BYTE [di+DPT.bIdeOff]			; CS:BX now points to IDEVARS
	mov		bl, BYTE [cs:bx+IDEVARS.bBusType]	; Load bus type to BX
	mov		bx, [cs:bx+si]						; Load offset to transfer function
	mov		[bp+PIOVARS.fnXfer], bx				; Store offset to transfer function
	xchg	bx, ax
	; Fall to HPIO_NormalizePtr

;--------------------------------------------------------------------
; Initializes PIOVARS members.
;
; HPIO_InitializePIOVARS
;	Parameters:
;		ES:BX:	Ptr to source or destination data buffer
;	Returns:
;		ES:BX:	Normalized pointer to data buffer
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
HPIO_NormalizeDataPointer:
	HPIO_NORMALIZE_PTR	es, bx, ax, cx
	ret


;--------------------------------------------------------------------
; Reads blocks using PIO transfers.
;
; HPIO_ReadFromDrive
;	Parameters:
;		DX:		IDE Data port address
;		DS:BX:	Ptr to DPT (in RAMVARS segment)
;		ES:DI:	Normalized ptr to buffer to recieve data
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if transfer succesfull
;				1 if any error
;	Corrupts registers:
;		AL, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HPIO_ReadFromDrive:
	cld									; INS to increment DI
ALIGN JUMP_ALIGN
.BlockLoop:
	call	HStatus_WaitIrqOrDrq		; Wait until ready to transfer
	jc		SHORT HPIO_WriteToDrive.RetError	; Return if error (code in AH)
	mov		cx, [bp+PIOVARS.wBlockSize]	; Load block size
	sub		[bp+PIOVARS.wWordsLeft], cx	; Transferring last (possibly partial) block?
	jbe		SHORT .XferLastBlock		;  If so, jump to transfer
	call	[bp+PIOVARS.fnXfer]			; Transfer full block
	jmp		SHORT .BlockLoop			; Loop while blocks left
ALIGN JUMP_ALIGN
.XferLastBlock:
	add		cx, [bp+PIOVARS.wWordsLeft]	; CX to partial block size
	call	[bp+PIOVARS.fnXfer]			; Transfer possibly partial block
	jmp		HStatus_WaitBsyDefTime		; Check for errors


;--------------------------------------------------------------------
; Writes sectors to hard disk using PIO transfer mode.
;
; HPIO_WriteBlock
;	Parameters:
;		AL:		Number of sectors to write (1...255)
;		ES:BX:	Pointer to buffer containing data
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if transfer successfull
;				1 if any error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HPIO_WriteBlock:
	push	es
	push	si

	; Create PIOVARS to stack
	eENTER	PIOVARS_size, 0

	mov		si, g_rgfnPioWrite				; Offset to write function lookup
	call	HPIO_InitializePIOVARS			; Store word count and block size

	; Prepare pointers and start transfer
	mov		si, bx							; ES:SI now points source buffer
	mov		bx, di							; DS:BX now points DPT
	call	HPIO_WriteToDrive

	; Destroy stack frame
	eLEAVE

	pop		si
	pop		es
	ret


;--------------------------------------------------------------------
; Writes blocks using PIO transfers.
;
; HPIO_WriteToDrive
;	Parameters:
;		DS:BX:	Ptr to DPT (in RAMVARS segment)
;		ES:SI:	Normalized ptr to buffer containing data
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if transfer succesfull
;				1 if any error
;	Corrupts registers:
;		AL, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HPIO_WriteToDrive:
	cld										; OUTS to increment SI
	call	HStatus_WaitDrqDefTime			; Always poll DRQ for first block, get status reg to DX
	jc		SHORT .RetError					; Return if error (code in AH)
	sub		dx, BYTE REGR_IDE_ST			; DX to Data Port address
ALIGN JUMP_ALIGN
.BlockLoop:
	mov		cx, [bp+PIOVARS.wBlockSize]		; Load block size
	sub		[bp+PIOVARS.wWordsLeft], cx		; Transferring last (possibly partial) block?
	jbe		SHORT .XferLastBlock			;  If so, jump to transfer
	call	[bp+PIOVARS.fnXfer]				; Transfer full block
	call	HStatus_WaitIrqOrDrq			; Wait until ready to transfer
	jnc		SHORT .BlockLoop				; If no error, loop while blocks left
.RetError:
	ret										; This ret is shared with HPIO_ReadFromDrive
ALIGN JUMP_ALIGN
.XferLastBlock:
	add		cx, [bp+PIOVARS.wWordsLeft]		; CX to partial block size
	call	[bp+PIOVARS.fnXfer]				; Transfer possibly partial block
	jmp		HStatus_WaitIrqOrRdy			; Check for errors


;--------------------------------------------------------------------
; Bus specific transfer functions and lookup table.
;
; HPIO_DualByteRead		Dual port 8-bit XTIDE PIO read transfer
; HPIO_WordRead			Normal 16-bit IDE PIO read transfer
; HPIO_DualByteWrite	Dual port 8-bit XTIDE PIO write transfer
; HPIO_WordWrite		Normal 16-bit IDE PIO write transfer
;	Parameters:
;		CX:		Block size in WORDs
;		DX:		IDE Data port address
;		ES:DI:	Normalized ptr to buffer to recieve data (read only)
;		ES:SI:	Normalized ptr to buffer containing data (write only)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HPIO_DualByteRead:
	eREP_DUAL_BYTE_PORT_INSW
	ret
ALIGN JUMP_ALIGN
HPIO_WordRead:
	rep
	db		6Dh			; INSW
	ret
ALIGN JUMP_ALIGN
HPIO_DWordRead:
	shr		cx, 1		; WORD count to DWORD count
	rep
	db		66h			; Override operand size to 32-bit
	db		6Dh			; INSW/INSD
	ret
ALIGN JUMP_ALIGN
HPIO_SingleByteRead:
	eREP_SINGLE_BYTE_PORT_INSW
	ret

ALIGN JUMP_ALIGN
HPIO_DualByteWrite:
	eREP_DUAL_BYTE_PORT_OUTSW
	ret
ALIGN JUMP_ALIGN
HPIO_WordWrite:
	eSEG	es			; Source is ES segment
	rep
	db		6Fh			; OUTSW
	ret
ALIGN JUMP_ALIGN
HPIO_DWordWrite:
	shr		cx, 1		; WORD count to DWORD count
	eSEG	es			; Source is ES segment
	rep
	db		66h			; Override operand size to 32-bit
	db		6Fh			; OUTSW/OUTSD
	ret
ALIGN JUMP_ALIGN
HPIO_SingleByteWrite:
	eREP_SINGLE_BYTE_PORT_OUTSW
	ret

ALIGN WORD_ALIGN
g_rgfnPioRead:
	dw		HPIO_DualByteRead		; 8-bit dual port reads
	dw		HPIO_WordRead			; 16-bit reads
	dw		HPIO_DWordRead			; 32-bit reads
	dw		HPIO_SingleByteRead		; 8-bit single port reads
g_rgfnPioWrite:
	dw		HPIO_DualByteWrite		; 8-bit dual port writes
	dw		HPIO_WordWrite			; 16-bit writes
	dw		HPIO_DWordWrite			; 32-bit writes
	dw		HPIO_SingleByteWrite	; 8-bit single port writes
