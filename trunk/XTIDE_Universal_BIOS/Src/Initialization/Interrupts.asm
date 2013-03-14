; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for initializing the BIOS.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Drives must be detected before this function is called!
;
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
	; Install INT 19h handler to properly reset the system
	mov		al, BIOS_BOOT_LOADER_INTERRUPT_19h	; INT 19h interrupt vector offset
	mov		si, Int19hReset_Handler				; INT 19h handler to reboot the system
	call	Interrupts_InstallHandlerToVectorInALFromCSSI

	; If no drives detected, leave system INT 13h and 40h handlers
	; in place. We need our INT 13h handler to swap drive letters.
%ifndef MODULE_DRIVEXLATE
	cmp		BYTE [RAMVARS.bDrvCnt], 0
	je		SHORT Interrupts_InstallHandlerToVectorInALFromCSSI.Interrupts_Return
%endif
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
	mov		ax, [es:BIOS_DISK_INTERRUPT_13h*4+2]; Load old INT 13h segment
	mov		[RAMVARS.fpOldI13h+2], ax			; Store old INT 13h segment
	xchg	dx, ax
	mov		ax, [es:BIOS_DISK_INTERRUPT_13h*4]	; Load old INT 13h offset
	mov		[RAMVARS.fpOldI13h], ax				; Store old INT 13h offset

%ifdef COPY_13H_HANDLER_TO_40H
	; Only store INT 13h handler to 40h if 40h is not already installed.
	; At least AMI BIOS for 286 stores 40h handler by itself and calls
	; 40h from 13h. That system locks to infinite loop if we copy 13h to 40h.
	call	FloppyDrive_IsInt40hInstalled
	jc		SHORT .Int40hAlreadyInstalled
	mov		[es:BIOS_DISKETTE_INTERRUPT_40h*4], ax		; Store old INT 13h offset
	mov		[es:BIOS_DISKETTE_INTERRUPT_40h*4+2], dx	; Store old INT 13h segment
.Int40hAlreadyInstalled:
%endif ; COPY_13H_HANDLER_TO_40H

	mov		al, BIOS_DISK_INTERRUPT_13h			; INT 13h interrupt vector offset
%ifdef RELOCATE_INT13H_STACK
	mov		si, Int13h_DiskFunctionsHandlerWithStackChange
%else
	mov		si, Int13h_DiskFunctionsHandler
%endif

%ifndef MODULE_IRQ
	; Fall to Interrupts_InstallHandlerToVectorInALFromCSSI
%else
	call	Interrupts_InstallHandlerToVectorInALFromCSSI
	; Fall to .InitializeHardwareIrqHandlers

;--------------------------------------------------------------------
; .InitializeHardwareIrqHandlers
;	Parameters:
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX, DX, SI, DI, AX
;--------------------------------------------------------------------
.InitializeHardwareIrqHandlers:
	call	RamVars_GetIdeControllerCountToCX
	mov		di, ROMVARS.ideVars0+IDEVARS.bIRQ	; CS:SI points to first IDEVARS
.IdeControllerLoop:
	mov		al, [cs:di]
	add		di, BYTE IDEVARS_size			; Increment to next controller
	call	.InstallLowOrHighIrqHandler
	loop	.IdeControllerLoop
.Return:
	ret		; This ret is shared with .InstallLowOrHighIrqHandler

;--------------------------------------------------------------------
; .InstallLowOrHighIrqHandler
;	Parameters:
;		AL:		IRQ number, 0 if IRQ disabled
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, SI
;--------------------------------------------------------------------
.InstallLowOrHighIrqHandler:
	test	al, al
	jz		SHORT .Return	; IRQ not used
	cmp		al, 8
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
;		AL, BX, SI
;--------------------------------------------------------------------
.InstallHighIrqHandler:
	add		al, BYTE HARDWARE_IRQ_8_INTERRUPT_70h - 8	; Interrupt vector number
	mov		si, IdeIrq_InterruptServiceRoutineForIrqs8to15
	jmp		SHORT Interrupts_InstallHandlerToVectorInALFromCSSI

;--------------------------------------------------------------------
; .InstallLowIrqHandler
;	Parameters:
;		AL:		IRQ number (0...7)
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL, BX, SI
;--------------------------------------------------------------------
.InstallLowIrqHandler:
	add		al, BYTE HARDWARE_IRQ_0_INTERRUPT_08h		; Interrupt vector number
	mov		si, IdeIrq_InterruptServiceRoutineForIrqs2to7
	; Fall to Interrupts_InstallHandlerToVectorInALFromCSSI
%endif ; MODULE_IRQ


;--------------------------------------------------------------------
; Interrupts_InstallHandlerToVectorInALFromCSSI
;	Parameters:
;		AL:		Interrupt vector number (for example 13h)
;		ES:		BDA and Interrupt Vector segment (zero)
;		CS:SI:	Ptr to interrupt handler
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
Interrupts_InstallHandlerToVectorInALFromCSSI:
	mov		bl, 4					; Shift for DWORD offset, MUL smaller than other alternatives
	mul		bl
	xchg	ax, bx
	mov		[es:bx], si				; Store offset
	mov		[es:bx+2], cs			; Store segment
.Interrupts_Return:
	ret


%ifdef MODULE_IRQ
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
	eMOVZX	bx, [di+DPT.bIdevarsOffset]
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

%endif ; MODULE_IRQ
