; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=44h, Extended Verify Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=44h, Extended Verify Sectors.
;
; AH44h_HandlerForExtendedVerifySectors
;	Parameters:
;		SI:		Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		DS:SI:	Ptr to Disk Address Packet
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;	Return with Disk Address Packet in INTPACK:
;		.bSectorCount	Number of sectors verified successfully
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH44h_HandlerForExtendedVerifySectors:
	call	AH42h_LoadDapToESSIandVerifyForTransfer
	call	CommandLookup_GetEbiosIndexToBX
	mov		ah, [cs:bx+g_rgbVerifyCommandLookup]
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRDY)
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	jmp		Idepack_ConvertDapToIdepackAndIssueCommandFromAH
%else
	call	Idepack_ConvertDapToIdepackAndIssueCommandFromAH
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif
