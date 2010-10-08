; File name		:	CgaSnow.asm
; Project name	:	Assembly Library
; Created date	:	8.10.2010
; Last update	:	8.10.2010
; Author		:	Tomi Tilli
; Description	:	Functions for preventing CGA snow.

; Section containing code
SECTION .text


; CGA snow preventing must be kept optional so unnecerrasy overhead
; can be prevented when building program ment for non-CGA systems.
%ifdef ELIMINATE_CGA_SNOW

;--------------------------------------------------------------------
; CgaSnow_Stosb
; CgaSnow_Stosw
;	Parameters:
;		AL:		Character to output
;		AH:		Attribute to output (CgaSnow_StoswWithoutCgaSnow only)
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CgaSnow_Stosb:
	call	LoadAndVerifyStatusRegisterFromBDA
	jne		SHORT .StosbWithoutWaitSinceUnknownPort

	mov		ah, al
	cli				; Interrupt request would mess up timing
	WAIT_UNTIL_SAFE_CGA_WRITE
	mov		al, ah
.StosbWithoutWaitSinceUnknownPort:
	stosb
	sti
	ret

ALIGN JUMP_ALIGN
CgaSnow_Stosw:
	push	bx
	call	LoadAndVerifyStatusRegisterFromBDA
	jne		SHORT .StoswWithoutWaitSinceUnknownPort

	xchg	bx, ax
	cli				; Interrupt request would mess up timing
	WAIT_UNTIL_SAFE_CGA_WRITE
	xchg	ax, bx
.StoswWithoutWaitSinceUnknownPort:
	stosw
	pop		bx
	sti
	ret


;--------------------------------------------------------------------
; CgaSnow_Scasb
;	Parameters:
;		AL:		Byte for comparison
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CgaSnow_Scasb:
	call	LoadAndVerifyStatusRegisterFromBDA
	jne		SHORT .ScasbWithoutWaitSinceUnknownPort

	mov		ah, al
	cli				; Interrupt request would mess up timing
	WAIT_UNTIL_SAFE_CGA_WRITE
	mov		al, ah
.ScasbWithoutWaitSinceUnknownPort:
	scasb
	sti
	ret


;--------------------------------------------------------------------
; CgaSnow_RepMovsb
;	Parameters:
;		CX:		Number of characters to copy
;		DS:		BDA segment (zero)
;		ES:SI:	Ptr to video memory where to read from
;		ES:DI:	Ptr to video memory where to write to
;	Returns:
;		SI, DI:	Updated for next character
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CgaSnow_RepMovsb:
	call	LoadAndVerifyStatusRegisterFromBDA
	jne		SHORT .RepMovsbWithoutWaitSinceUnknownPort

.MovsbNextByte:
	cli				; Interrupt request would mess up timing
	WAIT_UNTIL_SAFE_CGA_WRITE
	eSEG	es
	movsb
	sti
	loop	.MovsbNextByte
	ret
.RepMovsbWithoutWaitSinceUnknownPort:
	eSEG_STR rep, es, movsb
	ret


;--------------------------------------------------------------------
; LoadAndVerifyStatusRegisterFromBDA
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		DX:		CGA Status Register Address
;		ZF:		Set if CGA Base Port found in BDA
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
LoadAndVerifyStatusRegisterFromBDA:
	mov		dx, [BDA.wVidPort]
	add		dl, OFFSET_TO_CGA_STATUS_REGISTER
	cmp		dx, CGA_STATUS_REGISTER
	je		SHORT .CheckIfEgaOrLater
	ret

ALIGN JUMP_ALIGN
.CheckIfEgaOrLater:
	push	ax
	call	DisplayPage_GetColumnsToALandRowsToAH
	cmp		ah, [BDA.bVidRows]		; Video rows stored only by EGA and later
	lahf
	xor		ah, 1<<6				; Invert ZF
	sahf
	pop		ax
	ret


%endif ; ELIMINATE_CGA_SNOW
