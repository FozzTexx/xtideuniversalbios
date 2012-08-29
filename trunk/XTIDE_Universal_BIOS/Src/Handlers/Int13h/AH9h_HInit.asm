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
;		AL, BX, CX, DX
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


;;;	SelectDrive
	; Try to select drive and wait until ready
	call	AccessDPT_GetDriveSelectByteForOldInt13hToAL
	mov		[bp+IDEPACK.bDrvAndHead], al
	call	Device_SelectDrive
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_SELECT_DRIVE
	jnc		SHORT .ContinueInitializationSinceDriveSelectedSuccesfully
	jmp		.ReturnWithErrorCodeInAH
.ContinueInitializationSinceDriveSelectedSuccesfully:


;;;	InitializeDeviceParameters
	; Initialize CHS parameters if LBA is not used and
	; user has specified P-CHS parameters
	test	BYTE [di+DPT.bFlagsLow], FLGL_DPT_ASSISTED_LBA
	jnz		SHORT .SkipInitializeDeviceParameters		; No need to initialize CHS parameters if LBA mode enabled
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	test	BYTE [cs:bx+DRVPARAMS.wFlags], FLG_DRVPARAMS_USERCHS    ; User specified P-CHS?
	jz		SHORT .SkipInitializeDeviceParameters

	; Initialize Logical Sectors per Track and Max Head number
	mov		ax, [cs:bx+DRVPARAMS.wHeadsAndSectors]
	dec		ax							; Max Head number
	xchg	al, ah						; Heads now in AH
	mov		dx, ax						; Sectors per Track now in DL
	mov		al, COMMAND_INITIALIZE_DEVICE_PARAMETERS
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_BSY, FLG_STATUS_BSY)
	call	Idepack_StoreNonExtParametersAndIssueCommandFromAL
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_INITIALIZE_CHS_PARAMETERS
.SkipInitializeDeviceParameters:


%ifdef MODULE_8BIT_IDE
;;; Enable 8-bit PIO Transfer Mode for Lo-tech XT-CF (CF and Microdrives only)
	call	AH9h_Enable8bitPioModeForXTCF
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_ENABLE_8BIT_PIO_MODE
%endif


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
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_BLOCK_MODE_SUPPORTED
	jz		SHORT .BlockModeNotSupportedOrDisabled
	test	al, FLG_DRVPARAMS_BLOCKMODE
	jz		SHORT .BlockModeNotSupportedOrDisabled

	; Try block sizes until we find largest possible supported by drive
	mov		bl, 128
.TryNextBlockSize:
	mov		al, bl
	call	AH24h_SetBlockSize	; Stores block size to DPT
	jnc		SHORT .SupportedBlockSizeFound
	shr		bl, 1
	jnc		SHORT .TryNextBlockSize
	STORE_ERROR_FLAG_TO_DPT		FLG_INITERROR_FAILED_TO_SET_BLOCK_MODE
.BlockModeNotSupportedOrDisabled:
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
DoNotEnable8bitMode:
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


%ifdef MODULE_8BIT_IDE
;--------------------------------------------------------------------
; AH9h_Enable8bitPioModeForXTCF
;	Parameters:
;		DS:DI:	Ptr to DPT
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX, SI
;--------------------------------------------------------------------
AH9h_Enable8bitPioModeForXTCF:
	eMOVZX	bx, [di+DPT.bIdevarsOffset]
	cmp		BYTE [cs:bx+IDEVARS.bDevice], DEVICE_8BIT_XTCF
	jne		SHORT DoNotEnable8bitMode

	mov		si, FEATURE_ENABLE_8BIT_PIO_TRANSFER_MODE
	jmp		AH23h_SetControllerFeatures
%endif ; MODULE_8BIT_IDE
