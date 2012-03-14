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
	call	AccessDPT_ConvertSectorCountFromBXDXAXtoLbaAssistedCHSinDXAXBLBH
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


;--------------------------------------------------------------------
; LBA assist calculation:
; this is how to fit a big drive into INT13's skimpy size requirements,
; with a maximum of 8.4G available.
;
; total LBAs (as obtained by words 60+61)
; divided by 63 (sectors per track) (save as value A)
; Sub 1 from A
; divide A by 1024 + truncate.
; == total number of heads to use.
; add 1
; this value must be either 16, 32, 64, 128, or 256 (round up)
; then take the value A above and divide by # of heads
; to get the # of cylinders to use.
;
;
; so a LBA28 drive will have 268,435,456 as maximum LBAs
;
; 10000000h / 63   = 410410h (total cylinders or tracks)
;   410410h / 1024 = 1041h, which is way more than 256 heads, but 256 is max.
;   410410h / 256  = 4104h cylinders
;
; there's a wealth of information at: http://www.mossywell.com/boot-sequence
; they show a slightly different approach to LBA assist calulations, but
; the method here provides compatibility with phoenix BIOS
;
; we're using the values from 60+61 here because we're topping out at 8.4G
; anyway, so there's no need to use the 48bit LBA values.
;
; AccessDPT_ConvertSectorCountFromBXDXAXtoLbaAssistedCHStoDXAXBLBH:
;	Parameters:
;		BX:DX:AX:	Total number of sectors
;	Returns:
;		DX:AX:	Number of cylinders
;		BH:		Number of sectors per track (always 63)
;		BL:		Number of heads (16, 32, 64, 128 or 255)
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
AccessDPT_ConvertSectorCountFromBXDXAXtoLbaAssistedCHSinDXAXBLBH:
	push	bp
	push	si

	; Value A = Total sector count / 63
	xor		cx, cx
	push	cx		; Push zero for bits 48...63
	push	bx
	push	dx
	push	ax						; 64-bit sector count now in stack
	mov		cl, LBA_ASSIST_SPT
	mov		bp, sp					; SS:BP now points sector count
	call	Math_DivQWatSSBPbyCX	; Temporary value A now in stack

	; BX = Number of heads =  A / 1024
	mov		ax, [bp]
	mov		dx, [bp+2]
	mov		bx, [bp+4]
	call	Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX

	; Heads must be 16, 32, 64, 128 or 256 (round up)
	mov		bx, 256						; Max number of heads
	test	dx, dx						; 65536 or more heads?
	jnz		SHORT .GetNumberOfCylinders
	mov		cx, 128						; Half BX for rounding up
.FindMostSignificantBitForHeadSize:
	cmp		ax, cx
	jae		SHORT .GetNumberOfCylinders
	shr		cx, 1
	shr		bx, 1						; Halve number of heads
	jmp		SHORT .FindMostSignificantBitForHeadSize

	; DX:AX = Number of cylinders = A / number of heads
.GetNumberOfCylinders:
	mov		cx, bx
	call	Math_DivQWatSSBPbyCX
	mov		ax, [bp]
	mov		dx, [bp+2]					; Cylinders now in DX:AX

	; Return LBA assisted CHS
	add		sp, BYTE 8					; Clean stack
	sub		bl, bh						; Limit heads to 255
	mov		bh, LBA_ASSIST_SPT
	pop		si
	pop		bp
	ret
