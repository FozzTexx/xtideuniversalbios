; File name		:	AH23h_HFeatures.asm
; Project name	:	IDE BIOS
; Created date	:	28.12.2009
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=23h,
;					Set Controller Features Register.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=23h, Set Controller Features Register.
;
; AH23h_HandlerForSetControllerFeatures
;	Parameters:
;		AH:		Bios function 23h
;		AL:		Feature Number (parameter to Features Register = subcommand)
;		DL:		Drive number (8xh)
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Parameter registers are undocumented, specific for this BIOS:
;		BH:		Parameter to Sector Count Register (subcommand specific)
;		BL:		Parameter to Sector Number Register (subcommand specific)
;		CL:		Parameter to Low Cylinder Register (subcommand specific)
;		CH:		Parameter to High Cylinder Register (subcommand specific)
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH23h_HandlerForSetControllerFeatures:
	push	dx
	push	cx
	push	bx
	push	ax
	push	si

	; Backup AL and BH to SI
	mov		ah, bh
	xchg	si, ax

	; Select Master or Slave and wait until ready
	call	FindDPT_ForDriveNumber		; DS:DI now points to DPT
	call	HDrvSel_SelectDriveAndDisableIRQ
	jc		SHORT .Return				; Return if error

	; Output Feature Number
	mov		ax, si						; Feature number to AL
	mov		dx, [RAMVARS.wIdeBase]		; Load base port address
	inc		dx							; REGW_IDE_FEAT
	out		dx, al

	; Output parameters to Sector Number Register and Cylinder Registers
	xor		bh, bh						; Zero head number
	dec		dx							; Back to base port address
	call	HCommand_OutputTranslatedLCHSaddress

	; Output parameter to Sector Count Register and command
	xchg	ax, si						; Sector Count Reg param to AH
	mov		al, ah						; Sector Count Reg param to AL
	mov		ah, HCMD_SET_FEAT			; Load Set Features command to AH
	call	HCommand_OutputSectorCountAndCommand

	call	HStatus_WaitBsyDefTime		; Wait until drive ready
.Return:
	pop		si
	jmp		Int13h_PopXRegsAndReturn
