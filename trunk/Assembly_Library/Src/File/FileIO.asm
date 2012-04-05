; Project name	:	Assembly Library
; Description	:	Functions for file access.

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
; FileIO_OpenWithPathInDSSIandFileAccessInAL
;	Parameters:
;		AL:		FILE_ACCESS.(mode)
;		DS:SI:	Ptr to NULL terminated path or file name
;	Returns:
;		AX:		DOS error code if CF set
;		BX:		File handle if CF cleared
;		CF:		Clear if file opened successfully
;				Set if error
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FileIO_OpenWithPathInDSSIandFileAccessInAL:
	xchg	dx, si		; Path now in DS:DX
	mov		ah, OPEN_EXISTING_FILE
	int		DOS_INTERRUPT_21h
	xchg	si, dx
	mov		bx, ax		; Copy file handle to BX
	ret


;--------------------------------------------------------------------
; FileIO_ReadDXCXbytesToDSSIusingHandleFromBX
;	Parameters:
;		BX:		File handle
;		DX:CX:	Number of bytes to read
;		DS:SI:	Ptr to destination buffer
;	Returns:
;		AX:		DOS error code if CF set
;		CF:		Clear if successful
;				Set if error
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FileIO_ReadDXCXbytesToDSSIusingHandleFromBX:
	push	bp
	mov		bp, FileIO_ReadCXbytesToDSSIusingHandleFromBX
	call	SplitLargeReadOrWritesToSmallerBlocks
	pop		bp
	ret

;--------------------------------------------------------------------
; File position is updated so next read will start where
; previous read stopped.
;
; FileIO_ReadCXbytesToDSSIusingHandleFromBX
;	Parameters:
;		BX:		File handle
;		CX:		Number of bytes to read
;		DS:SI:	Ptr to destination buffer
;	Returns:
;		AX:		Number of bytes actually read if successful (0 if at EOF before call)
;				DOS error code if CF set
;		CF:		Clear if successful
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FileIO_ReadCXbytesToDSSIusingHandleFromBX:
	xchg	dx, si				; DS:DX now points to destination buffer
	mov		ah, READ_FROM_FILE_OR_DEVICE
	int		DOS_INTERRUPT_21h
	xchg	si, dx
	ret


;--------------------------------------------------------------------
; FileIO_WriteDXCXbytesFromDSSIusingHandleFromBX
;	Parameters:
;		BX:		File handle
;		DX:CX:	Number of bytes to write
;		DS:SI:	Ptr to source buffer
;	Returns:
;		AX:		DOS error code if CF set
;		CF:		Clear if successful
;				Set if error
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FileIO_WriteDXCXbytesFromDSSIusingHandleFromBX:
	push	bp
	mov		bp, FileIO_WriteCXbytesFromDSSIusingHandleFromBX
	call	SplitLargeReadOrWritesToSmallerBlocks
	pop		bp
	ret

;--------------------------------------------------------------------
; File position is updated so next write will start where
; previous write stopped.
;
; FileIO_WriteCXbytesFromDSSIusingHandleFromBX:
;	Parameters:
;		BX:		File handle
;		CX:		Number of bytes to write
;		DS:SI:	Ptr to source buffer
;	Returns:
;		AX:		Number of bytes actually written if successful (EOF check)
;				DOS error code if CF set
;		CF:		Clear if successful
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FileIO_WriteCXbytesFromDSSIusingHandleFromBX:
	xchg	dx, si				; DS:DX now points to source buffer
	mov		ah, WRITE_TO_FILE_OR_DEVICE
	int		DOS_INTERRUPT_21h
	xchg	si, dx
	ret


