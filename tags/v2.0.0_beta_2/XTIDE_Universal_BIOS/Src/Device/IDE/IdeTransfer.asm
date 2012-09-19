; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device transfer functions.

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

; Structure containing variables for PIO transfer functions.
; This struct must not be larger than IDEPACK without INTPACK.
struc PIOVARS	; Must not be larger than 9 bytes! See IDEPACK in RamVars.inc.
	.wDataPort				resb	2	; 0-1, IDE Data Port
	.fnXfer					resb	2	; 2-3, Offset to transfer function
	.wSectorsInBlock		resb	2	; 4-5, Block size in sectors
	.bSectorsLeft			resb	1	; 6, Sectors left to transfer
							resb	1	; 7, IDEPACK.bDeviceControl
	.bSectorsDone			resb	1	; 8, Number of sectors xferred
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeTransfer_StartWithCommandInAL
;	Parameters:
;		AL:		IDE command that was used to start the transfer
;				(all PIO read and write commands including Identify Device)
;		ES:SI:	Ptr to normalized data buffer
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CX:		Number of successfully transferred sectors
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeTransfer_StartWithCommandInAL:
	; Are we reading or writing?
	test	al, 16	; Bit 4 is cleared on all the read commands but set on 3 of the 4 write commands
	mov		ah, [bp+IDEPACK.bSectorCount]
	jnz		SHORT WriteToDrive
	cmp		al, COMMAND_WRITE_MULTIPLE
	je		SHORT WriteToDrive
	; Fall to ReadFromDrive

;--------------------------------------------------------------------
; ReadFromDrive
;	Parameters:
;		AH:		Number of sectors to transfer (1...128)
;		ES:SI:	Normalized ptr to buffer to receive data
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		AH:		BIOS Error code
;		CX:		Number of successfully transferred sectors
;		CF:		0 if transfer successful
;				1 if any error
;	Corrupts registers:
;		AL, BX, DX, SI, ES
;--------------------------------------------------------------------
ReadFromDrive:
	; Prepare to read data to ESSI
	mov		bx, g_rgfnPioRead
	call	InitializePiovarsInSSBPwithSectorCountInAH

	; Wait until drive is ready to transfer
	call	IdeWait_IRQorDRQ					; Wait until ready to transfer
	jc		SHORT ReturnWithTransferErrorInAH
	xchg	si, di								; ES:DI now points buffer

	mov		cx, [bp+PIOVARS.wSectorsInBlock]	; Max 128

ALIGN JUMP_ALIGN
.ReadNextBlockFromDrive:
	mov		dx, [bp+PIOVARS.wDataPort]
	cmp		[bp+PIOVARS.bSectorsLeft], cl
	jbe		SHORT .ReadLastBlockFromDrive
	call	[bp+PIOVARS.fnXfer]

	; Wait until ready for next block and check for errors
	xchg	di, si								; DS:DI now points DPT
	call	IdeWait_IRQorDRQ					; Wait until ready to transfer
	jc		SHORT ReturnWithTransferErrorInAH
	xchg	si, di								; ES:DI now points buffer

	; Increment number of successfully read sectors
	mov		cx, [bp+PIOVARS.wSectorsInBlock]
	sub		[bp+PIOVARS.bSectorsLeft], cl
	add		[bp+PIOVARS.bSectorsDone], cl
	jmp		SHORT .ReadNextBlockFromDrive

ALIGN JUMP_ALIGN
.ReadLastBlockFromDrive:
	mov		cl, [bp+PIOVARS.bSectorsLeft]		; CH is already zero
	push	cx
	call	[bp+PIOVARS.fnXfer]					; Transfer possibly partial block

	; Check for errors in last block
	mov		di, si								; DS:DI now points DPT
CheckErrorsAfterTransferringLastBlock:
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_BSY)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
	pop		cx	; [bp+PIOVARS.bSectorsLeft]
	jc		SHORT ReturnWithTransferErrorInAH

	; All sectors successfully transferred
	add		cx, [bp+PIOVARS.bSectorsDone]		; Never sets CF
	ret

	; Return number of successfully read sectors
ReturnWithTransferErrorInAH:
%ifdef USE_386
	movzx	cx, [bp+PIOVARS.bSectorsDone]
%else
	mov		cl, [bp+PIOVARS.bSectorsDone]
	mov		ch, 0								; Preserve CF
%endif
	ret


;--------------------------------------------------------------------
; WriteToDrive
;	Parameters:
;		AH:		Number of sectors to transfer (1...128)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		ES:SI:	Normalized ptr to buffer containing data
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		AH:		BIOS Error code
;		CX:		Number of successfully transferred sectors
;		CF:		0 if transfer successful
;				1 if any error
;	Corrupts registers:
;		AL, BX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteToDrive:
	; Prepare to write data from ESSI
	mov		bx, g_rgfnPioWrite
	call	InitializePiovarsInSSBPwithSectorCountInAH

	; Always poll when writing first block (IRQs are generated for following blocks)
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
	jc		SHORT ReturnWithTransferErrorInAH

	mov		cx, [bp+PIOVARS.wSectorsInBlock]	; Max 128

