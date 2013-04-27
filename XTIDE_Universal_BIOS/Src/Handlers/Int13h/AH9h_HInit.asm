; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=9h, Initialize Drive Parameters.

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
; STORE_ERROR_FLAG_TO_DPT
;	Parameters:
;		%1:		Error flag to set
;		AH:		BIOS Error Code
;		DS:DI:	Ptr to DPT
;		CF:		Set if error code in AH
;	Returns:
;		CF:		Clear if no error
;				Set if error flag was set
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro STORE_ERROR_FLAG_TO_DPT 1
	mov		al, %1
	call	SetErrorFlagFromALwithErrorCodeInAH
%endmacro


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
; Initialize drive to be ready for use.
;
; AH9h_InitializeDriveForUse
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
AH9h_InitializeDriveForUse:
	xor		ax, ax				; Clear AH to assume no errors

%ifdef MODULE_ADVANCED_ATA
	; Clear Initialization Error flags from DPT
	mov		[di+DPT.bInitError], al
%endif

%ifdef MODULE_SERIAL
	; No need to do this for serial devices
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE	; Clears CF
	jz		SHORT .ContinueInitialization
	ret		; With AH and CF cleared
.ContinueInitialization:
%endif

	push	es
	push	si
	push	dx
	push	bx


;;;	SelectDrive
	; Try to select drive and wait until ready
	call	AccessDPT_GetDriveSelectByteToAL
	mov		[bp+IDEPACK.bDrvAndHead], al
	call	Device_SelectDrive
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_SELECT_DRIVE
%ifdef USE_386
	jc		.ReturnWithErrorCodeInAH
%else
	jnc		SHORT .ContinueInitializationSinceDriveSelectedSuccesfully
	jmp		.ReturnWithErrorCodeInAH
.ContinueInitializationSinceDriveSelectedSuccesfully:
%endif


;;; Set XT-CF mode
%ifdef MODULE_8BIT_IDE_ADVANCED
	call	AH1Eh_GetCurrentXTCFmodeToAX
	call	AH9h_SetModeFromALtoXTCF
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_SET_XTCF_MODE
.DoNotSetXTCFmode:
%endif	; MODULE_8BIT_IDE_ADVANCED

%ifdef MODULE_8BIT_IDE
;;; Set 8-bit PIO mode
	call	AH9h_Enable8bitModeForDevice8bitAta
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_SET_8BIT_MODE
.DoNotSet8bitMode:
%endif ; MODULE_8BIT_IDE


;;;	InitializeDeviceParameters
	; Initialize Logical Sectors per Track and Max Head number
	mov		ax, [di+DPT.wPchsHeadsAndSectors]
	dec		ax							; Max Head number
	xchg	ah, al
	mov		dl, al						; Sectors per track
	mov		al, COMMAND_INITIALIZE_DEVICE_PARAMETERS
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_BSY, FLG_STATUS_BSY)
	call	Idepack_StoreNonExtParametersAndIssueCommandFromAL
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_INITIALIZE_CHS_PARAMETERS
.SkipInitializeDeviceParameters:


;;;	SetWriteCache
	; Enable or Disable Write Cache
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	mov		bl, [cs:bx+DRVPARAMS.wFlags]
	push	bx	; Save .wFlags for later use in InitializeBlockMode
	and		bx, BYTE MASK_DRVPARAMS_WRITECACHE
	jz		SHORT .SkipSetWriteCache		; DEFAULT_WRITE_CACHE
	mov		si, [cs:bx+.rgbWriteCacheCommands]
	call	AH23h_SetControllerFeatures
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_SET_WRITE_CACHE
.SkipSetWriteCache:


;;;	RecalibrateDrive
	; Recalibrate drive by seeking to cylinder 0
	call	AH11h_RecalibrateDrive
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_RECALIBRATE_DRIVE


;;;	InitializeBlockMode
	; Initialize block mode transfers
	pop		ax	; Restore .wFlags saved in SetWriteCache
	test	al, FLG_DRVPARAMS_BLOCKMODE	; Tested here so block mode can be enabled with AH=24h
	jz		SHORT .BlockModeDisabled

	; Try block sizes until we find largest possible supported by drive
	mov		bl, 128
.TryNextBlockSize:
	mov		al, bl
	call	AH24h_SetBlockSize	; Stores block size to DPT
	jnc		SHORT .SupportedBlockSizeFound
	shr		bl, 1
	jnc		SHORT .TryNextBlockSize
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_SET_BLOCK_MODE
.BlockModeDisabled:
.SupportedBlockSizeFound:


