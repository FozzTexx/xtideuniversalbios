; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=48h, Get Extended Drive Parameters.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=48h, Get Extended Drive Parameters.
;
; AH48h_GetExtendedDriveParameters
;	Parameters:
;		SI:		Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		DS:SI:	Ptr to Extended Drive Information Table to fill
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		DS:SI:	Ptr to Extended Drive Information Table
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH48h_HandlerForGetExtendedDriveParameters:
	; Get ATA Drive Information and total sector count from it
	push	ds
	pop		es			; ES now points RAMVARS segment
	mov		si, [cs:ROMVARS.bStealSize]
	and		si, BYTE 7Fh
	eSHL_IM	si, 10		; Kilobytes to bytes
	sub		si, 512		; Subtract buffer size for offset in RAMVARS
	call	AH25h_GetDriveInformationToBufferInESSIfromDriveInDL
	call	AtaID_GetTotalSectorCountToBXDXAXfromAtaInfoInESSI
	xchg	cx, ax

	; Point ES:DI to Destination buffer
	mov		di, [bp+IDEPACK.intpack+INTPACK.si]
	mov		es, [bp+IDEPACK.intpack+INTPACK.ds]
	cmp		WORD [es:di+EDRIVE_INFO.wSize], MINIMUM_EDRIVEINFO_SIZE
	jb		SHORT .BufferTooSmall

	; Fill Extended Drive Information Table in ES:DI
	mov		ax, MINIMUM_EDRIVEINFO_SIZE
	stosw
	mov		al, FLG_DMA_BOUNDARY_ERRORS_HANDLED_BY_BIOS
	stosw
	add		di, BYTE 12	; Skip CHS parameters
	xchg	ax, cx
	stosw				; LBA WORD 0
	xchg	ax, dx
	stosw				; LBA WORD 1
	xchg	ax, bx
	stosw				; LBA WORD 2
	xor		ax, ax
	stosw				; LBA WORD 3 always zero since 48-bit address
	mov		ah, 512>>8
	stosw				; Always 512-byte sectors

	; Return with success
	xor		ah, ah
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH

.BufferTooSmall:
	mov		ah, RET_HD_INVALID
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
