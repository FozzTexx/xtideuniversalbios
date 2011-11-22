; Project name	:	XTIDE Universal BIOS
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

.DriveDetectLoop:							; Loop through IDEVARS
	mov		si, g_szDetect					; Setup standard print string
%ifdef MODULE_SERIAL
	cmp		byte [cs:bp+IDEVARS.bDevice], DEVICE_SERIAL_PORT
	jnz		.DriveNotSerial					; Special print string for serial drives
	mov		si, g_szDetectCOM
.DriveNotSerial:
%endif
	call	.DetectDrives_WithIDEVARS		; Detect Master and Slave
	add		bp, BYTE IDEVARS_size			; Point to next IDEVARS
	loop	.DriveDetectLoop
		
%ifdef MODULE_SERIAL
	call	FindDPT_ToDSDIforSerialDevice	; Did we already find any serial drives? 
	jc		.done							; Yes, do not scan
	mov		al,[cs:ROMVARS.wFlags]			; Configurator set to always scan?
	or		al,[es:BDA.bKBFlgs1]			; Or, did the user hold down the ALT key?
	and		al,8							; 8 = alt key depressed, same as FLG_ROMVARS_SERIAL_ALWAYSDETECT
	jz		.done							
	mov		bp, ROMVARS.ideVarsSerialAuto	; Point to our special IDEVARS sructure, just for serial scans
	mov		si, g_szDetectCOMAuto			; Special, special print string for serial drives during a scan
;;; fall-through					
%else
	ret
%endif

%if FLG_ROMVARS_SERIAL_SCANDETECT != 8
%error "DetectDrives is currently coded to assume that FLG_ROMVARS_SERIAL_SCANDETECT is the same bit as the ALT key code in the BDA.  Changes in the code will be needed if these values are no longer the same."
%endif

;--------------------------------------------------------------------
; Detects IDE hard disks by using information from IDEVARS.
;
; DetectDrives_WithIDEVARS
;	Parameters:
;		CS:BP:		Ptr to IDEVARS
;		DS:			RAMVARS segment
;		ES:			Zero (BDA segment)
;       SI:		    Ptr to template string
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
.DetectDrives_WithIDEVARS:
	push	cx

	push	si		
	mov		ax, g_szMaster
	mov		bh, MASK_DRVNHEAD_SET								; Select Master drive
	call	StartDetectionWithDriveSelectByteInBHandStringInAX	; Detect and create DPT + BOOTNFO
	pop		si

%ifdef MODULE_SERIAL
;
; This block of code checks to see if we found a master during a serial drives scan.  If no master
; was found, there is no point in scanning for a slave as the server will not return a slave without a master,
; as there is very little point given the drives are emulated.  Performing the slave scan will take 
; time to rescan all the COM port and baud rate combinations.
;
	jnc		.masterFound
	pop		cx
	jcxz	.done		; note that CX will only be zero after the .DriveDetectLoop, indicating a serial scan
	push	cx
.masterFound:
%endif
		
	mov		ax, g_szSlave
	mov		bh, MASK_DRVNHEAD_SET | FLG_DRVNHEAD_DRV
	call	StartDetectionWithDriveSelectByteInBHandStringInAX
	pop		cx
		
.done:	
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
;		CF:		Set on failure, Clear on success
;               Note that this is set in the last thing both cases
;               do: printing the drive name, or printing "Not Found"
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
;		CF:		Cleared if ATA-information read successfully
;				Set if any error
;	Corrupts registers:
;		AX, BL, CX, DX, SI, DI
;--------------------------------------------------------------------
.ReadAtaInfoFromHardDisk:
	mov		si, BOOTVARS.rgbAtaInfo		; ES:SI now points to ATA info location
	push	es
	push	si
	push	bx
	call	Device_IdentifyToBufferInESSIwithDriveSelectByteInBH
	pop		bx
	pop		si
	pop		es
	jnc		SHORT CreateBiosTablesForHardDisk
	; Fall to .ReadAtapiInfoFromDrive

.ReadAtapiInfoFromDrive:				; Not yet implemented
	;call	ReadAtapiInfoFromDrive		; Assume CD-ROM
	;jnc	SHORT _CreateBiosTablesForCDROM
	jmp		short DetectDrives_DriveNotFound


;--------------------------------------------------------------------
; CreateBiosTablesForHardDisk
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Register
;		CS:BP:	Ptr to IDEVARS for the drive
;		ES:SI	Ptr to ATA information for the drive
;		DS:		RAMVARS segment
;		ES:		BDA/Bootnfo segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
CreateBiosTablesForHardDisk:
	call	CreateDPT_FromAtaInformation
	jc		SHORT DetectDrives_DriveNotFound
	call	BootInfo_CreateForHardDisk
	jmp		short DetectPrint_DriveNameFromBootnfoInESBX

;--------------------------------------------------------------------
; DetectDrives_DriveNotFound
;	Parameters:
;		Nothing
;	Returns:
;		CF:     Set (from BootMenuPrint_NullTerminatedStringFromCSSIandSetCF)
;	Corrupts registers:
;		AX, SI
;--------------------------------------------------------------------
DetectDrives_DriveNotFound:		
	mov		si, g_szNotFound
	jmp		BootMenuPrint_NullTerminatedStringFromCSSIandSetCF		

