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
;		AX, BX, CX
;--------------------------------------------------------------------
.StorePioMode:
	call	AtaID_GetMaxPioModeToAXandMinCycleTimeToCX
	mov		[di+DPT_ADVANCED_ATA.wMinPioCycleTime], cx
	mov		[di+DPT_ADVANCED_ATA.bPioMode], al
	or		[di+DPT.bFlagsHigh], ah	

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
	call	AccessDPT_GetIdeBasePortToBX
	call	AdvAtaInit_DetectControllerForIdeBaseInBX
	mov		[di+DPT_ADVANCED_ATA.wControllerID], ax	; Store zero if none detected
	mov		[di+DPT_ADVANCED_ATA.wControllerBasePort], dx
	jnc		SHORT .NoAdvancedControllerDetected

	; Use highest common PIO mode from controller and drive.
	; Many VLB controllers support PIO modes up to 2.
	call	AdvAtaInit_GetControllerMaxPioModeToAL
	jnc		SHORT .ChangeTo32bitDevice
	and		BYTE [di+DPT.bFlagsHigh], ~FLGH_DPT_IORDY	; No IORDY supported if need to limit
	MIN_U	[di+DPT_ADVANCED_ATA.bPioMode], al

	; We have detected 32-bit controller so change Device Type since
	; it might have been set to 16-bit on IDEVARS
.ChangeTo32bitDevice:
	mov		BYTE [di+DPT_ADVANCED_ATA.bDevice], DEVICE_32BIT_ATA

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
	mov		[di+DPT_ADVANCED_ATA.bDevice], al
	ret

%endif
