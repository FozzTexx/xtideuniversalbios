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
Initialize_FromMainBiosRomSearch:			; unused entrypoint ok
	pushf
	push	es
	push	ds
	ePUSHA

	LOAD_BDA_SEGMENT_TO	es, ax
	sti										; Enable interrupts
	test	BYTE [es:BDA.bKBFlgs1], (1<<2)	; Clears ZF if CTRL is held down
	jnz		SHORT .SkipRomInitialization

	; Install INT 19h handler (boot loader) where drives are detected
	mov		al, BIOS_BOOT_LOADER_INTERRUPT_19h
	mov		si, Int19h_BootLoaderHandler
	call	Interrupts_InstallHandlerToVectorInALFromCSSI

.SkipRomInitialization:
	ePOPA
	pop		ds
	pop		es
	popf
	retf


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
	call	DetectPrint_InitializeDisplayContext
	call	DetectPrint_RomFoundAtSegment
	call	RamVars_Initialize
	call	BootVars_Initialize
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
	call	FindDPT_ForDriveNumberInDL   ; DPT to DS:DI
	jc		SHORT .FindForDrive81h	; Store nothing if not our drive
	mov		[es:HD0_DPT_POINTER_41h*4], di
	mov		[es:HD0_DPT_POINTER_41h*4+2], ds
.FindForDrive81h:
	inc		dx
	call	FindDPT_ForDriveNumberInDL
	jc		SHORT .ResetDetectedDrives
	mov		[es:HD1_DPT_POINTER_46h*4], di
	mov		[es:HD1_DPT_POINTER_46h*4+2], ds
	; Fall to .ResetDetectedDrives

;--------------------------------------------------------------------
; .ResetDetectedDrives
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except DS and ES
;--------------------------------------------------------------------
.ResetDetectedDrives:
	call	Idepack_FakeToSSBP
	call	AH0h_ResetAllOurHardDisksAtTheEndOfDriveInitialization
	add		sp, BYTE EXTRA_BYTES_FOR_INTPACK
	ret
