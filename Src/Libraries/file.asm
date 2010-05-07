; File name		:	file.asm
; Project name	:	File library
; Created date	:	19.11.2009
; Last update	:	24.11.2009
; Author		:	Tomi Tilli
; Description	:	ASM library for DOS file handling.	

;--------------- Equates -----------------------------

; DOS DTA (Disk Transfer Area)
struc DTA
	; Undocumented fields
	.reserved	resb	21
	; Documented fields
	.bFileAttr	resb	1	; 15h, Attribute of matching file
	.wFileTime	resb	2	; 16h, File time
	.wFileDate	resb	2	; 18h, File date
	.dwFileSize	resb	4	; 1Ah, File size in bytes
	.szFile		resb	13	; 1Eh, ASCIZ filename + extension
endstruc

; Bits for file attribute byte
FLG_FATTR_RDONLY	EQU		(1<<0)	; Read only
FLG_FATTR_HIDDEN	EQU		(1<<1)	; Hidden
FLG_FATTR_SYS		EQU		(1<<2)	; System
FLG_FATTR_LABEL		EQU		(1<<3)	; Volume Label
FLG_FATTR_DIR		EQU		(1<<4)	; Directory
FLG_FATTR_ARCH		EQU		(1<<5)	; Archive

; File access and sharing modes
VAL_FACCS_READ		EQU		0		; Read only
VAL_FACCS_WRITE		EQU		1		; Write only
VAL_FACCS_RW		EQU		2		; Read and Write

; DOS File I/O error codes
ERR_DOS_SUCCESS		EQU		0		; No error
ERR_DOS_FUNC		EQU		1		; Function number invalid
ERR_DOS_NOFILE		EQU		2		; File not found
ERR_DOS_NOPATH		EQU		3		; Path not found
ERR_DOS_TOOMANY		EQU		4		; Too many open files
ERR_DOS_DENIED		EQU		5		; Access denied
ERR_DOS_HANDLE		EQU		6		; Invalid handle
ERR_DOS_CODE		EQU		12		; Access code invalid
ERR_DOS_NOMORE		EQU		18		; No more files


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data

; DOS file I/O related error strings
g_szNoErr:		db	"No error",STOP
g_szFunc:		db	"Function number invalid",STOP
g_szNoFile:		db	"File not found",STOP
g_szNoPath:		db	"Path not found",STOP
g_szTooMany:	db	"Too many open files",STOP
g_szDenied:		db	"Access denied",STOP
g_szHandle:		db	"Invalid handle",STOP
g_szCode:		db	"Access code invalid",STOP
g_szNoMore:		db	"No more files",STOP
g_szUnknown:	db	"Unknown file I/O error",STOP


;-------------- Public functions ---------------------
; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Returns pointer to error string.
; Pointer is always valid, even if error code is not.
; 
; File_GetErrStr
;	Parameters:
;		AX:		DOS File I/O error code
;	Returns:
;		ES:DI:	Ptr to error string
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_GetErrStr:
	mov		di, g_szNoMore		; Assume ERR_DOS_NOMORE
	cmp		ax, ERR_DOS_NOMORE
	je		.Return
	mov		di, g_szCode		; Assume ERR_DOS_CODE
	cmp		ax, ERR_DOS_CODE
	je		.Return
	mov		di, g_szUnknown		; Assume unknown error
	cmp		ax, ERR_DOS_HANDLE	; Can use lookup?
	ja		.Return				;  If not, return
	mov		di, ax				; Copy error code to DI
	shl		di, 1				; Shift for word lookup
	mov		di, [cs:di+.rgwErrLookup]
ALIGN JUMP_ALIGN
.Return:
	push	cs					; Copy CS...
	pop		es					; ...to ES
	ret
ALIGN WORD_ALIGN
.rgwErrLookup:
	dw	g_szNoErr	; 0
	dw	g_szFunc	; 1
	dw	g_szNoFile	; 2
	dw	g_szNoPath	; 3
	dw	g_szTooMany	; 4
	dw	g_szDenied	; 5
	dw	g_szHandle	; 6


;--------------------------------------------------------------------
; Opens file for reading and writing.
; File must be closed with File_Close when no longer needed.
; 
; File_Open
;	Parameters:
;		AL:		File access and sharing mode:
;					VAL_FACCS_READ	Open file for reading
;					VAL_FACCS_WRITE	Open file for writing
;					VAL_FACCS_RW	Open file for read and write
;		DS:DX:	Ptr to destination ASCIZ file name
;	Returns:
;		AX:		DOS error code if CF set
;		BX:		File handle if CF cleared
;		CF:		Clear if file opened successfully
;				Set if error
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_Open:
	mov		ah, 3Dh				; Open Existing File
	int		21h
	mov		bx, ax				; Copy handle to BX
	ret


