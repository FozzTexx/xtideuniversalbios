; File name		:	AH1h_HStatus.asm
; Project name	:	IDE BIOS
; Created date	:	27.9.2007
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=1h, Read Disk Status.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=1h, Read Disk Status.
;
; AH1h_HandlerForReadDiskStatus
;	Parameters:
;		AH:		Bios function 1h
;		DL:		Drive number (8xh)
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		Int 13h floppy return status
;		CF:		0 if AH = RET_HD_SUCCESS, 1 otherwise (error)
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH1h_HandlerForReadDiskStatus:
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, di
	xor		ah, ah					; Zero AH
	cmp		ah, [BDA.bHDLastSt]		; Set CF if error code is non-zero
	mov		ah, [BDA.bHDLastSt]
	pop		ds
	jmp		Int13h_PopDiDsAndReturn
