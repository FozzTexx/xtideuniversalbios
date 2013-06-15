; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for initializing the BIOS.

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
Initialize_FromMainBiosRomSearch:		; unused entrypoint ok
	pushf								; To store IF
	push	ds

%ifndef USE_186
	push	ax
	LOAD_BDA_SEGMENT_TO	ds, ax
%else
	push	BYTE 0
	pop		ds
%endif

	sti									; Enable interrupts for keystrokes
	test	BYTE [BDA.bKBFlgs1], (1<<2)	; Clears ZF if CTRL is held down
	jnz		SHORT .SkipRomInitialization

	; Install INT 19h handler (boot loader) where drives are detected
	mov		WORD [BIOS_BOOT_LOADER_INTERRUPT_19h*4], Int19h_BootLoaderHandler
	mov		[BIOS_BOOT_LOADER_INTERRUPT_19h*4+2], cs

	; Install special INT 13h hander that initializes XTIDE Universal BIOS
	; when our INT 19h is not called
	les		ax, [BIOS_DISK_INTERRUPT_13h*4]	; Load system INT 13h handler
	mov		[TEMPORARY_VECTOR_FOR_SYSTEM_INT13h*4], ax
	mov		[TEMPORARY_VECTOR_FOR_SYSTEM_INT13h*4+2], es
	mov		WORD [BIOS_DISK_INTERRUPT_13h*4], Int13hBiosInit_Handler
	mov		[BIOS_DISK_INTERRUPT_13h*4+2], cs

.SkipRomInitialization:
%ifndef USE_186
	pop		ax
%endif
	pop		ds
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
;		All, except ES
;--------------------------------------------------------------------
Initialize_AndDetectDrives:
	call	DetectPrint_InitializeDisplayContext
	call	DetectPrint_RomFoundAtSegment
	call	RamVars_Initialize
	call	BootVars_Initialize
	call	Interrupts_InitializeInterruptVectors	; HotkeyBar requires INT 40h so install handlers before drive detection
	call	DetectDrives_FromAllIDEControllers
	mov		[RAMVARS.wDrvDetectSignature], es		; No longer in drive detection mode (set normal timeouts)
	; Fall to .StoreDptPointersToIntVectors

;--------------------------------------------------------------------
; .StoreDptPointersToIntVectors
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
%ifdef MODULE_COMPATIBLE_TABLES
.StoreDptPointersToIntVectors:
%ifndef USE_AT
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .CompatibleDPTsCreated	; Only Full operating mode has extra RAM to spare
%endif

	mov		dl, 80h
	call	FindDPT_ForDriveNumberInDL	; DPT to DS:DI
	jc		SHORT .FindForDrive81h		; Store nothing if not our drive

	call	CompatibleDPT_CreateToAXSIforDriveDL
	mov		[es:HD0_DPT_POINTER_41h*4], si
	mov		[es:HD0_DPT_POINTER_41h*4+2], ax

.FindForDrive81h:
	mov		dl, 81h
	call	FindDPT_ForDriveNumberInDL
	jc		SHORT .CompatibleDPTsCreated

	call	CompatibleDPT_CreateToAXSIforDriveDL
	mov		[es:HD1_DPT_POINTER_46h*4], si
	mov		[es:HD1_DPT_POINTER_46h*4+2], ax
.CompatibleDPTsCreated:
%endif ; MODULE_COMPATIBLE_TABLES
	ret
