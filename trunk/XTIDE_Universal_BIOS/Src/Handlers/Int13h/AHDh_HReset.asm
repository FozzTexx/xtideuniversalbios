; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=Dh, Reset Hard Disk (Alternate reset).

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=Dh, Reset Hard Disk (Alternate reset).
;
; AHDh_HandlerForResetHardDisk
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AHDh_HandlerForResetHardDisk:
%ifndef USE_186
	call	AHDh_ResetDrive
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%else
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall through to AHDh_ResetDrive
%endif


;--------------------------------------------------------------------
; Resets hard disk.
;
; AHDh_ResetDrive
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AHDh_ResetDrive:
	push	dx
	push	bx

	call	FindDPT_ForDriveNumber		; DS:DI now points to DPT
	call	Interrupts_UnmaskInterruptControllerForDriveInDSDI
	call	Device_ResetMasterAndSlaveController
	;jc		SHORT .ReturnError			; CF would be set if slave drive present without master
										; (error register has special values after reset)

	; Initialize Master and Slave drives
	eMOVZX	bx, BYTE [di+DPT.bIdevarsOffset]
	mov		dx, [cs:bx+IDEVARS.wPort]
	call	InitializeMasterAndSlaveDriveFromPortInDX

	pop		bx
	pop		dx
	ret


;--------------------------------------------------------------------
; InitializeMasterAndSlaveDriveFromPortInDX
;	Parameters:
;		DX:		IDE Base Port address
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Error code
;		CF:		0 if initialization succesfull
;				1 if any error
;	Corrupts registers:
;		AL, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
InitializeMasterAndSlaveDriveFromPortInDX:
	push	dx							; Store base port address
	xor		cx, cx						; Assume no errors
	call	FindDPT_ToDSDIForIdeMasterAtPortDX
	jnc		SHORT .InitializeSlave		; Master drive not present
	call	AH9h_InitializeDriveForUse
	mov		cl, ah						; Copy error code to CL
.InitializeSlave:
	pop		dx							; Restore base port address
	call	FindDPT_ToDSDIForIdeSlaveAtPortDX
	jnc		SHORT .CombineErrors		; Slave drive not present
	call	AH9h_InitializeDriveForUse
	mov		ch, ah						; Copy error code to CH
.CombineErrors:
	or		cl, ch						; OR error codes, clear CF
	jz		SHORT .Return
	mov		ah, RET_HD_RESETFAIL		; Load Reset Failed error code
	stc
.Return:
	ret
