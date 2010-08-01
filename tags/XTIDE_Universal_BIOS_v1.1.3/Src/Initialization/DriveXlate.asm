; File name		:	DriveXlate.asm
; Project name	:	IDE BIOS
; Created date	:	15.3.2010
; Last update	:	2.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions for swapping drive letters.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Translates drive number when entering INT 13h.
;
; DriveXlate_WhenEnteringInt13h
;	Parameters:
;		DL:		Drive number to be possibly translated
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Translated drive number
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DriveXlate_WhenEnteringInt13h:
	inc		BYTE [RAMVARS.xlateVars+XLATEVARS.bRecurCnt]
	cmp		BYTE [RAMVARS.xlateVars+XLATEVARS.bRecurCnt], 1
	je		SHORT DriveXlate_ToOrBack
	ret


;--------------------------------------------------------------------
; Translates drive number when leaving INT 13h.
;
; DriveXlate_WhenLeavingInt13h
;	Parameters:
;		DL:		Drive number to be possibly translated
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Translated drive number
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DriveXlate_WhenLeavingInt13h:
	dec		BYTE [RAMVARS.xlateVars+XLATEVARS.bRecurCnt]
	jz		SHORT DriveXlate_ToOrBack
	ret


;--------------------------------------------------------------------
; Translates drive number to or back.
;
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
	call	DriveXlate_SwapFloppyDriveOrHardDisk
	xchg	ax, di
.Return:
	ret


;--------------------------------------------------------------------
; Swaps Floppy Drive or Hard Disk number.
;
; DriveXlate_SwapFloppyDriveOrHardDisk
;	Parameters:
;		DL:		Drive number to be possibly swapped
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Translated drive number
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DriveXlate_SwapFloppyDriveOrHardDisk:
	test	dl, 80h							; Hard disk?
	jnz		SHORT DriveXlate_SwapHardDisk	; If so, jump to swap
	; Fall to DriveXlate_SwapFloppyDrive

;--------------------------------------------------------------------
; Swaps Floppy Drive number.
;
; DriveXlate_SwapFloppyDrive
;	Parameters:
;		DL:		Drive number to be possibly swapped
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Translated drive number
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
DriveXlate_SwapFloppyDrive:
	eMOVZX	ax, BYTE [RAMVARS.xlateVars+XLATEVARS.bFDSwap]
	jmp		SHORT DriveXlate_SwapDrive

;--------------------------------------------------------------------
; Swaps Hard Disk number.
;
; DriveXlate_SwapHardDisk
;	Parameters:
;		DL:		Drive number to be possibly swapped
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Translated drive number
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DriveXlate_SwapHardDisk:
	mov		ah, 80h
	mov		al, BYTE [RAMVARS.xlateVars+XLATEVARS.bHDSwap]
	; Fall to DriveXlate_SwapDrive

;--------------------------------------------------------------------
; Swaps Hard Disk or Floppy Drive number.
;
; DriveXlate_SwapDrive
;	Parameters:
;		AL:		Drive number to swap to 00h/80h
;		AH:		00h/80h to be swapped to stored drive number
;		DL:		Drive number to be possibly swapped
;	Returns:
;		DL:		Translated drive number
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
DriveXlate_SwapDrive:
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
	mov		BYTE [RAMVARS.xlateVars+XLATEVARS.bRecurCnt], 0
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
	test	dl, 80h				; Floppy drive?
	jnz		SHORT DriveXlate_SetHardDiskToSwap
	; Fall to DriveXlate_SetFloppyDriveToSwap

;--------------------------------------------------------------------
; Stores floppy drive to be swapped.
;
; DriveXlate_SetFloppyDriveToSwap
;	Parameters:
;		DL:		Drive to swap to 00h
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
DriveXlate_SetFloppyDriveToSwap:
	mov		[RAMVARS.xlateVars+XLATEVARS.bFDSwap], dl
	ret

;--------------------------------------------------------------------
; Stores hard disk to be swapped.
;
; DriveXlate_SetHardDiskToSwap
;	Parameters:
;		DL:		Drive to swap to 80h
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
DriveXlate_SetHardDiskToSwap:
	mov		[RAMVARS.xlateVars+XLATEVARS.bHDSwap], dl
	ret


;--------------------------------------------------------------------
; Checks if INT 13h function returns some value in DL
; (other than the drive number that was also parameter).
;
; DriveXlate_DoesFunctionReturnSomethingInDL
;	Parameters:
;		AH:		INT 13h BIOS Function
;		DL:		Drive number
;	Returns:
;		CF:		Set if something is returned in DL
;				Cleared if only drive number parameter is returned in DL
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
DriveXlate_DoesFunctionReturnSomethingInDL:
	cmp		ah, 08h			; AH=08h, Read Disk Drive Parameters?
	je		SHORT DriveXlate_FunctionReturnsSomethingInDL
	test	dl, 80h
	jz		SHORT DriveXlate_DoesFloppyFunctionReturnSomethingInDL
	; Fall to DriveXlate_DoesHardDiskFunctionReturnSomethingInDL

;--------------------------------------------------------------------
; Checks if INT 13h hard disk or floppy drive function returns some
; value in DL other than the drive number that was also parameter).
; Some functions return different values for hard disks and floppy drives.
;
; DriveXlate_DoesHardDiskFunctionReturnSomethingInDL
; DriveXlate_DoesFloppyFunctionReturnSomethingInDL
;	Parameters:
;		AH:		INT 13h BIOS Function
;		DL:		Hard Disk number
;	Returns:
;		CF:		Set if something is returned in DL
;				Cleared if only drive number parameter is returned in DL
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------	
; ALIGN JUMP_ALIGN
DriveXlate_DoesHardDiskFunctionReturnSomethingInDL:
	cmp		ah, 15h			; AH=15h, Read Disk Drive Size?
	je		SHORT DriveXlate_FunctionReturnsSomethingInDL
DriveXlate_DoesFloppyFunctionReturnSomethingInDL:
	clc
	ret

ALIGN JUMP_ALIGN
DriveXlate_FunctionReturnsSomethingInDL:
	stc
	ret
