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
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH25h_HandlerForGetDriveInformation:
	push	bp

	mov		si, [bp+IDEPACK.intpack+INTPACK.bx]
	call	AccessDPT_GetDriveSelectByteToAL
	mov		bh, al
	eMOVZX	ax, BYTE [di+DPT.bIdevarsOffset]
	xchg	bp, ax
	call	Device_IdentifyToBufferInESSIwithDriveSelectByteInBH

	pop		bp
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
