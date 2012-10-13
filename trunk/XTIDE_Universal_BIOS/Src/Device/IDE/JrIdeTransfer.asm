; Project name	:	XTIDE Universal BIOS
; Description	:	Memory mapped IDE Device transfer functions.

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
struc MEMPIOVARS	; Must not be larger than 9 bytes! See IDEPACK in RamVars.inc.
	.wSectorsInBlock		resb	2	; 0-1, Block size in sectors
	.fpDPT					resb	4	; 2-5, Far pointer to DPT
	.bSectorsLeft			resb	1	; 6, Sectors left to transfer
							resb	1	; 7, IDEPACK.bDeviceControl
	.bSectorsDone			resb	1	; 8, Number of sectors xferred
endstruc

SECTOR_ACCESS_WINDOW_SIZE	EQU		512	; 512 bytes


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; JrIdeTransfer_StartWithCommandInAL
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
JrIdeTransfer_StartWithCommandInAL:
	; Initialize MEMPIOVARS
	xchg	cx, ax			; IDE command to CL
	xor		ax, ax
	mov		[bp+MEMPIOVARS.bSectorsDone], al
	mov		al, [bp+IDEPACK.bSectorCount]
	mov		[bp+MEMPIOVARS.bSectorsLeft], al
	mov		al, [di+DPT_ATA.bBlockSize]
	mov		[bp+MEMPIOVARS.wSectorsInBlock], ax
	mov		[bp+MEMPIOVARS.fpDPT], di
	mov		[bp+MEMPIOVARS.fpDPT+2], ds

	; Get far pointer to Sector Access Window
	mov		dx, [di+DPT.wBasePort]
	cmp		BYTE [di+DPT_ATA.bDevice], DEVICE_8BIT_JRIDE_ISA
	jne		SHORT .GetSectorAccessWindowForXTCF

	; Get Sector Access Window for JR-IDE/ISA
	mov		di, JRIDE_SECTOR_ACCESS_WINDOW_OFFSET
	mov		ds, dx		; Segment for JR-IDE/ISA
	jmp		SHORT .SectorAccessWindowLoadedToDSDI

.GetSectorAccessWindowForXTCF:
	xor		di, di
	add		dl, XTCF_CONTROL_REGISTER
	in		al, dx					; Read high byte for Sector Access Window segment
	xchg	ah, al
	mov		ds, ax

	; Are we reading or writing?
.SectorAccessWindowLoadedToDSDI:
	test	cl, 16	; Bit 4 is cleared on all the read commands but set on 3 of the 4 write commands
	jnz		SHORT WriteToSectorAccessWindow
	cmp		cl, COMMAND_WRITE_MULTIPLE
	je		SHORT WriteToSectorAccessWindow
	; Fall to ReadFromSectorAccessWindow

;--------------------------------------------------------------------
; ReadFromSectorAccessWindow
;	Parameters:
;		DS:DI:	Ptr to Sector Access Window
;		ES:SI:	Normalized ptr to buffer to receive data
;		SS:BP:	Ptr to MEMPIOVARS
;	Returns:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		AH:		BIOS Error code
;		CX:		Number of successfully transferred sectors
;		CF:		0 if transfer successful
;				1 if any error
;	Corrupts registers:
;		AL, BX, DX, SI
;--------------------------------------------------------------------
ReadFromSectorAccessWindow:
	xchg	si, di	; DS:SI = source, ES:DI = Destination
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	mov		cx, [bp+MEMPIOVARS.wSectorsInBlock]	; Clears CH
	cmp		[bp+MEMPIOVARS.bSectorsLeft], cl
	jbe		SHORT .ReadLastBlockFromDrive

ALIGN JUMP_ALIGN
.ReadNextBlockFromDrive:
	call	ReadSingleBlockFromSectorAccessWindowInDSSItoESDI
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	; Update number of successfully read sectors and sectors left to transfer.
	; We cannot use SUB instruction as a comparison since it will not
	; work in this situation:
	; Before SUB we have 2 full blocks left to transfer. SUB command
	; then compares 2 full blocks against one full block and updates
	; sectors left to one full block and jumps to .ReadNextBlockFromDrive,
	; since we have one full block left to transfer. After it has been
	; transferred, there will be a wait for next block but DRQ is never
	; set since all is transferred! Then we get timeout error.
	mov		cx, [bp+MEMPIOVARS.wSectorsInBlock]
	sub		[bp+MEMPIOVARS.bSectorsLeft], cl
	add		[bp+MEMPIOVARS.bSectorsDone], cl
	cmp		[bp+MEMPIOVARS.bSectorsLeft], cl
	ja		SHORT .ReadNextBlockFromDrive

ALIGN JUMP_ALIGN
.ReadLastBlockFromDrive:
	mov		cl, [bp+MEMPIOVARS.bSectorsLeft]
	push	cx
	call	ReadSingleBlockFromSectorAccessWindowInDSSItoESDI

	; Check for errors in last block
