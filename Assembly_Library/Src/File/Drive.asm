; Project name	:	Assembly Library
; Description	:	Functions for accessing drives.


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Drive_GetNumberOfAvailableDrivesToAX
;	Parameters:
;		Nothing
;	Returns:
;		AX:		Number of available drives
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Drive_GetNumberOfAvailableDrivesToAX:
	push	dx
	push	cx

	call	Drive_GetFlagsForAvailableDrivesToDXAX
	call	Bit_GetSetCountToCXfromDXAX
	xchg	ax, cx

	pop		cx
	pop		dx
	ret


;--------------------------------------------------------------------
; Drive_GetFlagsForAvailableDrivesToDXAX
;	Parameters:
;		Nothing
;	Returns:
;		DX:AX:	Flags containing valid drives (bit 0 = drive A, bit 1 = drive B ...)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Drive_GetFlagsForAvailableDrivesToDXAX:
	push	cx
	push	bx
	mov		dx, DosCritical_HandlerToIgnoreAllErrors
	call	DosCritical_InstallNewHandlerFromCSDX

	call	.GetNumberOfPotentiallyValidDriveLettersToCX
	xor		bx, bx
	xor		ax, ax				; Temporary use BX:AX for flags
	cwd							; Start from drive 0
	call	.CheckDriveValidityUntilCXisZero
	mov		dx, bx				; Flags now in DX:AX

	call	DosCritical_RestoreDosHandler
	pop		bx
	pop		cx
	ret

;--------------------------------------------------------------------
; .GetNumberOfPotentiallyValidDriveLettersToCX
;	Parameters:
;		Nothing
;	Returns:
;		CX:		Number of potentially valid drive letters available
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetNumberOfPotentiallyValidDriveLettersToCX:
	call	Drive_GetDefaultToAL
	xchg	dx, ax			; Default drive to DL
	call	Drive_SetDefaultFromDL
	eMOVZX	cx, al			; Number of potentially valid drive letters available
	MIN_U	cx, 32
	ret

;--------------------------------------------------------------------
; .CheckDriveValidityUntilCXisZero
;	Parameters:
;		CX:		Number of potentially valid drive letters left
;		DL:		Drive number (00h=A:, 01h=B: ...)
;		BX:AX:	Flags for drive numbers
;	Returns:
;		BX:AX:	Flags for valid drive numbers
;	Corrupts registers:
;		CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.CheckDriveValidityUntilCXisZero:
	call	.IsValidDriveNumberInDL
	jnz		SHORT .PrepareToCheckNextDrive
	call	.SetFlagToBXAXfromDriveInDL
ALIGN JUMP_ALIGN
.PrepareToCheckNextDrive:
	inc		dx
	loop	.CheckDriveValidityUntilCXisZero
	ret

;--------------------------------------------------------------------
; .IsValidDriveNumberInDL
;	Parameters:
;		DL:		Drive number (00h=A:, 01h=B: ...)
;	Returns:
;		ZF:		Set if drive number is valid
;				Cleared if drive number is invalid
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.IsValidDriveNumberInDL:
	push	ds
	push	bx
	push	ax

	inc		dx			; Default drive is 00h and first drive is 01h
	mov		ah, GET_DOS_DRIVE_PARAMETER_BLOCK_FOR_SPECIFIC_DRIVE
	int		DOS_INTERRUPT_21h
	dec		dx
	test	al, al

	pop		ax
	pop		bx
	pop		ds
	ret

;--------------------------------------------------------------------
; .SetFlagToBXAXfromDriveInDL
;	Parameters:
;		DL:		Drive number (0...31)
;		BX:AX:	Flags containing drive numbers
;	Returns:
;		BX:AX:	Flags with wanted drive bit set
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.SetFlagToBXAXfromDriveInDL:
	push	cx

	mov		cl, dl
	xchg	dx, bx
	call	Bit_SetToDXAXfromIndexInCL
	xchg	bx, dx

	pop		cx
	ret


;--------------------------------------------------------------------
; Drive_GetDefaultToAL
;	Parameters:
;		Nothing
;	Returns:
;		AL:		Current default drive (00h=A:, 01h=B: ...)
;	Corrupts registers:
;		AH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Drive_GetDefaultToAL:
	mov		ah, GET_CURRENT_DEFAULT_DRIVE
	SKIP2B	f	; cmp ax, <next instruction>
	; Fall to Drive_SetDefaultFromDL


;--------------------------------------------------------------------
; Drive_SetDefaultFromDL
;	Parameters:
;		DL:		New default drive (00h=A:, 01h=B: ...)
;	Returns:
;		AL:		Number of potentially valid drive letters available
;	Corrupts registers:
;		AH
;--------------------------------------------------------------------
Drive_SetDefaultFromDL:
	mov		ah, SELECT_DEFAULT_DRIVE
	int		DOS_INTERRUPT_21h
	ret
