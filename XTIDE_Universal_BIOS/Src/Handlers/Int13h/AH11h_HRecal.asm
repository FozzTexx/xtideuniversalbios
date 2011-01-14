; File name		:	AH11h_HRecal.asm
; Project name	:	IDE BIOS
; Created date	:	28.9.2007
; Last update	:	14.1.2011
; Author		:	Tomi Tilli,
;				:	Krister Nordvall (optimizations)
; Description	:	Int 13h function AH=11h, Recalibrate.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=11h, Recalibrate.
;
; AH11h_HandlerForRecalibrate
;	Parameters:
;		AH:		Bios function 11h
;		DL:		Drive number
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		BIOS Error code
;		CF:		0 if succesfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH11h_HandlerForRecalibrate:
	push	dx
	push	cx
	push	bx
	push	ax
%ifndef USE_186
	call	AH11h_RecalibrateDrive
	jmp		Int13h_PopXRegsAndReturn
%else
	push	Int13h_PopXRegsAndReturn
	; Fall through to AH11h_RecalibrateDrive
%endif


;--------------------------------------------------------------------
; Int 13h function AH=11h, Recalibrate.
;
; AH11h_HRecalibrate
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to DPT
;		AH:		BIOS Error code
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH11h_RecalibrateDrive:
	; Recalibrate command is optional, vendor specific and not even
	; supported on later ATA-standards. Let's do seek instead.
	mov		cx, 1						; Seek to Cylinder 0, Sector 1
	xor		dh, dh						; Head 0
	jmp		AHCh_SeekToCylinder