CheckErrorsAfterTransferringLastMemoryMappedBlock:
	lds		di, [bp+MEMPIOVARS.fpDPT]			; DPT now in DS:DI
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_BSY)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH
	pop		cx	; [bp+MEMPIOVARS.bSectorsLeft]
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	; All sectors successfully transferred
	add		cl, [bp+MEMPIOVARS.bSectorsDone]	; Never sets CF
	ret

	; Return number of successfully transferred sectors
ReturnWithMemoryIOtransferErrorInAH:
	lds		di, [bp+MEMPIOVARS.fpDPT]			; DPT now in DS:DI
%ifdef USE_386
	movzx	cx, BYTE [bp+MEMPIOVARS.bSectorsDone]
%else
	mov		ch, 0								; Preserve CF
	mov		cl, [bp+MEMPIOVARS.bSectorsDone]
%endif
	ret


;--------------------------------------------------------------------
; WriteToSectorAccessWindow
;	Parameters:
;		DS:DI:	Ptr to Sector Access Window
;		ES:SI:	Normalized ptr to buffer containing data
;		SS:BP:	Ptr to MEMPIOVARS
;	Returns:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		AH:		BIOS Error code
;		CX:		Number of successfully transferred sectors
;		CF:		0 if transfer successful
;				1 if any error
;	Corrupts registers:
;		AL, BX, DX, SI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteToSectorAccessWindow:
	push	es
	push	ds
	pop		es		; ES:DI = Sector Access Window (destination)
	pop		ds		; DS:SI = Ptr to source buffer

	; Always poll when writing first block (IRQs are generated for following blocks)
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	mov		cx, [bp+MEMPIOVARS.wSectorsInBlock]
	cmp		[bp+MEMPIOVARS.bSectorsLeft], cl
	jbe		SHORT .WriteLastBlockToDrive

ALIGN JUMP_ALIGN
.WriteNextBlockToDrive:
	call	WriteSingleBlockFromDSSIToSectorAccessWindowInESDI
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	; Increment number of successfully written WORDs
	mov		cx, [bp+MEMPIOVARS.wSectorsInBlock]
	sub		[bp+MEMPIOVARS.bSectorsLeft], cl
	add		[bp+MEMPIOVARS.bSectorsDone], cl
	cmp		[bp+MEMPIOVARS.bSectorsLeft], cl
	ja		SHORT .WriteNextBlockToDrive

ALIGN JUMP_ALIGN
.WriteLastBlockToDrive:
	mov		cl, [bp+MEMPIOVARS.bSectorsLeft]
	push	cx
	ePUSH_T	bx, CheckErrorsAfterTransferringLastMemoryMappedBlock
	; Fall to WriteSingleBlockFromDSSIToSectorAccessWindowInESDI

;--------------------------------------------------------------------
; WriteSingleBlockFromDSSIToSectorAccessWindowInESDI
;	Parameters:
;		CX:		Number of sectors in block
;		DS:SI:	Normalized ptr to source buffer
;		ES:DI:	Ptr to Sector Access Window
;	Returns:
;		CX, DX:	Zero
;		SI:		Updated
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WriteSingleBlockFromDSSIToSectorAccessWindowInESDI:
	mov		bx, di
	mov		dx, cx
	xor		cl, cl
ALIGN JUMP_ALIGN
.WriteNextSector:
	mov		ch, SECTOR_ACCESS_WINDOW_SIZE >> 9
	rep movsw
	mov		di, bx	; Reset for next sector
	dec		dx
	jnz		SHORT .WriteNextSector
	ret


;--------------------------------------------------------------------
; ReadSingleBlockFromSectorAccessWindowInDSSItoESDI
;	Parameters:
;		CX		Number of sectors in full block or sectors in last partial block
;		ES:DI:	Normalized ptr to buffer to receive data (destination)
;		DS:SI:	Ptr to Sector Access Window (source)
;	Returns:
;		CX, DX:	Zero
;		DI:		Updated
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadSingleBlockFromSectorAccessWindowInDSSItoESDI:
	mov		bx, si
	mov		dx, cx
	xor		cl, cl
ALIGN JUMP_ALIGN
.ReadNextSector:
	mov		ch, SECTOR_ACCESS_WINDOW_SIZE >> 9
	rep movsw
	mov		si, bx	; Reset for next sector
	dec		dx
	jnz		SHORT .ReadNextSector
	ret


;--------------------------------------------------------------------
; WaitUntilReadyToTransferNextBlock
;	Parameters:
;		SS:BP:	Ptr to MEMPIOVARS
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
WaitUntilReadyToTransferNextBlock:
	push	ds
	push	di
	lds		di, [bp+MEMPIOVARS.fpDPT]	; DPT now in DS:DI
	call	IdeWait_IRQorDRQ			; Always polls
	pop		di
	pop		ds
	ret


%if SECTOR_ACCESS_WINDOW_SIZE <> 512
	%error "SECTOR_ACCESS_WINDOW_SIZE is no longer equal to 512. JrIdeTransfer.asm needs changes."
%endif
