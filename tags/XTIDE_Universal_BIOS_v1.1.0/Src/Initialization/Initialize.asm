; File name		:	Initialize.asm
; Project name	:	IDE BIOS
; Created date	:	23.3.2010
; Last update	:	2.5.2010
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
	; Fall to Initialize_InstallInterruptHandler

;--------------------------------------------------------------------
; Installs any interrupt handler.
;
; Initialize_InstallInterruptHandler
;	Parameters:
;		BX:		Interrupt vector number (for example 13h)
;		ES:		BDA and Interrupt Vector segment (zero)
;		CS:SI:	Ptr to interrupt handler
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
Initialize_InstallInterruptHandler:
	eSHL_IM	bx, 2					; Shift for DWORD offset
	mov		[es:bx], si				; Store offset
	mov		[es:bx+2], cs			; Store segment
	ret


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
	call	Initialize_InterruptVectors
	call	DetectDrives_FromAllIDEControllers
	call	CompatibleDPT_CreateForDrives80hAnd81h
	jmp		Initialize_ResetDetectedDrives


;--------------------------------------------------------------------
; Initializes Interrupt Vectors.
;
; Initialize_InterruptVectors
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		All except segments
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
Initialize_InterruptVectors:
	call	Initialize_Int13hAnd40h
	call	Initialize_Int19h
	jmp		SHORT Initialize_HardwareIrqHandlers


;--------------------------------------------------------------------
; Initializes INT 13h and 40h handlers for Hard Disk and
; Floppy Drive BIOS functions.
;
; Initialize_Int13hAnd40h
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
Initialize_Int13hAnd40h:
	mov		ax, [es:INTV_DISK_FUNC*4]			; Load old INT 13h offset
	mov		dx, [es:INTV_DISK_FUNC*4+2]			; Load old INT 13h segment
	mov		[RAMVARS.fpOldI13h], ax				; Store old INT 13h offset
	mov		[RAMVARS.fpOldI13h+2], dx			; Store old INT 13h segment
	mov		bx, INTV_DISK_FUNC					; INT 13h interrupt vector offset
	mov		si, Int13h_DiskFunctions			; Interrupt handler offset
	call	Initialize_InstallInterruptHandler

	; Only store INT 13h handler to 40h if 40h is not already installed.
	; At least AMI BIOS for 286 stores 40h handler by itself and calls
	; 40h from 13h. That system locks to infinite loop if we copy 13h to 40h.
	call	FloppyDrive_IsInt40hInstalled
	jnc		SHORT Initialize_Int40h
	ret

;--------------------------------------------------------------------
; Initializes INT 40h handler for Floppy Drive BIOS functions.
;
; Initialize_Int40h
;	Parameters:
;		DX:AX:	Ptr to old INT 13h handler
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
Initialize_Int40h:
	mov		[es:INTV_FLOPPY_FUNC*4], ax		; Store offset
	mov		[es:INTV_FLOPPY_FUNC*4+2], dx	; Store segment
	ret


;--------------------------------------------------------------------
; Initializes INT 19h handler for boot loader.
;
; Initialize_Int19h
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, SI
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
Initialize_Int19h:
	eMOVZX	bx, [cs:ROMVARS.bBootLdrType]	; Load boot loader type
	mov		si, INTV_BOOTSTRAP				; 19h
	xchg	bx, si							; SI=Loader type, BX=19h
	jmp		[cs:si+.rgwSetupBootLoader]		; Jump to install selected loader
ALIGN WORD_ALIGN
.rgwSetupBootLoader:
	dw		.SetupBootMenuLoader		; BOOTLOADER_TYPE_MENU
	dw		.SetupSimpleLoader			; BOOTLOADER_TYPE_SIMPLE
	dw		.SetupBootMenuLoader		; reserved
	dw		.NoBootLoader				; BOOTLOADER_TYPE_NONE

ALIGN JUMP_ALIGN
.NoBootLoader:
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_LATE
	jnz		SHORT .SetupSimpleLoader	; Boot loader required for late initialization
	ret
ALIGN JUMP_ALIGN
.SetupSimpleLoader:
	mov		si, Int19h_SimpleBootLoader
	jmp		Initialize_InstallInterruptHandler
ALIGN JUMP_ALIGN
.SetupBootMenuLoader:
	mov		si, Int19hMenu_BootLoader
	jmp		Initialize_InstallInterruptHandler


;--------------------------------------------------------------------
; Initializes hardware IRQ handlers.
;
; Initialize_HardwareIrqHandlers
;	Parameters:
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------		
ALIGN JUMP_ALIGN
Initialize_HardwareIrqHandlers:
	mov		di, ROMVARS.ideVars0			; CS:SI points to first IDEVARS
	call	Initialize_GetIdeControllerCountToCX
ALIGN JUMP_ALIGN
.IdeControllerLoop:
	mov		al, [cs:di+IDEVARS.bIRQ]		; Load IRQ number
	add		di, BYTE IDEVARS_size			; Increment to next controller
	call	Initialize_LowOrHighIrqHandler
	loop	.IdeControllerLoop
	ret

;--------------------------------------------------------------------
; Returns number of IDE controllers handled by our BIOS.
;
; Initialize_GetIdeControllerCountToCX
;	Parameters:
;		Nothing
;	Returns:
;		CX:		Number of IDE controllers to handle
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
Initialize_GetIdeControllerCountToCX:
	mov		cx, 1					; Assume lite mode (one controller)
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .Return
	mov		cl, [cs:ROMVARS.bIdeCnt]
ALIGN JUMP_ALIGN
.Return:
	ret

;--------------------------------------------------------------------
; Initializes hardware IRQ handler for specific IRQ.
;
; Initialize_LowOrHighIrqHandler
;	Parameters:
;		AL:		IRQ number, 0 if IRQ disabled
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI
;--------------------------------------------------------------------		
ALIGN JUMP_ALIGN
Initialize_LowOrHighIrqHandler:
	test	al, al							; IRQ disabled?
	jz		SHORT .Return					;  If so, return
	eMOVZX	bx, al							; Copy IRQ number to BX
	cmp		al, 8							; High IRQ? (AT systems only)
	jae		SHORT Initialize_HighIrqHandler
	jmp		SHORT Initialize_LowIrqHandler
ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; Initializes handler for high IRQ (8...15).
;
; Initialize_HighIrqHandler
;	Parameters:
;		AL,BX:	IRQ number (8...15)
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI
;--------------------------------------------------------------------		
ALIGN JUMP_ALIGN
Initialize_HighIrqHandler:
	add		bx, BYTE INTV_IRQ8 - 8			; Interrupt vector number
	mov		si, HIRQ_InterruptServiceRoutineForIrqs8to15
	call	Initialize_InstallInterruptHandler
	; Fall to Initialize_UnmaskHighIrqController

;--------------------------------------------------------------------
; Unmasks interrupt from Slave 8259 interrupt controller (IRQs 8...15)
;
; Initialize_HighIrqHandler
;	Parameters:
;		AL:		IRQ number (8...15)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Initialize_UnmaskHighIrqController:
	sub		al, 8				; Slave interrupt number
	mov		dx, PORT_8259SL_IMR	; Load Slave Mask Register address
	call	Initialize_ClearBitFrom8259MaskRegister
	mov		al, 2				; Master IRQ 2 to allow slave IRQs
	jmp		SHORT Initialize_UnmaskLowIrqController


;--------------------------------------------------------------------
; Initializes handler for low IRQ (0...7).
;
; Initialize_LowIrqHandler
;	Parameters:
;		AL,BX:	IRQ number (0...7)
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI
;--------------------------------------------------------------------		
ALIGN JUMP_ALIGN
Initialize_LowIrqHandler:
	add		bx, BYTE INTV_IRQ0				; Interrupt vector number
	mov		si, HIRQ_InterruptServiceRoutineForIrqs2to7
	call	Initialize_InstallInterruptHandler
	; Fall to Initialize_UnmaskLowIrqController

;--------------------------------------------------------------------
; Unmasks interrupt from Master 8259 interrupt controller (IRQs 0...7)
;
; Initialize_UnmaskLowIrqController
;	Parameters:
;		AL:		IRQ number (0...7)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Initialize_UnmaskLowIrqController:
	mov		dx, PORT_8259MA_IMR	; Load Mask Register address
	; Fall to Initialize_ClearBitFrom8259MaskRegister

;--------------------------------------------------------------------
; Unmasks interrupt from Master or Slave 8259 Interrupt Controller.
;
; Initialize_ClearBitFrom8259MaskRegister
;	Parameters:
;		AL:		8259 interrupt index (0...7)
;		DX:		Port address to Interrupt Mask Register
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Initialize_ClearBitFrom8259MaskRegister:
	push	cx
	xchg	ax, cx				; IRQ index to CL
	mov		ch, 1				; Load 1 to be shifted
	shl		ch, cl				; Shift bit to correct position
	not		ch					; Invert to create bit mask for clearing
	in		al, dx				; Read Interrupt Mask Register
	and		al, ch				; Clear wanted bit
	out		dx, al				; Write modified Interrupt Mask Register
	pop		cx
	ret


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
ALIGN JUMP_ALIGN
Initialize_ResetDetectedDrives:
	; Initialize to speed up POST. DOS will reset drives anyway.
	eMOVZX	cx, BYTE [RAMVARS.bDrvCnt]
	jcxz	.Return
	mov		dl, [RAMVARS.bFirstDrv]
ALIGN JUMP_ALIGN
.InitLoop:
	call	AH9h_InitializeDriveForUse
	inc		dx					; Next drive
	loop	.InitLoop
.Return:
	ret
