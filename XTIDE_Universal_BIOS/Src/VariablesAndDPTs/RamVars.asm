; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessings RAMVARS.

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
; Initializes RAMVARS.
; Drive detection can be started after this function returns.
;
; RamVars_Initialize
;	Parameters:
;		Nothing
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		AX, CX, DI
;--------------------------------------------------------------------
RamVars_Initialize:
	push	es
	; Fall to .StealMemoryForRAMVARS

;--------------------------------------------------------------------
; .StealMemoryForRAMVARS
;	Parameters:
;		Nothing
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.StealMemoryForRAMVARS:
%ifndef USE_AT
	mov		ax, LITE_MODE_RAMVARS_SEGMENT
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .InitializeRamvars	; No need to steal RAM
%endif

	LOAD_BDA_SEGMENT_TO	ds, ax, !		; Zero AX
	mov		al, [cs:ROMVARS.bStealSize]
	sub		[BDA.wBaseMem], ax
	mov		ax, [BDA.wBaseMem]
	eSHL_IM	ax, 6						; Segment to first stolen kB (*=40h)
	; Fall to .InitializeRamvars

;--------------------------------------------------------------------
; .InitializeRamvars
;	Parameters:
;		AX:		RAMVARS segment
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		AX, CX, DI, ES
;--------------------------------------------------------------------
.InitializeRamvars:
	mov		ds, ax
	mov		es, ax
	mov		cx, RAMVARS_size
	xor		di, di
	call	Memory_ZeroESDIwithSizeInCX
	mov		WORD [RAMVARS.wDrvDetectSignature], RAMVARS_DRV_DETECT_SIGNATURE
	mov		WORD [RAMVARS.wSignature], RAMVARS_RAM_SIGNATURE
;; There used to be a DriveXlate_Reset call here.  It isn't necessary, as we reset
;; when entering the boot menu and also before transferring control at boot time and
;; for ROM boots (in int19h.asm).

	pop		es
	ret

;--------------------------------------------------------------------
; Returns segment to RAMVARS.
; RAMVARS might be located at the top of interrupt vectors (0030:0000h)
; or at the top of system base RAM.
;
; RamVars_GetSegmentToDS
;	Parameters:
;		Nothing
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_GetSegmentToDS:

%ifndef USE_AT	; Always in Full Mode for AT builds
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jnz		SHORT .GetStolenSegmentToDS
	%ifndef USE_186
		mov		di, LITE_MODE_RAMVARS_SEGMENT
		mov		ds, di
	%else
		push	LITE_MODE_RAMVARS_SEGMENT
		pop		ds
	%endif
	ret
%endif

ALIGN JUMP_ALIGN
.GetStolenSegmentToDS:
	LOAD_BDA_SEGMENT_TO	ds, di
	mov		di, [BDA.wBaseMem]		; Load available base memory size in kB
	eSHL_IM	di, 6					; Segment to first stolen kB (*=40h)
ALIGN JUMP_ALIGN
.LoopStolenKBs:
	mov		ds, di					; EBDA segment to DS
	add		di, BYTE 64				; DI to next stolen kB
	cmp		WORD [RAMVARS.wSignature], RAMVARS_RAM_SIGNATURE
	jne		SHORT .LoopStolenKBs	; Loop until sign found (always found eventually)
	ret


;--------------------------------------------------------------------
; RamVars_GetHardDiskCountFromBDAtoAX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AX:		Total hard disk count
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
%ifdef MODULE_BOOT_MENU
RamVars_GetHardDiskCountFromBDAtoAX:
	call	RamVars_GetCountOfKnownDrivesToAX
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, bx
	mov		bl, [BDA.bHDCount]
	MAX_U	al, bl
	pop		ds
	ret
%endif


;--------------------------------------------------------------------
; RamVars_GetCountOfKnownDrivesToAX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AX:		Total hard disk count
;	Corrupts registers:
;		None
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_GetCountOfKnownDrivesToAX:
	mov		ax, [RAMVARS.wFirstDrvAndCount]
	add		al, ah
	and		ax, BYTE 7fh
	ret

;--------------------------------------------------------------------
; RamVars_GetIdeControllerCountToCX
;	Parameters:
;		Nothing
;	Returns:
;		CX:		Number of IDE controllers to handle
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_GetIdeControllerCountToCX:
	eMOVZX	cx, [cs:ROMVARS.bIdeCnt]
	ret


%ifdef MODULE_SERIAL_FLOPPY
;--------------------------------------------------------------------
; RamVars_UnpackFlopCntAndFirstToAL
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AL:		First floppy drive number supported
;       CF:		Number of floppy drives supported (clear = 1, set = 2)
;		SF:		Emulating drives (clear = yes, set = no)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_UnpackFlopCntAndFirstToAL:
	mov		al, [RAMVARS.xlateVars+XLATEVARS.bFlopCntAndFirst]
	sar		al, 1
	ret
%endif


%if 0							; unused...
;--------------------------------------------------------------------
; RamVars_IsDriveDetectionInProgress
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		ZF:		Set if drive detection is in progress (ROM initialization)
;	Corrupts registers:
;		None
;--------------------------------------------------------------------
RamVars_IsDriveDetectionInProgress:
	cmp		WORD [RAMVARS.wSignature], RAMVARS_DRV_DETECT_SIGNATURE
	ret
%endif
