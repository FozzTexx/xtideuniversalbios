; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=9h, Initialize Drive Parameters.

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
; Int 13h function AH=9h, Initialize Drive Parameters.
;
; AH9h_HandlerForInitializeDriveParameters
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
AH9h_HandlerForInitializeDriveParameters:
%ifndef USE_186
	call	AH9h_InitializeDriveForUse
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%else
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall to AH9h_InitializeDriveForUse
%endif


;--------------------------------------------------------------------
; Initialized drive to be ready for use.
;
; AH9h_InitializeDriveForUse
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
AH9h_InitializeDriveForUse:
	push	es
	push	si

%ifdef MODULE_SERIAL
	; no need to do this for serial devices
	xor		ah, ah
	test	byte [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE	; Clears CF
	jnz		.ReturnWithErrorCodeInAH

%else
	; Clear Initialization Error flags from DPT
	mov		BYTE [di+DPT_ATA.bInitError], 0
%endif

	; Try to select drive and wait until ready
	call	AccessDPT_GetDriveSelectByteToAL
	mov		[bp+IDEPACK.bDrvAndHead], al
	call	Device_SelectDrive
	mov		al, FLG_INITERROR_FAILED_TO_SELECT_DRIVE
	call	SetErrorFlagFromALwithErrorCodeInAH
	jc		SHORT .ReturnWithErrorCodeInAH

	; Initialize CHS parameters if LBA is not used
	call	InitializeDeviceParameters
	mov		al, FLG_INITERROR_FAILED_TO_INITIALIZE_CHS_PARAMETERS
	call	SetErrorFlagFromALwithErrorCodeInAH

	; Enable or Disable Write Cache
	call	SetWriteCache
	mov		al, FLG_INITERROR_FAILED_TO_SET_WRITE_CACHE
	call	SetErrorFlagFromALwithErrorCodeInAH

	; Recalibrate drive by seeking to cylinder 0
.RecalibrateDrive:
	call	AH11h_RecalibrateDrive
	mov		al, FLG_INITERROR_FAILED_TO_RECALIBRATE_DRIVE
	call	SetErrorFlagFromALwithErrorCodeInAH

	; Initialize block mode transfers
.InitializeBlockMode:
	call	InitializeBlockMode
	mov		al, FLG_INITERROR_FAILED_TO_SET_BLOCK_MODE
	call	SetErrorFlagFromALwithErrorCodeInAH

%ifdef MODULE_ADVANCED_ATA
; Initialize fastest supported PIO mode
.InitializePioMode:
	call	InitializePioMode
	mov		al, FLG_INITERROR_FAILED_TO_SET_PIO_MODE
	call	SetErrorFlagFromALwithErrorCodeInAH
%endif

	; There might have been several errors so just return
	; one error code for them all
	cmp		BYTE [di+DPT_ATA.bInitError], 0
	je		SHORT .ReturnWithErrorCodeInAH
	mov		ah, RET_HD_RESETFAIL
	stc

.ReturnWithErrorCodeInAH:
	pop		si
	pop		es
	ret


;--------------------------------------------------------------------
; InitializeDeviceParameters
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		BIOS Error code
;		CF:		Cleared if successful
;				Set if any error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
InitializeDeviceParameters:
	; No need to initialize CHS parameters if LBA mode enabled
	test	BYTE [di+DPT.bFlagsLow], FLG_DRVNHEAD_LBA	; Clear CF
	jnz		SHORT ReturnSuccessSinceInitializationNotNeeded

	; Initialize Logical Sectors per Track and Max Head number
	mov		ah, [di+DPT.bPchsHeads]
	dec		ah							; Max Head number
	mov		dl, [di+DPT.bPchsSectors]	; Sectors per Track
	mov		al, COMMAND_INITIALIZE_DEVICE_PARAMETERS
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_BSY, FLG_STATUS_BSY)
	jmp		Idepack_StoreNonExtParametersAndIssueCommandFromAL


;--------------------------------------------------------------------
; SetWriteCache
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		BIOS Error code
;		CF:		Cleared if successful
;				Set if any error
;	Corrupts registers:
;		AL, BX, CX, DX, SI
;--------------------------------------------------------------------
SetWriteCache:
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	mov		bl, [cs:bx+DRVPARAMS.wFlags]
	and		bx, BYTE MASK_DRVPARAMS_WRITECACHE
	jz		SHORT ReturnSuccessSinceInitializationNotNeeded		; DEFAULT_WRITE_CACHE
	mov		si, [cs:bx+.rgbWriteCacheCommands]
	jmp		AH23h_SetControllerFeatures

.rgbWriteCacheCommands:
	db		0								; DEFAULT_WRITE_CACHE
	db		FEATURE_DISABLE_WRITE_CACHE		; DISABLE_WRITE_CACHE
	db		FEATURE_ENABLE_WRITE_CACHE		; ENABLE_WRITE_CACHE


%ifdef MODULE_ADVANCED_ATA
;--------------------------------------------------------------------
; InitializePioMode
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		BIOS Error code
;		CF:		Cleared if successful
;				Set if any error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
InitializePioMode:
	mov		dl, PIO_DEFAULT_MODE_DISABLE_IORDY
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_IORDY
	jz		SHORT .IordyNotSupported

	; Advanced PIO mode 3 and above
	mov		dl, [di+DPT_ADVANCED_ATA.bPioMode]
	or		dl, PIO_FLOW_CONTROL_MODE_xxx

.IordyNotSupported:
	mov		si, FEATURE_SET_TRANSFER_MODE
	jmp		AH23h_SetControllerFeatures
%endif


;--------------------------------------------------------------------
; InitializeBlockMode
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		BIOS Error code
;		CF:		Cleared if successful
;				Set if any error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
InitializeBlockMode:
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_BLOCK_MODE_SUPPORTED	; Clear CF
	jz		SHORT .BlockModeNotSupportedOrDisabled
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	test	BYTE [cs:bx+DRVPARAMS.wFlags], FLG_DRVPARAMS_BLOCKMODE
	jz		SHORT .BlockModeNotSupportedOrDisabled

	; Try block sizes until we find largest possible supported by drive
	mov		bl, 128
.TryNextBlockSize:
	mov		al, bl
	call	AH24h_SetBlockSize
	jnc		SHORT .SupportedBlockSizeFound
	shr		bl, 1						; Try next size
	jmp		SHORT .TryNextBlockSize
.SupportedBlockSizeFound:
	mov		[di+DPT_ATA.bBlockSize], bl
.BlockModeNotSupportedOrDisabled:
ReturnSuccessSinceInitializationNotNeeded:
	ret


;--------------------------------------------------------------------
; SetErrorFlagFromALwithErrorCodeInAH
;	Parameters:
;		AH:		BIOS Error Code
;		AL:		Error flag to set
;		DS:DI:	Ptr to DPT
;	Returns:
;		CF:		Clear if no error
;				Set if error flag was set
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
SetErrorFlagFromALwithErrorCodeInAH:
	jnc		SHORT .NoErrorFlagToSet
	cmp		ah, RET_HD_INVALID
	jbe		SHORT .IgnoreInvalidCommandError

	or		[di+DPT_ATA.bInitError], al
	stc
	ret
.IgnoreInvalidCommandError:
	xor		ah, ah
.NoErrorFlagToSet:
	ret
