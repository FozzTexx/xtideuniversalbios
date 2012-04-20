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
struc MEMPIOVARS
	.wSectorsInBlock		resb	2	; 0, Block size in sectors
	.bSectorsLeft			resb	1	; 2, Sectors left to transfer
	.bSectorsDone			resb	1	; 3, Number of sectors xferred
							resb	3	; 4, 5, 6
							resb	1	; 7, IDEPACK.bDeviceControl
	.fpDPT					resb	4	; 8, Far pointer to DPT
endstruc


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
	push	cs	; We push CS here (segment of SAW) and later pop it to DS (reads) or ES (writes)

	; Initialize PIOVARS
	xor		cx, cx
	mov		[bp+MEMPIOVARS.bSectorsDone], cl
	mov		cl, [bp+IDEPACK.bSectorCount]
	mov		[bp+MEMPIOVARS.bSectorsLeft], cl
	mov		cl, [di+DPT_ATA.bBlockSize]
	mov		[bp+MEMPIOVARS.wSectorsInBlock], cx
	mov		[bp+MEMPIOVARS.fpDPT], di
	mov		[bp+MEMPIOVARS.fpDPT+2], ds

	; Are we reading or writing?
	test	al, 16	; Bit 4 is cleared on all the read commands but set on 3 of the 4 write commands
	jnz		SHORT WriteToSectorAccessWindow
	cmp		al, COMMAND_WRITE_MULTIPLE
	je		SHORT WriteToSectorAccessWindow
	; Fall to ReadFromSectorAccessWindow

;--------------------------------------------------------------------
; ReadFromSectorAccessWindow
;	Parameters:
;		Stack:	Segment part of ptr to Sector Access Window
;		ES:SI:	Normalized ptr to buffer to receive data
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
ReadFromSectorAccessWindow:
	pop		ds		; CS -> DS
	mov		di, si	; ES:DI = destination
	mov		si, JRIDE_SECTOR_ACCESS_WINDOW_OFFSET	; DS:SI = source

	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	mov		cx, [bp+MEMPIOVARS.wSectorsInBlock]

ALIGN JUMP_ALIGN
.ReadNextBlockFromDrive:
	cmp		[bp+MEMPIOVARS.bSectorsLeft], cl
	jbe		SHORT .ReadLastBlockFromDrive
	call	ReadSingleBlockFromSectorAccessWindowInDSSItoESDI
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	; Increment number of successfully read sectors
	mov		cx, [bp+MEMPIOVARS.wSectorsInBlock]
	sub		[bp+MEMPIOVARS.bSectorsLeft], cl
	add		[bp+MEMPIOVARS.bSectorsDone], cl
	jmp		SHORT .ReadNextBlockFromDrive

ALIGN JUMP_ALIGN
.ReadLastBlockFromDrive:
	mov		cl, [bp+MEMPIOVARS.bSectorsLeft]
	call	ReadSingleBlockFromSectorAccessWindowInDSSItoESDI

	; Check for errors in last block
CheckErrorsAfterTransferringLastMemoryMappedBlock:
	lds		di, [bp+MEMPIOVARS.fpDPT]			; DPT now in DS:DI
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRDY)
	call	IdeWait_PollStatusFlagInBLwithTimeoutInBH

	; Return number of successfully transferred sectors
ReturnWithMemoryIOtransferErrorInAH:
	lds		di, [bp+MEMPIOVARS.fpDPT]			; DPT now in DS:DI
%ifdef USE_386
	movzx	cx, BYTE [bp+MEMPIOVARS.bSectorsDone]
%else
	mov		ch, 0
	mov		cl, [bp+MEMPIOVARS.bSectorsDone]
%endif
	ret


;--------------------------------------------------------------------
; WriteToSectorAccessWindow
;	Parameters:
;		Stack:	Segment part of ptr to Sector Access Window
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
	pop		ds
	pop		es	; CS -> ES
	mov		di, JRIDE_SECTOR_ACCESS_WINDOW_OFFSET

	; Always poll when writing first block (IRQs are generated for following blocks)
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	mov		cx, [bp+MEMPIOVARS.wSectorsInBlock]

ALIGN JUMP_ALIGN
.WriteNextBlockToDrive:
	cmp		[bp+MEMPIOVARS.bSectorsLeft], cl
	jbe		SHORT .WriteLastBlockToDrive
	call	WriteSingleBlockFromDSSIToSectorAccessWindowInESDI
	call	WaitUntilReadyToTransferNextBlock
	jc		SHORT ReturnWithMemoryIOtransferErrorInAH

	; Increment number of successfully written WORDs
	mov		cx, [bp+MEMPIOVARS.wSectorsInBlock]
	sub		[bp+MEMPIOVARS.bSectorsLeft], cl
	add		[bp+MEMPIOVARS.bSectorsDone], cl
	jmp		SHORT .WriteNextBlockToDrive

ALIGN JUMP_ALIGN
.WriteLastBlockToDrive:
	mov		cl, [bp+MEMPIOVARS.bSectorsLeft]
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
.WriteBlock:
	mov		ch, JRIDE_SECTOR_ACCESS_WINDOW_SIZE >> 9
	rep movsw
	mov		di, bx	; Reset for next sector
	dec		dx
	jnz		SHORT .WriteBlock
	ret


;--------------------------------------------------------------------
; ReadSingleBlockFromSectorAccessWindowInDSSItoESDI
;	Parameters:
;		CX		Number of sectors in block
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
.ReadBlock:
	mov		ch, JRIDE_SECTOR_ACCESS_WINDOW_SIZE >> 9
	rep movsw
	mov		si, bx	; Reset for next sector
	dec		dx
	jnz		SHORT .ReadBlock
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


%if JRIDE_SECTOR_ACCESS_WINDOW_SIZE <> 512
	%error "JRIDE_SECTOR_ACCESS_WINDOW_SIZE is no longer equal to 512. MemIdeTransfer.asm needs changes."
%endif
