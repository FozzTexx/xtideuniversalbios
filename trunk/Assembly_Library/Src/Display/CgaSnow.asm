; Project name	:	Assembly Library
; Description	:	Functions for preventing CGA snow.

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.		
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;		

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
ALIGN DISPLAY_JUMP_ALIGN
CgaSnow_IsCgaPresent:
	cmp		WORD [BDA.wVidPort], CGA_STATUS_REGISTER - OFFSET_TO_CGA_STATUS_REGISTER
	jne		SHORT .CgaNotFound

	; All standard CGA modes use 25 rows but only EGA and later store it to BDA.
	cmp		BYTE [BDA.bVidRows], 25
	jge		SHORT .CgaNotFound
	stc
	ret
ALIGN DISPLAY_JUMP_ALIGN
.CgaNotFound:
	clc
	ret


; CGA snow prevention must be kept optional to avoid unnecessary
; overhead when building programs meant for non-CGA systems.
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
ALIGN DISPLAY_JUMP_ALIGN
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

ALIGN DISPLAY_JUMP_ALIGN
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
	sti
	pop		bx
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
ALIGN DISPLAY_JUMP_ALIGN
CgaSnow_RepMovsb:
	call	LoadCgaStatusRegisterAddressToDXifCgaPresent
	jz		SHORT .RepMovsbWithoutWaitSinceUnknownPort

.MovsbNextByte:
	cli				; Interrupt request would mess up timing
	WAIT_UNTIL_SAFE_CGA_WRITE
	es movsb
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
ALIGN DISPLAY_JUMP_ALIGN
LoadCgaStatusRegisterAddressToDXifCgaPresent:
	test	BYTE [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.bFlags], FLG_CONTEXT_CGA
	jz		SHORT .NoCgaDetected
	mov		dx, CGA_STATUS_REGISTER
ALIGN DISPLAY_JUMP_ALIGN, ret
.NoCgaDetected:
	ret


%endif ; ELIMINATE_CGA_SNOW
