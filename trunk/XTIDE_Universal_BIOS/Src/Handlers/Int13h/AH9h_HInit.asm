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
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
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
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX, DX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
AH9h_InitializeDriveForUse:
	push	cx

	; Try to select drive and wait until ready
	or		BYTE [di+DPT.bFlagsHigh], MASKH_DPT_RESET		; Everything uninitialized
	call	AccessDPT_GetDriveSelectByteToAL
	mov		[bp+IDEPACK.bDrvAndHead], al
	call	Device_SelectDrive
	jc		SHORT .ReturnNotSuccessfull
	and		BYTE [di+DPT.bFlagsHigh], ~FLGH_DPT_RESET_nDRDY	; Clear since success

	; Initialize CHS parameters if LBA is not used
	call	InitializeDeviceParameters
	jc		SHORT .RecalibrateDrive
	and		BYTE [di+DPT.bFlagsHigh], ~FLGH_DPT_RESET_nINITPRMS

	; Recalibrate drive by seeking to cylinder 0
.RecalibrateDrive:
	call	AH11h_RecalibrateDrive
	jc		SHORT .InitializeBlockMode
	and		BYTE [di+DPT.bFlagsHigh], ~FLGH_DPT_RESET_nRECALIBRATE

	; Initialize block mode transfers
.InitializeBlockMode:
	call	InitializeBlockMode
	jc		SHORT .ReturnNotSuccessfull
	and		BYTE [di+DPT.bFlagsHigh], ~FLGH_DPT_RESET_nSETBLOCK	; Keeps CF clear

.ReturnNotSuccessfull:
	pop		cx
	ret


;--------------------------------------------------------------------
; InitializeDeviceParameters
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		BIOS Error code
;		CF:		Cleared if succesfull
;				Set if any error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
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
; InitializeBlockMode
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		BIOS Error code
;		CF:		Cleared if succesfull
;				Set if any error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
InitializeBlockMode:
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_BLOCK_MODE_SUPPORTED	; Clear CF
	jz		SHORT ReturnSuccessSinceInitializationNotNeeded

	mov		al, [di+DPT_ATA.bMaxBlock]	; Load max block size, zero AH
	jmp		AH24h_SetBlockSize
ReturnSuccessSinceInitializationNotNeeded:
	ret
