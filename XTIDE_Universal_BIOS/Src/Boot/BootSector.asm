; Project name	:	XTIDE Universal BIOS
; Description	:	Reading and jumping to boot sector.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; BootSector_TryToLoadFromDriveDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		DS:		RAMVARS segment
;	Returns:
;		ES:BX:	Ptr to boot sector (if successfull)
;		CF:		Set if boot sector loaded succesfully
;				Cleared if failed to load boot sector
;	Corrupts registers:
;		AX, CX, DH, SI, DI, (DL if failed to read boot sector)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootSector_TryToLoadFromDriveDL:
	call	BootPrint_TryToBootFromDL
	call	LoadFirstSectorFromDriveDL
	jc		SHORT .FailedToLoadFirstSector

	test	dl, dl
	jns		SHORT .AlwaysBootFromFloppyDriveForBooterGames
	cmp		WORD [es:bx+510], 0AA55h		; Valid boot sector?
	jne		SHORT .FirstHardDiskSectorNotBootable
.AlwaysBootFromFloppyDriveForBooterGames:
	stc
	ret
.FailedToLoadFirstSector:
	call	BootPrint_FailedToLoadFirstSector
	clc
	ret
.FirstHardDiskSectorNotBootable:
	mov		si, g_szBootSectorNotFound
	call	BootMenuPrint_NullTerminatedStringFromCSSIandSetCF
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
	mov		di, BOOT_READ_RETRY_TIMES		; Initialize retry counter
ALIGN JUMP_ALIGN
.ReadRetryLoop:
	call	.ResetBootDriveFromDL
	call	.LoadFirstSectorFromDLtoESBX
	jnc		SHORT .Return
	dec		di								; Decrement retry counter
	jnz		SHORT .ReadRetryLoop			; Loop while retries left
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
	test	dl, dl							; Floppy drive?
	jns		SHORT .SkipAltReset
	mov		ah, 0Dh							; AH=Dh, Reset Hard Disk (Alternate reset)
.SkipAltReset:
	int		BIOS_DISK_INTERRUPT_13h
	ret

;--------------------------------------------------------------------
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
	int		BIOS_DISK_INTERRUPT_13h
	ret
