; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=25h, Get Drive Information.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=25h, Get Drive Information.
;
; AH25h_HandlerForGetDriveInformation
;	Parameters:
;		ES:		Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		ES:BX:	Ptr to buffer to receive 512-byte drive information
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH25h_HandlerForGetDriveInformation:
	mov		al, 1			; Read 1 sector
	call	Prepare_BufferToESSIforOldInt13hTransfer
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall to AH25h_GetDriveInformationToBufferInESSI
%else
	call	AH25h_GetDriveInformationToBufferInESSI
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif


;--------------------------------------------------------------------
; AH25h_GetDriveInformationToBufferInESSI
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		ES:SI:	Ptr to buffer to receive 512-byte drive information
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
AH25h_GetDriveInformationToBufferInESSI:
	push	es
	push	bp
	push	di
	push	si

	call	AccessDPT_GetDriveSelectByteToAL
	mov		bh, al
	eMOVZX	ax, [di+DPT.bIdevarsOffset]
	xchg	bp, ax
	call	Device_IdentifyToBufferInESSIwithDriveSelectByteInBH

	pop		si
	pop		di
	pop		bp
	pop		es
	ret
