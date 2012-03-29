; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=Dh, Reset Hard Disk (Alternate reset).

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=Dh, Reset Hard Disk (Alternate reset).
;
; AHDh_HandlerForResetHardDisk
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
AHDh_HandlerForResetHardDisk:
%ifndef USE_186
	call	AHDh_ResetDrive
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%else
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall to AHDh_ResetDrive
%endif


;--------------------------------------------------------------------
; Resets hard disk.
;
; AHDh_ResetDrive
;	Parameters:
;		DS:DI:	Ptr to DPT
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;	Corrupts registers:
;		AL, SI
;--------------------------------------------------------------------
AHDh_ResetDrive:
	push	dx
	push	cx
	push	bx
	push	di

	call	Interrupts_UnmaskInterruptControllerForDriveInDSDI
	call	Device_ResetMasterAndSlaveController
	;jc		SHORT .ReturnError					; CF would be set if slave drive present without master
												; (error register has special values after reset)

	; Initialize Master and Slave drives
	eMOVZX	ax, [di+DPT.bIdevarsOffset]			; (AL) pointer to controller we are looking to reset
												; (AH) initialize error code, assume success

	mov		si, IterateAndResetDrives			; Callback function for FindDPT_IterateAllDPTs
	call	FindDPT_IterateAllDPTs

	shr		ah, 1								; Move error code and CF into proper position

	pop		di
	pop		bx
	pop		cx
	pop		dx
	ret

;--------------------------------------------------------------------
; IterateAndResetDrives: Iteration routine for use with IterateAllDPTs.
;
; When a drive on the controller is found, it is reset, and the error code
; merged into overall error code for this controller.  Master will be reset
; first.  Note that the iteration will go until the end of the DPT list.
;
;	Parameters:
;		AL:		Offset to IDEVARS for drives to initialize
;		AH:		Error status from previous initialization
;		DS:DI:	Ptr to DPT to examine
;	Returns:
;		AH:		Error status from initialization
;		CF:		Set to iterate all DPTs
;	Corrupts registers:
;		AL, BX, DX
;--------------------------------------------------------------------
IterateAndResetDrives:
	cmp		al, [di+DPT.bIdevarsOffset]			; The right controller?
	jne		.Done
	push	cx
	push	ax
	call	AH9h_InitializeDriveForUse			; Reset Master and Slave (Master will come first in DPT list)

%ifdef MODULE_ADVANCED_ATA
	jc		SHORT .SkipControllerInitSinceError
	; Here we initialize the more advanced controllers (VLB and PCI) to get better performance for systems with 32-bit bus.
	; This step is optional since the controllers use slowest possible settings by default if they are not initialized.

	pop		ax
	push	ax
	cmp		al, [di+LARGEST_DPT_SIZE+DPT.bIdevarsOffset]	; We check if next DPT is for the same IDE controller.
	je		SHORT .SkipInitializationUntilNextDrive			; If it is, we skip the initialization.
	call	AdvAtaInit_InitializeControllerForDPTinDSDI		; Done after drive init so drives are first set to advanced PIO mode, then the controller
.SkipInitializationUntilNextDrive:
.SkipControllerInitSinceError:
%endif	; MODULE_ADVANCED_ATA

	pop		ax
	pop		cx
	jnc		.Done
	or		ah, (RET_HD_RESETFAIL << 1) | 1		; OR in Reset Failed error code and CF, will SHR into position later
.Done:
	stc											; From IterateAllDPTs perspective, the DPT is never found (continue iteration)
	ret

