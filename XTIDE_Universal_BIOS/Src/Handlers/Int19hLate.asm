; Project name	:	XTIDE Universal BIOS
; Description	:	Late initialization for XT builds.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int19hLate_InitializeInt19h
;	Parameters:
;		ES:		BDA segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19hLate_InitializeInt19h:
	mov		bx, BIOS_BOOT_LOADER_INTERRUPT_19h
	mov		si, HandlerForLateInitialization
	jmp		Interrupts_InstallHandlerToVectorInBXFromCSSI


;--------------------------------------------------------------------
; HandlerForLateInitialization
;	Parameters:
;		Nothing
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HandlerForLateInitialization:
	LOAD_BDA_SEGMENT_TO	es, ax
	call	Initialize_ShouldSkip			; Skip initialization?
	jnz		SHORT .SkipInitialization
	call	Initialize_AndDetectDrives		; Installs boot menu loader
	int		BIOS_BOOT_LOADER_INTERRUPT_19h
.SkipInitialization:
	call	RamVars_Initialize				; RAMVARS must be initialized even for simple boot loader
	int		BIOS_BOOT_LOADER_INTERRUPT_19h	; Call default system boot loader
