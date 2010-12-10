; File name		:	Initialize.asm
; Project name	:	IDE BIOS
; Created date	:	23.3.2010
; Last update	:	23.8.2010
; Author		:	Tomi Tilli
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

	call	Initialize_ShouldSkip
	jc		SHORT .ReturnFromRomInit

	ePUSH_T	ax, .ReturnFromRomInit		; Push return address
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_LATE
	jnz		SHORT Initialize_PrepareLateInitialization
	jmp		SHORT Initialize_AndDetectDrives

ALIGN JUMP_ALIGN
.ReturnFromRomInit:
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
;		Nothing
;	Returns:
;		CF:		Set if ROM initialization is to be skipped
;				Cleared to continue ROM initialization
;	Corrupts registers:
;		AX, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Initialize_ShouldSkip:
	sti							; Enable interrupts
	LOAD_BDA_SEGMENT_TO	ds, ax
	mov		al, [BDA.bKBFlgs1]	; Load shift flags
	eSHR_IM	al, 3				; Set CF if CTRL is held down
	ret


;--------------------------------------------------------------------
; Installs INT 19h boot loader handler for late initialization.
;
; Initialize_PrepareLateInitialization
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Initialize_PrepareLateInitialization:
	LOAD_BDA_SEGMENT_TO	es, bx
	mov		bl, INTV_BOOTSTRAP
	mov		si, Int19h_LateInitialization
	jmp		Interrupts_InstallHandlerToVectorInBXFromCSSI


;--------------------------------------------------------------------
; Initializes the BIOS variables and detects IDE drives.
;
; Initialize_AndDetectDrives
;	Parameters:
;		Nothing
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
	LOAD_BDA_SEGMENT_TO	es, ax
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
