; File name		:	AH4h_HVerify.asm
; Project name	:	IDE BIOS
; Created date	:	13.10.2007
; Last update	:	13.4.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=4h, Verify Disk Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=4h, Verify Disk Sectors.
;
; AH4h_HandlerForVerifyDiskSectors
;	Parameters:
;		AH:		Bios function 4h
;		AL:		Number of sectors to verify
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		DL:		Drive number
;		ES:BX:	Pointer to source data (not used)
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
AH4h_HandlerForVerifyDiskSectors:
	test	al, al						; Invalid sector count?
	jz		SHORT AH2h_ZeroCntErr		;  If so, return with error
	push	dx
	push	cx
	push	bx
	push	ax
	call	AH4h_VerifySectors
	jmp		Int13h_PopXRegsAndReturn


;--------------------------------------------------------------------
; Verifies hard disk sectors.
;
; AH4h_VerifySectors
;	Parameters:
;		AL:		Number of sectors to verify
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to DPT
;		AH:		Int 13h/40h floppy return status
;		CF:		0 if successfull, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH4h_VerifySectors:
	call	FindDPT_ForDriveNumber		; DS:DI now points to DPT
	mov		ah, HCMD_VERIFY_SECT		; Load command to AH
	call	HCommand_OutputCountAndLCHSandCommand
	jc		SHORT .Return				; Return if error
	mov		bx, di						; DS:BX now points to DPT
	jmp		HStatus_WaitIrqOrRdy		; Wait for IRQ or RDY
.Return:
	ret
