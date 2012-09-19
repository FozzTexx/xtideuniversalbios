; Project name	:	XTIDE Universal BIOS
; Description	:	Equates for 8259 Interrupt Controllers.

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

%ifndef INT_CONTROLLER_INC
%define INT_CONTROLLER_INC

; 8259 Master and Slave Interrupt Controller Ports
MASTER_8259_IRR_AND_ISR_in	EQU		20h		; Interrupt Request Register / Interrupt In-Service Register
MASTER_8259_COMMAND_out		EQU		20h		; Command output
MASTER_8259_IMR				EQU		21h		; Interrupt Mask Register
MASTER_8259_INIT_out		EQU		21h		; Initialization Command Parameters
SLAVE_8259_IRR_AND_ISR_in	EQU		0A0h	; Interrupt Request Register / Interrupt In-Service Register
SLAVE_8259_COMMAND_out		EQU		0A0h	; Command output
SLAVE_8259_IMR				EQU		0A1h	; Interrupt Mask Register
SLAVE_8259_INIT_out			EQU		0A1h	; Initialization Command Parameters

; 8259 Interrupt Controller Commands
COMMAND_CLEAR_ROTATE_IN_AUTOMATIC_EOI_MODE	EQU		00h
COMMAND_READ_INTERRUPT_REQUEST_REGISTER		EQU		0Ah
COMMAND_READ_INTERRUPT_INSERVICE_REGISTER	EQU		0Bh
COMMAND_END_OF_INTERRUPT					EQU		20h
COMMAND_NO_OPERATION						EQU		40h
COMMAND_CLEAR_SPECIAL_MASK_MODE				EQU		48h
COMMAND_SPECIFIC_EOI_FOR_IR0				EQU		60h
COMMAND_SPECIFIC_EOI_FOR_IR1				EQU		61h
COMMAND_SPECIFIC_EOI_FOR_IR2				EQU		62h
COMMAND_SPECIFIC_EOI_FOR_IR3				EQU		63h
COMMAND_SPECIFIC_EOI_FOR_IR4				EQU		64h
COMMAND_SPECIFIC_EOI_FOR_IR5				EQU		65h
COMMAND_SPECIFIC_EOI_FOR_IR6				EQU		66h
COMMAND_SPECIFIC_EOI_FOR_IR7				EQU		67h
COMMAND_SET_SPECIAL_MASK_MODE				EQU		68h
COMMAND_SET_ROTATE_IN_AUTOMATIC_EOI_MODE	EQU		80h
COMMAND_ROTATE_ON_NONSPECIFIC_EOI			EQU		0A0h
COMMAND_IR0_LOWEST_PRIORITY					EQU		0C0h
COMMAND_IR1_LOWEST_PRIORITY					EQU		0C1h
COMMAND_IR2_LOWEST_PRIORITY					EQU		0C2h
COMMAND_IR3_LOWEST_PRIORITY					EQU		0C3h
COMMAND_IR4_LOWEST_PRIORITY					EQU		0C4h
COMMAND_IR5_LOWEST_PRIORITY					EQU		0C5h
COMMAND_IR6_LOWEST_PRIORITY					EQU		0C6h
COMMAND_IR7_LOWEST_PRIORITY					EQU		0C7h
COMMAND_EOI_AND_IR0_LOWEST_PRIORITY			EQU		0E0h
COMMAND_EOI_AND_IR1_LOWEST_PRIORITY			EQU		0E1h
COMMAND_EOI_AND_IR2_LOWEST_PRIORITY			EQU		0E2h
COMMAND_EOI_AND_IR3_LOWEST_PRIORITY			EQU		0E3h
COMMAND_EOI_AND_IR4_LOWEST_PRIORITY			EQU		0E4h
COMMAND_EOI_AND_IR5_LOWEST_PRIORITY			EQU		0E5h
COMMAND_EOI_AND_IR6_LOWEST_PRIORITY			EQU		0E6h
COMMAND_EOI_AND_IR7_LOWEST_PRIORITY			EQU		0E7h


%endif ; INT_CONTROLLER_INC