;--------------------------------------------------------------------
; Closes file.
; 
; File_Close
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
File_Close:
	mov		ah, 3Eh				; Open Existing File
	int		21h
	ret


;--------------------------------------------------------------------
; Reads binary data from file.
; File position is updated so next read will start where
; previous read stopped.
; 
; File_Read
;	Parameters:
;		BX:		File handle
;		CX:		Number of bytes to read
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		AX:		Number of bytes actually read if successfull (EOF check)
;				DOS error code if CF set
;		CF:		Clear if successfull
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_Read:
	push	ds
	push	dx
	push	es					; Copy ES...
	pop		ds					; ...to DS
	mov		dx, di				; DS:DX now points to destination buffer
	mov		ah, 3Fh				; Read from File or Device
	int		21h
	pop		dx
	pop		ds
	ret


;--------------------------------------------------------------------
; Writes binary data to file.
; File position is updated so next write will start where
; previous write stopped.
; 
; File_Write
;	Parameters:
;		BX:		File handle
;		CX:		Number of bytes to write
;		ES:DI:	Ptr to source buffer
;	Returns:
;		AX:		Number of bytes actually written if successfull (EOF check)
;				DOS error code if CF set
;		CF:		Clear if successfull
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_Write:
	push	ds
	push	dx
	push	es					; Copy ES...
	pop		ds					; ...to DS
	mov		dx, di				; DS:DX now points to source buffer
	mov		ah, 40h				; Write to File or Device
	int		21h
	pop		dx
	pop		ds
	ret


;--------------------------------------------------------------------
; Sets current file position to wanted offset.
; 
; File_SetFilePos
;	Parameters:
;		BX:		File handle
;		CX:DX:	New offset (signed)
;	Returns:
;		AX:		DOS error code if CF set
;		CF:		Clear if successfull
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_SetFilePos:
	push	dx
	mov		ax, 42h<<8			; Set Current File Position (from file start)
	int		21h
	pop		dx
	ret


;--------------------------------------------------------------------
; Changes current default drive.
; 
; File_SetDrive
;	Parameters:
;		DL:		New default drive (00h=A:, 01h=B: ...)
;	Returns:
;		AL:		Number of potentially valid drive letters available
;	Corrupts registers:
;		AH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_SetDrive:
	mov		ah, 0Eh				; Select Default Drive
	int		21h
	ret


;--------------------------------------------------------------------
; Returns current default drive and number of
; potentially drive letters available.
; 
; File_GetDrive
;	Parameters:
;		Nothing
;	Returns:
;		AL:		Number of potentially valid drive letters available
;		AH:		Current default drive (00h=A:, 01h=B: ...)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_GetDrive:
	push	dx
	mov		ah, 19h				; Get Current Default Drive
	int		21h					; Get drive to AL
	mov		dl, al				; Copy drive number to DL
	call	File_SetDrive		; Set to current and get drive letter count
	mov		ah, dl				; Copy current drive to AH
	pop		dx
	ret


;--------------------------------------------------------------------
; Checks are the potentially valid drive letters returned by 
; File_SetDrive and File_GetDrive actually valid or not.
; 
; File_IsDrive
;	Parameters:
;		DL:		Drive number (00h=A:, 01h=B: ...)
;	Returns:
;		AL:		00h if valid drive number, FFh if invalid drive number
;		ZF:		Set if drive number is valid
;				Cleared if drive number is invalid
;	Corrupts registers:
;		AH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_IsDrive:
	push	ds
	push	bx
	inc		dx					; 00h=default drive, 01h=A:, 02h=B: ...
	mov		ah, 32h				; Get DOS Drive Parameter Block for Specific Drive
	int		21h
	dec		dx					; Restore DX
	test	al, al				; Set ZF according to result
	pop		bx
	pop		ds
	ret


;--------------------------------------------------------------------
; Returns number of valid drive letters.
; 
; File_GetValidDrvCnt
;	Parameters:
;		Nothing
;	Returns:
;		CX:		Number of valid drives
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_GetValidDrvCnt:
	call	File_GetDrive		; Get potential drive letters to AL
	eMOVZX	cx, al				; Letter count to CX
	xor		dx, dx				; Zero DX (DH=valid count, DL=drv num)
