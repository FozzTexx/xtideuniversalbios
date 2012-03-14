; Project name	:	BIOS Drive Information Tool
; Description	:	Functions to read information from BIOS.


; Section containing code
SECTION .text

;---------------------------------------------------------------------
; Bios_GetNumberOfHardDrivesToDX
;	Parameters:
;		Nothing
;	Returns: (if no errors)
;       DX:		Number of hard drives in system
;		CF:		Set if no hard drives found
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Bios_GetNumberOfHardDrivesToDX:
	mov		dl, 80h		; First hard drive
	mov		ah, GET_DRIVE_PARAMETERS
	int		BIOS_DISK_INTERRUPT_13h
	mov		dh, 0		; Preserve CF
	ret


;---------------------------------------------------------------------
; Bios_ReadOldInt13hParametersFromDriveDL
;	Parameters:
;		DL:		BIOS drive number
;	Returns: (if no errors)
;       BL:     Drive Type (for floppies only)
;		AX:		Sectors per track (1...63)
;		DX:		Number of heads (1...255)
;		CX:		Number of cylinders (1...1024)
;		CF:		Cleared = no errors
;				Set = BIOS error code stored in AH
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Bios_ReadOldInt13hParametersFromDriveDL:
	mov		ah, GET_DRIVE_PARAMETERS
	int		BIOS_DISK_INTERRUPT_13h
	jc		SHORT ReturnWithBiosErrorCodeInAH
	; Fall to ExtractCHSfromOldInt13hDriveParameters

;---------------------------------------------------------------------
; ExtractCHSfromOldInt13hDriveParameters
;	Parameters:
;		CH:		Maximum cylinder number, bits 7...0
;		CL:		Bits 7...6: Maximum cylinder number, bits 9 and 8
;				Bits 5...0:	Maximum sector number (1...63)
;		DH:		Maximum head number (0...254)
;	Returns:
;       BL:     Drive Type (for floppies only)
;		AX:		Sectors per track (1...63)
;		DX:		Number of heads (1...255)
;		CX:		Number of cylinders (1...1024)
;		CF:		Cleared
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ExtractCHSfromOldInt13hDriveParameters:
	mov		al, cl				; Copy sector number...
	and		ax, BYTE 3Fh		; ...and limit to 1...63
	sub		cl, al				; Remove from max cylinder high
	eROL_IM	cl, 2				; High bits to beginning
	eMOVZX	dx, dh				; Copy Max head to DX
	xchg	cl, ch				; Max cylinder now in CX
	inc		cx					; Max cylinder to number of cylinders
	inc		dx					; Max head to number of heads
	clc							; No errors
	ret


;---------------------------------------------------------------------
; Bios_ReadOldInt13hCapacityFromDriveDL
;	Parameters:
;		DL:		BIOS drive number
;	Returns: (if no errors)
;       CX:DX:	Total number of sectors
;       AH:		BIOS Error code
;		CF:		Cleared = no errors
;				Set = BIOS error code stored in AH
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Bios_ReadOldInt13hCapacityFromDriveDL:
	mov		ah, GET_DISK_TYPE
	int		BIOS_DISK_INTERRUPT_13h
	jc		SHORT ReturnInvalidErrorCodeInAH
	xor		ah, ah
	ret


;---------------------------------------------------------------------
; Bios_ReadAtaInfoFromDriveDLtoBX
;	Parameters:
;		DL:		BIOS drive number
;	Returns: (if no errors)
;      	DS:BX:	Ptr to ATA information
;       AH:		BIOS Error code
;		CF:		Cleared = no errors
;				Set = BIOS error code stored in AH
;	Corrupts registers:
;		ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Bios_ReadAtaInfoFromDriveDLtoBX:
	mov		bx, g_rgbAtaInfo
	push	ds
	pop		es
	mov		ah, GET_DRIVE_INFORMATION
	int		BIOS_DISK_INTERRUPT_13h
	ret


;---------------------------------------------------------------------
; Bios_ReadEbiosVersionFromDriveDL
;	Parameters:
;		DL:		BIOS drive number
;	Returns:
;		AH:		BIOS error code
;       BX:		Version of extensions
;		CX:		Interface support bit map
;		CF:		Cleared = no errors
;				Set = BIOS error code stored in AH
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Bios_ReadEbiosVersionFromDriveDL:
	mov		ah, CHECK_EXTENSIONS_PRESENT
	mov		bx, 55AAh
	int		BIOS_DISK_INTERRUPT_13h
	jc		SHORT .NoEbiosPresent
	cmp		bx, 0AA55h
	jne		SHORT .NoEbiosPresent
	eMOVZX	bx, ah			; Copy version to BX
	xor		ah, ah
	ret
.NoEbiosPresent:
	mov		ah, RET_HD_INVALID
	stc
	ret


;---------------------------------------------------------------------
; Bios_ReadEbiosInfoFromDriveDLtoDSSI
;	Parameters:
;		DL:		BIOS drive number
;	Returns: (if no errors)
;      	DS:SI:	Ptr to EDRIVE_INFO
;       AH:		BIOS Error code
;		CF:		Cleared = no errors
;				Set = BIOS error code stored in AH
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Bios_ReadEbiosInfoFromDriveDLtoDSSI:
	mov		si, g_edriveInfo
	mov		WORD [si+EDRIVE_INFO.wSize], MINIMUM_EDRIVEINFO_SIZE
	mov		ah, GET_EXTENDED_DRIVE_INFORMATION
	int		BIOS_DISK_INTERRUPT_13h
	ret


;---------------------------------------------------------------------
; ReturnInvalidErrorCodeInAH
; ReturnWithBiosErrorCodeInAH
;	Parameters:
;		Nothing
;	Returns: (if no errors)
;       AH:		BIOS Error code
;		CF:		Set
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ReturnInvalidErrorCodeInAH:
	stc
	mov		ah, RET_HD_INVALID	
ReturnWithBiosErrorCodeInAH:
	ret


; Section containing uninitialized data
SECTION .bss

g_edriveInfo:
g_rgbAtaInfo:		resb	512
