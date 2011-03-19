; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=24h, Set Multiple Blocks.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=24h, Set Multiple Blocks.
;
; AH24h_HandlerForSetMultipleBlocks
;	Parameters:
;		AL:		Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Parameters on INTPACK in SS:BP:
;		AL:		Number of Sectors per Block (1, 2, 4, 8, 16, 32, 64 or 128)
;	Returns with INTPACK in SS:BP:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH24h_HandlerForSetMultipleBlocks:
%ifndef USE_186
	call	AH24h_SetBlockSize
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%else
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall through to AH24h_SetBlockSize
%endif


;--------------------------------------------------------------------
; Sets block size for block mode transfers.
;
; AH24h_SetBlockSize
;	Parameters:
;		AL:		Number of Sectors per Block (1, 2, 4, 8, 16, 32, 64 or 128)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH24h_SetBlockSize:
	; Select Master or Slave and wait until ready
	mov		bl, al								; Backup block size
	call	HDrvSel_SelectDriveAndDisableIRQ	; Select drive and wait until ready
	jc		SHORT .ReturnWithErrorCodeInAH		; Return if error

	; Output block size and command
	mov		al, bl								; Restore block size to AL
	mov		ah, HCMD_SET_MUL					; Load command to AH
	mov		dx, [RAMVARS.wIdeBase]				; Load base port address
	add		dx, BYTE REG_IDE_CNT
	call	HCommand_OutputSectorCountAndCommand
	call	HStatus_WaitBsyDefTime				; Wait until drive not busy
	jc		SHORT .DisableBlockMode

	; Store new block size to DPT and return
	mov		[di+DPT.bSetBlock], bl				; Store new block size
	xor		ah, ah								; Zero AH and CF since success
	ret
.DisableBlockMode:
	mov		BYTE [di+DPT.bSetBlock], 1			; Disable block mode
.ReturnWithErrorCodeInAH:
	ret
