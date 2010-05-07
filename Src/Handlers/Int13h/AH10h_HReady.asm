; File name		:	AH10h_HReady.asm
; Project name	:	IDE BIOS
; Created date	:	9.12.2007
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=10h, Check Drive Ready.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=10h, Check Drive Ready.
;
; AH10h_HandlerForCheckDriveReady
;	Parameters:
;		AH:		Bios function 10h
;		DL:		Drive number (8xh)
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH10h_HandlerForCheckDriveReady:
	; Save registers
	push	dx
	push	cx
	push	bx
	push	ax

	; Wait until drive is ready
	call	FindDPT_ForDriveNumber		; DS:DI now points to DPT
	call	HStatus_WaitRdyDefTime
	jmp		Int13h_PopXRegsAndReturn