;--------------------------------------------------------------------
; SplitLargeReadOrWritesToSmallerBlocks
;	Parameters:
;		BX:		File handle
;		BP:		Ptr to transfer function
;		DX:CX:	Number of bytes to transfer
;		DS:SI:	Ptr to transfer buffer
;	Returns:
;		AX:		DOS error code if CF set
;		CF:		Clear if successful
;				Set if error
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SplitLargeReadOrWritesToSmallerBlocks:
	push	ds
	push	si
	push	dx
	push	cx

	xchg	ax, cx					; DX:AX now holds bytes to transfer
	mov		cx, SPLIT_SIZE_FOR_LARGE_TRANSFERS
	div		cx						; AX = Number of full transfers
	push	dx						; Bytes for last transfer
	test	ax, ax
	jz		SHORT .TransferRemainingBytes
	xchg	dx, ax					; DX = Number of full transfers

ALIGN JUMP_ALIGN
.TransferNextBytes:
	call	NormalizeDSSI
	call	bp						; Transfer function
	jc		SHORT .ErrorOccurredDuringTransfer
	add		si, SPLIT_SIZE_FOR_LARGE_TRANSFERS
	dec		dx
	jnz		SHORT .TransferNextBytes
.TransferRemainingBytes:
	pop		cx						; CX = Bytes for last transfer
	jcxz	.ReturnErrorCodeInAX	; No remaining bytes
	call	NormalizeDSSI
	call	bp
.ReturnErrorCodeInAX:
	pop		cx
	pop		dx
	pop		si
	pop		ds
	ret
.ErrorOccurredDuringTransfer:
	pop		cx						; Remove bytes for last transfer
	jmp		SHORT .ReturnErrorCodeInAX

;--------------------------------------------------------------------
; NormalizeDSSI
;	Parameters
;		DS:SI:	Ptr to normalize
;	Returns:
;		DS:SI:	Normalized pointer
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
NormalizeDSSI:
	push	dx
	push	ax
	NORMALIZE_FAR_POINTER ds, si, ax, dx
	pop		ax
	pop		dx
	ret


;--------------------------------------------------------------------
; FileIO_GetFileSizeToDXAXusingHandleFromBXandResetFilePosition:
;	Parameters:
;		BX:		File handle
;	Returns:
;		DX:AX:	Signed file size (if CF cleared)
;		AX:		DOS error code (if CF set)
;		CF:		Clear if successful
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FileIO_GetFileSizeToDXAXusingHandleFromBXandResetFilePosition:
	push	cx

	; Get file size to DX:AX
	xor		cx, cx
	xor		dx, dx
	mov		al, SEEK_FROM.endOfFile
	call	FileIO_SeekFromOriginInALtoOffsetInDXAXusingHandleFromBX
	jc		SHORT .ReturnFileError
	push	dx
	push	ax

	; Reset file position
	xor		dx, dx
	mov		al, SEEK_FROM.startOfFile
	call	FileIO_SeekFromOriginInALtoOffsetInDXAXusingHandleFromBX
	pop		ax
	pop		dx

.ReturnFileError:
	pop		cx
	ret


;--------------------------------------------------------------------
; FileIO_CloseUsingHandleFromBX
;	Parameters:
;		BX:		File handle
;	Returns:
;		AX:		DOS error code if CF set
;		CF:		Clear if file closed successfully
;				Set if error
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FileIO_CloseUsingHandleFromBX:
	mov		ah, CLOSE_FILE
	SKIP2B	f	; cmp ax, <next instruction>
	; Fall to FileIO_SeekFromOriginInALtoOffsetInDXAXusingHandleFromBX


;--------------------------------------------------------------------
; FileIO_SeekFromOriginInALtoOffsetInDXAXusingHandleFromBX:
;	Parameters:
;		AL:		SEEK_FROM.(origin)
;		BX:		File handle
;		CX:DX:	Signed offset to seek starting from AL
;	Returns:
;		DX:AX:	New file position in bytes from start of file (if CF cleared)
;		AX:		DOS error code (if CF set)
;		CF:		Clear if successful
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
FileIO_SeekFromOriginInALtoOffsetInDXAXusingHandleFromBX:
	mov		ah, SET_CURRENT_FILE_POSITION
	int		DOS_INTERRUPT_21h
	ret
