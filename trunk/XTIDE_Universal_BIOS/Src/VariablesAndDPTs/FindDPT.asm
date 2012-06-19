; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for finding Disk Parameter Table.

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
; Checks if drive is handled by this BIOS, and return DPT pointer.
;
; FindDPT_ForDriveNumberInDL
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Cleared if drive is handled by this BIOS
;				Set if drive belongs to some other BIOS
;		DI:		DPT Pointer if drive is handled by this BIOS
;				Zero if drive belongs to some other BIOS
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ForDriveNumberInDL:
	xchg	di, ax								; Save the contents of AX in DI

;
; Check Our Hard Disks
;
	mov		ax, [RAMVARS.wFirstDrvAndCount]		; Drive count to AH, First number to AL
	add		ah, al								; One past last drive to AH

%ifdef MODULE_SERIAL_FLOPPY
	cmp		dl, ah								; Above last supported?
	jae		SHORT .HardDiskNotHandledByThisBIOS

	cmp		dl, al								; Below first supported?
	jae		SHORT .CalcDPTForDriveNumber

ALIGN JUMP_ALIGN
.HardDiskNotHandledByThisBIOS:
;
; Check Our Floppy Disks
;
	call	RamVars_UnpackFlopCntAndFirstToAL
	js		SHORT .DiskIsNotHandledByThisBIOS

	cbw											; Always 0h (no floppy drive covered above)
	adc		ah, al								; Add in first drive number and number of drives

	cmp		ah, dl								; Check second drive if two, first drive if only one
	jz		SHORT .CalcDPTForDriveNumber
	cmp		al, dl								; Check first drive in all cases, redundant but OK to repeat
	jnz		SHORT .DiskIsNotHandledByThisBIOS
%else
	cmp		dl, ah								; Above last supported?
	jae		SHORT .DiskIsNotHandledByThisBIOS

	cmp		dl, al								; Below first supported?
	jb		SHORT .DiskIsNotHandledByThisBIOS
%endif
	; fall-through to CalcDPTForDriveNumber

;--------------------------------------------------------------------
; Finds Disk Parameter Table for drive number.
; Not intended to be called except by FindDPT_ForDriveNumberInDL
;
; CalcDPTForDriveNumber
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;       DI:     Saved copy of AX from entry at FindDPT_ForDriveNumberInDL
;	Returns:
;		DS:DI:	Ptr to DPT
;       CF:     Clear
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.CalcDPTForDriveNumber:
	push	dx

%ifdef MODULE_SERIAL_FLOPPY
	mov		ax, [RAMVARS.wFirstDrvAndCount]

	test	dl, dl
	js		.harddisk

	call	RamVars_UnpackFlopCntAndFirstToAL
	add		dl, ah						; add in end of hard disk DPT list, floppies start immediately after

ALIGN JUMP_ALIGN
.harddisk:
	sub		dl, al						; subtract off beginning of either hard disk or floppy list (as appropriate)
%else
	sub		dl, [RAMVARS.bFirstDrv]		; subtract off beginning of hard disk list
%endif

.CalcDPTForNewDrive:
	mov		al, LARGEST_DPT_SIZE

	mul		dl
	add		ax, BYTE RAMVARS_size		; Clears CF (will not overflow)

	pop		dx

	xchg	di, ax						; Restore AX from entry at FindDPT_ForDriveNumber, put DPT pointer in DI
	ret

ALIGN JUMP_ALIGN
.DiskIsNotHandledByThisBIOS:
;
; Drive not found...
;
	xor		ax, ax								; Clear DPT pointer
	stc											; Is not supported by our BIOS

	xchg	di, ax								; Restore AX from save at top
	ret


;--------------------------------------------------------------------
; FindDPT_ForIdevarsOffsetInDL
;	Parameters:
;		DL:		Offset to IDEVARS to search for
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:		Ptr to first DPT with same IDEVARS as in DL
;		CF:			Clear if wanted DPT found
;					Set if DPT not found, or no DPTs present
;	Corrupts registers:
;		SI
;--------------------------------------------------------------------
FindDPT_ForIdevarsOffsetInDL:
	mov		si, IterateFindFirstDPTforIdevars			; iteration routine (see below)
	jmp		SHORT FindDPT_IterateAllDPTs				; look for the first drive on this controller, if any

