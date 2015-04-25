; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device transfer functions.

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
;		ES:SI:	Ptr to data buffer
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
;		ES:SI:	Ptr to buffer to receive data
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
%ifdef USE_AT
	jc		SHORT ReturnWithTransferErrorInAH
%endif

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
;		ES:SI:	Ptr to buffer containing data
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
%ifdef USE_AT
	jc		SHORT ReturnWithTransferErrorInAH
%endif

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
	call	[bp+PIOVARS.fnXfer]					; Transfer possibly partial block
	jmp		SHORT CheckErrorsAfterTransferringLastBlock


;--------------------------------------------------------------------
; InitializePiovarsInSSBPwithSectorCountInAH
;	Parameters:
;		AH:		Number of sectors to transfer (1...128)
;		BX:		Offset to transfer function lookup table
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		ES:SI:	Ptr to data buffer
;		SS:BP:	Ptr to PIOVARS
;	Returns:
;		ES:SI:	Normalized pointer
;		AH:		INT 13h Error Code (only when CF set)
;		CF:		Set if failed to normalize pointer (segment overflow)
;				Cleared if success
;	Corrupts registers:
;		AL, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
InitializePiovarsInSSBPwithSectorCountInAH:
	; Store sizes and Data Port
	mov		[bp+PIOVARS.bSectorsLeft], ah
%ifdef USE_AT
	xchg	dx, ax
%endif
	mov		ax, [di+DPT.wBasePort]
	mov		[bp+PIOVARS.wDataPort], ax
	eMOVZX	ax, [di+DPT_ATA.bBlockSize]
	mov		[bp+PIOVARS.wSectorsInBlock], ax
	mov		[bp+PIOVARS.bSectorsDone], ah		; Zero

	; Get transfer function based on bus type
	mov		al, [di+DPT_ATA.bDevice]
	add		bx, ax
%ifdef MODULE_8BIT_IDE_ADVANCED
	cmp		al, DEVICE_8BIT_XTCF_DMA
%endif
	mov		ax, [cs:bx]							; Load offset to transfer function
	mov		[bp+PIOVARS.fnXfer], ax

	; Normalize pointer for PIO-transfers and convert to physical address for DMA transfers
%ifdef MODULE_8BIT_IDE_ADVANCED
	jb		SHORT IdeTransfer_NormalizePointerInESSI

	; Convert ES:SI to physical address
%ifdef USE_386

	mov		dx, es
	xor		ax, ax
	shld	ax, dx, 4
	shl		dx, 4
	add		si, dx
	adc		al, ah
	mov		es, ax

%elifdef USE_186
						; Bytes	EU Cycles(286)
	mov		ax, es		; 2		2
	rol		ax, 4		; 3		9
	mov		dx, ax		; 2		2
	and		ax, BYTE 0Fh; 3		3
	xor		dx, ax		; 2		2
	add		si, dx		; 2		2
	adc		al, ah		; 2		2
	mov		es, ax		; 2		2
	;------------------------------------
						; 18	24
%else ; 808x
						; Bytes	EU Cycles(808x)
	mov		al, 4		; 2		4
	mov		dx, es		; 2		2
	xchg	cx, ax		; 1		3
	rol		dx, cl		; 2		24
	mov		cx, dx		; 2		2
	xchg	cx, ax		; 1		3
	and		ax, BYTE 0Fh; 3		4
	xor		dx, ax		; 2		3
	add		si, dx		; 2		3
	adc		al, ah		; 2		3
	mov		es, ax		; 2		2
	;------------------------------------
						; 21	53
;
; Judging by the Execution Unit cycle count the above block of code is
; apparently slower. However, the shifts and rotates in the block below
; execute faster than the Bus Interface Unit on an 8088 can fetch them,
; thus causing the EU to starve. The difference in true execution speed
; (if any) might not be worth the extra 5 bytes.
; In other words, we could use a real world test here.
;
%if 0
						; Bytes	EU Cycles(808x/286)
	xor		dx, dx		; 2		3/2
	mov		ax, es		; 2		2/2
%rep 4
	shl		ax, 1		; 8		8/8
	rcl		dx, 1		; 8		8/8
%endrep
	add		si, ax		; 2		3/2
	adc		dl, dh		; 2		3/2
	mov		es, dx		; 2		2/2
	;------------------------------------
						; 26	29/26
%endif ; 0
%endif

	ret		; With CF cleared (taken care of by the physical address conversion)
