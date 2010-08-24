; File name		:	AH15h_HSize.asm
; Project name	:	IDE BIOS
; Created date	:	28.9.2007
; Last update	:	24.8.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=15h, Read Disk Drive Size.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=15h, Read Disk Drive Size.
;
; AH15h_HandlerForReadDiskDriveSize
;	Parameters:
;		AH:		Bios function 15h
;		DL:		Drive number
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		If succesfull:
;			AH:		3 (Hard disk accessible)
;			CX:DX:	Total number of sectors
;			CF:		0
;		If failed:
;			AH:		0 (Drive not present)
;			CX:DX:	0
;			CF:		1
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH15h_HandlerForReadDiskDriveSize:
	push	bx
	push	ax

	call	HCapacity_GetSectorCountFromOurAH08h; Sector count to DX:AX
	mov		cx, dx								; HIWORD to CX
	xchg	dx, ax								; LOWORD to DX

	pop		ax
	pop		bx
	mov		ah, 3								; Type code = Hard disk
	clc
	jmp		Int13h_ReturnWithValueInDL
