; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Read/Write functions for transferring
;					block using PIO modes.
;					These functions should only be called from IdeTransfer.asm.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
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

; Modified by JJP for XT-CFv3 support, Mar-13

; Section containing code
SECTION .text


; --------------------------------------------------------------------------------------------------
;
; READ routines follow
;
; --------------------------------------------------------------------------------------------------


%ifdef MODULE_8BIT_IDE

;--------------------------------------------------------------------
; IdePioBlock_ReadFromXtideRev1
;	Parameters:
;		CX:		Block size in 512 byte sectors
;		DX:		IDE Data port address
;		ES:DI:	Normalized ptr to buffer to receive data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdePioBlock_ReadFromXtideRev1:
	UNROLL_SECTORS_IN_CX_TO_OWORDS
	mov		bl, 8		; Bit mask for toggling data low/high reg
ALIGN JUMP_ALIGN
.InswLoop:
	%rep 8 ; WORDs
		XTIDE_INSW
	%endrep
	loop	.InswLoop
	ret


;--------------------------------------------------------------------
; IdePioBlock_ReadFrom8bitDataPort
;
; 8-bit PIO from a single data port.
;
;	Parameters:
;		CX:	Block size in 512 byte sectors
;		DX:	IDE Data port address
;		ES:DI:	Normalized ptr to buffer to receive data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdePioBlock_ReadFrom8bitDataPort:
%ifdef USE_186
	shl		cx, 9		; Sectors to BYTEs
	rep insb
	ret
%else ; If 8088/8086
	UNROLL_SECTORS_IN_CX_TO_OWORDS
ALIGN JUMP_ALIGN
.ReadNextOword:
	%rep 16	; BYTEs
		in		al, dx	; Read BYTE
		stosb			; Store BYTE to [ES:DI]
	%endrep
	loop	.ReadNextOword
	ret
%endif

%endif	; MODULE_8BIT_IDE


;--------------------------------------------------------------------
; IdePioBlock_ReadFrom16bitDataPort
;
; 16-bit PIO from a single data port.
;
;	Parameters:
;		CX:	Block size in 512 byte sectors
;		DX:	IDE Data port address
;		ES:DI:	Normalized ptr to buffer to receive data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdePioBlock_ReadFrom16bitDataPort:
%ifdef USE_186
	xchg		cl, ch	; Sectors to WORDs
	rep insw
	ret

%else ; If 8088/8086
	UNROLL_SECTORS_IN_CX_TO_OWORDS
ALIGN JUMP_ALIGN
.ReadNextOword:
	%rep 8	; WORDs
		in		ax, dx	; Read BYTE
		stosw			; Store BYTE to [ES:DI]
	%endrep
	loop	.ReadNextOword
	ret
%endif


;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdePioBlock_ReadFrom32bitDataPort:
	db		0C1h		; SHL
	db		0E1h		; CX
	db		7			; 7	(Sectors to DWORDs)
	rep
	db		66h			; Override operand size to 32-bit
	db		6Dh			; INSW/INSD
	ret



; --------------------------------------------------------------------------------------------------
;
; WRITE routines follow
;
; --------------------------------------------------------------------------------------------------

%ifdef MODULE_8BIT_IDE

;--------------------------------------------------------------------
; IdePioBlock_WriteToXtideRev1
;	Parameters:
;		CX:	Block size in 512-byte sectors
;		DX:	IDE Data port address
;		ES:SI:	Normalized ptr to buffer containing data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdePioBlock_WriteToXtideRev1:
	push	ds
	UNROLL_SECTORS_IN_CX_TO_QWORDS
	mov		bl, 8		; Bit mask for toggling data low/high reg
	push	es			; Copy ES...
	pop		ds			; ...to DS
ALIGN JUMP_ALIGN
.OutswLoop:
	%rep 4	; WORDs
		XTIDE_OUTSW
	%endrep
	loop	.OutswLoop
	pop		ds
	ret


;--------------------------------------------------------------------
; IdePioBlock_WriteToXtideRev2	or rev 1 with swapped A0 and A3 (chuck-mod)
;	Parameters:
;		CX:	Block size in 512-byte sectors
;		DX:	IDE Data port address
;		ES:SI:	Normalized ptr to buffer containing data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdePioBlock_WriteToXtideRev2:
	UNROLL_SECTORS_IN_CX_TO_QWORDS
	push		ds
	push		es		; Copy ES...
	pop			ds		; ...to DS
ALIGN JUMP_ALIGN
.WriteNextQword:
	%rep 4	; WORDs
		XTIDE_MOD_OUTSW	; special macro
	%endrep
	loop	.WriteNextQword
	pop		ds
	ret


;--------------------------------------------------------------------
; IdePioBlock_WriteTo8bitDataPort
;	Parameters:
;		CX:	Block size in 512-byte sectors
;		DX:	IDE Data port address
;		ES:SI:	Normalized ptr to buffer containing data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdePioBlock_WriteTo8bitDataPort:
%ifdef USE_186
	shl		cx, 9		; Sectors to BYTEs
	es					; Source is ES segment
	rep outsb
	ret

%else ; If 8088/8086
	UNROLL_SECTORS_IN_CX_TO_QWORDS
	push		ds
	;mov		ax, es
	;mov		ds, ax	; move es to ds via ax (does this run faster on 8088?)
	push		es
	pop			ds
ALIGN JUMP_ALIGN
.WriteNextQword:
	%rep 8	; BYTEs
		lodsb			; Load BYTE from [DS:SI]
		out	dx, al		; Write BYTE
	%endrep
	loop	.WriteNextQword
	pop		ds
	ret
%endif

%endif ; MODULE_8BIT_IDE


;--------------------------------------------------------------------
; IdePioBlock_WriteTo16bitDataPort		Normal 16-bit IDE, XT-CFv3 in BIU Mode
; IdePioBlock_WriteTo32bitDataPort		VLB/PCI 32-bit IDE
;	Parameters:
;		CX:	Block size in 512-byte sectors
;		DX:	IDE Data port address
;		ES:SI:	Normalized ptr to buffer containing data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdePioBlock_WriteTo16bitDataPort:
%ifdef USE_186
	xchg	cl, ch		; Sectors to WORDs
	es					; Source is ES segment
	rep outsw
	ret

%else ; If 8088/8086
	UNROLL_SECTORS_IN_CX_TO_QWORDS
	push	ds
	;mov	ax, es
	;mov	ds, ax		; move es to ds via ax (does this run faster on 8088?)
	push	es
	pop		ds
ALIGN JUMP_ALIGN
.WriteNextQword:
	%rep 4	; WORDs
		lodsw			; Load BYTE from [DS:SI]
		out	dx, ax		; Write BYTE
	%endrep
	loop	.WriteNextQword
	pop		ds
	ret
%endif	; if/else USE_186

;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdePioBlock_WriteTo32bitDataPort:
	db		0C1h		; SHL
	db		0E1h		; CX
	db		7			; 7	(Sectors to DWORDs)
	es					; Source is ES segment
	rep
	db		66h			; Override operand size to 32-bit
	db		6Fh			; OUTSW/OUTSD
	ret
