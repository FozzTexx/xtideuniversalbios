; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device error functions.

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
; IdeError_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL
;	Parameters:
;		AL:		IDE Status Register contents
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AH:		BIOS error code
;		CF:		Set if error
;				Cleared if no error
;	Corrupts registers:
;		AL, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeError_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL:
	mov		ah, al			; IDE Status Register to AH
	INPUT_TO_AL_FROM_IDE_REGISTER	ERROR_REGISTER_in
	xchg	al, ah			; Status Register now in AL, Error Register now in AH
	; Fall to GetBiosErrorCodeToAHfromStatusAndErrorRegistersInAX


;--------------------------------------------------------------------
; GetBiosErrorCodeToAHfromStatusAndErrorRegistersInAX
;	Parameters:
;		AL:		IDE Status Register contents
;		AH:		IDE Error Register contents
;	Returns:
;		AH:		BIOS INT 13h error code
;		CF:		Set if error
;				Cleared if no error
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetBiosErrorCodeToAHfromStatusAndErrorRegistersInAX:
	test	al, FLG_STATUS_BSY | FLG_STATUS_DF | FLG_STATUS_CORR | FLG_STATUS_ERR	; Clears CF
	jnz		SHORT .CheckErrorBitsFromStatusRegisterInAL
	; The MSB of AL (FLG_STATUS_BSY) is cleared at this point.
	cbw								; No errors, zero AH (CF already cleared)
	ret

ALIGN JUMP_ALIGN
.CheckErrorBitsFromStatusRegisterInAL:
	js		SHORT .Flg_Status_Bsy	; Jump if FLG_STATUS_BSY
	test	al, FLG_STATUS_ERR		; Error specified in Error register?
	jnz		SHORT .ConvertBiosErrorToAHfromErrorRegisterInAH
	mov		ah, RET_HD_ECC			; Assume ECC corrected error
	test	al, FLG_STATUS_CORR		; ECC corrected error?
	jnz		SHORT .ReturnBiosErrorCodeInAH
	mov		ah, RET_HD_CONTROLLER	; Must be Device Fault
	SKIP2B	bx
.Flg_Status_Bsy:
	mov		ah, RET_HD_TIMEOUT
.ReturnBiosErrorCodeInAH:
	stc
	ret

.ConvertBiosErrorToAHfromErrorRegisterInAH:
	stc								; Needed in case Error register (AH) is zero
	mov		bx, .rgbRetCodeLookup-1
.ErrorBitLoop:
	inc		bx
	rcr		ah, 1
	jnc		SHORT .ErrorBitLoop		; CF will be set eventually
	mov		ah, [cs:bx]
	ret


.rgbRetCodeLookup:
	db	RET_HD_ADDRMARK		; Bit0=AMNF, Address Mark Not Found
	db	RET_HD_SEEK_FAIL	; Bit1=TK0NF, Track 0 Not Found
	db	RET_HD_INVALID		; Bit2=ABRT, Aborted Command
	db	RET_HD_NOTLOCKED	; Bit3=MCR, Media Change Requested
	db	RET_HD_NOT_FOUND	; Bit4=IDNF, ID Not Found
	db	RET_HD_LOCKED		; Bit5=MC, Media Changed
	db	RET_HD_UNCORRECC	; Bit6=UNC, Uncorrectable Data Error
	db	RET_HD_BADSECTOR	; Bit7=BBK, Bad Block Detected
	db	RET_HD_STATUSERR	; When Error Register is zero
