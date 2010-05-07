; File name		:	BootPrint.asm
; Project name	:	IDE BIOS
; Created date	:	19.3.2010
; Last update	:	1.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions for printing boot related strings.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Prints trying to boot string.
;
; BootPrint_TryToBootFromDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_TryToBootFromDL:
	push	dx
	ePUSH_T	ax, BootPrint_PopDxAndReturn	; Return address

	xor		dh, dh				; Translated drive number to DX
	push	dx					; Push translated drive number
	call	DriveXlate_ToOrBack
	push	dx					; Push untranslated drive number

	mov		ax, g_szFloppyDrv	; Assume "Floppy Drive"
	test	dl, 80h				; Hard Disk?
	jz		SHORT .PushHardOrFloppy
	add		ax, BYTE g_szHardDrv - g_szFloppyDrv
.PushHardOrFloppy:
	push	ax

	mov		si, g_szTryToBoot
	mov		dh, 6				; 6 bytes pushed to stack
	jmp		PrintString_JumpToFormat

ALIGN JUMP_ALIGN
BootPrint_PopDxAndReturn:
	pop		dx
	ret


;--------------------------------------------------------------------
; Prints message that valid boot sector has been found.
;
; BootPrint_BootSectorLoaded
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_BootSectorLoaded:
	push	dx
	ePUSH_T	ax, BootPrint_PopDxAndReturn	; Return address

	ePUSH_T	ax, g_szFound
	ePUSH_T	ax, g_szBootSector
	mov		si, g_szSectRead
	mov		dh, 4							; 4 bytes pushed to stack
	jmp		PrintString_JumpToFormat


;--------------------------------------------------------------------
; Prints message that first sector is not boot sector.
;
; BootPrint_FirstSectorNotBootable
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_FirstSectorNotBootable:
	ePUSH_T	ax, g_szNotFound
	ePUSH_T	ax, g_szBootSector
	mov		si, g_szSectRead
	mov		dh, 4				; 4 bytes pushed to stack
	jmp		PrintString_JumpToFormat


;--------------------------------------------------------------------
; Prints error code for failed first sector read attempt.
;
; BootPrint_FailedToLoadFirstSector
;	Parameters:
;		AH:		INT 13h error code
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_FailedToLoadFirstSector:
	eMOVZX	cx, ah				; Error code to CX
	push	cx					; Push INT 13h error code
	mov		si, g_szReadError
	mov		dh, 2				; 2 bytes pushed to stack
	jmp		PrintString_JumpToFormat