%ifdef MODULE_ADVANCED_ATA
;;;	InitializePioMode
	; Initialize fastest supported PIO mode
	mov		dl, PIO_DEFAULT_MODE_DISABLE_IORDY
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_IORDY
	jz		SHORT .IordyNotSupported

	; Advanced PIO mode 3 and above
	mov		dl, [di+DPT_ADVANCED_ATA.bPioMode]
	or		dl, PIO_FLOW_CONTROL_MODE_xxx

.IordyNotSupported:
	mov		si, FEATURE_SET_TRANSFER_MODE
	call	AH23h_SetControllerFeatures
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_SET_PIO_MODE
%endif ; MODULE_ADVANCED_ATA


%ifdef MODULE_FEATURE_SETS
;;;	InitStandbyTimer
	; Initialize the standby timer (if supported)
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_POWER_MANAGEMENT_SUPPORTED
	jz		SHORT .NoPowerManagementSupport

	mov		al, COMMAND_IDLE
	mov		dl, [cs:ROMVARS.bIdleTimeout]
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_BSY, FLG_STATUS_BSY)
	call	Idepack_StoreNonExtParametersAndIssueCommandFromAL
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_INITIALIZE_STANDBY_TIMER
.NoPowerManagementSupport:
%endif ; MODULE_FEATURE_SETS


	; There might have been several errors so just return one error code for them all
.ReturnWithErrorCodeInAH:
%ifdef MODULE_ADVANCED_ATA
	mov		ah, [di+DPT.bInitError]
	test	ah, ah	; Clears CF
	jz		SHORT .ReturnWithSuccess
	mov		ah, RET_HD_RESETFAIL
	stc
.ReturnWithSuccess:
%endif

	pop		bx
	pop		dx
	pop		si
	pop		es
	ret


.rgbWriteCacheCommands:
	db		0								; DEFAULT_WRITE_CACHE
	db		FEATURE_DISABLE_WRITE_CACHE		; DISABLE_WRITE_CACHE
	db		FEATURE_ENABLE_WRITE_CACHE		; ENABLE_WRITE_CACHE



;--------------------------------------------------------------------
; SetErrorFlagFromALwithErrorCodeInAH
;	Parameters:
;		AH:		BIOS Error Code
;		AL:		Error flag to set
;		DS:DI:	Ptr to DPT
;		CF:		Set if error code in AH
;				Clear if AH = 0
;	Returns:
;		CF:		Clear if no error
;				Set if error flag was set
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
IgnoreInvalidCommandError:
	xor		ah, ah	; Clears CF
SetErrorFlagFromALwithErrorCodeInAH:
	jnc		SHORT .NoErrorFlagToSet
	cmp		ah, RET_HD_INVALID
	jbe		SHORT IgnoreInvalidCommandError

	or		[di+DPT.bInitError], al
	stc
.NoErrorFlagToSet:
	ret


%ifdef MODULE_8BIT_IDE_ADVANCED
;--------------------------------------------------------------------
; AH9h_SetModeFromALtoXTCF
;	Parameters:
;		AL:		XT-CF Mode to set
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		Clear if successful or device is not XT-CF
;				Set if failed to set mode for XT-CF
;	Corrupts registers:
;		AL, BX, CX, DX, SI
;--------------------------------------------------------------------
AH9h_SetModeFromALtoXTCF:
	call	AccessDPT_IsThisDeviceXTCF
	jne		SHORT IgnoreInvalidCommandError
	jmp		AH1Eh_ChangeXTCFmodeBasedOnModeInAL
%endif ; MODULE_8BIT_IDE_ADVANCED


%ifdef MODULE_8BIT_IDE
;--------------------------------------------------------------------
; AH9h_Enable8bitModeForDevice8bitAta
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		Clear if successful or device is not DEVICE_8BIT_ATA
;				Set if failed to set 8-bit mode for DEVICE_8BIT_ATA
;	Corrupts registers:
;		AL, BX, CX, DX, SI
;--------------------------------------------------------------------
AH9h_Enable8bitModeForDevice8bitAta:
	cmp		BYTE [di+DPT_ATA.bDevice], DEVICE_8BIT_ATA
	jne		SHORT IgnoreInvalidCommandError
	jmp		AH23h_Enable8bitPioMode
%endif
