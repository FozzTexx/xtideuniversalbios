; Project name	:	XTIDE Univeral BIOS Configurator
; Description	:	Function for flashing the EEPROM.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Loads old XTIDE Universal BIOS settings from ROM to RAM.
;
; EEPROM_LoadSettingsFromRomToRam
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Flash_CopyCurrentContentsForComparison:
	push	ds
	push	di
	push	si

	call	EEPROM_GetComparisonBufferPointerToDSBX
	push	ds
	pop		es
	mov		di, bx										; Comparison buffer now in ES:DI
	xor		si, si
	mov		ds, [cs:g_cfgVars+CFGVARS.wEepromSegment]	; EEPROM now in DS:SI
	mov		cx, [cs:g_cfgVars+CFGVARS.wEepromSize]
	shr		cx, 1			; Byte count to word count
	cld													; MOVSW to increment DI and SI
	rep movsw

	pop		si
	pop		di
	pop		ds
	ret


;--------------------------------------------------------------------
; Verifies that all data has been written successfully.
;
; Flash_WasDataWriteSuccessful
;	Parameters:
;		Nothing
;	Returns:
;		ZF:		Set if data was written successfully
;				Cleared if write failed
;	Corrupts registers:
;		CX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Flash_WasDataWriteSuccessful:
	push	ds
	push	di
	push	si

	call	EEPROM_GetSourceBufferPointerToDSSI
	call	EEPROM_GetEepromPointerToESDI
	mov		cx, [cs:g_cfgVars+CFGVARS.wEepromSize]
	shr		cx, 1			; Byte count to word count
	cld						; CMPSW to increment SI and DI
	repe cmpsw

	pop		si
	pop		di
	pop		ds
	ret


;--------------------------------------------------------------------
; Writes page of data to EEPROM.
;
; Flash_WritePage
;	Parameters:
;		AX:		SDP command
;		CX:		Page size (1, 2, 4, 8, 16, 32 or 64 bytes)
;		DS:BX:	Ptr to comparison buffer with old EEPROM data
;		DS:SI:	Ptr to source data to write
;		ES:DI:	Ptr to destination EEPROM
;	Returns:
;		BX, SI, DI:	Updated to next page
;		CF:		Cleared if page written successfully
;				Set if polling timeout
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Flash_WritePage:
	call	Flash_DoesPageNeedToBeWritten
	jz		SHORT .ReturnWithoutWriting
	push	bp
	push	cx
	push	ax

	mov		bp, .LoopWritePageBytes	; Return address from SDP command
	cli								; Disable interrupts
	jmp		SHORT Flash_WriteSdpCommand

ALIGN JUMP_ALIGN
.LoopWritePageBytes:
	lodsb							; Load source byte to AL, increment SI
	cmp		al, [bx]				; Trying to write existing data?
	je		SHORT .SkipByte
	inc		bx						; Increment comparison buffer pointer
	mov		ah, al					; Last byte written to AH
	mov		bp, di					; ES:BP points to last byte written
	stosb							; Write source byte to EEPROM, increment DI
	loop	.LoopWritePageBytes
	jmp		SHORT .PageCompleted
ALIGN JUMP_ALIGN
.SkipByte:
	inc		bx
	inc		di
	loop	.LoopWritePageBytes

ALIGN JUMP_ALIGN
.PageCompleted:
	sti								; Enable interrupts
	call	Flash_PollEepromUntilWriteCycleHasCompleted
	pop		ax
	pop		cx
	pop		bp
	ret

ALIGN JUMP_ALIGN
.ReturnWithoutWriting:
	add		bx, cx
	add		si, cx
	add		di, cx
	clc
	ret

;--------------------------------------------------------------------
; Compares source data and comparison buffer.
;
; Flash_DoesPageNeedToBeWritten
;	Parameters:
;		CX:		Page size (1, 2, 4, 8, 16, 32 or 64 bytes)
;		DS:BX:	Ptr to comparison buffer with old EEPROM data
;		DS:SI:	Ptr to source data to write
;	Returns:
;		ZF:		Set if no need to write page
;				Cleared if writing is needed
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Flash_DoesPageNeedToBeWritten:
	push	es
	push	di
	push	si
	push	cx

	push	ds
	pop		es
	mov		di, bx				; ES:DI now points to comparison buffer
	cld							; CMPSB to increment SI and DI
	repe cmpsb

	pop		cx
	pop		si
	pop		di
	pop		es
	ret


