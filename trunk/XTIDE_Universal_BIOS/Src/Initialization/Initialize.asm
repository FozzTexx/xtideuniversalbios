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
Initialize_FromMainBiosRomSearch:
	pushf
	push	es
	push	ds
	ePUSHA

	LOAD_BDA_SEGMENT_TO	es, ax
	call	Initialize_ShouldSkip
	jnz		SHORT .SkipRomInitialization

%ifdef USE_AT	; Early initialization on AT build
	call	Initialize_AndDetectDrives
%else			; Late initialization on XT builds
	call	Int19hLate_InitializeInt19h
%endif
.SkipRomInitialization:
	ePOPA
	pop		ds
	pop		es
	popf
	retf


;--------------------------------------------------------------------
; Checks if user wants to skip ROM initialization.
;
; Initialize_ShouldSkip
;	Parameters:
;		ES:		BDA segment
;	Returns:
;		ZF:		Cleared if ROM initialization is to be skipped
;				Set to continue ROM initialization
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
Initialize_ShouldSkip:
	sti										; Enable interrupts
	test	BYTE [es:BDA.bKBFlgs1], (1<<2)	; Clear ZF if CTRL is held down
	ret


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
	CALL_DISPLAY_LIBRARY InitializeDisplayContext
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
	call	FindDPT_ForDriveNumber	; DPT to DS:DI
	jnc		SHORT .FindForDrive81h	; Store nothing if not our drive
	mov		[es:INTV_HD0DPT*4], di
	mov		[es:INTV_HD0DPT*4+2], ds
.FindForDrive81h:
	inc		dx
	call	FindDPT_ForDriveNumber
	jnc		SHORT .ResetDetectedDrives
	mov		[es:INTV_HD1DPT*4], di
	mov		[es:INTV_HD1DPT*4+2], ds
	; Fall to .ResetDetectedDrives

;--------------------------------------------------------------------
; .ResetDetectedDrives
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, DI
;--------------------------------------------------------------------
.ResetDetectedDrives:
	jmp		AH0h_ResetHardDisksHandledByOurBIOS
