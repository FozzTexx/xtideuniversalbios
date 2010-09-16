; File name		:	FileIO.asm
; Project name	:	Assembly Library
; Created date	:	1.9.2010
; Last update	:	3.9.2010
; Author		:	Tomi Tilli
; Description	:	Functions for file access.


; File access and sharing modes
struc FILE_ACCESS
	.ReadOnly		resb	1
	.WriteOnly		resb	1
	.ReadAndWrite	resb	1
endstruc

; Origin of file seek
struc SEEK_FROM
	.startOfFile			resb	1
	.currentFilePosition	resb	1
	.endOfFile				resb	1
endstruc


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
	int		DOS_INTERRUPT_21h
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
;		AX:		Number of bytes actually read if successfull (0 if at EOF before call)
;				DOS error code if CF set
;		CF:		Clear if successfull
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FileIO_ReadCXbytesToDSSIusingHandleFromBX:
	xchg	dx, si				; DS:DX now points to source buffer
	mov		ah, READ_FROM_FILE_OR_DEVICE
	int		DOS_INTERRUPT_21h
	xchg	si, dx
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
;		AX:		Number of bytes actually written if successfull (EOF check)
;				DOS error code if CF set
;		CF:		Clear if successfull
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
; FileIO_SeekFromOriginInALtoOffsetInDXAXusingHandleFromBX:
;	Parameters:
;		AL:		SEEK_FROM.(origin)
;		BX:		File handle
;		DX:AX:	Seek offset (signed)
;	Returns:
;		AX:		DOS error code if CF set
;		CF:		Clear if successfull
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FileIO_SeekFromOriginInALtoOffsetInDXAXusingHandleFromBX:
	push	dx
	push	cx

	mov		cx, dx				; DOS wants high word in CX
	xchg	dx, ax				; DOS wants low word in DX
	mov		ah, SET_CURRENT_FILE_POSITION
	int		DOS_INTERRUPT_21h

	pop		cx
	pop		dx
	ret
