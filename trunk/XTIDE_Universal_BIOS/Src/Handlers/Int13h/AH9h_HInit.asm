; File name		:	AH9h_HInit.asm
; Project name	:	IDE BIOS
; Created date	:	9.12.2007
; Last update	:	14.1.2011
; Author		:	Tomi Tilli,
;				:	Krister Nordvall (optimizations)
; Description	:	Int 13h function AH=9h, Initialize Drive Parameters.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=9h, Initialize Drive Parameters.
;
; AH9h_HandlerForInitializeDriveParameters
;	Parameters:
;		AH:		Bios function 9h
;		DL:		Drive number
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH9h_HandlerForInitializeDriveParameters:
	push	dx
	push	cx
	push	bx
	push	ax
%ifndef USE_186
	call	AH9h_InitializeDriveForUse
	jmp		Int13h_PopXRegsAndReturn
%else
	push	Int13h_PopXRegsAndReturn
	; Fall through to AH9h_InitializeDriveForUse
%endif


;--------------------------------------------------------------------
; Initialized drive to be ready for use.
;
; AH9h_InitializeDriveForUse
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to DPT
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH9h_InitializeDriveForUse:
	push	dx
	push	cx

	; Try to select drive and wait until ready
	call	FindDPT_ForDriveNumber
	or		BYTE [di+DPT.bReset], MASK_RESET_ALL		; Everything uninitialized
	call	HDrvSel_SelectDriveAndDisableIRQ
	jc		SHORT .ReturnNotSuccessfull
	and		BYTE [di+DPT.bReset], ~FLG_RESET_nDRDY		; Clear since success

	; Initialize CHS parameters if LBA is not used
	call	AH9h_InitializeDeviceParameters
	jc		SHORT .RecalibrateDrive
	and		BYTE [di+DPT.bReset], ~FLG_RESET_nINITPRMS

	; Recalibrate drive by seeking to cylinder 0
ALIGN JUMP_ALIGN
.RecalibrateDrive:
	call	AH11h_RecalibrateDrive
	mov		dl, [di+DPT.bDrvNum]		; Restore DL
	jc		SHORT .InitializeBlockMode
	and		BYTE [di+DPT.bReset], ~FLG_RESET_nRECALIBRATE

	; Initialize block mode transfers
ALIGN JUMP_ALIGN
.InitializeBlockMode:
	call	AH9h_InitializeBlockMode
	;mov		dl, [di+DPT.bDrvNum]		; Restore DL
	jc		SHORT .ReturnNotSuccessfull
	and		BYTE [di+DPT.bReset], ~FLG_RESET_nSETBLOCK

.ReturnNotSuccessfull:
	pop		cx
	pop		dx
	ret


;--------------------------------------------------------------------
; Sends Initialize Device Parameters command to IDE Hard Disk.
; Initialization is used to initialize logical CHS parameters. Drives
; may not support all CHS values.
; This command is only supported by drives that supports CHS addressing.
;
; AH9h_InitializeDeviceParameters
;	Parameters:
;		DS:DI:	Ptr to DPT
;	Returns:
;		AH:		BIOS Error code
;		CF:		Cleared if succesfull
;				Set if any error
;	Corrupts registers:
;		AL, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH9h_InitializeDeviceParameters:
	; No need to initialize CHS parameters if LBA mode enabled
	test	BYTE [di+DPT.bDrvSel], FLG_IDE_DRVHD_LBA	; Clears CF
	jnz		SHORT .Return

	push	dx
	mov		bh, [di+DPT.bPHeads]
	dec		bh						; Max head number
	mov		dx, [RAMVARS.wIdeBase]
	call	HCommand_OutputTranslatedLCHSaddress
	mov		ah, HCMD_INIT_DEV
	mov		al, [di+DPT.bPSect]		; Sectors per track
	call	HCommand_OutputSectorCountAndCommand
	call	HStatus_WaitBsyDefTime	; Wait until drive ready (DRDY won't be set!)
	pop		dx
.Return:
	ret


;--------------------------------------------------------------------
; Initializes block mode transfers.
;
; AH9h_InitializeBlockMode
;	Parameters:
;		DL:		Drive number
;		DS:DI:	Ptr to DPT
;	Returns:
;		AH:		BIOS Error code
;		CF:		Cleared if succesfull
;				Set if any error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH9h_InitializeBlockMode:
	mov		ax, FLG_DRVPARAMS_BLOCKMODE
	call	AccessDPT_TestIdeVarsFlagsForMasterOrSlaveDrive
	jz		SHORT .Return				; Block mode disabled (CF cleared)
	eMOVZX	ax, BYTE [di+DPT.bMaxBlock]	; Load max block size, zero AH
	test	al, al						; Block mode supported? (clears CF)
	jz		SHORT .Return				;  If not, return
	jmp		AH24h_SetBlockSize
.Return:
	ret
