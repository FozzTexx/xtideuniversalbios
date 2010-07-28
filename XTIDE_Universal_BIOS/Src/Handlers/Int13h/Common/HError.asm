; File name		:	HError.asm
; Project name	:	IDE BIOS
; Created date	:	30.11.2007
; Last update	:	28.7.2010
; Author		:	Tomi Tilli
; Description	:	Error checking functions for BIOS Hard disk functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; HError_GetErrorCodeToAHforBitPollingTimeout
;	Parameters:
;		AL:		IDE Status Register contents
;		DX:		IDE Status Register Address
;	Returns:
;		AH:		Hard disk BIOS error code
;		CF:		Set since error
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HError_GetErrorCodeToAHforBitPollingTimeout:
	test	al, FLG_IDE_ST_BSY						; Other bits undefined when BSY set
	jnz		SHORT HError_GetErrorCodeForStatusReg	; Busy, normal timeout
	test	al, FLG_IDE_ST_DF | FLG_IDE_ST_CORR | FLG_IDE_ST_ERR
	jnz		SHORT HError_GetErrorCodeForStatusReg	; Not busy but some error
	or		al, FLG_IDE_ST_BSY						; Polled bit got never set, force timeout
	; Fall to HError_GetErrorCodeForStatusReg

;--------------------------------------------------------------------
; Converts Status Register error to BIOS error code.
;
; HError_GetErrorCodeForStatusReg
;	Parameters:
;		AL:		IDE Status Register contents
;		DX:		IDE Status Register Address
;	Returns:
;		AH:		Hard disk BIOS error code
;		CF:		0 if no errors (AH=RET_HD_SUCCESS)
;				1 if some error
;	Corrupts registers:
;		AL, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HError_GetErrorCodeForStatusReg:
	; Get Error Register contents to AH
	mov		ah, al								; Backup Status Reg to AH
	sub		dx, BYTE REGR_IDE_ST-REGR_IDE_ERROR	; Status Reg to Error Reg
	in		al, dx								; Read Error Register to AL
	xchg	al, ah								; Swap status and error
	add		dx, BYTE REGR_IDE_ST-REGR_IDE_ERROR	; Restore DX

	; Store Register contents to BDA
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, cx
	mov		[HDBDA.wHDStAndErr], ax			; Store Status and Error to BDA
	pop		ds
	; Fall to HError_ConvertIdeErrorToBiosRet

;--------------------------------------------------------------------
; Converts error flags from IDE status and error register contents
; to BIOS Int 13h return value.
;
; HError_ConvertIdeErrorToBiosRet
;	Parameters:
;		AL:		Status Register Contents
;		AH:		Error Register Contents
;	Returns:
;		AH:		Hard disk BIOS error code
;		CF:		0 if no errors (AH=RET_HD_SUCCESS)
;				1 if any error
;	Corrupts registers:
;		AL
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
HError_ConvertIdeErrorToBiosRet:
	test	al, FLG_IDE_ST_BSY
	jnz		SHORT .TimeoutError
	test	al, FLG_IDE_ST_DF | FLG_IDE_ST_CORR | FLG_IDE_ST_ERR
	jnz		SHORT .ReadErrorFromStatusReg
	xor		ah, ah					; No errors, zero AH and CF
	ret

.TimeoutError:
	mov		ah, RET_HD_TIMEOUT
	stc
	ret

; Convert error code based on status or error register
.ReadErrorFromStatusReg:
	test	al, FLG_IDE_ST_ERR		; Error specified in Error register?
	jnz		SHORT .ReadErrorFromErrorReg
	mov		ah, RET_HD_ECC			; Assume ECC corrected error
	test	al, FLG_IDE_ST_CORR		; ECC corrected error?
	jnz		SHORT .Return
	mov		ah, RET_HD_CONTROLLER	; Must be Device Fault
	jmp		SHORT .Return

; Convert error register to bios error code
.ReadErrorFromErrorReg:
	push	bx
	mov		al, ah					; Copy error reg to AL...
	xor		ah, ah					; ...and zero extend to AX
	eBSF	bx, ax					; Get bit index to BX
	mov		ah, RET_HD_STATUSERR	; Error code if Error Reg is zero
	jz		SHORT .SkipLookup		; Return if error register is zero
	mov		ah, [cs:bx+.rgbRetCodeLookup]
.SkipLookup:
	pop		bx
.Return:
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