ALIGN JUMP_ALIGN
.LetterLoop:
	call	File_IsDrive
	not		al					; Invert return bits
	and		al, 1				; Clear all but bit 1
	add		dh, al				; Increment valid count
	inc		dx					; Increment drive number
	loop	.LetterLoop			; Loop while drive letters left
	eMOVZX	cx, dh				; Valid drv count to CX
	ret


;--------------------------------------------------------------------
; Return device number for Nth valid drive.
; This function does not check if index in CX is valid.
; 
; File_GetNthValidDrv
;	Parameters:
;		CX:		Index of valid drive to look for
;	Returns:
;		AX:		Drive letter (A, B...)
;		DX:		Drive device number (00h=A:, 01h=B: ...)
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
File_GetNthValidDrv:
	inc		cx					; Index to count
	mov		dx, -1				; Dev num, increments to zero
ALIGN JUMP_ALIGN
.DrvLoop:
	inc		dx					; Increment device number
	call	File_IsDrive		; Is drive valid?
	jnz		.DrvLoop			;  Loop if not
	loop	.DrvLoop			; Loop until wanted drive found
	mov		ax, dx				; Drive device number to AX
	add		ax, 'A'				; Dev number to drive letter
	ret


;--------------------------------------------------------------------
; Changes current directory.
; 
; File_ChangeDir
;	Parameters:
;		DS:DX	Ptr to destination ASCIZ path name
;	Returns:
;		AX:		DOS Error code
;		CF:		Clear if successfull
;				Set if error
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_ChangeDir:
	mov		ah, 3Bh				; Set Current Directory
	int		21h
	ret


;--------------------------------------------------------------------
; Finds files from wanted path using search wildcard characters.
; 
; File_FindAndCount
;	Parameters:
;		DS:DX	Ptr to ASCIZ path or file name (* and ? wildcards allowed)
;	Returns:
;		CX:		Number of files found
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_IsFile:
File_FindAndCount:
	xor		cx, cx				; Zero file count
	call	File_FindFirst		; Find first file
	jc		.Return				; Return if no files found
ALIGN JUMP_ALIGN
.IsNextLoop:
	inc		cx					; Increment file count
	call	File_FindNext		; Find next file
	jnc		.IsNextLoop			; Loop while files left
ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; Finds files from wanted path using search wildcard characters.
; Ptr to DTA is returned for wanted file.
; 
; File_GetDTA
;	Parameters:
;		CX:		Index for file whose DTA is to be returned
;		DS:DX	Ptr to ASCIZ path or file name (* and ? wildcards allowed)
;	Returns:
;		DS:BX:	Ptr to file DTA
;		CF:		Set if file was not found
;				Cleared if file found and DTA is returned
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_GetDTA:
	call	File_FindFirst		; Find first file
	jc		.RetErr				; Return if no files found
	xor		dx, dx				; Zero file index
ALIGN JUMP_ALIGN
.IsNextLoop:
	cmp		cx, dx				; Wanted file found?
	je		.RetDTA				;  If so, jump to return DTA
	inc		dx					; Increment index for next file
	call	File_FindNext		; Find next file
	jnc		.IsNextLoop			; Loop while files left
.RetErr:
	ret
ALIGN JUMP_ALIGN
.RetDTA:
	push	cs					; Push code segment
	pop		ds					; CS to DS
	mov		bx, 80h				; DTA starts at DOS PSP:80h
	ret


;-------------- Private functions ---------------------

;--------------------------------------------------------------------
; Find first file or directory.
; 
; File_FindFirst
;	Parameters:
;		DS:DX	Ptr to ASCIZ path or file name (* and ? wildcards allowed)
;	Returns:
;		AX:		DOS Error code
;		CF:		Set if file was not found
;				Cleared if file was found
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_FindFirst:
	push	cx
	;mov		cx, FLG_FATTR_DIR	; Directories and files
	xor		cx, cx
	mov		ax, 4Eh<<8			; Find First Matching File
	int		21h
	pop		cx
	ret


;--------------------------------------------------------------------
; Find next file or directory. File_FindFirst must always be called
; before calling File_FindNext.
; 
; File_FindNext
;	Parameters:
;		Nothing
;	Returns:
;		AX:		DOS Error code
;		CF:		Set if file was not found
;				Cleared if file was found
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
File_FindNext:
	mov		ah, 4Fh				; Find Next Matching File
	int		21h
	ret
