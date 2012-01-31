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
; AccessDPT_GetLCHStoAXBLBH
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AX:		Number of L-CHS cylinders
;		BL:		Number of L-CHS heads
;		BH:		Number of L-CHS sectors per track
;	Corrupts registers:
;		CX, DX
;--------------------------------------------------------------------
AccessDPT_GetLCHStoAXBLBH:
	; Return LBA-assisted CHS if LBA addressing used
	test	BYTE [di+DPT.bFlagsLow], FLG_DRVNHEAD_LBA
	jz		SHORT .ConvertPchsToLchs

	call	AccessDPT_GetLbaSectorCountToBXDXAX
	call	AtaID_GetLbaAssistedCHStoDXAXBLBH
	test	dx, dx
	jnz		SHORT .LimitAXtoMaxLCHScylinders
	cmp		ax, MAX_LCHS_CYLINDERS
	jb		SHORT .returnLCHS
.LimitAXtoMaxLCHScylinders:
	mov		ax, MAX_LCHS_CYLINDERS
.returnLCHS:
	ret

.ConvertPchsToLchs:
	mov		ax, [di+DPT.wPchsCylinders]
	mov		bx, [di+DPT.wPchsHeadsAndSectors]
	; Fall to AccessDPT_ShiftPCHinAXBLtoLCH


;--------------------------------------------------------------------
; AccessDPT_ShiftPCHinAXBLtoLCH
;	Parameters:
;		AX:		P-CHS cylinders (1...16383)
;		BL:		P-CHS heads (1...16)
;	Returns:
;		AX:		Number of L-CHS cylinders (1...1024)
;		BL:		Number of L-CHS heads (1...255)
;		CX:		Number of bits shifted (4 at most)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AccessDPT_ShiftPCHinAXBLtoLCH:
	xor		cx, cx
.ShiftLoop:
	cmp		ax, MAX_LCHS_CYLINDERS		; Need to shift?
	jbe		SHORT .Return				;  If not, return
	inc		cx							; Increment shift count
	shr		ax, 1						; Halve cylinders
	shl		bl, 1						; Double heads
	jnz		SHORT .ShiftLoop			; Falls through only on the last (4th) iteration and only if BL was 16 on entry
	dec		bl							; DOS doesn't support drives with 256 heads so we limit heads to 255
	; We can save a byte here by using DEC BX if we don't care about BH
.Return:
	ret


;--------------------------------------------------------------------
; AccessDPT_GetLbaSectorCountToBXDXAX
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AccessDPT_GetLbaSectorCountToBXDXAX:
	mov		ax, [di+DPT.twLbaSectors]
	mov		dx, [di+DPT.twLbaSectors+2]
	mov		bx, [di+DPT.twLbaSectors+4]
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

;--------------------------------------------------------------------
; AccessDPT_GetUnshiftedAddressModeToALZF
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		AL:		Addressing Mode (L-CHS, P-CHS, LBA28, LBA48)
;               unshifted (still shifted where it is in bFlagsLow)
;       ZF:     Set based on value in AL
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
;
; Converted to a macro since only called in two places, and the call/ret overhead
; is not worth it for these two instructions (4 bytes total)
;
%macro AccessDPT_GetUnshiftedAddressModeToALZF 0
	mov		al, [di+DPT.bFlagsLow]
	and		al, MASKL_DPT_ADDRESSING_MODE
%endmacro
