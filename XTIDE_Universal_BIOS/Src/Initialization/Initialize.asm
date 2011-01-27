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
ALIGN JUMP_ALIGN
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
ALIGN JUMP_ALIGN
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
;		Nothing
;	Corrupts registers:
;		All, including segments
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Initialize_AndDetectDrives:
	call	DetectPrint_RomFoundAtSegment
	call	RamVars_Initialize
	call	RamVars_GetSegmentToDS
	call	Interrupts_InitializeInterruptVectors
	call	DetectDrives_FromAllIDEControllers
	call	CompatibleDPT_CreateForDrives80hAnd81h
	; Fall to .ResetDetectedDrives

;--------------------------------------------------------------------
; Resets all hard disks.
;
; Initialize_ResetDetectedDrives
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, DI
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
.ResetDetectedDrives:
	jmp		AH0h_ResetHardDisksHandledByOurBIOS
