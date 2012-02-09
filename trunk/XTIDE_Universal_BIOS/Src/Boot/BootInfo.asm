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
;	Corrupts registers:
;		AX, BX, CX, DX, DI, SI
;--------------------------------------------------------------------
BootInfo_CreateForHardDisk:
	call	BootInfo_ConvertDPTtoBX		; ES:BX now points to new BOOTNFO
	push	bx							; Preserve for return

	mov		di, bx						; Starting pointer at beginning of structure

;
; Store Drive Name
;		
	push	ds							; Preserve RAMVARS
	push	si							; Preserve SI for call to GetTotalSectorCount...

	push	es							; ES copied to DS
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
	stosw								; Terminate with NULL

	pop		si
	pop		ds

;
; Store Sector Count
;
	call	AtaID_GetTotalSectorCountToBXDXAXfromAtaInfoInESSI

	stosw
	xchg	ax, dx
	stosw
	xchg	ax, bx
	stosw

	pop		bx
		
	ret

		
;--------------------------------------------------------------------
; Finds BOOTNFO for drive and returns total sector count.
;
; BootInfo_GetTotalSectorCount
;	Parameters:
;		DS:DI:		DPT Pointer
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootInfo_GetTotalSectorCount:
	push	ds
	call	BootInfo_ConvertDPTtoBX
	LOAD_BDA_SEGMENT_TO	ds, ax
	mov		ax, [bx+BOOTNFO.twSectCnt]
	mov		dx, [bx+BOOTNFO.twSectCnt+2]
	mov		bx, [bx+BOOTNFO.twSectCnt+4]
	pop		ds
	ret


;--------------------------------------------------------------------
; Returns offset to BOOTNFO based on DPT pointer.
;
; BootInfo_ConvertDPTtoBX
;	Parameters:
;		DS:DI:	DPT Pointer
;	Returns:
;		BX:		Offset to BOOTNFO struct
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootInfo_ConvertDPTtoBX:
	mov		ax, di
	sub		ax, RAMVARS_size				; subtract off base of DPTs
	mov		bl, DPT_BOOTNFO_SIZE_MULTIPLIER	; BOOTNFO's are a whole number multiple of DPT size
	mul		bl								
	add		ax, BOOTVARS.rgBootNfo			; add base of BOOTNFO
	xchg	ax, bx
	ret			
