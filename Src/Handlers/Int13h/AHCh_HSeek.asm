; File name		:	AHCh_HSeek.asm
; Project name	:	IDE BIOS
; Created date	:	13.12.2007
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=Ch, Seek.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=Ch, Seek.
;
; AHCh_HandlerForSeek
;	Parameters:
;		AH:		Bios function Ch
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
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
AHCh_HandlerForSeek:
	push	dx
	push	cx
	push	bx
	push	ax
	call	AHCh_SeekToCylinder
	jmp		Int13h_PopXRegsAndReturn


;--------------------------------------------------------------------
; Seeks to a cylinder.
;
; AHCh_SeekToCylinder
;	Parameters:
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		DL:		Drive Number
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to DPT
;		AH:		BIOS Error code
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AHCh_SeekToCylinder:
	call	FindDPT_ForDriveNumber		; DS:DI now points to DPT
	mov		ax, HCMD_SEEK<<8			; Load cmd to AH, AL=zero sector cnt
	call	HCommand_OutputCountAndLCHSandCommand
	jc		SHORT .Return				; Return if error
	mov		bx, di						; DS:BX now points to DPT
	jmp		HStatus_WaitIrqOrRdy		; Wait for IRQ or RDY
.Return:
	ret
