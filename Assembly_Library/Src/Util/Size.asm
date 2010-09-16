; File name		:	Size.asm
; Project name	:	Assembly Library
; Created date	:	7.9.2010
; Last update	:	15.9.2010
; Author		:	Tomi Tilli
; Description	:	Functions for size calculations.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Size_GetWordSizeToAXfromBXDXAXwithMagnitudeInCX
;	Parameters:
;		BX:DX:AX:	Size in magnitude
;		CX:			Magnitude (0=B, 1=kiB, 2=MiB...)
;	Returns:
;		AX:			Size in magnitude
;		CX:			Tenths
;		DL:			Magnitude character:
;						'k' = *1024   B = kiB
;						'M' = *1024 kiB = MiB
;						'G' = *1024 MiB = GiB
;						'T' = *1024 GiB = TiB
;						'P' = *1024 TiB = PiB
;	Corrupts registers:
;		BX, DH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Size_GetSizeToAXAndCharToDLfromBXDXAXwithMagnitudeInCX:
	push	si

ALIGN JUMP_ALIGN
.MagnitudeConversionLoop:
	ePUSH_T	si, .MagnitudeConversionLoop
	test	bx, bx					; Bits 32...47 in use?
	jnz		SHORT Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX
	test	dx, dx					; Bits 16...31 in use?
	jnz		SHORT Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX
	cmp		ax, 10000				; 5 digits needed?
	jae		SHORT Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX

	add		sp, BYTE 2				; Clean return address from stack
	call	Size_ConvertMagnitudeRemainderInSItoTenths
	call	Size_GetMagnitudeCharacterToDLfromMagnitudeInCX
	mov		cx, si

	pop		si
	ret

;--------------------------------------------------------------------
; Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX
;	Parameters:
;		BX:DX:AX:	Size
;		CX:			Magnitude (0=B, 1=kiB, 2=MiB...)
;	Returns:
;		BX:DX:AX:	Size in magnitude
;		SI:			Remainder (0...1023)
;		CX:			Magnitude (1=kiB, 2=MiB...)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Size_DivideSizeInBXDXAXby1024andIncrementMagnitudeInCX:
	push	cx
	xor		si, si					; Zero remainder
	mov		cl, 10					; Divide by 1024
ALIGN JUMP_ALIGN
.ShiftLoop:
	call	Size_DivideBXDXAXbyTwo
	rcr		si, 1					; Update remainder
	loop	.ShiftLoop
	eSHR_IM	si, 6					; Remainder to SI beginning
	pop		cx
	inc		cx						; Increment magnitude
	ret


;--------------------------------------------------------------------
; Size_ConvertSectorCountInBXDXAXtoKiB
; Size_DivideBXDXAXbyTwo
;	Parameters:
;		BX:DX:AX:	Total sector count
;	Returns:
;		BX:DX:AX:	Total size in kiB
;		CF:			Remainder from division
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Size_ConvertSectorCountInBXDXAXtoKiB:
Size_DivideBXDXAXbyTwo:
	shr		bx, 1					; Divide sector count by 2...
	rcr		dx, 1					; ...to get disk size in...
	rcr		ax, 1					; ...kiB
	ret


;--------------------------------------------------------------------
; Size_ConvertMagnitudeRemainderInSItoTenths
;	Parameters:
;		SI:			Remainder from last magnitude division (0...1023)
;	Returns:
;		SI:			Tenths
;	Corrupts registers:
;		DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Size_ConvertMagnitudeRemainderInSItoTenths:
	push	ax

	mov		ax, 10
	mul		si					; DX:AX = remainder * 10
	eSHR_IM	ax, 10				; Divide AX by 1024
	xchg	si, ax				; SI = tenths

	pop		ax
	ret


;--------------------------------------------------------------------
; Size_GetMagnitudeCharacterToDLfromMagnitudeInCX
;	Parameters:
;		CX:		Magnitude (0=B, 1=kiB, 2=MiB...)
;	Returns:
;		DL:		Magnitude character
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Size_GetMagnitudeCharacterToDLfromMagnitudeInCX:
	mov		bx, cx
	mov		dl, [cs:bx+.rgbMagnitudeToChar]
	ret
ALIGN WORD_ALIGN
.rgbMagnitudeToChar:	db	" kMGTP"
