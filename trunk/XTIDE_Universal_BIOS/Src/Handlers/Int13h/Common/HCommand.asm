; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for outputting IDE commands and parameters.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Outputs sector count, L-CHS address and command to IDE registers.
; This function does not wait until command has been completed.
;
; HCommand_OutputCountAndLCHSandCommand
;	Parameters:
;		AH:		Seek or data transfer command
;		AL:		Sector count (1...255, 0=256)
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		DS:DI:	Ptr to DPT
;	Returns:
;		AH:		BIOS Error code (if error)
;		CF:		0 if succesfull
;				1 if any error
;	Corrupts registers:
;		CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HCommand_OutputCountAndLCHSandCommand:
	push	bx
	push	ax										; Store sector count and command
	call	HDrvSel_SelectDriveForDataTransfer
	jc		SHORT .ReturnError
	call	HIRQ_ClearTaskFlag
	call	HAddress_ConvertParamsFromBiosLCHStoIDE
	mov		dx, [RAMVARS.wIdeBase]					; Load IDE Base Port address
	call	HCommand_OutputTranslatedLCHSaddress	; DX to Sector count register
	pop		ax										; Restore sector count and command
	call	HCommand_OutputSectorCountAndCommand

	clc												; Clear CF since success
	pop		bx
	ret
.ReturnError:
	pop		bx										; Discard pushed AX
	pop		bx
	ret


;--------------------------------------------------------------------
; Outputs L-CHS address that has been translated P-CHS or LBA28
; when necessary.
;
; HCommand_OutputTranslatedLCHSaddress
;	Parameters:
;		BL:		LBA Low Register / Sector Number Register (LBA 7...0)
;		CL:		LBA Mid Register / Low Cylinder Register (LBA 15...8)
;		CH:		LBA High Register / High Cylinder Register (LBA 23...16)
;		BH:		Drive and Head Register (LBA 27...24)
;		DX:		IDE Base Port address
;		DS:DI:	Ptr to DPT
;	Returns:
;		DX:		IDE Sector Count Register address
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HCommand_OutputTranslatedLCHSaddress:
	add		dx, BYTE REG_IDE_LBA_LOW
	mov		al, bl
	out		dx, al						; Output LBA 7...0

	; Some (VLB) controllers fail to accept WORD write to cylinder
	; registers so we must output two bytes instead.
	inc		dx							; REG_IDE_LBA_MID
	mov		al, cl
	out		dx, al						; Output LBA 8...15

	inc		dx							; REG_IDE_LBA_HIGH
	mov		al, ch
	out		dx, al						; Output LBA 16...23

	inc		dx							; REG_IDE_DRVHD
	mov		al, [di+DPT.bDrvSel]		; Load other bits for Drive and Head Register
	or		al, bh
	out		dx, al						; Output LBA 27...24

	sub		dx, BYTE REG_IDE_DRVHD-REG_IDE_CNT
	ret


;--------------------------------------------------------------------
; Outputs sector count and seek or data transfer command.
;
; HCommand_OutputSectorCountAndCommand
;	Parameters:
;		AH:		Seek or data transfer command
;		AL:		Sector count (1...255, 0=256)
;		DX:		IDE Sector Count Register address
;	Returns:
;		Nothing
;	Corrupts registers:
;		AH, DX
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
HCommand_OutputSectorCountAndCommand:
	out		dx, al						; Output sector count
	add		dx, BYTE REGW_IDE_CMD-REG_IDE_CNT
	xchg	al, ah						; AL=Command, AH=Sector count
	out		dx, al
	mov		al, ah						; Restore sector count to AL
	ret
