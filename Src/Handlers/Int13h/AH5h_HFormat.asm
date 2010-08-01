; File name		:	AH5h_HFormat.asm
; Project name	:	IDE BIOS
; Created date	:	2.11.2007
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=5h, Format Disk Track.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=5h, Format Disk Track.
;
; AH5h_HandlerForFormatDiskTrack
;	Parameters:
;		AH:		Bios function 5h
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		DL:		Drive number
;		ES:BX:	Pointer to address table
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		Int 13h/40h floppy return status
;		CF:		0 if successfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH5h_HandlerForFormatDiskTrack:
	push	dx
	push	cx
	push	bx
	push	ax

	; Format command is vendor specific on IDE drives.
	; Let's do verify instead.
	call	FindDPT_ForDriveNumber		; DS:DI now points to DPT
	mov		al, [di+DPT.bPSect]			; Load Sectors per Track to AL
	call	AH4h_VerifySectors
	jmp		Int13h_PopXRegsAndReturn
