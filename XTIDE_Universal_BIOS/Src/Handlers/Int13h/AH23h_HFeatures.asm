; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=23h,
;					Set Controller Features Register.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=23h, Set Controller Features Register.
;
; AH23h_HandlerForSetControllerFeatures
;	Parameters:
;		AL, CX:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Parameters on INTPACK in SS:BP:
;		AL:		Feature Number (parameter to Features Register = subcommand)
;	(Parameter registers are undocumented, there are specific for this BIOS):
;		BH:		Parameter to Sector Count Register (subcommand specific)
;		BL:		Parameter to Sector Number Register (subcommand specific)
;		CL:		Parameter to Low Cylinder Register (subcommand specific)
;		CH:		Parameter to High Cylinder Register (subcommand specific)
;	Returns with INTPACK in SS:BP:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH23h_HandlerForSetControllerFeatures:
%ifndef USE_186
	call	AH23h_SetControllerFeatures
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%else
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall through to AH23h_SetControllerFeatures
%endif


;--------------------------------------------------------------------
; AH23h_SetControllerFeatures
;	Parameters:
;		AL:		Feature Number (parameter to Features Register = subcommand)
;		BH:		Parameter to Sector Count Register (subcommand specific)
;		BL:		Parameter to Sector Number Register (subcommand specific)
;		CL:		Parameter to Low Cylinder Register (subcommand specific)
;		CH:		Parameter to High Cylinder Register (subcommand specific)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AX, BX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH23h_SetControllerFeatures:
	; Backup AL and BH to SI
	mov		ah, bh
	xchg	si, ax

	; Select Master or Slave and wait until ready
	call	HDrvSel_SelectDriveAndDisableIRQ
	jc		SHORT .ReturnWithErrorCodeInAH

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

	jmp		HStatus_WaitBsyDefTime		; Wait until drive ready
.ReturnWithErrorCodeInAH:
	ret
