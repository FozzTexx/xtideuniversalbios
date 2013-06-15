; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=0h, Disk Controller Reset.

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
; Int 13h function AH=0h, Disk Controller Reset.
;
; Note: We handle all AH=0h calls, even for drives handled by other
; BIOSes!
;
; AH0h_HandlerForDiskControllerReset
;	Parameters:
;		DL:		Translated Drive number (ignored so all drives are reset)
;				If bit 7 is set all hard disks and floppy disks reset.
;		DS:DI:	Ptr to DPT (or Null if foreign drive)
;		SS:BP:	Ptr to IDEPACK
;	Returns with INTPACK:
;		AH:		Int 13h return status (from drive requested in DL)
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
AH0h_HandlerForDiskControllerReset:
	; Reset foreign Floppy and Hard Drives (those handled by other BIOSes)
	eMOVZX	bx, dl										; Copy requested drive to BL and zero BH to assume no errors

	xor		ah, ah										; Disk Controller Reset
	call	Int13h_CallPreviousInt13hHandler			; Reset floppy drives only or floppy drives and foreign hard disks
	call	BackupErrorCodeFromTheRequestedDriveToBH

%ifdef MODULE_SERIAL_FLOPPY
;
; "Reset" emulated serial floppy drives, if any.  There is nothing to actually do for this reset,
; but record the proper error return code if one of these floppy drives is the drive requested.
;
	call	RamVars_UnpackFlopCntAndFirstToAL
	cbw													; Clears AH (there are flop drives) or ffh (there are not)
														; Either AH has success code (flop drives are present)
														; or it doesn't matter because we won't match drive ffh

	cwd													; clears DX (there are flop drives) or ffffh (there are not)

	adc		dl, al										; second drive (CF set) if present
														; If no drive is present, this will result in ffh which
														; won't match a drive
	call	BackupErrorCodeFromTheRequestedDriveToBH
	mov		dl, al										; We may end up doing the first drive twice (if there is
	call	BackupErrorCodeFromTheRequestedDriveToBH	; only one drive), but doing it again is not harmful.
%endif
	test	bl, bl										; If we were called with a floppy disk, then we are done,
	jns		SHORT .SkipHardDiskReset					; don't do hard disks.

	; Resetting our hard disks will modify dl and bl to be idevars offset based instead of drive number based,
	; such that this call must be the last in the list of reset routines called.
	;
	; This needs to happen after ResetForeignDrives, as that call may have set the error code for 80h,
	; and we need to override that value if we are xlate'd into 80h with one of our drives.
	;
	call	ResetHardDisksHandledByOurBIOS

.SkipHardDiskReset:
	mov		ah, bh
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH


;--------------------------------------------------------------------
; BackupErrorCodeFromTheRequestedDriveToBH
;	Parameters:
;		AH:		Error code from the last resetted drive
;		DL:		Drive last resetted
;		BL:		Requested drive (DL when entering AH=00h)
;	Returns:
;		BH:		Backuped error code
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
BackupErrorCodeFromTheRequestedDriveToBH:
	cmp		dl, bl				; Requested drive?
	eCMOVE	bh, ah
	ret


;--------------------------------------------------------------------
; ResetHardDisksHandledByOurBIOS
;	Parameters:
;		BL:		Requested drive (DL when entering AH=00h)
;		DS:DI:	Ptr to DPT for requested drive
;				If DPT pointer is not available, or error result in BH won't be used anyway,
;				enter through .ErrorCodeNotUsed.
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		BH:		Error code from requested drive (if available)
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ResetHardDisksHandledByOurBIOS:
	xor		bl, bl										; Assume Null IdevarsOffset for now, assuming foreign drive
	test	di, di
	jz		SHORT .ErrorCodeNotUsed
	mov		bl, [di+DPT.bIdevarsOffset]					; replace drive number with Idevars pointer for cmp with dl
.ErrorCodeNotUsed:										; BH will be garbage on exit if this entry point is used,
														; but reset of all drives will still happen
	mov		dl, ROMVARS.ideVars0						; starting Idevars offset

    ; Get count of ALL Idevars structures, not just the ones that are configured.  This may seem odd,
    ; but it catches the .ideVarsSerialAuto structure, which would not be scanned if the count from
	; RamVars_GetIdeControllerCountToCX was used.  Unused controllers won't make a difference, since no DPT
	; will point to them.  Performance isn't an issue, as this is a reset operation.
    ;
	mov		cx, NUMBER_OF_IDEVARS

.loop:
	call	FindDPT_MasterOrSingleForIdevarsOffsetInDL
	jc		SHORT .ControllerNotAvailable

	; Reset controller (both Master and Slave Drive). We ignore error codes
	; here since initialization is the one that matters.
	push	cx
	push	dx
	push	bx
%ifdef MODULE_IRQ
	call	Interrupts_UnmaskInterruptControllerForDriveInDSDI
%endif
	call	Device_ResetMasterAndSlaveController
%ifdef MODULE_ADVANCED_ATA
	call	AdvAtaInit_InitializeControllerForDPTinDSDI
%endif
	pop		bx
	pop		dx

	; Initialize Master Drive
	call	AH9h_InitializeDriveForUse					; Initialize Master drive
	call	BackupErrorCodeFromTheRequestedDriveToBH

	; Initialize Slave Drive
	call	FindDPT_SlaveForIdevarsOffsetInDL
	jc		SHORT .SlaveDriveNotAvailable
	call	AH9h_InitializeDriveForUse
	; Here we have a small problem. Since DL now has offset to IDEVARS, it will be the same
	; for both Master and Slave Drive. We simply ignore error from slave drive reset since most
	; systems do not have slave drives at all and it is unlikely that AH=00h would be called for
	; specific drive anyway. AH=Dh is for that.

.SlaveDriveNotAvailable:
	pop		cx
.ControllerNotAvailable:
	add		dl, IDEVARS_size							; move Idevars pointer forward
	loop	.loop
	ret
