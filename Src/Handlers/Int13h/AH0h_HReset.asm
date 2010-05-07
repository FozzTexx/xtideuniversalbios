; File name		:	AH0h_HReset.asm
; Project name	:	IDE BIOS
; Created date	:	27.9.2007
; Last update	:	2.5.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=0h, Disk Controller Reset.

RETRIES_IF_RESET_FAILS		EQU		3
TIMEOUT_BEFORE_RESET_RETRY	EQU		5		; System timer ticks

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=0h, Disk Controller Reset.
;
; AH0h_HandlerForDiskControllerReset
;	Parameters:
;		AH:		Bios function 0h
;		DL:		Drive number (ignored so all drives are reset)
;				If bit 7 is set all hard disks and floppy disks reset.
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
AH0h_HandlerForDiskControllerReset:
	push	dx
	push	cx
	push	bx
	push	ax

	test	dl, 80h						; Reset floppy drives only?
	jz		SHORT .ResetForeignControllers
	call	AH0h_ResetOurControllers
.ResetForeignControllers:
	call	AH0h_ResetFloppyAndForeignHardDiskControllers
	jmp		Int13h_PopXRegsAndReturn	; Return since error


;--------------------------------------------------------------------
; Resets all IDE controllers handled by this BIOS.
;
; AH0h_ResetOurControllers
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_ResetOurControllers:
	push	dx
	mov		bx, ROMVARS.ideVars0			; Load offset to first IDEVARS
	call	Initialize_GetIdeControllerCountToCX
ALIGN JUMP_ALIGN
.ResetLoop:
	call	AH0h_ResetIdevarsController
	jc		SHORT .Return
	add		bx, BYTE IDEVARS_size
	loop	.ResetLoop
	xor		ax, ax							; Clear AH and CF since no errors
.Return:
	pop		dx
	ret


;--------------------------------------------------------------------
; Resets master and slave drive based on either drive number.
;
; AH0h_ResetIdevarsController
;	Parameters:
;		CS:BX:	Ptr to IDEVARS
;		DS:		RAMVARS segment
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_ResetIdevarsController:
	mov		dx, [cs:bx+IDEVARS.wPort]
	call	FindDPT_ForIdeMasterAtPort		; Find master drive to DL
	jc		SHORT AH0h_ResetMasterAndSlaveDriveWithRetries
	call	FindDPT_ForIdeSlaveAtPort		; Find slave if master not present
	jc		SHORT AH0h_ResetMasterAndSlaveDriveWithRetries
	clc
	ret


;--------------------------------------------------------------------
; Resets master and slave drive based on either drive number.
;
; AH0h_ResetMasterAndSlaveDriveWithRetries
;	Parameters:
;		DL:		Drive number for master or slave drive
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_ResetMasterAndSlaveDriveWithRetries:
	push	cx
	push	bx
	mov		cx, RETRIES_IF_RESET_FAILS
ALIGN JUMP_ALIGN
.RetryLoop:
	mov		di, cx						; Backup counter
	call	AHDh_ResetDrive
	jnc		SHORT .Return
	mov		cx, TIMEOUT_BEFORE_RESET_RETRY
	call	SoftDelay_TimerTicks
	mov		cx, di
	loop	.RetryLoop
	mov		ah, RET_HD_RESETFAIL
	stc
ALIGN JUMP_ALIGN
.Return:
	pop		bx
	pop		cx
	ret


;--------------------------------------------------------------------
; Resets floppy drives and foreign hard disks.
;
; AH0h_ResetFloppyAndForeignHardDiskControllers
;	Parameters:
;		DL:		Drive number (ignored so all drives are reset)
;				If bit 7 is set all hard disks and floppy disks reset.
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH0h_ResetFloppyAndForeignHardDiskControllers:
	xor		ah, ah						; AH=0h, Disk Controller Reset
	pushf								; Push flags to simulate INT
	cli									; Disable interrupts
	call	FAR [RAMVARS.fpOldI13h]
	ret
