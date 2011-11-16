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
; AccessDPT_GetAddressingModeToAXZF
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AX:		Addressing Mode (L-CHS, P-CHS, LBA28, LBA48)
;       ZF:		Set if AX=0
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AccessDPT_GetAddressingModeToAXZF:
	mov		al, [di+DPT.bFlagsLow]
	and		ax, BYTE MASKL_DPT_ADDRESSING_MODE 
	eSHR_IM	ax, ADDRESSING_MODE_FIELD_POSITION
	ret


;--------------------------------------------------------------------
; AccessDPT_GetLCHS
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AX:		Number of L-CHS sectors per track
;		BX:		Number of L-CHS cylinders
;		DX:		Number of L-CHS heads
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
AccessDPT_GetLCHS:
	; Load CHS from DPT
	eMOVZX	ax, BYTE [di+DPT.bSectors]
	mov		bx, [di+DPT.dwCylinders]
	cwd
	mov		dl, [di+DPT.bHeads]

	; Only need to limit sectors for LBA assist
	test	BYTE [di+DPT.bFlagsLow], FLG_DRVNHEAD_LBA
	jz		SHORT AccessDPT_ShiftPCHinBXDXtoLCH

	cmp		WORD [di+DPT.dwCylinders+2], BYTE 0
	jnz		SHORT .Return_MAX_LCHS_CYLINDERS

	; Limit cylinders to 1024
	cmp		bx, MAX_LCHS_CYLINDERS
	jb		SHORT .Return
ALIGN JUMP_ALIGN
.Return_MAX_LCHS_CYLINDERS:
	mov		bx, MAX_LCHS_CYLINDERS
ALIGN JUMP_ALIGN, ret
.Return:
	ret


;--------------------------------------------------------------------
; AccessDPT_ShiftPCHinBXDXtoLCH
;	Parameters:
;		BX:		P-CHS cylinders (1...16383)
;		DX:		P-CHS heads (1...16)
;	Returns:
;		BX:		Number of L-CHS cylinders (1...1024)
;		DX:		Number of L-CHS heads (1...255)
;		CX:		Number of bits shifted
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AccessDPT_ShiftPCHinBXDXtoLCH:
	xor		cx, cx
.ShiftLoop:
	cmp		bx, MAX_LCHS_CYLINDERS		; Need to shift?
	jbe		SHORT .LimitHeadsTo255		;  If not, return
	inc		cx							; Increment shift count
	shr		bx, 1						; Halve cylinders
	shl		dx, 1						; Double heads
	jmp		SHORT .ShiftLoop
.LimitHeadsTo255:						; DOS does not support drives with 256 heads
	sub		dl, dh						; DH set only when 256 logical heads
	xor		dh, dh
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
