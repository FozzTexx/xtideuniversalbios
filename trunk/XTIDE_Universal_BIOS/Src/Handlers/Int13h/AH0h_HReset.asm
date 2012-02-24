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

	; Resetting our hard disks will modify dl and bl such that this call must be the last in the list
	;
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
	test	di, di
	jz		SHORT .Return				; Return what was in BL unmodified
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
	mov		bl, [di+DPT.bIdevarsOffset]					; replace drive number with Idevars pointer for cmp with dl
	mov		dl, ROMVARS.ideVars0						; starting Idevars offset

	mov		cl, [cs:ROMVARS.bIdeCnt]					; get count of ide controllers
	mov		ch, 0
	jcxz	.done										; just in case bIdeCnt is zero (shouldn't be)

	mov		si, IterateFindFirstDPTforIdevars			; iteration routine (see below)

.loop:
	call	IterateAllDPTs								; look for the first drive on this controller, if any
	jc		.notFound

	call	AHDh_ResetDrive								; reset master and slave on that controller
	call	BackupErrorCodeFromTheRequestedDriveToBH	; save error code if same controller as drive from entry

.notFound:
	add		dl, IDEVARS_size							; move Idevars pointer forward
	loop	.loop

.done:
	ret

;--------------------------------------------------------------------
; Iteration routine for AH0h_ResetHardDisksHandledByOurBIOS, 
; for use with IterateAllDPTs
; 
; Returns when DPT is found on the controller with Idevars offset in DL
;--------------------------------------------------------------------
IterateFindFirstDPTforIdevars:		
	cmp		dl, [di+DPT.bIdevarsOffset]			; Clears CF if matched
	jz		.done
	stc											; Set CF for not found
.done:	
	ret
