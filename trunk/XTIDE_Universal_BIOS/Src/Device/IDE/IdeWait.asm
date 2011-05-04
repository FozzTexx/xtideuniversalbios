; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device wait functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeWait_IRQorDRQ
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK or PIOVARS
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
IdeWait_IRQorDRQ:
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
	test	BYTE [bp+IDEPACK.bDeviceControl], FLG_DEVCONTROL_nIEN
	jnz		SHORT IdeWait_PollStatusFlagInBLwithTimeoutInBH	; Interrupt disabled
	; Fall to IdeWait_IRQorStatusFlagInBLwithTimeoutInBH


;--------------------------------------------------------------------
; IdeWait_IRQorStatusFlagInBLwithTimeoutInBH
;	Parameters:
;		BH:		Timeout ticks
;		BL:		IDE Status Register bit to wait
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
IdeWait_IRQorStatusFlagInBLwithTimeoutInBH:
	call	IdeIrq_WaitForIRQ
	; Always fall to IdeWait_PollStatusFlagInBLwithTimeoutInBH for error processing


;--------------------------------------------------------------------
; IdeWait_PollStatusFlagInBLwithTimeoutInBH
;	Parameters:
;		BH:		Timeout ticks
;		BL:		IDE Status Register bit to poll
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
IdeWait_PollStatusFlagInBLwithTimeoutInBH:
	mov		ah, bl
	mov		cl, bh
	call	Timer_InitializeTimeoutWithTicksInCL
	and		ah, ~FLG_STATUS_BSY
	jz		SHORT PollBsyOnly
	; Fall to PollBsyAndFlgInAH

;--------------------------------------------------------------------
; PollBsyAndFlgInAH
;	Parameters:
;		AH:		Status Register Flag to poll (until set) when device not busy
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		BIOS Error code
;		CF:		Clear if wait completed successfully (no errors)
;				Set if any error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
PollBsyAndFlgInAH:
	call	ReadIdeStatusRegisterToAL			; Discard contents for first read
ALIGN JUMP_ALIGN
.PollLoop:
	call	ReadIdeStatusRegisterToAL
	test	al, FLG_STATUS_BSY					; Controller busy?
	jnz		SHORT .UpdateTimeout				;  If so, jump to timeout update
	test	al, ah								; Test secondary flag
	jnz		SHORT IdeError_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL
.UpdateTimeout:
	call	Timer_SetCFifTimeout
	jnc		SHORT .PollLoop						; Loop if time left
	call	IdeError_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL
	jc		SHORT .ReturnErrorCodeInAH
	mov		ah, RET_HD_TIMEOUT					; Expected bit never got set
	stc
.ReturnErrorCodeInAH:
	ret


;--------------------------------------------------------------------
; PollBsyOnly
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		BIOS Error code
;		CF:		Clear if wait completed successfully (no errors)
;				Set if any error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
PollBsyOnly:
	call	ReadIdeStatusRegisterToAL			; Discard contents for first read
ALIGN JUMP_ALIGN
.PollLoop:
	call	ReadIdeStatusRegisterToAL
	test	al, FLG_STATUS_BSY					; Controller busy?
	jz		SHORT IdeError_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL
	call	Timer_SetCFifTimeout				; Update timeout counter
	jnc		SHORT .PollLoop						; Loop if time left (sets CF on timeout)
	jmp		SHORT IdeError_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL


;--------------------------------------------------------------------
; ReadIdeStatusRegisterToAL
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AL:		IDE Status Register contents
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ReadIdeStatusRegisterToAL:
	mov		dl, STATUS_REGISTER_in
	jmp		IdeIO_InputToALfromIdeRegisterInDL
