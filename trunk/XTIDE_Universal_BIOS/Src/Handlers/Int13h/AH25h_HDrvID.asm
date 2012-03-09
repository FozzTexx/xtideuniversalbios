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
	mov		ah, COMMAND_IDENTIFY_DEVICE
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	jmp		Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
%else
	call	Idepack_TranslateOldInt13hAddressAndIssueCommandFromAH
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif
