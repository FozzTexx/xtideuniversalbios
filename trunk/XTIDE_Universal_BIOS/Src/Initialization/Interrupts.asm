; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for initializing the BIOS.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Interrupts_InitializeInterruptVectors
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		All except segments
;--------------------------------------------------------------------
Interrupts_InitializeInterruptVectors:
	; Fall to .InitializeInt13hAnd40h

;--------------------------------------------------------------------
; .InitializeInt13hAnd40h
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
.InitializeInt13hAnd40h:
	mov		ax, [es:BIOS_DISK_INTERRUPT_13h*4]	; Load old INT 13h offset
	mov		dx, [es:BIOS_DISK_INTERRUPT_13h*4+2]; Load old INT 13h segment
	mov		[RAMVARS.fpOldI13h], ax				; Store old INT 13h offset
	mov		[RAMVARS.fpOldI13h+2], dx			; Store old INT 13h segment
	mov		bx, BIOS_DISK_INTERRUPT_13h			; INT 13h interrupt vector offset
	mov		si, Int13h_DiskFunctionsHandler		; Interrupt handler offset
	call	Interrupts_InstallHandlerToVectorInBXFromCSSI

	; Only store INT 13h handler to 40h if 40h is not already installed.
	; At least AMI BIOS for 286 stores 40h handler by itself and calls
	; 40h from 13h. That system locks to infinite loop if we copy 13h to 40h.
	call	FloppyDrive_IsInt40hInstalled
	jc		SHORT .InitializeInt19h
	mov		[es:BIOS_DISKETTE_INTERRUPT_40h*4], ax		; Store old INT 13h offset
	mov		[es:BIOS_DISKETTE_INTERRUPT_40h*4+2], dx	; Store old INT 13h segment
	; Fall to .InitializeInt19h

;--------------------------------------------------------------------
; .InitializeInt19h
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, SI
;--------------------------------------------------------------------
.InitializeInt19h:
	mov		bx, BIOS_BOOT_LOADER_INTERRUPT_19h
	mov		si, Int19hMenu_BootLoader
	call	Interrupts_InstallHandlerToVectorInBXFromCSSI
	; Fall to .InitializeHardwareIrqHandlers

;--------------------------------------------------------------------
; .InitializeHardwareIrqHandlers
;	Parameters:
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX, DX, SI, DI
;--------------------------------------------------------------------
.InitializeHardwareIrqHandlers:
	call	RamVars_GetIdeControllerCountToCX
	mov		di, ROMVARS.ideVars0			; CS:SI points to first IDEVARS
.IdeControllerLoop:
	eMOVZX	bx, BYTE [cs:di+IDEVARS.bIRQ]
	add		di, BYTE IDEVARS_size			; Increment to next controller
	call	.InstallLowOrHighIrqHandler
	loop	.IdeControllerLoop
.Return:
	ret		; This ret is shared with .InstallLowOrHighIrqHandler

;--------------------------------------------------------------------
; .InstallLowOrHighIrqHandler
;	Parameters:
;		BX:		IRQ number, 0 if IRQ disabled
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, SI
;--------------------------------------------------------------------
.InstallLowOrHighIrqHandler:
	test	bl, bl
	jz		SHORT .Return	; IRQ not used
	cmp		bl, 8
	jb		SHORT .InstallLowIrqHandler
	; Fall to .InstallHighIrqHandler

;--------------------------------------------------------------------
; .InstallHighIrqHandler
;	Parameters:
;		BX:		IRQ number (8...15)
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, SI
;--------------------------------------------------------------------
.InstallHighIrqHandler:
	add		bx, BYTE HARDWARE_IRQ_8_INTERRUPT_70h - 8	; Interrupt vector number
	mov		si, IdeIrq_InterruptServiceRoutineForIrqs8to15
	jmp		SHORT Interrupts_InstallHandlerToVectorInBXFromCSSI

;--------------------------------------------------------------------
; .InstallLowIrqHandler
;	Parameters:
;		BX:		IRQ number (0...7)
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, SI
;--------------------------------------------------------------------
.InstallLowIrqHandler:
	add		bx, BYTE HARDWARE_IRQ_0_INTERRUPT_08h		; Interrupt vector number
	mov		si, IdeIrq_InterruptServiceRoutineForIrqs2to7
	; Fall to Interrupts_InstallHandlerToVectorInBXFromCSSI


;--------------------------------------------------------------------
; Interrupts_InstallHandlerToVectorInBXFromCSSI
;	Parameters:
;		BX:		Interrupt vector number (for example 13h)
;		ES:		BDA and Interrupt Vector segment (zero)
;		CS:SI:	Ptr to interrupt handler
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
Interrupts_InstallHandlerToVectorInBXFromCSSI:
	eSHL_IM	bx, 2					; Shift for DWORD offset
	mov		[es:bx], si				; Store offset
	mov		[es:bx+2], cs			; Store segment
	ret


;--------------------------------------------------------------------
; Interrupts_UnmaskInterruptControllerForDriveInDSDI
;	Parameters:
;		DS:DI:	Ptr to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
Interrupts_UnmaskInterruptControllerForDriveInDSDI:
	eMOVZX	bx, BYTE [di+DPT.bIdevarsOffset]
	mov		al, [cs:bx+IDEVARS.bIRQ]
	test	al, al
	jz		SHORT .Return	; Interrupts disabled
	cmp		al, 8
	jb		SHORT .UnmaskLowIrqController
	; Fall to .UnmaskHighIrqController

;--------------------------------------------------------------------
; .UnmaskHighIrqController
;	Parameters:
;		AL:		IRQ number (8...15)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
.UnmaskHighIrqController:
	sub		al, 8				; Slave interrupt number
	mov		dx, SLAVE_8259_IMR
	call	.ClearBitFrom8259MaskRegister
	mov		al, 2				; Master IRQ 2 to allow slave IRQs
	; Fall to .UnmaskLowIrqController

;--------------------------------------------------------------------
; .UnmaskLowIrqController
;	Parameters:
;		AL:		IRQ number (0...7)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
.UnmaskLowIrqController:
	mov		dx, MASTER_8259_IMR
	; Fall to .ClearBitFrom8259MaskRegister

;--------------------------------------------------------------------
; .ClearBitFrom8259MaskRegister
;	Parameters:
;		AL:		8259 interrupt index (0...7)
;		DX:		Port address to Interrupt Mask Register
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.ClearBitFrom8259MaskRegister:
	push	cx
	xchg	ax, cx				; IRQ index to CL
	mov		ch, 1				; Load 1 to be shifted
	shl		ch, cl				; Shift bit to correct position
	not		ch					; Invert to create bit mask for clearing
	in		al, dx				; Read Interrupt Mask Register
	and		al, ch				; Clear wanted bit
	out		dx, al				; Write modified Interrupt Mask Register
	pop		cx
.Return:
	ret
