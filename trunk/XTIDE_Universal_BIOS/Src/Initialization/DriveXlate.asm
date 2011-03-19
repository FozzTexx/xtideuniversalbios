; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for swapping drive letters.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DriveXlate_ToOrBack
;	Parameters:
;		DL:		Drive number to be possibly translated
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Translated drive number
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DriveXlate_ToOrBack:
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_DRVXLAT
	jz		SHORT .Return			; Return if translation disabled
	xchg	di, ax					; Backup AX
	call	SwapFloppyDriveOrHardDisk
	xchg	ax, di
.Return:
	ret


;--------------------------------------------------------------------
; SwapFloppyDriveOrHardDisk
;	Parameters:
;		DL:		Drive number to be possibly swapped
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Translated drive number
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SwapFloppyDriveOrHardDisk:
	mov		ah, 80h					; Assume hard disk
	mov		al, BYTE [RAMVARS.xlateVars+XLATEVARS.bHDSwap]
	test	dl, ah					; Hard disk?
	jnz		SHORT SwapDrive			; If so, jump to swap
	mov		al, BYTE [RAMVARS.xlateVars+XLATEVARS.bFDSwap]
	cbw
	; Fall to SwapDrive

;--------------------------------------------------------------------
; SwapDrive
;	Parameters:
;		AL:		Drive number to swap to 00h/80h
;		AH:		00h/80h to be swapped to stored drive number
;		DL:		Drive number to be possibly swapped
;	Returns:
;		DL:		Translated drive number
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
SwapDrive:
	cmp		ah, dl				; Swap DL from 00h/80h to xxh?
	je		SHORT .SwapToXXhInAL
	cmp		al, dl				; Swap DL from xxh to 00h/80h?
	je		SHORT .SwapTo00hOr80hInAH
	ret
ALIGN JUMP_ALIGN
.SwapTo00hOr80hInAH:
	mov		dl, ah
	ret
ALIGN JUMP_ALIGN
.SwapToXXhInAL:
	mov		dl, al
	ret


;--------------------------------------------------------------------
; Resets drive swapping variables to defaults (no swapping).
;
; DriveXlate_Reset
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DriveXlate_Reset:
	mov		WORD [RAMVARS.xlateVars], 8000h	; .bFDSwap and .bHDSwap
	ret


;--------------------------------------------------------------------
; Stores drive to be swapped.
;
; DriveXlate_SetDriveToSwap
;	Parameters:
;		DL:		Drive to swap to 00h or 80h
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DriveXlate_SetDriveToSwap:
	test	dl, dl				; Floppy drive?
	js		SHORT .SetHardDiskToSwap
.SetFloppyDriveToSwap:
	mov		[RAMVARS.xlateVars+XLATEVARS.bFDSwap], dl
	ret
ALIGN JUMP_ALIGN
.SetHardDiskToSwap:
	mov		[RAMVARS.xlateVars+XLATEVARS.bHDSwap], dl
	ret
