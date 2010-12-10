; File name		:	HError.asm
; Project name	:	IDE BIOS
; Created date	:	30.11.2007
; Last update	:	24.8.2010
; Author		:	Tomi Tilli
; Description	:	Error checking functions for BIOS Hard disk functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; HError_ProcessTimeoutAfterPollingBSYandSomeOtherStatusBit
; HError_ProcessErrorsAfterPollingBSY
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		BIOS error code
;		CF:		Set if error
;				Cleared if no error
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HError_ProcessTimeoutAfterPollingBSYandSomeOtherStatusBit:
	call	HError_GetStatusAndErrorRegistersToAXandStoreThemToBDA
	call	GetBiosErrorCodeToAHfromStatusAndErrorRegistersInAX
	jc		SHORT .ReturnErrorCodeInAH
	mov		ah, RET_HD_TIMEOUT			; Force timeout since no actual error...
	stc									; ...but wanted bit was never set
.ReturnErrorCodeInAH:
	ret


ALIGN JUMP_ALIGN
HError_ProcessErrorsAfterPollingBSY:
	call	HError_GetStatusAndErrorRegistersToAXandStoreThemToBDA
	jmp		SHORT GetBiosErrorCodeToAHfromStatusAndErrorRegistersInAX


;--------------------------------------------------------------------
; HError_GetStatusAndErrorRegistersToAXandStoreThemToBDA
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AL:		IDE Status Register contents
;		AH:		IDE Error Register contents
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HError_GetStatusAndErrorRegistersToAXandStoreThemToBDA:
	push	ds
	push	dx

	mov		dx, [RAMVARS.wIdeBase]		; Load IDE base port address
	inc		dx							; Increment to Error Register
	in		al, dx						; Read Error Register...
	mov		ah, al						; ...and copy it to AH
	add		dx, BYTE REGR_IDE_ST - REGR_IDE_ERROR
	in		al, dx						; Read Status Register to AL

	LOAD_BDA_SEGMENT_TO	ds, dx
	mov		[HDBDA.wHDStAndErr], ax

	pop		dx
	pop		ds
	ret


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
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetBiosErrorCodeToAHfromStatusAndErrorRegistersInAX:
	test	al, FLG_IDE_ST_BSY
	jz		SHORT .CheckErrorBitsFromStatusRegisterInAL
	mov		ah, RET_HD_TIMEOUT
	jmp		SHORT .ReturnBiosErrorCodeInAH

ALIGN JUMP_ALIGN
.CheckErrorBitsFromStatusRegisterInAL:
	test	al, FLG_IDE_ST_DF | FLG_IDE_ST_CORR | FLG_IDE_ST_ERR
	jnz		SHORT .ProcessErrorFromStatusRegisterInAL
	xor		ah, ah					; No errors, zero AH and CF
	ret

.ProcessErrorFromStatusRegisterInAL:
	test	al, FLG_IDE_ST_ERR		; Error specified in Error register?
	jnz		SHORT .ConvertBiosErrorToAHfromErrorRegisterInAH
	mov		ah, RET_HD_ECC			; Assume ECC corrected error
	test	al, FLG_IDE_ST_CORR		; ECC corrected error?
	jnz		SHORT .ReturnBiosErrorCodeInAH
	mov		ah, RET_HD_CONTROLLER	; Must be Device Fault
	jmp		SHORT .ReturnBiosErrorCodeInAH

.ConvertBiosErrorToAHfromErrorRegisterInAH:
	push	bx
	mov		bx, .rgbRetCodeLookup
.ErrorBitLoop:
	rcr		ah, 1					; Set CF if error bit set
	jc		SHORT .LookupErrorCode
	inc		bx
	cmp		bx, .rgbRetCodeLookup + 8
	jb		SHORT .ErrorBitLoop		; Loop until all bits checked
.LookupErrorCode:
	mov		ah, [cs:bx+.rgbRetCodeLookup]
	pop		bx

.ReturnBiosErrorCodeInAH:
	stc								; Set CF since error
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
