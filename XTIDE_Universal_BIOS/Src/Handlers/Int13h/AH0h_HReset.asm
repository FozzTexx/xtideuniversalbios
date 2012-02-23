; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=0h, Disk Controller Reset.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=0h, Disk Controller Reset.
;
; AH0h_HandlerForDiskControllerReset
;	Parameters:
;		DL:		Translated Drive number (ignored so all drives are reset)
;				If bit 7 is set all hard disks and floppy disks reset.
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns with INTPACK:
;		AH:		Int 13h return status (from drive requested in DL)
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_HandlerForDiskControllerReset:
	eMOVZX	bx, dl						; Copy requested drive to BL, zero BH to assume no errors
	call	ResetFloppyDrivesWithInt40h

%ifdef MODULE_SERIAL_FLOPPY
;
; "Reset" emulatd serial floppy drives, if any.  There is nothing to actually do for this reset,
; but record the proper error return code if one of these floppy drives is the drive requested.
;
	call	RamVars_UnpackFlopCntAndFirstToAL
	cbw													; Clears AH (there are flop drives) or ffh (there are not)
														; Either AH has success code (flop drives are present)
														; or it doesn't matter because we won't match drive ffh

	cwd													; clears DX (there are flop drives) or ffffh (there are not)

	adc		dl, al										; second drive (CF set) if present
														; If no drive is present, this will result in ffh which 
														; won't match a drive
	call	BackupErrorCodeFromTheRequestedDriveToBH
	mov		dl, al										; We may end up doing the first drive twice (if there is
	call	BackupErrorCodeFromTheRequestedDriveToBH	; only one drive), but doing it again is not harmful.
%endif

	test	bl, bl										; If we were called with a floppy disk, then we are done,
	jns		SHORT .SkipHardDiskReset					; don't do hard disks.
		
	call	ResetForeignHardDisks
	call	AH0h_ResetHardDisksHandledByOurBIOS
.SkipHardDiskReset:
	mov		ah, bh
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH


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
	int		BIOS_DISKETTE_INTERRUPT_40h
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
;;; fall-through to BackupErrorCodeFromTheRequestedDriveToBH


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
	eCMOVE	bh, ah
	ret
		

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
	jc		SHORT .Return				; Return what was in BL unmodified
	mov		dl, 80h
.Return:
	ret


;--------------------------------------------------------------------
; AH0h_ResetHardDisksHandledByOurBIOS
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:		RAMVARS segment
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_ResetHardDisksHandledByOurBIOS:
	mov		dx, [RAMVARS.wDrvCntAndFirst]	; DL = drive number, DH = drive count
	test	dh, dh
	jz		SHORT .AllDrivesReset		; Return if no drives
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
	call	GetBasePortToCX				; Load base port for resetted drive
	push	cx
	inc		dx							; DL to next drive
	call	GetBasePortToCX
	pop		di
	cmp		cx, di						; Next drive is from same controller?
	je		SHORT BackupErrorCodeFromTheRequestedDriveToBH
.NoMoreDrivesOrNoSlaveDrive:
	dec		dx
	ret

		
;--------------------------------------------------------------------
; GetBasePortToCX
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		CX:		Base port address
;		CF:		Set if valid drive number
;				Cleared if invalid drive number
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetBasePortToCX:
	xchg	cx, bx
	xor		bx, bx
	call	FindDPT_ForDriveNumber
	mov		bl, [di+DPT.bIdevarsOffset]
	mov		bx, [cs:bx+IDEVARS.wPort]
	xchg	bx, cx
	ret


