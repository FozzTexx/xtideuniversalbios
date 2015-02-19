; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for detecting drive for the BIOS.

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
; Detects all IDE hard disks to be controlled by this BIOS.
;
; DetectDrives_FromAllIDEControllers
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		All (not segments)
;--------------------------------------------------------------------
DetectDrives_FromAllIDEControllers:
	call	RamVars_GetIdeControllerCountToCX
	mov		bp, ROMVARS.ideVars0			; CS:BP now points to first IDEVARS

.DriveDetectLoop:							; Loop through IDEVARS
	push	cx

	mov		cx, g_szDetectMaster
	mov		bh, MASK_DRVNHEAD_SET								; Select Master drive
	call	StartDetectionWithDriveSelectByteInBHandStringInCX	; Detect and create DPT + BOOTNFO

	mov		cx, g_szDetectSlave
	mov		bh, MASK_DRVNHEAD_SET | FLG_DRVNHEAD_DRV
	call	StartDetectionWithDriveSelectByteInBHandStringInCX

%ifdef MODULE_HOTKEYS
%ifdef MODULE_SERIAL
	; This is only needed for hotkey F6 (ComDtct) to work
	call	ScanHotkeysFromKeyBufferAndStoreToBootvars			; Done here while CX is still protected
%endif
%endif

	pop		cx

	add		bp, BYTE IDEVARS_size			; Point to next IDEVARS

%ifdef MODULE_SERIAL
	jcxz	.AddHardDisks					; Set to zero on .ideVarsSerialAuto iteration (if any)
%endif
	loop	.DriveDetectLoop

