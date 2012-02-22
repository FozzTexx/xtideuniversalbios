; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for initializing the BIOS.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Initializes the BIOS.
; This function is called from main BIOS ROM search routine.
;
; Initialize_FromMainBiosRomSearch
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
Initialize_FromMainBiosRomSearch:			; unused entrypoint ok
	pushf
	push	es
	push	ds
	ePUSHA

	LOAD_BDA_SEGMENT_TO	es, ax
	sti										; Enable interrupts
	test	BYTE [es:BDA.bKBFlgs1], (1<<2)	; Clears ZF if CTRL is held down
	jnz		SHORT .SkipRomInitialization

	; Install INT 19h handler (boot loader) where drives are detected
	mov		al, BIOS_BOOT_LOADER_INTERRUPT_19h
	mov		si, Int19h_BootLoaderHandler
	call	Interrupts_InstallHandlerToVectorInALFromCSSI

.SkipRomInitialization:
	ePOPA
	pop		ds
	pop		es
	popf
	retf


;--------------------------------------------------------------------
; Initializes the BIOS variables and detects IDE drives.
;
; Initialize_AndDetectDrives
;	Parameters:
;		ES:		BDA Segment
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		All
;--------------------------------------------------------------------
Initialize_AndDetectDrives:
	call	BootMenuPrint_InitializeDisplayContext
	call	DetectPrint_RomFoundAtSegment
	call	RamVars_Initialize
	call	Interrupts_InitializeInterruptVectors
	call	DetectDrives_FromAllIDEControllers
	; Fall to .StoreDptPointersToIntVectors

;--------------------------------------------------------------------
; .StoreDptPointersToIntVectors
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		DX, DI
;--------------------------------------------------------------------
.StoreDptPointersToIntVectors:
	mov		dl, 80h
	call	RamVars_IsDriveHandledByThisBIOS
	jc		SHORT .FindForDrive81h	; Store nothing if not our drive
	call	FindDPT_ForDriveNumber	; DPT to DS:DI
	mov		[es:HD0_DPT_POINTER_41h*4], di
	mov		[es:HD0_DPT_POINTER_41h*4+2], ds
.FindForDrive81h:
	inc		dx
	call	RamVars_IsDriveHandledByThisBIOS
	jc		SHORT .ResetDetectedDrives
	call	FindDPT_ForDriveNumber
	mov		[es:HD1_DPT_POINTER_46h*4], di
	mov		[es:HD1_DPT_POINTER_46h*4+2], ds
	; Fall to .ResetDetectedDrives

;--------------------------------------------------------------------
; .ResetDetectedDrives
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except DS and ES
;--------------------------------------------------------------------
.ResetDetectedDrives:
	call	Idepack_FakeToSSBP
	call	AH0h_ResetHardDisksHandledByOurBIOS
	add		sp, BYTE EXTRA_BYTES_FOR_INTPACK
	ret
