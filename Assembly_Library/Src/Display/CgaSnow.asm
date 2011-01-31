; Project name	:	Assembly Library
; Description	:	Functions for preventing CGA snow.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; CgaSnow_IsCgaPresent
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		CF:		Set if CGA detected
;				Cleared if CGA not detected
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CgaSnow_IsCgaPresent:
	cmp		WORD [BDA.wVidPort], CGA_STATUS_REGISTER - OFFSET_TO_CGA_STATUS_REGISTER
	jne		SHORT .CgaNotFound

	; All standard CGA modes use 25 rows but only EGA and later store it to BDA.
	cmp		BYTE [BDA.bVidRows], 25
	jge		SHORT .CgaNotFound
	stc
	ret
ALIGN JUMP_ALIGN
.CgaNotFound:
	clc
	ret


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
	call	LoadCgaStatusRegisterAddressToDXifCgaPresent
	jz		SHORT .StosbWithoutWaitSinceUnknownPort

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
	call	LoadCgaStatusRegisterAddressToDXifCgaPresent
	jz		SHORT .StoswWithoutWaitSinceUnknownPort

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
	call	LoadCgaStatusRegisterAddressToDXifCgaPresent
	jz		SHORT .RepMovsbWithoutWaitSinceUnknownPort

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
; LoadCgaStatusRegisterAddressToDXifCgaPresent
;	Parameters:
;		DS:		BDA segment (zero)
;	Returns:
;		DX:		CGA Status Register Address
;		ZF:		Set if CGA not present
;				Cleared if CGA present
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
LoadCgaStatusRegisterAddressToDXifCgaPresent:
	test	BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], FLG_CONTEXT_CGA
	jz		SHORT .NoCgaDetected
	mov		dx, CGA_STATUS_REGISTER
ALIGN JUMP_ALIGN, ret
.NoCgaDetected:
	ret


%endif ; ELIMINATE_CGA_SNOW
