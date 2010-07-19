; File name		:	BootInfo.asm
; Project name	:	IDE BIOS
; Created date	:	16.3.2010
; Last update	:	9.4.2010
; Author		:	Tomi Tilli
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
ALIGN JUMP_ALIGN
BootInfo_CreateForHardDisk:
	call	BootInfo_GetOffsetToBX		; ES:BX now points to new BOOTNFO
	call	BootInfo_StoreSectorCount
	jmp		SHORT BootInfo_StoreDriveName


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
	mov		bx, ax						; Copy offset to BX
	add		bx, BOOTVARS.rgBootNfo		; Add offset to BOOTNFO array
	ret


;--------------------------------------------------------------------
; Stores total sector count to BOOTNFO.
;
; BootInfo_StoreSectorCount
;	Parameters:
;		ES:BX:	Ptr to BOOTNFO
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;		DS:DI:	Ptr to Disk Parameter Table
;	Returns:
;		CF:		Cleared if variables stored succesfully
;				Set if any error
;	Corrupts registers:
;		AX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootInfo_StoreSectorCount:
	push	bx
	call	AtaID_GetTotalSectorCount		; Get to BX:DX:AX
	mov		cx, bx							; Now in CX:DX:AX
	pop		bx
	mov		[es:bx+BOOTNFO.twSectCnt], ax
	mov		[es:bx+BOOTNFO.twSectCnt+2], dx
	mov		[es:bx+BOOTNFO.twSectCnt+4], cx
	clc
	ret


;--------------------------------------------------------------------
; Stores drive name to BOOTNFO.
;
; BootInfo_StoreDriveName
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
ALIGN JUMP_ALIGN
BootInfo_StoreDriveName:
	push	ds
	push	si
	push	di

	; DS:SI to ATA source string
	push	es
	pop		ds
	add		si, BYTE ATA1.strModel

	; ES:DI to BOOTNFO destination string
	lea		di, [bx+BOOTNFO.szDrvName]

	; Read string
	mov		cx, LEN_BOOTNFO_DRV>>1
	call	BootInfo_StoreAtaString
	pop		di
	pop		si
	pop		ds
	clc
	ret

;--------------------------------------------------------------------
; Stores ATA string.
; Byte ordering will be corrected and string will be STOP terminated.
;
; BootInfo_StoreAtaString
;	Parameters:
;		CX:		Maximum number of WORDs to copy (without STOP)
;		DS:SI:	Ptr to ATA string
;		ES:DI:	Ptr to destination string
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootInfo_StoreAtaString:
	lodsw							; Load WORD from DS:SI to AX
	xchg	al, ah					; Change byte order
	call	BootInfo_StoreAtaChar
	jc		SHORT .Return			; Return if invalid character
	mov		al, ah					; Write next char
	call	BootInfo_StoreAtaChar
	jc		SHORT .Return			; Return if invalid character
	loop	BootInfo_StoreAtaString	; Loop while words left
.Return:
	mov		al, STOP				; End string with STOP
	stosb
	ret

;--------------------------------------------------------------------
; Stores ATA character.
;
; BootInfo_StoreAtaChar
;	Parameters:
;		AL:		Character to store
;		ES:DI:	Ptr to destination character
;	Returns:
;		DI:		Incremented to next character
;		CF:		Set if non writable ASCII character
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootInfo_StoreAtaChar:
	cmp		al, 20h					; First allowed ASCII char?
	jb		SHORT .SkipStoring		;  If below, end string
	cmp		al, 7Eh					; Last allowed ASCII char?
	ja		SHORT .SkipStoring		;  If above, end string
	stosb							; Store character
	clc								; Clear CF to continue with next char
	ret
.SkipStoring:
	stc
	ret


;--------------------------------------------------------------------
; Finds BOOTNFO for drive and return total sector count.
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