;--------------------------------------------------------------------
; Iteration routine for FindDPT_ForIdevarsOffsetInDL,
; for use with IterateAllDPTs
;
; Returns when DPT is found on the controller with Idevars offset in DL
;
; IterateFindFirstDPTforIdevars
;       DL:		Offset to IDEVARS to search from DPTs
;		DS:DI:	Ptr to DPT to examine
;	Returns:
;		CF:		Clear if wanted DPT found
;				Set if wrong DPT
;--------------------------------------------------------------------
IterateFindFirstDPTforIdevars:
	cmp		dl, [di+DPT.bIdevarsOffset]			; Clears CF if matched
	je		.done
	stc											; Set CF for not found
.done:
	ret


;--------------------------------------------------------------------
; Finds pointer to first unused Disk Parameter Table.
; Should only be used before DetectDrives is complete (not valid after this time).
;
; FindDPT_ForNewDriveToDSDI
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to first unused DPT
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ForNewDriveToDSDI:
	push	dx

%ifdef MODULE_SERIAL_FLOPPY
	mov		dx, [RAMVARS.wDrvCntAndFlopCnt]
	add		dl, dh
%else
	mov		dl, [RAMVARS.bDrvCnt]
%endif

	jmp		short FindDPT_ForDriveNumberInDL.CalcDPTForNewDrive

;--------------------------------------------------------------------
; IterateToDptWithFlagsHighInBL
;	Parameters:
;		DS:DI:	Ptr to DPT to examine
;       BL:		Bit(s) to test in DPT.bFlagsHigh
;	Returns:
;		CF:		Clear if wanted DPT found
;				Set if wrong DPT
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IterateToDptWithFlagsHighInBL:
	test	[di+DPT.bFlagsHigh], bl				; Clears CF
	jnz		SHORT .ReturnRightDPT
	stc
.ReturnRightDPT:
	ret

;--------------------------------------------------------------------
; FindDPT_ToDSDIforSerialDevice
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to DPT
;		CF:		Set if wanted DPT found
;				Cleared if DPT not found
;	Corrupts registers:
;		SI
;--------------------------------------------------------------------
%ifdef MODULE_SERIAL
ALIGN JUMP_ALIGN
FindDPT_ToDSDIforSerialDevice:
	mov		bl, FLGH_DPT_SERIAL_DEVICE
; fall-through
%endif

;--------------------------------------------------------------------
; FindDPT_ToDSDIforFlagsHigh
;	Parameters:
;		DS:		RAMVARS segment
;       BL:		Bit(s) to test in DPT.bFlagsHigh
;	Returns:
;		DS:DI:	Ptr to DPT
;		CF:		Set if wanted DPT found
;				Cleared if DPT not found
;	Corrupts registers:
;		SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ToDSDIforFlagsHighInBL:
	mov		si, IterateToDptWithFlagsHighInBL
	; Fall to IterateAllDPTs

;--------------------------------------------------------------------
; Iterates all Disk Parameter Tables.
;
; FindDPT_IterateAllDPTs
;	Parameters:
;		AX,BX,DX:	Parameters to callback function
;		CS:SI:		Ptr to callback function
;                   Callback routine should return CF=clear if found
;		DS:			RAMVARS segment
;	Returns:
;		DS:DI:		Ptr to wanted DPT (if found)
;					If not found, points to first empty DPT
;		CF:			Clear if wanted DPT found
;					Set if DPT not found, or no DPTs present
;	Corrupts registers:
;		Nothing unless corrupted by callback function
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_IterateAllDPTs:
	push	cx

	mov		di, RAMVARS_size			; Point DS:DI to first DPT
	eMOVZX	cx, [RAMVARS.bDrvCnt]
	jcxz	.NotFound					; Return if no drives

ALIGN JUMP_ALIGN
.LoopWhileDPTsLeft:
	call	si							; Is wanted DPT?
	jnc		SHORT .Found				;  If so, return
	add		di, BYTE LARGEST_DPT_SIZE	; Point to next DPT
	loop	.LoopWhileDPTsLeft

ALIGN JUMP_ALIGN
.NotFound:
	stc

ALIGN JUMP_ALIGN
.Found:
	pop		cx
	ret

