; File name		:	HAddress.asm
; Project name	:	IDE BIOS
; Created date	:	11.3.2010
; Last update	:	4.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions for address translations.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Outputs sector count, L-CHS address and command to IDE registers.
; This function does not wait until command has been completed.
;
; HAddress_ConvertParamsFromBiosLCHStoIDE
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
ALIGN WORD_ALIGN
g_rgfnAddressTranslation:
	dw		HAddress_DoNotConvertLCHS					; 0, ADDR_DPT_LCHS
	dw		HAddress_ConvertLCHStoPCHS					; 1, ADDR_DPT_PCHS
	dw		HAddress_ConvertLCHStoLBARegisterValues		; 2, ADDR_DPT_LBA28
	dw		HAddress_ConvertLCHStoLBARegisterValues		; 3, ADDR_DPT_LBA48

ALIGN JUMP_ALIGN
HAddress_ConvertParamsFromBiosLCHStoIDE:
	mov		bl, [di+DPT.bFlags]
	and		bx, BYTE MASK_DPT_ADDR						; Addressing mode to BX
	push	WORD [cs:bx+g_rgfnAddressTranslation]		; Push return address
	; Fall to HAddress_ExtractLCHSFromBiosParams

;---------------------------------------------------------------------
; Extracts L-CHS parameters from BIOS function parameters.
;
; HAddress_ExtractLCHSFromBiosParams:
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
HAddress_ExtractLCHSFromBiosParams:
	mov		bl, cl				; Copy sector number...
	and		bl, 3Fh				; ...and limit to 1...63
	sub		cl, bl				; Remove from cylinder number high
	eROL_IM	cl, 2				; High bits to beginning
	mov		bh, dh				; Copy Head number
	xchg	cl, ch				; Cylinder number now in CX
	ret


;---------------------------------------------------------------------
; Converts BIOS LCHS parameters to IDE P-CHS parameters.
; PCylinder	= (LCylinder << n) + (LHead / PHeadCount)
; PHead		= LHead % PHeadCount
; PSector	= LSector
;
; HAddress_ConvertLCHStoPCHS:
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
HAddress_ConvertLCHStoPCHS:
	; LHead / PHeadCount and LHead % PHeadCount
	eMOVZX	ax, bh					; Copy L-CHS Head number to AX
	div		BYTE [di+DPT.bPHeads]	; AL = LHead / PHeadCount, AH = LHead % PHeadCount
	mov		bh, ah					; Copy P-CHS Head number to BH
	xor		ah, ah					; AX = LHead / PHeadCount

	; (LCylinder << n) + (LHead / PHeadCount)
	mov		dx, cx					; Copy L-CHS Cylinder number to DX
	mov		cl, [di+DPT.bShLtoP]	; Load shift count
	shl		dx, cl					; DX = LCylinder << n
	add		ax, dx					; AX = P-CHS Cylinder number
	mov		cx, ax					; Copy P-CHS Cylinder number to CX
ALIGN JUMP_ALIGN
HAddress_DoNotConvertLCHS:
	ret


;---------------------------------------------------------------------
; Converts LCHS parameters to 28-bit LBA address.
; Returned address is in same registers that
; HAddress_DoNotConvertLCHS and HAddress_ConvertLCHStoPCHS returns.
;
; HAddress_ConvertLCHStoLBARegisterValues:
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
HAddress_ConvertLCHStoLBARegisterValues:
	call	HAddress_ConvertLCHStoLBA28
	mov		bl, al					; Sector Number Register (LBA 7...0)
	mov		cl, ah					; Low Cylinder Register (LBA 15...8)
	mov		ch, dl					; High Cylinder Register (LBA 23...16)
	mov		bh, dh					; Drive and Head Register (LBA 27...24)
	ret

;---------------------------------------------------------------------
; Converts LCHS parameters to 28-bit LBA address.
; Only 24-bits are used since LHCS to LBA28 conversion has 8.4GB limit.
; LBA = ((cylToSeek*headsPerCyl+headToSeek)*sectPerTrack)+sectToSeek-1
;
; HAddress_ConvertLCHStoLBA28:
;	Parameters:
;		BL:		Sector number (1...63)
;		BH:		Head number (0...255)
;		CX:		Cylinder number (0...1023)
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		DX:AX:	28-bit LBA address (DH is always zero)
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HAddress_ConvertLCHStoLBA28:
	; cylToSeek*headsPerCyl (18-bit result)
	mov		ax, cx					; Copy Cylinder number to AX
	mul		WORD [di+DPT.wLHeads]	; DX:AX = cylToSeek*headsPerCyl

	; +=headToSeek (18-bit result)
	add		al, bh					; Add Head number to DX:AX
	adc		ah, dh					; DH = Zero after previous multiplication
	adc		dl, dh

	; *=sectPerTrack (18-bit by 6-bit multiplication with 24-bit result)
	eMOVZX	cx, BYTE [di+DPT.bPSect]; Load Sectors per Track
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
	ret
