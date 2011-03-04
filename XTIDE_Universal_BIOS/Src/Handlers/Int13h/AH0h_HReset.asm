; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=0h, Disk Controller Reset.

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
	test	bl, bl
	jns		SHORT .SkipHardDiskReset
	call	ResetForeignHardDisks
	call	AH0h_ResetHardDisksHandledByOurBIOS
ALIGN JUMP_ALIGN
.SkipHardDiskReset:
	mov		ah, bh						; Copy error code to AH
	xor		al, al						; Zero AL...
	cmp		al, bh						; ...and set CF if error
	jmp		Int13h_PopXRegsAndReturn


;--------------------------------------------------------------------
; ResetFloppyDrivesWithInt40h
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, DL, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ResetFloppyDrivesWithInt40h:
	call	GetDriveNumberForForeignBiosesToDL
	and		dl, 7Fh						; Clear hard disk bit
	xor		ah, ah						; Disk Controller Reset
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
;		AX, DL, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ResetForeignHardDisks:
	call	GetDriveNumberForForeignBiosesToDL
	xor		ah, ah						; Disk Controller Reset
	call	Int13h_CallPreviousInt13hHandler
	jmp		SHORT BackupErrorCodeFromTheRequestedDriveToBH


;--------------------------------------------------------------------
; GetDriveNumberForForeignBiosesToDL
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:		RAMVARS segment
;	Returns:
;		DL:		BL if foreign drive
;				80h if our drive
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetDriveNumberForForeignBiosesToDL:
	mov		dl, bl
	call	RamVars_IsDriveHandledByThisBIOS
	jnc		SHORT .Return				; Return what was in BL unmodified
	mov		dl, 80h
ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; ResetHardDisksHandledByOurBIOS
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:		RAMVARS segment
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_ResetHardDisksHandledByOurBIOS:
	mov		dh, [RAMVARS.bDrvCnt]		; Load drive count to DH
	test	dh, dh
	jz		SHORT .AllDrivesReset		; Return if no drives
	mov		dl, [RAMVARS.bFirstDrv]		; Load number of first our drive
	add		dh, dl						; DH = one past last drive to reset
ALIGN JUMP_ALIGN
.DriveResetLoop:
	call	AHDh_ResetDrive
	call	.BackupErrorCodeFromMasterOrSlaveToBH
	inc		dx
	cmp		dl, dh						; All done?
	jb		SHORT .DriveResetLoop		;  If not, reset next drive
.AllDrivesReset:
	ret

;--------------------------------------------------------------------
; .BackupErrorCodeFromMasterOrSlaveToBH
;	Parameters:
;		AH:		Error code for drive DL reset
;		BL:		Requested drive (DL when entering AH=00h)
;		DL:		Drive just resetted
;		DS:		RAMVARS segment
;	Returns:
;		BH:		Backuped error code
;		DL:		Incremented if next drive is slave drive
;				(=already resetted)
;	Corrupts registers:
;		CX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.BackupErrorCodeFromMasterOrSlaveToBH:
	call	BackupErrorCodeFromTheRequestedDriveToBH
	mov		cx, [RAMVARS.wIdeBase]		; Load base port for resetted drive

	inc		dx							; DL to next drive
	call	FindDPT_ForDriveNumber		; Get DPT to DS:DI, store port to RAMVARS
	jnc		SHORT .NoMoreDrivesOrNoSlaveDrive
	cmp		cx, [RAMVARS.wIdeBase]		; Next drive is from same controller?
	je		SHORT BackupErrorCodeFromTheRequestedDriveToBH
.NoMoreDrivesOrNoSlaveDrive:
	dec		dx
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
