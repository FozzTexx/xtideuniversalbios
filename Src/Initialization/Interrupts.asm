; File name		:	Interrupts.asm
; Project name	:	IDE BIOS
; Created date	:	23.8.2010
; Last update	:	23.8.2010
; Author		:	Tomi Tilli
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
ALIGN JUMP_ALIGN
Interrupts_InitializeInterruptVectors:
	call	Interrupts_InitializeInt13hAnd40h
	call	Interrupts_InitializeInt19h
	jmp		SHORT Interrupts_InitializeHardwareIrqHandlers


;--------------------------------------------------------------------
; Interrupts_Int13hAnd40h
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
Interrupts_InitializeInt13hAnd40h:
	mov		ax, [es:INTV_DISK_FUNC*4]			; Load old INT 13h offset
	mov		dx, [es:INTV_DISK_FUNC*4+2]			; Load old INT 13h segment
	mov		[RAMVARS.fpOldI13h], ax				; Store old INT 13h offset
	mov		[RAMVARS.fpOldI13h+2], dx			; Store old INT 13h segment
	mov		bx, INTV_DISK_FUNC					; INT 13h interrupt vector offset
	mov		si, Int13h_DiskFunctions			; Interrupt handler offset
	call	Interrupts_InstallHandlerToVectorInBXFromCSSI

	; Only store INT 13h handler to 40h if 40h is not already installed.
	; At least AMI BIOS for 286 stores 40h handler by itself and calls
	; 40h from 13h. That system locks to infinite loop if we copy 13h to 40h.
	call	FloppyDrive_IsInt40hInstalled
	jnc		SHORT .InitializeInt40h
	ret

;--------------------------------------------------------------------
; .InitializeInt40h
;	Parameters:
;		DX:AX:	Ptr to old INT 13h handler
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
.InitializeInt40h:
	mov		[es:INTV_FLOPPY_FUNC*4], ax		; Store offset
	mov		[es:INTV_FLOPPY_FUNC*4+2], dx	; Store segment
	ret


;--------------------------------------------------------------------
; Interrupts_InitializeInt19h
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, SI
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
Interrupts_InitializeInt19h:
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
	jmp		Interrupts_InstallHandlerToVectorInBXFromCSSI
ALIGN JUMP_ALIGN
.SetupBootMenuLoader:
	mov		si, Int19hMenu_BootLoader
	jmp		Interrupts_InstallHandlerToVectorInBXFromCSSI


;--------------------------------------------------------------------
; Interrupts_InitializeHardwareIrqHandlers
;	Parameters:
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX, DX, SI, DI
;--------------------------------------------------------------------		
ALIGN JUMP_ALIGN
Interrupts_InitializeHardwareIrqHandlers:
	call	RamVars_GetIdeControllerCountToCX
	mov		di, ROMVARS.ideVars0			; CS:SI points to first IDEVARS
ALIGN JUMP_ALIGN
.IdeControllerLoop:
	eMOVZX	bx, BYTE [cs:di+IDEVARS.bIRQ]
	add		di, BYTE IDEVARS_size			; Increment to next controller
	call	.InstallLowOrHighIrqHandler
	loop	.IdeControllerLoop
	ret

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
ALIGN JUMP_ALIGN
.InstallLowOrHighIrqHandler:
	cmp		bl, 8
	jae		SHORT .InstallHighIrqHandler
	test	bl, bl
	jnz		SHORT .InstallLowIrqHandler
	ret		; IRQ not used

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
ALIGN JUMP_ALIGN
.InstallHighIrqHandler:
	add		bx, BYTE INTV_IRQ8 - 8			; Interrupt vector number
	mov		si, HIRQ_InterruptServiceRoutineForIrqs8to15
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
ALIGN JUMP_ALIGN
.InstallLowIrqHandler:
	add		bx, BYTE INTV_IRQ0				; Interrupt vector number
	mov		si, HIRQ_InterruptServiceRoutineForIrqs2to7
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
ALIGN JUMP_ALIGN
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
ALIGN JUMP_ALIGN
Interrupts_UnmaskInterruptControllerForDriveInDSDI:
	eMOVZX	bx, BYTE [di+DPT.bIdeOff]
	mov		al, [cs:bx+IDEVARS.bIRQ]
	cmp		al, 8
	jae		SHORT .UnmaskHighIrqController
	test	al, al
	jnz		SHORT .UnmaskLowIrqController
	ret		; Interrupts disabled

;--------------------------------------------------------------------
; .UnmaskHighIrqController
;	Parameters:
;		AL:		IRQ number (8...15)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.UnmaskHighIrqController:
	sub		al, 8				; Slave interrupt number
	mov		dx, PORT_8259SL_IMR	; Load Slave Mask Register address
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
ALIGN JUMP_ALIGN
.UnmaskLowIrqController:
	mov		dx, PORT_8259MA_IMR	; Load Mask Register address
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
;ALIGN JUMP_ALIGN
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
	ret
