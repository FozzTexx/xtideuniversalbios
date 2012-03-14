; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Device error functions.

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
IDEDEVICE%+Error_GetBiosErrorCodeToAHfromPolledStatusRegisterInAL:
	mov		ah, al			; IDE Status Register to AH
	INPUT_TO_AL_FROM_IDE_REGISTER	ERROR_REGISTER_in

%ifndef ASSEMBLE_SHARED_IDE_DEVICE_FUNCTIONS	; JR-IDE/ISA
	jmp		ContinueFromMemIdeError
%else
ContinueFromMemIdeError:
	xchg	al, ah			; Status Register now in AL, Error Register now in AH

	; I don't think anything actually reads these from BDA
	;push	ds
	;LOAD_BDA_SEGMENT_TO	ds, dx
	;mov		[HDBDA.wHDStAndErr], ax
	;pop		ds

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
	test	al, FLG_STATUS_BSY
	jz		SHORT .CheckErrorBitsFromStatusRegisterInAL
	mov		ah, RET_HD_TIMEOUT
	jmp		SHORT .ReturnBiosErrorCodeInAH

ALIGN JUMP_ALIGN
.CheckErrorBitsFromStatusRegisterInAL:
	test	al, FLG_STATUS_DF | FLG_STATUS_CORR | FLG_STATUS_ERR
	jnz		SHORT .ProcessErrorFromStatusRegisterInAL
	xor		ah, ah					; No errors, zero AH and CF
	ret

.ProcessErrorFromStatusRegisterInAL:
	test	al, FLG_STATUS_ERR		; Error specified in Error register?
	jnz		SHORT .ConvertBiosErrorToAHfromErrorRegisterInAH
	mov		ah, RET_HD_ECC			; Assume ECC corrected error
	test	al, FLG_STATUS_CORR		; ECC corrected error?
	jnz		SHORT .ReturnBiosErrorCodeInAH
	mov		ah, RET_HD_CONTROLLER	; Must be Device Fault
	jmp		SHORT .ReturnBiosErrorCodeInAH

.ConvertBiosErrorToAHfromErrorRegisterInAH:
	xor		bx, bx					; Clear CF
.ErrorBitLoop:
	rcr		ah, 1					; Set CF if error bit set
	jc		SHORT .LookupErrorCode
	inc		bx
	test	ah, ah					; Clear CF
	jnz		SHORT .ErrorBitLoop
.LookupErrorCode:
	mov		ah, [cs:bx+.rgbRetCodeLookup]
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
%endif
