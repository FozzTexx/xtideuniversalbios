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

	; Point DS:DI to Destination buffer
	mov		di, [bp+IDEPACK.intpack+INTPACK.si]
	mov		ds, [bp+IDEPACK.intpack+INTPACK.ds]
	mov		ax, MINIMUM_EDRIVEINFO_SIZE
	cmp		[di+EDRIVE_INFO.wSize], ax
	jb		SHORT AH42h_ReturnWithInvalidFunctionError
	je		SHORT .SkipEddConfigurationParameters

	; We do not support EDD Configuration Parameters so set to FFFF:FFFFh
	mov		ax, -1		; AX = FFFFh
	mov		[di+EDRIVE_INFO.fpEDDparams], ax
	mov		[di+EDRIVE_INFO.fpEDDparams+2], ax
	mov		ax, EDRIVE_INFO_size

	; Fill Extended Drive Information Table in DS:DI
.SkipEddConfigurationParameters:
	mov		[di+EDRIVE_INFO.wSize], ax
	mov		WORD [di+EDRIVE_INFO.wFlags], FLG_DMA_BOUNDARY_ERRORS_HANDLED_BY_BIOS | FLG_CHS_INFORMATION_IS_VALID

	call	AtaID_GetPCHStoAXBLBHfromAtaInfoInESSI
	xor		cx, cx
	mov		[di+EDRIVE_INFO.dwCylinders], ax
	mov		[di+EDRIVE_INFO.dwCylinders+2], cx
	eMOVZX	ax, bl
	mov		[di+EDRIVE_INFO.dwHeads], ax
	mov		[di+EDRIVE_INFO.dwHeads+2], cx
	mov		al, bh
	mov		[di+EDRIVE_INFO.dwSectorsPerTrack], ax
	mov		[di+EDRIVE_INFO.dwSectorsPerTrack+2], cx

	call	AtaID_GetTotalSectorCountToBXDXAXfromAtaInfoInESSI
	mov		[di+EDRIVE_INFO.qwTotalSectors], ax
	mov		[di+EDRIVE_INFO.qwTotalSectors+2], dx
	mov		[di+EDRIVE_INFO.qwTotalSectors+4], bx
	mov		[di+EDRIVE_INFO.qwTotalSectors+6], cx

	mov		WORD [di+EDRIVE_INFO.wSectorSize], 512

	; Return with success
	xor		ah, ah
.ReturnWithError:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
