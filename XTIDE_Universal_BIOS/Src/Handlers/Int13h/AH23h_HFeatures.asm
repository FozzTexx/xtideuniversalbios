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
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		AL:		Feature Number (parameter to Features Register = subcommand)
;	(Parameter registers are undocumented, these are specific for this BIOS):
;		BL:		Parameter to Sector Count Register (subcommand specific)
;		BH:		Parameter to LBA Low / Sector Number Register (subcommand specific)
;		CL:		Parameter to LBA Middle / Cylinder Low Register (subcommand specific)
;		CH:		Parameter to LBA High / Cylinder High Register (subcommand specific)
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH23h_HandlerForSetControllerFeatures:
	xchg	si, ax		; SI = Feature Number
	mov		dx, [bp+IDEPACK.intpack+INTPACK.bx]
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
;		DL:		Parameter to Sector Count Register (subcommand specific)
;		DH:		Parameter to LBA Low / Sector Number Register (subcommand specific)
;		CL:		Parameter to LBA Middle / Cylinder Low Register (subcommand specific)
;		CH:		Parameter to LBA High / Cylinder High Register (subcommand specific)
;		SI:		Feature Number (parameter to Features Register = subcommand)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH23h_SetControllerFeatures:
	mov		al, COMMAND_SET_FEATURES
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_BSY, FLG_STATUS_BSY)
	jmp		Idepack_StoreNonExtParametersAndIssueCommandFromAL