ALIGN JUMP_ALIGN
.WriteNextBlockToDrive:
	mov		dx, [bp+PIOVARS.wDataPort]
	cmp		[bp+PIOVARS.bSectorsLeft], cl
	jbe		SHORT .WriteLastBlockToDrive
	call	[bp+PIOVARS.fnXfer]

	; Wait until ready for next block and check for errors
	call	IdeWait_IRQorDRQ					; Wait until ready to transfer
	jc		SHORT ReturnWithTransferErrorInAH

	; Increment number of successfully written sectors
	mov		cx, [bp+PIOVARS.wSectorsInBlock]
	sub		[bp+PIOVARS.bSectorsLeft], cl
	add		[bp+PIOVARS.bSectorsDone], cl
	jmp		SHORT .WriteNextBlockToDrive

ALIGN JUMP_ALIGN
.WriteLastBlockToDrive:
	mov		cl, [bp+PIOVARS.bSectorsLeft]		; CH is already zero
	push	cx
%ifdef USE_186
	push	CheckErrorsAfterTransferringLastBlock
	jmp		[bp+PIOVARS.fnXfer]					; Transfer possibly partial block
%else
	call	[bp+PIOVARS.fnXfer]					; Transfer possibly partial block
	jmp		SHORT CheckErrorsAfterTransferringLastBlock
%endif


;--------------------------------------------------------------------
; InitializePiovarsInSSBPwithSectorCountInAH
;	Parameters:
;		AH:		Number of sectors to transfer (1...128)
;		BX:		Offset to transfer function lookup table
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
InitializePiovarsInSSBPwithSectorCountInAH:
	; Store sizes
	mov		[bp+PIOVARS.bSectorsLeft], ah
	eMOVZX	ax, [di+DPT_ATA.bBlockSize]
	mov		[bp+PIOVARS.wSectorsInBlock], ax
	mov		[bp+PIOVARS.bSectorsDone], ah		; Zero

	; Get transfer function based on bus type
	xchg	ax, bx								; Lookup table offset to AX
	mov		bl, [di+DPT.bIdevarsOffset]			; CS:BX now points to IDEVARS
	mov		dx, [cs:bx+IDEVARS.wPort]			; Load IDE Data port address
	mov		bl, [di+DPT_ATA.bDevice]
	add		bx, ax

	mov		[bp+PIOVARS.wDataPort], dx
	mov		ax, [cs:bx]							; Load offset to transfer function
	mov		[bp+PIOVARS.fnXfer], ax
	ret


;--------------------------------------------------------------------
; ReadBlockFromXtideRev1		XTIDE rev 1
; ReadBlockFromXtideRev2		XTIDE rev 2 or rev 1 with swapped A0 and A3 (chuck-mod)
; ReadBlockFrom8bitDataPort		CF-XT when using 8-bit PIO
; ReadBlockFrom16bitDataPort	Normal 16-bit IDE
; ReadBlockFrom32bitDataPort	VLB/PCI 32-bit IDE
;	Parameters:
;		CX:		Block size in 512 byte sectors
;		DX:		IDE Data port address
;		ES:DI:	Normalized ptr to buffer to receive data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
%ifdef MODULE_8BIT_IDE

	ALIGN JUMP_ALIGN
	ReadBlockFromXtideRev1:
		UNROLL_SECTORS_IN_CX_TO_OWORDS
		mov		bl, 8		; Bit mask for toggling data low/high reg
	ALIGN JUMP_ALIGN
	.InswLoop:
	%rep 8	; WORDs
		XTIDE_INSW
	%endrep
		loop	.InswLoop
		ret

	;--------------------------------------------------------------------
	%ifndef USE_186			; 8086/8088 compatible WORD read
		ALIGN JUMP_ALIGN
		ReadBlockFromXtideRev2:
			UNROLL_SECTORS_IN_CX_TO_OWORDS
		ALIGN JUMP_ALIGN
		.ReadNextOword:
		%rep 8	; WORDs
			in		ax, dx		; Read WORD
			stosw				; Store WORD to [ES:DI]
		%endrep
			loop	.ReadNextOword
			ret
	%endif

	;--------------------------------------------------------------------
	%ifdef USE_186
		ALIGN JUMP_ALIGN
		ReadBlockFrom8bitDataPort:
			shl		cx, 9		; Sectors to BYTEs
			rep insb
			ret

	%else ; If 8088/8086
		ALIGN JUMP_ALIGN
		ReadBlockFrom8bitDataPort:
			UNROLL_SECTORS_IN_CX_TO_OWORDS
		ALIGN JUMP_ALIGN
		.ReadNextOword:
		%rep 16	; BYTEs
			in		al, dx		; Read BYTE
			stosb				; Store BYTE to [ES:DI]
		%endrep
			loop	.ReadNextOword
			ret
	%endif
%endif	; MODULE_8BIT_IDE

