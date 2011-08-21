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
	; Get our buffer to ES:SI
	push	di
	call	FindDPT_ForNewDriveToDSDI
	lea		si, [di+LARGEST_DPT_SIZE]	; IdeCommand.asm required fake DPT
	pop		di
	push	ds
	pop		es

	; Get Drive ID and total sector count from it
	call	AH25h_GetDriveInformationToBufferInESSI
	jc		SHORT .ReturnWithError
	call	AtaID_GetTotalSectorCountToBXDXAXfromAtaInfoInESSI
	xchg	cx, ax		; Sector count now in BX:DX:CX

	; Point ES:DI to Destination buffer
	mov		di, [bp+IDEPACK.intpack+INTPACK.si]
	mov		es, [bp+IDEPACK.intpack+INTPACK.ds]
	mov		ax, MINIMUM_EDRIVEINFO_SIZE
	cmp		WORD [es:di+EDRIVE_INFO.wSize], ax
	jb		SHORT .BufferTooSmall
	je		SHORT .SkipEddConfigurationParameters

	; We do not support EDD Configuration Parameters so set to FFFF:FFFFh
	xor		ax, ax
	dec		ax			; AX = FFFFh
	mov		[es:di+EDRIVE_INFO.fpEDDparams], ax
	mov		[es:di+EDRIVE_INFO.fpEDDparams+2], ax
	mov		ax, EDRIVE_INFO_size

	; Fill Extended Drive Information Table in ES:DI
.SkipEddConfigurationParameters:
	stosw				; Store Extended Drive Information Table size
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
.ReturnWithError:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
