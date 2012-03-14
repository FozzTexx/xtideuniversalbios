; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=15h, Read Disk Drive Size.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=15h, Read Disk Drive Size.
;
; AH15h_HandlerForReadDiskDriveSize
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns with INTPACK:
;		If successful:
;			AH:		Hard Disk: 3 (Hard disk accessible)
;                   Floppy:    1 (Floppy disk, without change detection)
;			CX:DX:	Total number of sectors
;			CF:		0
;		If failed:
;			AH:		0 (Drive not present)
;			CX:DX:	0
;			CF:		1
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH15h_HandlerForReadDiskDriveSize:
%ifdef MODULE_SERIAL_FLOPPY
	mov		cl, 1										; 1 = floppy disk, no change detection

	test	dl,dl										; DO NOT store the sector count if this is a
	jns		.FloppyDrive								; floppy disk, some OS's depend on this not
														; happening for floppies in order to boot.
%endif

	call	AH15h_GetSectorCountToBXDXAX
	mov		[bp+IDEPACK.intpack+INTPACK.cx], dx			; HIWORD to CX
	xchg	[bp+IDEPACK.intpack+INTPACK.dx], ax			; LOWORD to DX, AL gets drive number

	xor		ah, ah
%ifdef MODULE_SERIAL_FLOPPY
	mov		cl, 3										; 3 = Hard Disk Accessible
.FloppyDrive:

	call	Int13h_SetErrorCodeToBdaAndToIntpackInSSBPfromAH_ALHasDriveNumber	; Store success to BDA and CF
	mov		[bp+IDEPACK.intpack+INTPACK.ah], cl
%else
	call	Int13h_SetErrorCodeToBdaAndToIntpackInSSBPfromAH	; Store success to BDA and CF
	mov		BYTE [bp+IDEPACK.intpack+INTPACK.ah], 3
%endif

	jmp		Int13h_ReturnFromHandlerWithoutStoringErrorCode


;--------------------------------------------------------------------
; AH15h_GetSectorCountFromForeignDriveToDXAX:
; AH15h_GetSectorCountToBXDXAX:
;	Parameters:
;		DL:		Drive number (AH15h_GetSectorCountFromForeignDriveToDXAX only)
;		DS:		RAMVARS segment
;		DS:DI:	Ptr to DPT (AH15h_GetSectorCountToDXAX only)
;	Returns:
;		DX:AX:	Total sector count
;		BX:		Zero
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
AH15h_GetSectorCountFromForeignDriveToDXAX:
	mov		ah, GET_DRIVE_PARAMETERS
	call	Int13h_CallPreviousInt13hHandler
	jmp		SHORT ConvertAH08hReturnValuesToSectorCount

AH15h_GetSectorCountToBXDXAX:
	call	AH8h_GetDriveParameters
	; Fall to ConvertAH08hReturnValuesToSectorCount

ConvertAH08hReturnValuesToSectorCount:
	call	Address_ExtractLCHSparametersFromOldInt13hAddress
	mov		al, bh		; AL = Max head number
	inc		cx			; Max cylinder number to cylinder count
	inc		ax			; Max head number to head count (AH=8h returns max 254 so no overflow to AH)
	mul		bl			; AX = Head count * Sectors per track
	mul		cx			; DX:AX = Total sector count for AH=0xh transfer functions
	xor		bx, bx
	ret
