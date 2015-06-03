; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device wait functions.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeWait_IRQorDRQ
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK, PIOVARS or MEMPIOVARS
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
IdeWait_IRQorDRQ:
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)

%ifdef MODULE_IRQ
	test	BYTE [bp+IDEPACK.bDeviceControl], FLG_DEVCONTROL_nIEN
	jnz		SHORT IdeWait_PollStatusFlagInBLwithTimeoutInBH	; Interrupt disabled
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
IdeWait_IRQorStatusFlagInBLwithTimeoutInBH:
%ifdef MODULE_IRQ
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
IdeWait_PollStatusFlagInBLwithTimeoutInBH:
	mov		ah, bl
	mov		cl, bh
	call	Timer_InitializeTimeoutWithTicksInCL
	call	IdeIO_InputStatusRegisterToAL		; Discard contents of first read
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
.PollLoop:
	call	IdeIO_InputStatusRegisterToAL
	test	al, al								; Controller busy? (Check for FLG_STATUS_BSY)
	js		SHORT .UpdateTimeout				;  If so, jump to timeout update
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
.PollLoop:
	call	IdeIO_InputStatusRegisterToAL
	test	al, al								; Controller busy? (Check for FLG_STATUS_BSY)
	jns		SHORT IdeError_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL
	call	Timer_SetCFifTimeout				; Update timeout counter
	jnc		SHORT .PollLoop						; Loop if time left (sets CF on timeout)
.End:											; Label used for sanity check during assembly
	; Fall to IdeError_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL

