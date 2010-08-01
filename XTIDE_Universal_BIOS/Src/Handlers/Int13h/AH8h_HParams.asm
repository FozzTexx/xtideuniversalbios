; File name		:	AH8h_HParams.asm
; Project name	:	IDE BIOS
; Created date	:	27.9.2007
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=8h, Read Disk Drive Parameters.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=8h, Read Disk Drive Parameters.
;
; AH8h_HandlerForReadDiskDriveParameters
;	Parameters:
;		AH:		Bios function 8h
;		DL:		Drive number
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		CH:		Maximum cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9...8
;				Bits 5...0:	Maximum sector number (1...63)
;		DH:		Maximum head number (0...255)
;		DL:		Number of drives
;		AH:		Int 13h/40h floppy return status
;		CF:		0 if successfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH8h_HandlerForReadDiskDriveParameters:
	push	bx
	call	AH8h_GetDriveParameters
	pop		bx
	jmp		Int13h_ReturnWithoutSwappingDrives


;--------------------------------------------------------------------
; Returns L-CHS parameters for drive and total hard disk count.
;
; AH8h_GetDriveParameters
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		CH:		Maximum cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9...8
;				Bits 5...0:	Maximum sector number (1...63)
;		DH:		Maximum head number (0...255)
;		DL:		Number of drives
;		DS:DI:	Ptr to DPT
;		AH:		Int 13h/40h floppy return status
;		CF:		0 if successfull, 1 if error
;	Corrupts registers:
;		AL, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH8h_GetDriveParameters:
	call	FindDPT_ForDriveNumber
	call	AccessDPT_GetLCHSfromPCHS	; AX=sectors, BX=cylinders, DX=heads
	call	AH8h_ReserveCylinders
	call	AH8h_PackReturnValues
	xor		ax, ax						; Clear AH and CF
	ret


;--------------------------------------------------------------------
; Reserves diagnostic cylinder if so configured.
;
; AH8h_ReserveCylinders
;	Parameters:
;		BX:		Total number of L-CHS cylinders available
;		DS:DI:	Ptr to DPT
;	Returns:
;		BX:		Number of L-CHS cylinders available after reserving
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH8h_ReserveCylinders:
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_MAXSIZE
	jnz		SHORT .Return
	dec		bx							; Reserve diagnostic cylinder
ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; Packs L-CHS values to INT 13h, AH=08h return values.
;
; AH8h_PackReturnValues
;	Parameters:
;		AX:		Number of L-CHS sectors per track (1...63)
;		BX:		Number of L-CHS cylinders available (1...1024)
;		DX:		Number of L-CHS heads (1...256)
;	Returns:
;		CH:		Maximum cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9...8
;				Bits 5...0:	Maximum sector number (1...63)
;		DH:		Maximum head number (0...255)
;		DL:		Number of drives
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH8h_PackReturnValues:
	dec		bx						; Cylinder count to last cylinder
	dec		dx						; Head count to max head number
	mov		dh, dl					; Max head number to DH
	push	ax
	call	RamVars_GetDriveCounts	; Hard disk count to CX
	pop		ax
	mov		dl, cl					; Hard disk count to DL
	mov		ch, bl					; Cylinder bits 7...0 to CH
	mov		cl, bh					; Cylinder bits 9...8 to CL
	eROR_IM	cl, 2					; Cylinder bits 9...8 to CL bits 7...6
	or		cl, al					; Sectors per track to CL bits 5...0
	ret