;--------------------------------------------------------------------
%ifdef USE_186
	ALIGN JUMP_ALIGN
	ReadBlockFrom16bitDataPort:
		xchg	cl, ch		; Sectors to WORDs
		rep insw
		ret
%endif

;--------------------------------------------------------------------
%ifdef USE_AT
	ALIGN JUMP_ALIGN
	ReadBlockFrom32bitDataPort:
		shl		cx, 7		; Sectors to DWORDs
		rep
		db		66h			; Override operand size to 32-bit
		db		6Dh			; INSW/INSD
		ret
%endif


;--------------------------------------------------------------------
; WriteBlockToXtideRev1			XTIDE rev 1
; WriteBlockToXtideRev2			XTIDE rev 2 or rev 1 with swapped A0 and A3 (chuck-mod)
; WriteBlockTo8bitDataPort		XT-CF when using 8-bit PIO
; WriteBlockTo16bitDataPort		Normal 16-bit IDE
; WriteBlockTo32bitDataPort		VLB/PCI 32-bit IDE
;	Parameters:
;		CX:		Block size in 512-byte sectors
;		DX:		IDE Data port address
;		ES:SI:	Normalized ptr to buffer containing data
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
%ifdef MODULE_8BIT_IDE

	ALIGN JUMP_ALIGN
	WriteBlockToXtideRev1:
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
	ALIGN JUMP_ALIGN
	WriteBlockToXtideRev2:
		UNROLL_SECTORS_IN_CX_TO_QWORDS
		push	ds
		push	es			; Copy ES...
		pop		ds			; ...to DS
	ALIGN JUMP_ALIGN
	.WriteNextQword:
	%rep 4	; WORDs
		XTIDE_MOD_OUTSW
	%endrep
		loop	.WriteNextQword
		pop		ds
		ret

	;--------------------------------------------------------------------
	%ifdef USE_186
		ALIGN JUMP_ALIGN
		WriteBlockTo8bitDataPort:
			shl		cx, 9		; Sectors to BYTEs
			es					; Source is ES segment
			rep outsb
			ret

	%else ; If 8088/8086
		ALIGN JUMP_ALIGN
		WriteBlockTo8bitDataPort:
			UNROLL_SECTORS_IN_CX_TO_DWORDS
			push	ds
			push	es
			pop		ds
		ALIGN JUMP_ALIGN
		.WriteNextDword:
		%rep 4	; BYTEs
			lodsb				; Load BYTE from [DS:SI]
			out		dx, al		; Write BYTE
		%endrep
			loop	.WriteNextDword
			pop		ds
			ret
	%endif
%endif	; MODULE_8BIT_IDE

;--------------------------------------------------------------------
%ifdef USE_AT
ALIGN JUMP_ALIGN
WriteBlockTo16bitDataPort:
	xchg	cl, ch		; Sectors to WORDs
	es					; Source is ES segment
	rep outsw
	ret

;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteBlockTo32bitDataPort:
	shl		cx, 7		; Sectors to DWORDs
	es					; Source is ES segment
	rep
	db		66h			; Override operand size to 32-bit
	db		6Fh			; OUTSW/OUTSD
	ret
%endif ; USE_AT



; Lookup tables to get transfer function based on bus type
ALIGN WORD_ALIGN
g_rgfnPioRead:
%ifdef MODULE_8BIT_IDE
		dw		0							; 0, DEVICE_8BIT_JRIDE_ISA
		dw		ReadBlockFrom8bitDataPort	; 1, DEVICE_8BIT_XTCF
	%ifdef USE_186
		dw		ReadBlockFrom16bitDataPort	; 2, DEVICE_8BIT_XTIDE_REV2
	%else
		dw		ReadBlockFromXtideRev2		; 2, DEVICE_8BIT_XTIDE_REV2
	%endif
		dw		ReadBlockFromXtideRev1		; 3, DEVICE_XTIDE_REV1

%else
		times	COUNT_OF_8BIT_IDE_DEVICES	dw	0
%endif
%ifdef USE_AT
		dw		ReadBlockFrom16bitDataPort	; 4, DEVICE_16BIT_ATA
		dw		ReadBlockFrom32bitDataPort	; 5, DEVICE_32BIT_ATA
%endif


g_rgfnPioWrite:
%ifdef MODULE_8BIT_IDE
		dw		0							; 0, DEVICE_8BIT_JRIDE_ISA
		dw		WriteBlockTo8bitDataPort	; 1, DEVICE_8BIT_XTCF
		dw		WriteBlockToXtideRev2		; 2, DEVICE_XTIDE_REV2
		dw		WriteBlockToXtideRev1		; 3, DEVICE_XTIDE_REV1

%else
		times	COUNT_OF_8BIT_IDE_DEVICES	dw	0
%endif
%ifdef USE_AT
		dw		WriteBlockTo16bitDataPort	; 4, DEVICE_16BIT_ATA
		dw		WriteBlockTo32bitDataPort	; 5, DEVICE_32BIT_ATA
%endif
