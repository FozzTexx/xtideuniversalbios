; Project name	:	XTIDE Universal BIOS
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
	call	Int13h_CallPreviousInt13hHandler
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
