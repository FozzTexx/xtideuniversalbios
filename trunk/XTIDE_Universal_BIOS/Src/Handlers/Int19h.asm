; Project name	:	XTIDE Universal BIOS
; Description	:	Int 19h BIOS functions (Boot Strap Loader).

; Section containing code
SECTION .text

B_READ_RETRY_TIMES	EQU	3	; Number of times to retry


;--------------------------------------------------------------------
; Boots if boot sector is successfully read from the drive.
;
; Int19h_TryToLoadBootSectorFromDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		DS:		RAMVARS segment
;	Returns:
;		ES:BX:	Ptr to boot sector (if successfull)
;		CF:		Set if boot sector loaded succesfully
;				Cleared if failed to load boot sector
;	Corrupts registers:
;		AX, CX, DH, DI, (DL if failed to read boot sector)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19h_TryToLoadBootSectorFromDL:
	call	BootPrint_TryToBootFromDL
	call	LoadFirstSectorFromDriveDL
	jc		SHORT .FailedToLoadFirstSector

	test	dl, 80h
	jz		SHORT .AlwaysBootFromFloppyDriveForBooterGames
	cmp		WORD [es:bx+510], 0AA55h		; Valid boot sector?
	jne		SHORT .FirstHardDiskSectorNotBootable
.AlwaysBootFromFloppyDriveForBooterGames:
	mov		bx, g_szFound
	call	BootPrint_BootSectorResultStringFromBX
	stc
	ret
.FailedToLoadFirstSector:
	call	BootPrint_FailedToLoadFirstSector
	clc
	ret
.FirstHardDiskSectorNotBootable:
	mov		bx, g_szNotFound
	call	BootPrint_BootSectorResultStringFromBX
	clc
	ret

;--------------------------------------------------------------------
; LoadFirstSectorFromDriveDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;	Returns:
;		AH:		INT 13h error code
;		ES:BX:	Ptr to boot sector (if successfull)
;		CF:		Cleared if read successfull
;				Set if any error
;	Corrupts registers:
;		AL, CX, DH, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
LoadFirstSectorFromDriveDL:
	LOAD_BDA_SEGMENT_TO	es, bx				; ES:BX now points to...
	mov		bx, BOOTVARS.rgbBootSect		; ...boot sector location
	mov		di, B_READ_RETRY_TIMES			; Initialize retry counter
ALIGN JUMP_ALIGN
.ReadRetryLoop:
	call	.ResetBootDriveFromDL
	call	.LoadFirstSectorFromDLtoESBX
	jnc		SHORT .Return
	dec		di								; Decrement retry counter
	jnz		SHORT .ReadRetryLoop			; Loop while retries left
ALIGN JUMP_ALIGN
.Return:
	ret

;--------------------------------------------------------------------
; .ResetBootDriveFromDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;	Returns:
;		AH:		INT 13h error code
;		CF:		Cleared if read successfull
;				Set if any error
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ResetBootDriveFromDL:
	xor		ax, ax							; AH=0h, Disk Controller Reset
	test	dl, 80h							; Floppy drive?
	eCMOVNZ	ah, 0Dh							; AH=Dh, Reset Hard Disk (Alternate reset)
	int		INTV_DISK_FUNC
	ret

;--------------------------------------------------------------------
; Reads first sector (boot sector) from drive DL to ES:BX.
;
; .LoadFirstSectorFromDLtoESBX
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		ES:BX:	Destination buffer for boot sector
;	Returns:
;		AH:		INT 13h error code
;		ES:BX:	Ptr to boot sector
;		CF:		Cleared if read successfull
;				Set if any error
;	Corrupts registers:
;		AL, CX, DH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.LoadFirstSectorFromDLtoESBX:
	mov		ax, 0201h						; Read 1 sector
	mov		cx, 1							; Cylinder 0, Sector 1
	xor		dh, dh							; Head 0
	int		INTV_DISK_FUNC
	ret


;--------------------------------------------------------------------
; Jumps to boot sector pointed by ES:BX.
;
; Int19h_JumpToBootSector
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		ES:BX:	Ptr to boot sector
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19h_JumpToBootSector:
	push	es								; Push boot sector segment
	push	bx								; Push boot sector offset
	call	Int19h_ClearSegmentsForBoot
	xor		dh, dh							; Device supported by INT 13h
	retf

;--------------------------------------------------------------------
; Clears DS and ES registers to zero.
;
; Int19h_ClearSegmentsForBoot
;	Parameters:
;		Nothing
;	Returns:
;		DS=ES:	Zero
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19h_ClearSegmentsForBoot:
	xor		ax, ax
	mov		ds, ax
	mov		es, ax
	ret
