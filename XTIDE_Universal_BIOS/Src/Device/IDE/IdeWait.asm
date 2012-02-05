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
IDEDEVICE%+Wait_IRQorDRQ:
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
%ifdef ASSEMBLE_SHARED_IDE_DEVICE_FUNCTIONS		; JR-IDE/ISA does not support IRQ
	test	BYTE [bp+IDEPACK.bDeviceControl], FLG_DEVCONTROL_nIEN
	jnz		SHORT IDEDEVICE%+Wait_PollStatusFlagInBLwithTimeoutInBH	; Interrupt disabled
%endif
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
IDEDEVICE%+Wait_IRQorStatusFlagInBLwithTimeoutInBH:
%ifdef ASSEMBLE_SHARED_IDE_DEVICE_FUNCTIONS		; JR-IDE/ISA does not support IRQ
	call	IdeIrq_WaitForIRQ
%endif
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
IDEDEVICE%+Wait_PollStatusFlagInBLwithTimeoutInBH:
	mov		ah, bl
	mov		cl, bh
	call	Timer_InitializeTimeoutWithTicksInCL
	and		ah, ~FLG_STATUS_BSY
	jz		SHORT IDEDEVICE%+PollBsyOnly
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
%ifdef ASSEMBLE_SHARED_IDE_DEVICE_FUNCTIONS
PollBsyAndFlgInAH:
	call	IDEDEVICE%+ReadIdeStatusRegisterToAL; Discard contents for first read
ALIGN JUMP_ALIGN
.PollLoop:
	call	IDEDEVICE%+ReadIdeStatusRegisterToAL
	test	al, FLG_STATUS_BSY					; Controller busy?
	jnz		SHORT .UpdateTimeout				;  If so, jump to timeout update
	test	al, ah								; Test secondary flag
	jnz		SHORT IDEDEVICE%+Error_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL
.UpdateTimeout:
	call	Timer_SetCFifTimeout
	jnc		SHORT .PollLoop						; Loop if time left
	call	IDEDEVICE%+Error_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL
	jc		SHORT .ReturnErrorCodeInAH
	mov		ah, RET_HD_TIMEOUT					; Expected bit never got set
	stc
.ReturnErrorCodeInAH:
	ret
%endif


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
IDEDEVICE%+PollBsyOnly:
	call	IDEDEVICE%+ReadIdeStatusRegisterToAL; Discard contents for first read
ALIGN JUMP_ALIGN
.PollLoop:
	call	IDEDEVICE%+ReadIdeStatusRegisterToAL
	test	al, FLG_STATUS_BSY					; Controller busy?
	jz		SHORT IDEDEVICE%+Error_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL
	call	Timer_SetCFifTimeout				; Update timeout counter
	jnc		SHORT .PollLoop						; Loop if time left (sets CF on timeout)
	jmp		SHORT IDEDEVICE%+Error_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL


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
IDEDEVICE%+ReadIdeStatusRegisterToAL:
	JUMP_TO_INPUT_TO_AL_FROM_IDE_REGISTER STATUS_REGISTER_in