%ifdef MODULE_SERIAL
;----------------------------------------------------------------------
;
; if serial drive detected, do not scan (avoids duplicate drives and isn't needed - we already have a connection)
;
	call	FindDPT_ToDSDIforSerialDevice	; Does not modify AX
	jnc		.AddHardDisks

	mov		bp, ROMVARS.ideVarsSerialAuto	; Point to our special IDEVARS structure, just for serial scans

%ifdef MODULE_HOTKEYS
	cmp		al, COM_DETECT_HOTKEY_SCANCODE	; Set by last call to ScanHotkeysFromKeyBufferAndStoreToBootvars above
	je		.DriveDetectLoop
%endif

	mov		al, [cs:ROMVARS.wFlags]			; Configurator set to always scan?
	or		al, [es:BDA.bKBFlgs1]			; Or, did the user hold down the ALT key?
	and		al, 8							; 8 = alt key depressed, same as FLG_ROMVARS_SERIAL_ALWAYSDETECT
	jnz		.DriveDetectLoop
%endif ; MODULE_SERIAL

.AddHardDisks:
;----------------------------------------------------------------------
;
; Add in hard disks to BDA, finalize our Count and First variables
;
; Note that we perform the add to bHDCount and store bFirstDrv even if the count is zero.
; This is done because we use the value of .bFirstDrv to know how many drives were in the system
; at the time of boot, and to return that number on int13h/8h calls.  Because the count is zero,
; FindDPT_ForDriveNumber will not find any drives that are ours.
;
	mov		cx, [RAMVARS.wDrvCntAndFlopCnt]		; Our count of hard disks
	mov		al, [es:BDA.bHDCount]
	add		[es:BDA.bHDCount], cl		; Add our drives to the system count
	or		al, 80h						; Or in hard disk flag
	mov		[RAMVARS.bFirstDrv], al		; Store first drive number

.AddFloppies:
%ifdef MODULE_SERIAL_FLOPPY
;----------------------------------------------------------------------
;
; Add in any emulated serial floppy drives, finalize our packed Count and First variables
;
	dec		ch
	mov		al, ch
	js		.NoFloppies						; if no drives are present, we store 0ffh

	call	FloppyDrive_GetCountFromBIOS_or_BDA

	push	ax

	add		al, ch							; Add our drives to existing drive count
	cmp		al, 3							; For BDA, max out at 4 drives (ours is zero based)
	jb		.MaxBDAFloppiesExceeded
	mov		al, 3
.MaxBDAFloppiesExceeded:
	eROR_IM	al, 2							; move to bits 6-7
	inc		ax								; low order bit, indicating floppy drive exists

	mov		ah, 3Eh							; AND mask to AH (all bits set except floppy drive count/present)
	and		ah, [es:BDA.wEquipment]			; Load Equipment WORD low byte and mask off drive number and drives present bit
	or		al, ah							; Or in new values
	mov		[es:BDA.wEquipment], al			; and store

	mov		al, 1Eh							; BDA pointer to Floppy DPT
	mov		si, AH8h_FloppyDPT
	call	Interrupts_InstallHandlerToVectorInALFromCSSI

	pop		ax

	shr		ch, 1							; number of drives, 1 or 2 only, to CF flag (clear=1, set=2)
	rcl		al, 1							; starting drive number in upper 7 bits, number of drives in low bit
.NoFloppies:
	mov		[RAMVARS.xlateVars+XLATEVARS.bFlopCntAndFirst], al
%endif
	ret

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if FLG_ROMVARS_SERIAL_SCANDETECT != 8
		%error "DetectDrives is currently coded to assume that FLG_ROMVARS_SERIAL_SCANDETECT is the same bit as the ALT key code in the BDA.  Changes in the code will be needed if these values are no longer the same."
	%endif
%endif


;--------------------------------------------------------------------
; StartDetectionWithDriveSelectByteInBHandStringInCX
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		CX:		Offset to "Master" or "Slave" string
;		CS:BP:	Ptr to IDEVARS for the drive
;		DS:		RAMVARS segment
;		ES:		Zero (BDA segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BL, CX, DX, SI, DI
;--------------------------------------------------------------------
StartDetectionWithDriveSelectByteInBHandStringInCX:
	call	DetectPrint_StartDetectWithMasterOrSlaveStringInCXandIdeVarsInCSBP

%ifdef MODULE_HOTKEYS
	call	HotkeyBar_UpdateDuringDriveDetection
%endif
	; Fall to .ReadAtaInfoFromHardDisk


;--------------------------------------------------------------------
; .ReadAtaInfoFromHardDisk
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DX:		Autodetected port (for devices that support autodetection)
;		CS:BP:	Ptr to IDEVARS for the drive
;		DS:		RAMVARS segment
;		ES:		Zero (BDA segment)
;	Returns:
;		CF:		Cleared if ATA-information read successfully
;				Set if any error
;	Corrupts registers:
;		AX, BL, CX, DX, SI, DI
;--------------------------------------------------------------------
.ReadAtaInfoFromHardDisk:
	mov		si, BOOTVARS.rgbAtaInfo		; ES:SI now points to ATA info location
	push	es
	push	si
	push	dx
	push	bx
	call	Device_IdentifyToBufferInESSIwithDriveSelectByteInBH
	pop		bx
	pop		dx
	pop		si
	pop		es
	jnc		SHORT CreateBiosTablesForHardDisk
	; Fall to .ReadAtapiInfoFromDrive

.ReadAtapiInfoFromDrive:				; Not yet implemented
	;call	ReadAtapiInfoFromDrive		; Assume CD-ROM
	;jnc	SHORT _CreateBiosTablesForCDROM

	;jmp	short DetectDrives_DriveNotFound
;;; fall-through instead of previous jmp instruction
;--------------------------------------------------------------------
; DetectDrives_DriveNotFound
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Set (from DetectPrint_NullTerminatedStringFromCSSIandSetCF)
;	Corrupts registers:
;		AX, SI
;--------------------------------------------------------------------
DetectDrives_DriveNotFound:
	mov		si, g_szNotFound
	jmp		DetectPrint_NullTerminatedStringFromCSSIandSetCF


;--------------------------------------------------------------------
; CreateBiosTablesForHardDisk
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		DX:		Autodetected port (for devices that support autodetection)
;		CS:BP:	Ptr to IDEVARS for the drive
;		ES:SI	Ptr to ATA information for the drive
;		DS:		RAMVARS segment
;		ES:		BDA segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
CreateBiosTablesForHardDisk:
%ifndef NO_ATAID_VALIDATION
	push	bx
	call	AtaID_VerifyFromESSI
	pop		bx
	jnz		SHORT DetectDrives_DriveNotFound
%endif
	call	CreateDPT_FromAtaInformation
	jc		SHORT DetectDrives_DriveNotFound
	call	DriveDetectInfo_CreateForHardDisk
	jmp		SHORT DetectPrint_DriveNameFromDrvDetectInfoInESBX
