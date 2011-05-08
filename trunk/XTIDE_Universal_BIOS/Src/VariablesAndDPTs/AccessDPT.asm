; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessing DPT data.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; AccessDPT_GetDriveSelectByteToAL
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AL:		Drive Select Byte
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AccessDPT_GetDriveSelectByteToAL:
	mov		al, [di+DPT.wFlags]
	and		al, FLG_DRVNHEAD_LBA | FLG_DRVNHEAD_DRV
	or		al, MASK_DRVNHEAD_SET	; Bits set to 1 for old drives
	ret


;--------------------------------------------------------------------
; AccessDPT_GetDeviceControlByteToAL
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AL:		Device Control Byte
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AccessDPT_GetDeviceControlByteToAL:
	xor		al, al
	test	BYTE [di+DPT.bFlagsLow], FLGL_DPT_ENABLE_IRQ
	jnz		SHORT .EnableDeviceIrq
	or		al, FLG_DEVCONTROL_nIEN	; Disable IRQ
.EnableDeviceIrq:
	ret


;--------------------------------------------------------------------
; AccessDPT_GetAddressingModeForWordLookToBX
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		BX:		Addressing Mode (L-CHS, P-CHS, LBA28, LBA48) shifted for WORD lookup
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AccessDPT_GetAddressingModeForWordLookToBX:
	mov		bl, [di+DPT.bFlagsLow]
	and		bx, BYTE MASKL_DPT_ADDRESSING_MODE
	eSHR_IM	bx, ADDRESSING_MODE_FIELD_POSITION-1
	ret


;--------------------------------------------------------------------
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
	mov		al, [di+DPT.bFlagsLow]
	and		al, MASKL_DPT_CHS_SHIFT_COUNT	; Load shift count
	xchg	cx, ax
	mov		bx, [di+DPT.wPchsCylinders]		; Load P-CHS cylinders
	shr		bx, cl							; Shift to L-CHS cylinders
	xchg	cx, ax
	eMOVZX	ax, BYTE [di+DPT.bPchsSectors]	; Load Sectors per track
	cwd
	mov		dl, [di+DPT.bLchsHeads]			; Load L-CHS heads
	ret


;--------------------------------------------------------------------
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
	eMOVZX	bx, [di+DPT.bIdevarsOffset]			; CS:BX points to IDEVARS
	add		bx, BYTE IDEVARS.drvParamsMaster	; CS:BX points to Master Drive DRVPARAMS
	test	BYTE [di+DPT.bFlagsLow], FLGL_DPT_SLAVE
	jz		SHORT .ReturnPointerToDRVPARAMS
	add		bx, BYTE DRVPARAMS_size				; CS:BX points to Slave Drive DRVPARAMS
.ReturnPointerToDRVPARAMS:
	ret
