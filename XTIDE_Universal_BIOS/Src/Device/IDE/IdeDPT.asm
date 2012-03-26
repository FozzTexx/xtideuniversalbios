; Project name	:	XTIDE Universal BIOS
; Description	:	Sets IDE Device specific parameters to DPT.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeDPT_Finalize
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		CF:		Clear, IDE interface only supports hard disks
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
IdeDPT_Finalize:

;--------------------------------------------------------------------
; .StoreBlockMode
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.StoreBlockMode:
	mov		al, 1							; Block mode will be enabled on AH=9h
	mov		ah, [es:si+ATA1.bBlckSize]		; Max block size in sectors
	mov		[di+DPT_ATA.wSetAndMaxBlock], ax

%ifdef MODULE_ADVANCED_ATA
;--------------------------------------------------------------------
; .StoreDeviceType
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.StoreDeviceType:
	call	IdeDPT_StoreDeviceTypeFromIdevarsInCSBPtoDPTinDSDI

;--------------------------------------------------------------------
; .StorePioModeAndTimings
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
.StorePioMode:
	call	AtaID_GetMaxPioModeToAXandMinCycleTimeToDX
	call	AtaID_ConvertPioModeFromAXandMinCycleTimeFromDXtoActiveAndRecoveryTime
	mov		[di+DPT_ATA.bPioMode], al
	mov		[di+DPT_ADVANCED_ATA.wMinPioActiveTimeNs], cx
	mov		[di+DPT_ADVANCED_ATA.wMinPioRecoveryTimeNs], dx

;--------------------------------------------------------------------
; .DetectAdvancedIdeController
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
.DetectAdvancedIdeController:
	mov		dx, [cs:bp+IDEVARS.wPort]
	mov		[di+DPT_ADVANCED_ATA.wIdeBasePort], dx
	call	AdvAtaInit_DetectControllerForIdeBaseInDX
	mov		[di+DPT_ADVANCED_ATA.wControllerID], ax	; Store zero if none detected
	mov		[di+DPT_ADVANCED_ATA.wControllerBasePort], cx
	jnc		SHORT .NoAdvancedControllerDetected

	; Use highest common PIO mode from controller and drive.
	; Many VLB controllers support PIO modes up to 2.
	call	AdvAtaInit_GetControllerMaxPioModeToAL
	jnc		SHORT .ChangeTo32bitDevice
	MIN_U	[di+DPT_ATA.bPioMode], al

	; We have detected 32-bit controller so change Device Type since
	; it might have been set to 16-bit on IDEVARS
.ChangeTo32bitDevice:
	mov		BYTE [di+DPT_ATA.bDevice], DEVICE_32BIT_ATA

.NoAdvancedControllerDetected:

%endif ; MODULE_ADVANCED_ATA

;--------------------------------------------------------------------
; IdeDPT_StoreReversedAddressLinesFlagIfNecessary
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		CF:		Always clear
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
IdeDPT_StoreReversedAddressLinesFlagIfNecessary:
	cmp		BYTE [cs:bp+IDEVARS.bDevice], DEVICE_XTIDE_REV2
	je		SHORT .SetFlagForSwappedA0andA3
	cmp		BYTE [cs:bp+IDEVARS.bDevice], DEVICE_FAST_XTIDE
	jne		SHORT .EndDPT
.SetFlagForSwappedA0andA3:
	or		BYTE [di+DPT.bFlagsHigh], FLGH_DPT_REVERSED_A0_AND_A3
.EndDPT:
	clc
	ret


%ifdef MODULE_ADVANCED_ATA
;--------------------------------------------------------------------
; IdeDPT_StoreDeviceTypeFromIdevarsInCSBPtoDPTinDSDI
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		CS:BP:	Ptr to IDEVARS for the controller
;	Returns:
;		Nothing
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
IdeDPT_StoreDeviceTypeFromIdevarsInCSBPtoDPTinDSDI:
	mov		al, [cs:bp+IDEVARS.bDevice]
	mov		[di+DPT_ATA.bDevice], al
	ret
%endif
