; File name		:	AH0h_HReset.asm
; Project name	:	IDE BIOS
; Created date	:	27.9.2007
; Last update	:	1.7.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=0h, Disk Controller Reset.

RETRIES_IF_RESET_FAILS		EQU		3
TIMEOUT_BEFORE_RESET_RETRY	EQU		5		; System timer ticks

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=0h, Disk Controller Reset.
;
; AH0h_HandlerForDiskControllerReset
;	Parameters:
;		AH:		Bios function 0h
;		DL:		Drive number (ignored so all drives are reset)
;				If bit 7 is set all hard disks and floppy disks reset.
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		Int 13h return status (from drive requested in DL)
;		CF:		0 if succesfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_HandlerForDiskControllerReset:
	push	dx
	push	cx
	push	bx
	push	ax

	eMOVZX	bx, dl						; Copy requested drive to BL, zero BH to assume no errors
	call	AH0h_ResetFloppyDrivesWithInt40h
	test	bl, 80h						; Reset hard disks too?
	jz		SHORT .Return
	call	AH0h_ResetForeignHardDisks
	call	AH0h_ResetAllOurControllers
ALIGN JUMP_ALIGN
.Return:
	mov		ah, bh						; Copy error code to AH
	xor		al, al						; Zero AL...
	sub		al, ah						; ...and set CF if error
	jmp		Int13h_PopXRegsAndReturn


;--------------------------------------------------------------------
; AH0h_ResetFloppyDrivesWithInt40h
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DL:		Drive number
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, DL
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
AH0h_ResetFloppyDrivesWithInt40h:
	xor		ax, ax						; Disk Controller Reset
	and		dl, 7Fh						; Clear bit 7
	int		INTV_FLOPPY_FUNC
	jmp		SHORT AH0h_BackupErrorCodeFromTheRequestedDriveToBH


;--------------------------------------------------------------------
; AH0h_ResetForeignHardDisks
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:		RAMVARS segment
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, DL
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
AH0h_ResetForeignHardDisks:
	mov		cl, [RAMVARS.bFirstDrv]		; Load number of first our drive
	and		cx, BYTE 7Fh				; CX = number of drives to reset
	jz		SHORT .Return
	mov		dl, 80h						; Start resetting from drive 80h
ALIGN JUMP_ALIGN
.DriveResetLoop:
	mov		ah, 0Dh						; Reset Hard Disk (Alternate reset)
	pushf								; Push flags to simulate INT
	cli									; Disable interrupts since INT does that
	call	FAR [RAMVARS.fpOldI13h]
	sti									; Make sure interrupts are enabled again (some BIOSes fails to enable it)
	call	AH0h_BackupErrorCodeFromTheRequestedDriveToBH
	inc		dx							; Next drive to reset
	loop	.DriveResetLoop
ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; AH0h_ResetAllOurControllers
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:		RAMVARS segment
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_ResetAllOurControllers:
	push	si
	mov		si, ROMVARS.ideVars0			; Load offset to first IDEVARS
	call	Initialize_GetIdeControllerCountToCX
ALIGN JUMP_ALIGN
.ResetLoop:
	call	AH0h_ResetIdevarsControllerMasterAndSlaveDrives
	add		si, BYTE IDEVARS_size
	loop	.ResetLoop
.Return:
	pop		si
	ret


;--------------------------------------------------------------------
; AH0h_ResetIdevarsControllerMasterAndSlaveDrives
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		CS:SI:	Ptr to IDEVARS
;		DS:		RAMVARS segment
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_ResetIdevarsControllerMasterAndSlaveDrives:
	mov		dx, [cs:si+IDEVARS.wPort]
	call	FindDPT_ForIdeMasterAtPort		; Find master drive to DL
	jc		SHORT AH0h_ResetMasterAndSlaveDriveWithRetries
	call	FindDPT_ForIdeSlaveAtPort		; Find slave if master not present
	jc		SHORT AH0h_ResetMasterAndSlaveDriveWithRetries
	ret

;--------------------------------------------------------------------
; AH0h_ResetMasterAndSlaveDriveWithRetries
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DL:		Drive number for master or slave drive
;		DS:		RAMVARS segment
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_ResetMasterAndSlaveDriveWithRetries:
	push	dx
	push	cx
	push	bx
	mov		di, RETRIES_IF_RESET_FAILS
ALIGN JUMP_ALIGN
.RetryLoop:
	call	AHDh_ResetDrive
	jnc		SHORT .Return				; Jump if successful
	mov		cx, TIMEOUT_BEFORE_RESET_RETRY
	call	SoftDelay_TimerTicks
	dec		di
	jnz		SHORT .RetryLoop
ALIGN JUMP_ALIGN
.Return:
	pop		bx
	pop		cx
	pop		dx
	; Fall to AH0h_BackupErrorCodeFromTheRequestedDriveToBH

;--------------------------------------------------------------------
; AH0h_BackupErrorCodeFromTheRequestedDriveToBH
;	Parameters:
;		AH:		Error code from the last resetted drive
;		DL:		Drive last resetted
;		BL:		Requested drive (DL when entering AH=00h)
;	Returns:
;		BH:		Backuped error code
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_BackupErrorCodeFromTheRequestedDriveToBH:
	cmp		dl, bl						; Requested drive?
	jne		SHORT .Return
	mov		bh, ah
ALIGN JUMP_ALIGN
.Return:
	ret