%endif ; MODULE_8BIT_IDE_ADVANCED
	; Fall to IdeTransfer_NormalizePointerInESSI if no MODULE_8BIT_IDE_ADVANCED


;--------------------------------------------------------------------
; IdeTransfer_NormalizePointerInESSI
;	Parameters:
;		DH:		Number of sectors to transfer (when USE_AT defined)
;		ES:SI:	Ptr to be normalized
;	Returns:
;		ES:SI:	Normalized pointer (SI = 0...15)
;		AH:		INT 13h Error Code (when USE_AT defined and normalization was attempted)
;		CF:		Set if failed to normalize pointer (segment overflow)
;				Cleared if success
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
IdeTransfer_NormalizePointerInESSI:
; Normalization can cause segment overflow if it is done when not needed
; (I don't know if any software calls with such seg:off address).
; This does not apply to XT systems since nothing will write to main BIOS ROM.
; On AT systems things are quite different, even in protected mode the address
; is passed in seg:offset form and HMA is accessible in real mode.
%ifdef USE_AT
	xor		dl, dl
	eSHL_IM	dx, 1
	dec		dx		; Prevents normalization when bytes + offset will be zero
	add		dx, si
	jc		SHORT .NormalizationRequired
	ret
.NormalizationRequired:
%endif ; USE_AT

	NORMALIZE_FAR_POINTER	es, si, ax, dx
%ifdef USE_AT		; CF is always clear for XT builds
	; AH = RET_HD_INVALID (01) if CF set, RET_HD_SUCCESS (00) if not. CF unchanged.
	sbb		ah, ah
	neg		ah
%endif
	ret



; Lookup tables to get transfer function based on bus type
ALIGN WORD_ALIGN
g_rgfnPioRead:
		dw		IdePioBlock_ReadFrom16bitDataPort	; 0, DEVICE_16BIT_ATA
		dw		IdePioBlock_ReadFrom32bitDataPort	; 1, DEVICE_32BIT_ATA
%ifdef MODULE_8BIT_IDE
		dw		IdePioBlock_ReadFrom8bitDataPort	; 2, DEVICE_8BIT_ATA
		dw		IdePioBlock_ReadFromXtideRev1		; 3, DEVICE_8BIT_XTIDE_REV1
		dw		IdePioBlock_ReadFrom16bitDataPort	; 4, DEVICE_8BIT_XTIDE_REV2
%ifdef MODULE_8BIT_IDE_ADVANCED
		dw		IdePioBlock_ReadFrom8bitDataPort	; 5, DEVICE_8BIT_XTCF_PIO8
		dw		IdePioBlock_ReadFrom16bitDataPort	; 6, DEVICE_8BIT_XTCF_PIO8_WITH_BIU_OFFLOAD
		dw		IdePioBlock_ReadFrom16bitDataPort	; 7, DEVICE_8BIT_XTCF_PIO16_WITH_BIU_OFFLOAD
		dw		IdeDmaBlock_ReadFromXTCF			; 8, DEVICE_8BIT_XTCF_DMA
%endif ; MODULE_8BIT_IDE_ADVANCED
%endif ; MODULE_8BIT_IDE


g_rgfnPioWrite:
		dw		IdePioBlock_WriteTo16bitDataPort	; 0, DEVICE_16BIT_ATA
		dw		IdePioBlock_WriteTo32bitDataPort	; 1, DEVICE_32BIT_ATA
%ifdef MODULE_8BIT_IDE
		dw		IdePioBlock_WriteTo8bitDataPort		; 2, DEVICE_8BIT_ATA
		dw		IdePioBlock_WriteToXtideRev1		; 3, DEVICE_8BIT_XTIDE_REV1
		dw		IdePioBlock_WriteToXtideRev2		; 4, DEVICE_8BIT_XTIDE_REV2
%ifdef MODULE_8BIT_IDE_ADVANCED
		dw		IdePioBlock_WriteTo8bitDataPort		; 5, DEVICE_8BIT_XTCF_PIO8
		dw		IdePioBlock_WriteTo16bitDataPort	; 6, DEVICE_8BIT_XTCF_PIO8_WITH_BIU_OFFLOAD
		dw		IdePioBlock_WriteTo16bitDataPort	; 7, DEVICE_8BIT_XTCF_PIO16_WITH_BIU_OFFLOAD
		dw		IdeDmaBlock_WriteToXTCF				; 8, DEVICE_8BIT_XTCF_DMA
%endif ; MODULE_8BIT_IDE_ADVANCED
%endif ; MODULE_8BIT_IDE
