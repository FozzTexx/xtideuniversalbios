; File name		:	AccessDPT.asm
; Project name	:	IDE BIOS
; Created date	:	16.3.2010
; Last update	:	26.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions for accessing DPT data.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Returns L-CHS values from DPT.
;
; AccessDPT_GetLCHSfromPCHS
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AX:		Number of L-CHS sectors per track
;		BX:		Number of L-CHS cylinders
;		DX:		Number of L-CHS heads
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AccessDPT_GetLCHSfromPCHS:
	xchg	ax, cx
	mov		cl, [di+DPT.bShLtoP]		; Load shift count
	mov		bx, [di+DPT.wPCyls]			; Load P-CHS cylinders
	shr		bx, cl						; Shift to L-CHS cylinders
	xchg	cx, ax
	mov		dx, [di+DPT.wLHeads]		; Load L-CHS heads
	eMOVZX	ax, BYTE [di+DPT.bPSect]	; Load Sectors per track
	ret


;--------------------------------------------------------------------
; Tests IDEVARS flags for master or slave drive.
;
; AccessDPT_TestIdeVarsFlagsForMasterOrSlaveDrive
;	Parameters:
;		AX:		Bitmask to test DRVPARAMS.wFlags
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		ZF:		Set if tested bit was zero
;				Cleared if tested bit was non-zero
;		CF:		0
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AccessDPT_TestIdeVarsFlagsForMasterOrSlaveDrive:
	call	AccessDPT_GetPointerToDRVPARAMStoCSBX
	test	[cs:bx+DRVPARAMS.wFlags], ax
	ret

;--------------------------------------------------------------------
; Returns pointer to DRVPARAMS for master or slave drive.
;
; AccessDPT_GetPointerToDRVPARAMStoCSBX
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		CS:BX:	Ptr to DRVPARAMS
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AccessDPT_GetPointerToDRVPARAMStoCSBX:
	eMOVZX	bx, [di+DPT.bIdeOff]		; CS:BX points to IDEVARS
	test	BYTE [di+DPT.bDrvSel], FLG_IDE_DRVHD_DRV
	jnz		SHORT .ReturnPointerToSlaveDRVPARAMS
	add		bx, BYTE IDEVARS.drvParamsMaster
	ret
ALIGN JUMP_ALIGN
.ReturnPointerToSlaveDRVPARAMS:
	add		bx, BYTE IDEVARS.drvParamsSlave
	ret
