; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for generating and accessing drive
;					information to be displayed on boot menu.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Creates new BOOTNFO struct for detected hard disk.
;
; BootInfo_CreateForHardDisk
;	Parameters:
;		DL:		Drive number
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		ES:BX:	Ptr to BOOTNFO (if successful)
;		CF:		Cleared if BOOTNFO created succesfully
;				Set if any error
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
BootInfo_CreateForHardDisk:
	call	BootInfo_GetOffsetToBX		; ES:BX now points to new BOOTNFO
	; Fall to .StoreSectorCount

;--------------------------------------------------------------------
; .StoreSectorCount
;	Parameters:
;		ES:BX:	Ptr to BOOTNFO
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
.StoreSectorCount:
	push	bx
	call	AtaID_GetTotalSectorCountToBXDXAXfromAtaInfoInESSI
	mov		cx, bx							; Now in CX:DX:AX
	pop		bx
	mov		[es:bx+BOOTNFO.twSectCnt], ax
	mov		[es:bx+BOOTNFO.twSectCnt+2], dx
	mov		[es:bx+BOOTNFO.twSectCnt+4], cx
	; Fall to .StoreDriveName

;--------------------------------------------------------------------
; .StoreDriveName
;	Parameters:
;		ES:BX:	Ptr to BOOTNFO
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		CF:		Cleared if variables stored succesfully
;				Set if any error
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
.StoreDriveName:
	push	ds
	push	si
	push	di

	push	es
	pop		ds
	add		si, BYTE ATA1.strModel		; DS:SI now points drive name
	lea		di, [bx+BOOTNFO.szDrvName]	; ES:DI now points to name destination
	mov		cx, LEN_BOOTNFO_DRV / 2		; Max number of WORDs allowed
.CopyNextWord:
	lodsw
	xchg	al, ah						; Change endianness
	stosw
	loop	.CopyNextWord
	xor		ax, ax						; Zero AX and clear CF
	stosb								; Terminate with NULL

	pop		di
	pop		si
	pop		ds
	ret


;--------------------------------------------------------------------
; Finds BOOTNFO for drive and returns total sector count.
;
; BootInfo_GetTotalSectorCount
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootInfo_GetTotalSectorCount:
	push	ds
	call	BootInfo_GetOffsetToBX
	LOAD_BDA_SEGMENT_TO	ds, ax
	mov		ax, [bx+BOOTNFO.twSectCnt]
	mov		dx, [bx+BOOTNFO.twSectCnt+2]
	mov		bx, [bx+BOOTNFO.twSectCnt+4]
	pop		ds
	ret


;--------------------------------------------------------------------
; Returns offset to BOOTNFO for wanted drive.
;
; BootInfo_GetOffsetToBX
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		BX:		Offset to BOOTNFO struct
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootInfo_GetOffsetToBX:
	mov		bl, dl						; Copy drive number to BL
	mov		al, BOOTNFO_size			; Size of struct
	sub		bl, [RAMVARS.bFirstDrv]		; Drive number to index
	mul		bl							; AX = Offset inside BOOTNFO array
	add		ax, BOOTVARS.rgBootNfo		; Add offset to BOOTNFO array
	xchg	bx, ax						; Copy result to BX
	ret
