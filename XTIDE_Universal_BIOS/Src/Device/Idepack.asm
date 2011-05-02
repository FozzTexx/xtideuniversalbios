; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for managing IDEPACK struct.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Idepack_FakeToSSBP
;	Parameters:
;		Nothing
;	Returns:
;		SS:BP:	Ptr to IDEPACK
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
Idepack_FakeToSSBP:
	pop		ax
	sub		sp, BYTE EXTRA_BYTES_FOR_INTPACK
	mov		bp, sp
	jmp		ax


;--------------------------------------------------------------------
; Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
;	Parameters:
;		AH:		IDE command to issue
;		AL:		Number of sectors to transfer (1...255, 0=256)
;		BH:		Timeout ticks
;		BL:		IDE Status Register flag to wait after command
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		ES:SI:	Ptr to data buffer
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH:
	mov		[bp+IDEPACK.bSectorCount], al
	mov		[bp+IDEPACK.bCommand], ah
	mov		BYTE [bp+IDEPACK.bSectorCountHighExt], 0

	push	bx
	call	Address_OldInt13hAddressToIdeAddress
	call	AccessDPT_GetDriveSelectByteToAL
	or		al, bh			; AL now has Drive and Head Select Byte
	mov		[bp+IDEPACK.bDrvAndHead], al
	mov		[bp+IDEPACK.bLbaLow], bl
	mov		[bp+IDEPACK.wLbaMiddleAndHigh], cx
	pop		bx

	call	AccessDPT_GetDeviceControlByteToAL
	mov		[bp+IDEPACK.bDeviceControl], al
	jmp		Device_OutputCommandWithParameters


;--------------------------------------------------------------------
; Idepack_StoreNonExtParametersAndIssueCommandFromAL
;	Parameters:
;		BH:		Timeout ticks
;		BL:		IDE Status Register flag to wait after command
;		AL:		IDE command to issue
;		AH:		Parameter to Drive and Head Select Register (Head bits only)
;		DL:		Parameter to Sector Count Register
;		DH:		Parameter to LBA Low / Sector Number Register
;		CL:		Parameter to LBA Middle / Cylinder Low Register
;		CH:		Parameter to LBA High / Cylinder High Register
;		SI:		Parameter to Features Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Idepack_StoreNonExtParametersAndIssueCommandFromAL:
	mov		[bp+IDEPACK.bFeatures], si
	mov		[bp+IDEPACK.bCommand], al
	mov		[bp+IDEPACK.wSectorCountAndLbaLow], dx
	mov		[bp+IDEPACK.wLbaMiddleAndHigh], cx
	mov		BYTE [bp+IDEPACK.bSectorCountHighExt], 0

	; Drive and Head select byte
	and		ah, MASK_DRVNHEAD_HEAD		; Keep head bits only
	call	AccessDPT_GetDriveSelectByteToAL
	or		al, ah
	mov		[bp+IDEPACK.bDrvAndHead], al

	; Device Control byte with interrupts disabled
	call	AccessDPT_GetDeviceControlByteToAL
	or		al, FLG_DEVCONTROL_nIEN		; Disable interrupt
	mov		[bp+IDEPACK.bDeviceControl], al

	jmp		Device_OutputCommandWithParameters
