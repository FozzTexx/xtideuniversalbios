; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=8h, Read Disk Drive Parameters.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=8h, Read Disk Drive Parameters.
;
; AH8h_HandlerForReadDiskDriveParameters
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns with INTPACK:
;		CH:		Maximum cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9...8
;				Bits 5...0:	Maximum sector number (1...63)
;		DH:		Maximum head number (0...255)
;		DL:		Number of drives
;		AH:		Int 13h/40h floppy return status
;		CF:		0 if successfull, 1 if error
;--------------------------------------------------------------------
AH8h_HandlerForReadDiskDriveParameters:
	call	RamVars_IsDriveHandledByThisBIOS
	jnc		SHORT .GetDriveParametersForForeignHardDiskInDL
	call	AH8h_GetDriveParameters
	jmp		SHORT .ReturnAfterStoringValuesToIntpack

.GetDriveParametersForForeignHardDiskInDL:
	call	Int13h_CallPreviousInt13hHandler
	jc		SHORT .ReturnErrorFromPreviousInt13hHandler
	call	RamVars_GetCountOfKnownDrivesToDL
.ReturnAfterStoringValuesToIntpack:
	mov		[bp+IDEPACK.intpack+INTPACK.cx], cx
	mov		[bp+IDEPACK.intpack+INTPACK.dx], dx
	xor		ah, ah
.ReturnErrorFromPreviousInt13hHandler:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH


;--------------------------------------------------------------------
; Returns L-CHS parameters for drive and total hard disk count.
;
; AH8h_GetDriveParameters
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		CH:		Maximum cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9...8
;				Bits 5...0:	Maximum sector number (1...63)
;		DH:		Maximum head number (0...255)
;		DL:		Number of drives
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
AH8h_GetDriveParameters:
	call	AccessDPT_GetLCHStoAXBLBH
	; Fall to .PackReturnValues

;--------------------------------------------------------------------
; Packs L-CHS values to INT 13h, AH=08h return values.
;
; .PackReturnValues
;	Parameters:
;		AX:		Number of L-CHS cylinders available (1...1024)
;		BL:		Number of L-CHS heads (1...256)
;		BH:		Number of L-CHS sectors per track (1...63)
;		DS:		RAMVARS segment
;	Returns:
;		CH:		Maximum cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9...8
;				Bits 5...0:	Maximum sector number (1...63)
;		DH:		Maximum head number (0...255)
;		DL:		Number of drives
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
.PackReturnValues:
	dec		ax						; AX = Number of last cylinder
	dec		bx						; BL = Number of last head
	xchg	cx, ax
	xchg	cl, ch					; CH = Last cylinder bits 0...7
	eROR_IM	cl, 2					; CL bits 6...7 = Last cylinder bits 8...9
	or		cl, bh					; CL bits 0...5 = Sectors per track
	mov		dh, bl					; DH = Maximum head number
	jmp		RamVars_GetCountOfKnownDrivesToDL
