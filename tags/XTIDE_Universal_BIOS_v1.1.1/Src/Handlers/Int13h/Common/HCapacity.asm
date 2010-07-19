; File name		:	HCapacity.asm
; Project name	:	IDE BIOS
; Created date	:	16.3.2010
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions for hard disk capacity calculations.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Calculates sector count from L-CHS values returned by INT 13h, AH=08h.
;
; HCapacity_GetSectorCountFromForeignAH08h:
; HCapacity_GetSectorCountFromOurAH08h:
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		DX:AX:	Total sector count
;		BX:		Zero
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HCapacity_GetSectorCountFromForeignAH08h:
	mov		ah, 08h			; Get Drive Parameters
	int		INTV_DISK_FUNC
	jmp		SHORT HCapacity_ConvertAH08hReturnValuesToSectorCount

ALIGN JUMP_ALIGN
HCapacity_GetSectorCountFromOurAH08h:
	push	di
	call	AH8h_GetDriveParameters
	pop		di
	; Fall to HCapacity_ConvertAH08hReturnValuesToSectorCount

ALIGN JUMP_ALIGN
HCapacity_ConvertAH08hReturnValuesToSectorCount:
	call	HAddress_ExtractLCHSFromBiosParams
	xor		ax, ax			; Zero AX
	inc		cx				; Max cylinder number to cylinder count
	xchg	al, bh			; AX=Max head number, BX=Sectors per track
	inc		ax				; AX=Head count
	mul		bx				; AX=Head count * Sectors per track
	mul		cx				; DX:AX = Total sector count
	xor		bx, bx			; Zero BX for 48-bit sector count
	ret


;--------------------------------------------------------------------
; Converts sector count to hard disk size.
;
; HCapacity_ConvertSectorCountToSize:
;	Parameters:
;		BX:DX:AX:	Total sector count
;	Returns:
;		AX:			Size in magnitude
;		SI:			Tenths
;		CX:			Magnitude character:
;						'k' = *1024   B = kiB
;						'M' = *1024 kiB = MiB
;						'G' = *1024 MiB = GiB
;						'T' = *1024 GiB = TiB
;						'P' = *1024 TiB = PiB
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HCapacity_ConvertSectorCountToSize:
	call	HCapacity_ConvertSectorCountToKiB
	mov		cx, 1					; Magnitude is 1 for kiB
ALIGN JUMP_ALIGN
.MagnitudeLoop:
	test	bx, bx					; Bits 32...47 in use?
	jnz		SHORT .ShiftByMagnitude	;  If so, jump to shift
	test	dx, dx					; Bits 16...31 in use?
	jnz		SHORT .ShiftByMagnitude	;  If so, jump to shift
	cmp		ax, 10000				; 5 digits needed?
	jb		SHORT .ShiftComplete	;  If less, all done
ALIGN JUMP_ALIGN
.ShiftByMagnitude:
	call	HCapacity_ShiftForNextMagnitude
	jmp		SHORT .MagnitudeLoop
ALIGN JUMP_ALIGN
.ShiftComplete:
	mov		bx, cx					; Copy shift count to BX
	mov		cl, [cs:bx+.rgbMagnitudeToChar]
	jmp		SHORT HCapacity_ConvertSizeRemainderToTenths
ALIGN WORD_ALIGN
.rgbMagnitudeToChar:	db	" kMGTP"

;--------------------------------------------------------------------
; Converts 48-bit sector count to size in kiB.
;
; HCapacity_ConvertSectorCountToKiB:
;	Parameters:
;		BX:DX:AX:	Total sector count
;	Returns:
;		BX:DX:AX:	Total size in kiB
;		CF:			Remainder from division
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HCapacity_ConvertSectorCountToKiB:
HCapacity_DivideSizeByTwo:
	shr		bx, 1					; Divide sector count by 2...
	rcr		dx, 1					; ...to get disk size in...
	rcr		ax, 1					; ...kiB
	ret

;--------------------------------------------------------------------
; Divides size by 1024 and increments magnitude.
;
; HCapacity_ShiftForNextMagnitude:
;	Parameters:
;		BX:DX:AX:	Size in magnitude
;		CX:			Magnitude (0=B, 1=kiB, 2=MiB...)
;	Returns:
;		BX:DX:AX:	Size in magnitude
;		SI:			Remainder (0...1023)
;		CX:			Magnitude (1=kiB, 2=MiB...)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HCapacity_ShiftForNextMagnitude:
	push	cx
	xor		si, si					; Zero remainder
	mov		cl, 10					; Divide by 1024
ALIGN JUMP_ALIGN
.ShiftLoop:
	call	HCapacity_DivideSizeByTwo
	rcr		si, 1					; Update remainder
	loop	.ShiftLoop
	eSHR_IM	si, 6					; Remainder to SI beginning
	pop		cx
	inc		cx						; Increment shift count
	ret

;--------------------------------------------------------------------
; Converts remainder from HCapacity_ShiftForNextMagnitude to tenths.
;
; HCapacity_ConvertSizeRemainderToTenths:
;	Parameters:
;		BX:DX:AX:	Size in magnitude
;		SI:			Remainder from last magnitude division (0...1023)
;	Returns:
;		BX:DX:AX:	Size in magnitude
;		SI:			Tenths
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HCapacity_ConvertSizeRemainderToTenths:
	push	dx
	push	ax

	mov		ax, 10
	mul		si					; DX:AX = remainder * 10
	eSHR_IM	ax, 10				; Divide AX by 1024
	xchg	si, ax				; SI = tenths

	pop		ax
	pop		dx
	ret
