; File name		:	AH24h_HSetBlocks.asm
; Project name	:	IDE BIOS
; Created date	:	28.12.2009
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=24h, Set Multiple Blocks.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=24h, Set Multiple Blocks.
;
; AH24h_HandlerForSetMultipleBlocks
;	Parameters:
;		AH:		Bios function 24h
;		AL:		Number of Sectors per Block (1, 2, 4, 8, 16, 32, 64 or 128)
;		DL:		Drive number
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH24h_HandlerForSetMultipleBlocks:
	push	dx
	push	cx
	push	bx
	push	ax
	call	AH24h_SetBlockSize
	jmp		Int13h_PopXRegsAndReturn


;--------------------------------------------------------------------
; Sets block size for block mode transfers.
;
; AH24h_SetBlockSize
;	Parameters:
;		AL:		Number of Sectors per Block (1, 2, 4, 8, 16, 32, 64 or 128)
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to DPT
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH24h_SetBlockSize:
	; Select Master or Slave and wait until ready
	mov		bl, al								; Backup block size
	call	FindDPT_ForDriveNumber				; DS:DI now points to DPT
	call	HDrvSel_SelectDriveAndDisableIRQ	; Select drive and wait until ready
	jc		SHORT .Return						; Return if error

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
.Return:
	ret
