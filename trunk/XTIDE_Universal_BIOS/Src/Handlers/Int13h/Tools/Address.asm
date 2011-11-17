; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for address translations.

; Section containing code
SECTION .text

;---------------------------------------------------------------------
; Address_ExtractLCHSparametersFromOldInt13hAddress
;	Parameters:
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Sector number
;		DH:		Head number
;	Returns:
;		BL:		Sector number (1...63)
;		BH:		Head number (0...255)
;		CX:		Cylinder number (0...1023)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Address_ExtractLCHSparametersFromOldInt13hAddress:
	mov		bl, cl				; Copy sector number...
	and		bl, 3Fh				; ...and limit to 1...63
	sub		cl, bl				; Remove from cylinder number high
	eROL_IM	cl, 2				; High bits to beginning
	mov		bh, dh				; Copy Head number
	xchg	cl, ch				; Cylinder number now in CX
	ret


;---------------------------------------------------------------------
; Converts LCHS parameters to IDE P-CHS parameters.
; PCylinder	= (LCylinder << n) + (LHead / PHeadCount)
; PHead		= LHead % PHeadCount
; PSector	= LSector
;
; Address_ConvertLCHStoPCHS:
;	Parameters:
;		BL:		Sector number (1...63)
;		BH:		Head number (0...255)
;		CX:		Cylinder number (0...1023)
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		BL:		Sector number (1...63)
;		BH:		Head number (0...15)
;		CX:		Cylinder number (0...16382)
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConvertLCHStoPCHS:
	; LHead / PHeadCount and LHead % PHeadCount
	eMOVZX	ax, bh					; Copy L-CHS Head number to AX
	div		BYTE [di+DPT.bHeads]	; AL = LHead / PHeadCount, AH = LHead % PHeadCount
	mov		bh, ah					; Copy P-CHS Head number to BH
	xor		ah, ah					; AX = LHead / PHeadCount

	; (LCylinder << n) + (LHead / PHeadCount)
	mov		dx, cx					; Copy L-CHS Cylinder number to DX
	mov		cl, [di+DPT.bFlagsLow]	; Load shift count
	and		cl, MASKL_DPT_CHS_SHIFT_COUNT
	shl		dx, cl					; DX = LCylinder << n
	add		ax, dx					; AX = P-CHS Cylinder number
	xchg	cx, ax					; Move P-CHS Cylinder number to CX
DoNotConvertLCHS:
	ret

;--------------------------------------------------------------------
; Address_OldInt13hAddressToIdeAddress
;	Parameters:
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		DS:DI:	Ptr to DPT
;	Returns:
;		BL:		LBA Low Register / Sector Number Register (LBA 7...0)
;		CL:		LBA Mid Register / Low Cylinder Register (LBA 15...8)
;		CH:		LBA High Register / High Cylinder Register (LBA 23...16)
;		BH:		Drive and Head Register (LBA 27...24)
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Address_OldInt13hAddressToIdeAddress:
	call	Address_ExtractLCHSparametersFromOldInt13hAddress
		
	CustomDPT_GetUnshiftedAddressModeToALZF
	jz		DoNotConvertLCHS	; 0, ADDR_DPT_LCHS
		
	;; 
	;; Since we are only checking for zero, we can do our math in the high order bits,
	;; in this case effectively subtracting 1 from the address mode.
	;; 
	sub		al,(1<<ADDRESSING_MODE_FIELD_POSITION)
	jz		ConvertLCHStoPCHS	; 1, ADDR_DPT_PCHS
		
;; Fall-through                 ; 2, ADDR_DPT_LBA28 and 3, ADDR_DPT_LBA48
		
;---------------------------------------------------------------------
; Converts LCHS parameters to 28-bit LBA address.
; Only 24-bits are used since LHCS to LBA28 conversion has 8.4GB limit.
; LBA = ((cylToSeek*headsPerCyl+headToSeek)*sectPerTrack)+sectToSeek-1
;
; Returned address is in same registers that
; Address_DoNotConvertLCHS and Address_ConvertLCHStoPCHS returns.
;
; ConvertLCHStoLBARegisterValues:
;	Parameters:
;		BL:		Sector number (1...63)
;		BH:		Head number (0...255)
;		CX:		Cylinder number (0...1023)
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		BL:		LBA Low Register / Sector Number Register (LBA 7...0)
;		CL:		LBA Mid Register / Low Cylinder Register (LBA 15...8)
;		CH:		LBA High Register / High Cylinder Register (LBA 23...16)
;		BH:		Drive and Head Register (LBA 27...24)
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConvertLCHStoLBARegisterValues:
	; cylToSeek*headsPerCyl (18-bit result)
	mov		ax, cx					; Copy Cylinder number to AX
	eMOVZX	dx, BYTE [di+DPT.bHeads]
	mul		dx						; DX:AX = cylToSeek*headsPerCyl

	; +=headToSeek (18-bit result)
	add		al, bh					; Add Head number to DX:AX
	adc		ah, dh					; DH = Zero after previous multiplication
	adc		dl, dh

	; *=sectPerTrack (18-bit by 6-bit multiplication with 24-bit result)
	mov		cx, LBA_ASSIST_SPT		; Load Sectors per Track
	xchg	ax, dx					; Hiword to AX, loword to DX
	mul		cl						; AX = hiword * Sectors per Track
	mov		bh, al					; Backup hiword * Sectors per Track
	xchg	ax, dx					; Loword back to AX
	mul		cx						; DX:AX = loword * Sectors per Track
	add		dl, bh					; DX:AX = (cylToSeek*headsPerCyl+headToSeek)*sectPerTrack

	; +=sectToSeek-1 (24-bit result)
	xor		bh, bh					; Sector number now in BX
	dec		bx						; sectToSeek-=1
	add		ax, bx					; Add to loword
	adc		dl, bh					; Add possible carry to byte2, BH=zero

	; Copy DX:AX to proper return registers
	xchg	bx, ax					; BL = Sector Number Register (LBA 7...0)
	mov		cl, bh					; Low Cylinder Register (LBA 15...8)
	mov		ch, dl					; High Cylinder Register (LBA 23...16)
	mov		bh, dh					; Drive and Head Register (LBA 27...24)
	ret
