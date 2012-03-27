; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=9h, Initialize Drive Parameters.

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
	call	ClearErrorFlagFromBootMenuInfo	; Do this for serial devices as well

%ifdef MODULE_SERIAL
	; no need to do this for serial devices
	xor		ah, ah
	test	byte [di+DPT.bFlagsHigh], FLGH_DPT_SERIAL_DEVICE	; Clears CF
	jnz		.ReturnWithErrorCodeInAH

%else
	; Clear Initialization Error flag from DPT
	and		BYTE [di+DPT.bFlagsHigh], ~FLGH_DPT_INITERROR
%endif

	; Try to select drive and wait until ready
	call	AccessDPT_GetDriveSelectByteToAL
	mov		[bp+IDEPACK.bDrvAndHead], al
	call	Device_SelectDrive
	mov		al, FLG_INIT_FAILED_TO_SELECT_DRIVE
	call	SetErrorFlagFromALwithErrorCodeInAHtoBootMenuInfo
	jc		SHORT .ReturnWithErrorCodeInAH

	; Initialize CHS parameters if LBA is not used
	call	InitializeDeviceParameters
	mov		al, FLG_INIT_FAILED_TO_INITIALIZE_CHS_PARAMETERS
	call	SetErrorFlagFromALwithErrorCodeInAHtoBootMenuInfo

	; Enable or Disable Write Cache
	call	SetWriteCache
	mov		al, FLG_INIT_FAILED_TO_SET_WRITE_CACHE
	call	SetErrorFlagFromALwithErrorCodeInAHtoBootMenuInfo

	; Recalibrate drive by seeking to cylinder 0
.RecalibrateDrive:
	call	AH11h_RecalibrateDrive
	mov		al, FLG_INIT_FAILED_TO_RECALIBRATE_DRIVE
	call	SetErrorFlagFromALwithErrorCodeInAHtoBootMenuInfo

	; Initialize block mode transfers
.InitializeBlockMode:
	call	InitializeBlockMode
	mov		al, FLG_INIT_FAILED_TO_SET_BLOCK_MODE
	call	SetErrorFlagFromALwithErrorCodeInAHtoBootMenuInfo

%ifdef MODULE_ADVANCED_ATA
; Initialize fastest supported PIO mode
.InitializePioMode:
	call	InitializePioMode
	mov		al, FLG_INIT_FAILED_TO_SET_PIO_MODE
	call	SetErrorFlagFromALwithErrorCodeInAHtoBootMenuInfo
%endif

	; There might have been several errors so just return
	; one error code for them all
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_INITERROR
	jz		SHORT .ReturnWithErrorCodeInAH
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
	jz		SHORT ReturnSuccessSinceInitializationNotNeeded

	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	mov		al, 1						; Disable block mode
	test	BYTE [cs:bx+DRVPARAMS.wFlags], FLG_DRVPARAMS_BLOCKMODE
	eCMOVNZ	al, [di+DPT_ATA.bMaxBlock]	; Load max block size
	jmp		AH24h_SetBlockSize


;--------------------------------------------------------------------
; ClearErrorFlagFromBootMenuInfo
;	Parameters:
;		DS:DI:	Ptr to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, ES
;--------------------------------------------------------------------
ClearErrorFlagFromBootMenuInfo:
	call	BootMenuInfo_IsAvailable	; Load BOOTMENUINFO segment to ES
	jne		SHORT .DoNotStoreErrorFlags
	call	BootMenuInfo_ConvertDPTtoBX
	mov		WORD [es:bx+BOOTMENUINFO.wInitErrorFlags], 0	; Must clear whole WORD!
.DoNotStoreErrorFlags:
	ret


;--------------------------------------------------------------------
; SetErrorFlagFromALwithErrorCodeInAHtoBootMenuInfo
;	Parameters:
;		AH:		BIOS Error Code
;		AL:		Error flag to set
;		DS:DI:	Ptr to DPT
;	Returns:
;		CF:		Clear if no error
;				Set if error flag was set
;	Corrupts registers:
;		BX, ES
;--------------------------------------------------------------------
SetErrorFlagFromALwithErrorCodeInAHtoBootMenuInfo:
	jnc		SHORT NoErrorFlagToSet
	cmp		ah, RET_HD_INVALID
	jbe		SHORT .IgnoreInvalidCommandError

	call	BootMenuInfo_IsAvailable
	jne		SHORT .BootvarsNotAvailableSoDoNotSetErrorFlag

	call	BootMenuInfo_ConvertDPTtoBX
	or		[es:bx+BOOTMENUINFO.wInitErrorFlags], al
.BootvarsNotAvailableSoDoNotSetErrorFlag:
	or		BYTE [di+DPT.bFlagsHigh], FLGH_DPT_INITERROR
	stc
	ret
.IgnoreInvalidCommandError:
ReturnSuccessSinceInitializationNotNeeded:
	xor		ah, ah
NoErrorFlagToSet:
	ret