;--------------------------------------------------------------------
; Writes Software Data Protection command to EEPROM.
;
; Flash_WriteSdpCommand
;	Parameters:
;		AX:		SDP command
;		BP:		Return address
;		ES:		Segment to EEPROM
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Flash_WriteSdpCommand:
	cmp		ax, CMD_SDP_ENABLE
	je		SHORT Flash_WriteSdpEnableCommand
	cmp		ax, CMD_SDP_DISABLE
	je		SHORT Flash_WriteSdpDisableCommand
	jmp		bp

ALIGN JUMP_ALIGN
Flash_WriteSdpEnableCommand:
	mov		BYTE [es:1555h], 0AAh	; Write AAh to address 1555h
	mov		BYTE [es:0AAAh], 55h	; Write 55h to address 0AAAh
	mov		BYTE [es:1555h], 0A0h	; Write A0h to address 1555h
	jmp		bp

ALIGN JUMP_ALIGN
Flash_WriteSdpDisableCommand:
	mov		BYTE [es:1555h], 0AAh	; Write AAh to address 1555h
	mov		BYTE [es:0AAAh], 55h	; Write 55h to address 0AAAh
	mov		BYTE [es:1555h], 80h	; Write 80h to address 1555h
	mov		BYTE [es:1555h], 0AAh	; Write AAh to address 1555h
	mov		BYTE [es:0AAAh], 55h	; Write 55h to address 0AAAh
	mov		BYTE [es:1555h], 20h	; Write 20h to address 1555h
	jmp		bp


;--------------------------------------------------------------------
; Polls EEPROM until write cycle ends.
;
; Flash_PollEepromUntilWriteCycleHasCompleted
;	Parameters:
;		AH:		Last byte written
;		ES:BP:	Ptr to EEPROM last write location
;	Returns:
;		CF:		Cleared if polling successful
;				Set if polling timeout
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Flash_PollEepromUntilWriteCycleHasCompleted:
	call	Flash_InitializePollingTimeout
ALIGN JUMP_ALIGN
.PollLoop:
	mov		al, [es:bp]				; Load byte from EEPROM
	and		ax, 8080h				; Clear all but bit 7 from both bytes
	cmp		al, ah					; Same bytes?
	je		SHORT .Return
	call	Flash_UpdatePollingTimeout
	jnc		SHORT .PollLoop			; Not timeout
ALIGN JUMP_ALIGN
.Return:
	ret

;--------------------------------------------------------------------
; Initializes timeout counter. Timeouts are implemented using system
; timer ticks. First tick might take 0...54.9ms and remaining ticks
; will occur at 54.9ms intervals. Use delay of two (or more) ticks to
; ensure at least 54.9ms wait.
;
; Flash_InitializePollingTimeout
;	Parameters:
;		Nothing
;	Returns:
;		CX:		Timeout end time for Flash_UpdatePollingTimeout
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Flash_InitializePollingTimeout:
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, cx
	mov		cx, CNT_TMEOUT_POLL
	add		cx, [BDA.dwTimerTicks]		; CX = End time
	pop		ds
	sti									; Enable interrupts
	ret

;--------------------------------------------------------------------
; Updates timeout counter. Timeout counter can be
; initialized with Flash_InitializePollingTimeout.
;
; Flash_UpdatePollingTimeout
;	Parameters:
;		CX:		Timeout end time
;	Returns:
;		CF:		Set if timeout
;				Cleared if time left
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Flash_UpdatePollingTimeout:
	push	ds
	push	ax
	LOAD_BDA_SEGMENT_TO	ds, ax
	cmp		cx, [BDA.dwTimerTicks]		; Timeout?
	pop		ax
	pop		ds
	je		SHORT .ReturnTimeout
	clc
	ret
.ReturnTimeout:
	stc
	ret
