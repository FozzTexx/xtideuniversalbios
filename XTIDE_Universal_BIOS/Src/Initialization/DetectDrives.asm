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
ALIGN JUMP_ALIGN
DetectDrives_FromAllIDEControllers:
	call	RamVars_GetIdeControllerCountToCX
	mov		bp, ROMVARS.ideVars0			; CS:BP now points to first IDEVARS
ALIGN JUMP_ALIGN
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
ALIGN JUMP_ALIGN
DetectDrives_WithIDEVARS:
	push	cx
	mov		ax, g_szMaster
	call	DetectPrint_StartDetectWithMasterOrSlaveStringInAXandIdeVarsInCSBP
	call	DetectDrives_DetectMasterDrive		; Detect and create DPT + BOOTNFO
	call	DetectPrint_DriveNameOrNotFound		; Print found or not found string

	mov		ax, g_szSlave
	call	DetectPrint_StartDetectWithMasterOrSlaveStringInAXandIdeVarsInCSBP
	call	DetectDrives_DetectSlaveDrive
	call	DetectPrint_DriveNameOrNotFound
	pop		cx
	ret


;--------------------------------------------------------------------
; Detects IDE Master or Slave drive.
;
; DetectDrives_DetectMasterDrive
; DetectDrives_DetectSlaveDrive
;	Parameters:
;		CS:BP:	Ptr to IDEVARS
;		DS:		RAMVARS segment
;		ES:		Zero (BDA segment)
;	Returns:
;		ES:BX:	Ptr to BOOTNFO (if successful)
;		CF:		Cleared if drive detected successfully
;				Set if any drive not found or other error
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DetectDrives_DetectMasterDrive:
	mov		bh, MASK_IDE_DRVHD_SET		; Select Master drive
	SKIP2B	ax							; mov ax, <next instruction>
DetectDrives_DetectSlaveDrive:
	mov		bh, MASK_IDE_DRVHD_SET | FLG_IDE_DRVHD_DRV
	; Fall to DetectDrives_StartDetection

;--------------------------------------------------------------------
; Detects IDE Master or Slave drive.
;
; DetectDrives_StartDetection
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		CS:BP:	Ptr to IDEVARS for the drive
;		DS:		RAMVARS segment
;		ES:		Zero (BDA segment)
;	Returns:
;		ES:BX:	Ptr to BOOTNFO (if successful)
;		CF:		Cleared if drive detected successfully
;				Set if any drive not found or other error
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DetectDrives_StartDetection:
	call	DetectDrives_ReadAtaInfoFromDrive	; Assume hard disk
	jnc		SHORT DetectDrives_CreateBiosTablesForHardDisk
	call	DetectDrives_ReadAtapiInfoFromDrive	; Assume CD-ROM
	jnc		SHORT DetectDrives_CreateBiosTablesForCDROM
	ret


;--------------------------------------------------------------------
; Reads ATA information from the drive (for hard disks).
;
; DetectDrives_ReadAtaInfoFromDrive
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
ALIGN JUMP_ALIGN
DetectDrives_ReadAtaInfoFromDrive:
	mov		bl, [cs:bp+IDEVARS.bBusType]; Load BUS type
	mov		dx, [cs:bp+IDEVARS.wPort]	; Load IDE Base Port address
	mov		di, BOOTVARS.rgbAtaInfo		; ES:DI now points to ATA info location
	call	AH25h_GetDriveInfo
	mov		si, di						; ES:SI now points to ATA information
	ret


;--------------------------------------------------------------------
; Creates all BIOS tables for detected hard disk.
;
; DetectDrives_CreateBiosTablesForHardDisk
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		CS:BP:	Ptr to IDEVARS for the drive
;		ES:SI	Ptr to ATA information for the drive
;		DS:		RAMVARS segment
;	Returns:
;		ES:BX:	Ptr to BOOTNFO (if successful)
;		CF:		Cleared if BIOS tables created succesfully
;				Set if any error
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DetectDrives_CreateBiosTablesForHardDisk:
	call	CreateDPT_FromAtaInformation
	jc		SHORT .InvalidAtaInfo
	call	BootInfo_CreateForHardDisk
	;jc		SHORT .InvalidAtaInfo
	; Call to search for BIOS partitions goes here
	;clc
.InvalidAtaInfo:
	ret


;--------------------------------------------------------------------
; Reads ATAPI information from the drive (for CD/DVD-ROMs).
;
; DetectDrives_ReadAtapiInfoFromDrive
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		CS:BP:	Ptr to IDEVARS for the drive
;		DS:		RAMVARS segment
;		ES:		Zero (BDA segment)
;	Returns:
;		ES:SI	Ptr to ATAPI information (read with IDENTIFY PACKET DEVICE command)
;		CF:		Cleared if ATAPI-information read successfully
;				Set if any error
;	Corrupts registers:
;		AX, BL, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DetectDrives_ReadAtapiInfoFromDrive:
	;stc
	;ret
	; Fall through to DetectDrives_CreateBiosTablesForCDROM


;--------------------------------------------------------------------
; Creates all BIOS tables for detected CD/DVD-ROM.
;
; DetectDrives_CreateBiosTablesForCDROM
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		CS:BP:	Ptr to IDEVARS for the drive
;		ES:SI	Ptr to ATAPI information for the drive
;		DS:		RAMVARS segment
;	Returns:
;		ES:BX:	Ptr to BOOTNFO (if successful)
;		CF:		Cleared if BIOS tables created succesfully
;				Set if any error
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DetectDrives_CreateBiosTablesForCDROM:
	stc
	ret
