; File name		:	AH0h_HReset.asm
; Project name	:	IDE BIOS
; Created date	:	27.9.2007
; Last update	:	26.7.2010
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
	call	ResetFloppyDrivesWithInt40h
	test	bl, 80h
	jz		SHORT .SkipHardDiskReset
	call	ResetForeignHardDisks
	call	ResetHardDisksHandledByOurBIOS
ALIGN JUMP_ALIGN
.SkipHardDiskReset:
	mov		ah, bh						; Copy error code to AH
	xor		al, al						; Zero AL...
	sub		al, ah						; ...and set CF if error
	jmp		Int13h_PopXRegsAndReturn


;--------------------------------------------------------------------
; ResetFloppyDrivesWithInt40h
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DL:		Drive number
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, DL
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
ResetFloppyDrivesWithInt40h:
	xor		ah, ah						; Disk Controller Reset
	and		dl, 7Fh						; Clear bit 7
	int		INTV_FLOPPY_FUNC
	jmp		SHORT BackupErrorCodeFromTheRequestedDriveToBH


;--------------------------------------------------------------------
; ResetForeignHardDisks
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:		RAMVARS segment
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, DL
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
ResetForeignHardDisks:
	mov		dl, bl						; Drive to reset
	mov		ah, 0Dh						; Reset Hard Disk (Alternate reset)

	pushf								; Push flags to simulate INT
	cli									; Disable interrupts since INT does that
	call	FAR [RAMVARS.fpOldI13h]
	sti									; Make sure interrupts are enabled again (some BIOSes fails to enable it)

	jmp		SHORT BackupErrorCodeFromTheRequestedDriveToBH


;--------------------------------------------------------------------
; ResetHardDisksHandledByOurBIOS
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:		RAMVARS segment
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ResetHardDisksHandledByOurBIOS:
	mov		dh, [RAMVARS.bDrvCnt]		; Load drive count to DH
	test	dh, dh
	jz		SHORT .AllDrivesReset		; Return if no drives
	mov		dl, [RAMVARS.bFirstDrv]		; Load number of first our drive
	add		dh, dl						; DH = one past last drive to reset
ALIGN JUMP_ALIGN
.DriveResetLoop:
	call	AHDh_ResetDrive
	call	BackupErrorCodeFromTheRequestedDriveToBH
	call	.SkipNextDriveIfItIsSlaveForThisController
	inc		dx
	cmp		dl, dh						; All done?
	jb		SHORT .DriveResetLoop		;  If not, reset next drive
.AllDrivesReset:
	ret

;--------------------------------------------------------------------
; .SkipNextDriveIfItIsSlaveForThisController
;	Parameters:
;		DL:		Drive just resetted
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Incremented if next drive is slave drive
;				(=already resetted)
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.SkipNextDriveIfItIsSlaveForThisController:
	push	di

	call	.GetBasePortToAXfromDriveInDL
	xchg	cx, ax

	inc		dx
	call	.GetBasePortToAXfromDriveInDL
	jnc		SHORT .SkipNextDrive

	cmp		ax, cx
	je		SHORT .SkipNextDrive		; Same controller so slave already reset

	dec		dx							; Restore DX
.SkipNextDrive:
	pop		di
	ret

;--------------------------------------------------------------------
; .GetBasePortToAXfromDriveInDL
;	Parameters:
;		DL:		Drive whose base port to find
;		DS:		RAMVARS segment
;	Returns:
;		AX:		Base port (if drive found)
;		CF:		Set if drive found
;				Cleared if drive not found
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetBasePortToAXfromDriveInDL:
	call	FindDPT_ForDriveNumber		; Get DPT to DS:DI
	jnc		SHORT .DriveNotFound
	eMOVZX	di, BYTE [di+DPT.bIdeOff]	; CS:DI now points to IDEVARS
	mov		ax, [cs:di+IDEVARS.wPort]
.DriveNotFound:
	ret


;--------------------------------------------------------------------
; BackupErrorCodeFromTheRequestedDriveToBH
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
BackupErrorCodeFromTheRequestedDriveToBH:
	cmp		dl, bl				; Requested drive?
	jne		SHORT .Return
	mov		bh, ah
ALIGN JUMP_ALIGN
.Return:
	ret
