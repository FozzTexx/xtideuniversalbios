; Project name	:	XTIDE Universal BIOS
; Description	:	Interrupt handling related functions.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
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
; IdeIrq_WaitForIRQ
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeIrq_WaitForIRQ:
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, ax, !		; Zero AX
	mov		ah, OS_HOOK_DEVICE_BUSY		; Hard disk busy (AX=9000h)
	cli									; Disable interrupts
	dec		BYTE [BDA.bHDTaskFlg]		; Clear to zero if still waiting for IRQ
	pop		ds
	jnz		SHORT .ReturnFromWaitNotify	; IRQ already! (CompactFlash was faster than CPU)	
	int		BIOS_SYSTEM_INTERRUPT_15h	; OS hook, device busy

.ReturnFromWaitNotify:
	sti									; Enable interrupts
	ret


;--------------------------------------------------------------------
; IDE Interrupt Service Routines.
;
; IdeIrq_InterruptServiceRoutineForIrqs2to7
; IdeIrq_InterruptServiceRoutineForIrqs8to15
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeIrq_InterruptServiceRoutineForIrqs2to7:
	push	ax
	mov		al, COMMAND_END_OF_INTERRUPT

%ifdef USE_AT
	jmp		SHORT AcknowledgeMasterInterruptController

ALIGN JUMP_ALIGN
IdeIrq_InterruptServiceRoutineForIrqs8to15:
	push	ax
	mov		al, COMMAND_END_OF_INTERRUPT
	out		SLAVE_8259_COMMAND_out, al	; Acknowledge Slave 8259
	JMP_DELAY
AcknowledgeMasterInterruptController:
%endif ; USE_AT

	out		MASTER_8259_COMMAND_out, al	; Acknowledge Master 8259

	; Set Task Flag
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, ax, !		; Clear AL and CF for INT 15h
	dec		BYTE [BDA.bHDTaskFlg]		; Set task flag (or clear if IRQ occurred before call to INT 15h AH=90h)
	sti									; Enable interrupts
	pop		ds

	; Issue Int 15h, function AX=9100h (Interrupt ready)
	jz		SHORT .DoNotPostSinceIrqOccurredBeforeWait
	mov		ah, OS_HOOK_DEVICE_POST		; Interrupt ready, device 0 (HD)
	int		BIOS_SYSTEM_INTERRUPT_15h
.DoNotPostSinceIrqOccurredBeforeWait:

	pop		ax
	iret
