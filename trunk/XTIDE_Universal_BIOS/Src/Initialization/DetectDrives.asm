; Project name	:	IDE BIOS
; Description	:	Functions for detecting drive for the BIOS.

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
.DriveDetectLoop:
	call	DetectDrives_WithIDEVARS		; Detect Master and Slave
	add		bp, BYTE IDEVARS_size			; Point to next IDEVARS
	loop	.DriveDetectLoop
	ret


;--------------------------------------------------------------------
; Detects IDE hard disks by using information from IDEVARS.
;
; DetectDrives_WithIDEVARS
;	Parameters:
;		CS:BP:		Ptr to IDEVARS
;		DS:			RAMVARS segment
;		ES:			Zero (BDA segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
DetectDrives_WithIDEVARS:
	push	cx
	mov		ax, g_szMaster
	mov		bh, MASK_IDE_DRVHD_SET								; Select Master drive
	call	StartDetectionWithDriveSelectByteInBHandStringInAX	; Detect and create DPT + BOOTNFO

	mov		ax, g_szSlave
	mov		bh, MASK_IDE_DRVHD_SET | FLG_IDE_DRVHD_DRV
	call	StartDetectionWithDriveSelectByteInBHandStringInAX
	pop		cx
	ret


;--------------------------------------------------------------------
; StartDetectionWithDriveSelectByteInBHandStringInAX
;	Parameters:
;		AX:		Offset to "Master" or "Slave" string
;		BH:		Drive Select byte for Drive and Head Register
;		CS:BP:	Ptr to IDEVARS for the drive
;		DS:		RAMVARS segment
;		ES:		Zero (BDA segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
StartDetectionWithDriveSelectByteInBHandStringInAX:
	call	DetectPrint_StartDetectWithMasterOrSlaveStringInAXandIdeVarsInCSBP
	; Fall to .ReadAtaInfoFromHardDisk

;--------------------------------------------------------------------
; .ReadAtaInfoFromHardDisk
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		CS:BP:	Ptr to IDEVARS for the drive
;		DS:		RAMVARS segment
;		ES:		Zero (BDA segment)
;	Returns:
;		ES:SI	Ptr to ATA information (read with IDENTIFY DEVICE command)
;		CF:		Cleared if ATA-information read successfully
;				Set if any error
;	Corrupts registers:
;		AX, BL, CX, DX, DI
;--------------------------------------------------------------------
.ReadAtaInfoFromHardDisk:
	mov		bl, [cs:bp+IDEVARS.bBusType]; Load BUS type
	mov		dx, [cs:bp+IDEVARS.wPort]	; Load IDE Base Port address
	mov		di, BOOTVARS.rgbAtaInfo		; ES:DI now points to ATA info location
	call	AH25h_GetDriveInfo
	jnc		SHORT CreateBiosTablesForHardDisk
	; Fall to .ReadAtapiInfoFromDrive

.ReadAtapiInfoFromDrive:				; Not yet implemented
	;call	ReadAtapiInfoFromDrive		; Assume CD-ROM
	;jnc	SHORT _CreateBiosTablesForCDROM
	jmp		DetectPrint_DriveNotFound


;--------------------------------------------------------------------
; CreateBiosTablesForHardDisk
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		CS:BP:	Ptr to IDEVARS for the drive
;		ES:DI	Ptr to ATA information for the drive
;		DS:		RAMVARS segment
;		ES:		BDA/Bootnfo segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
CreateBiosTablesForHardDisk:
	mov		si, di					; ES:SI now points to ATA information
	call	CreateDPT_FromAtaInformation
	jc		SHORT .InvalidAtaInfo
	call	BootInfo_CreateForHardDisk
	jmp		DetectPrint_DriveNameFromBootnfoInESBX
.InvalidAtaInfo:
	jmp		DetectPrint_DriveNotFound
