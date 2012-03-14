; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=42h, Extended Read Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=42h, Extended Read Sectors.
;
; AH42h_HandlerForExtendedReadSectors
;	Parameters:
;		SI:		Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		DS:SI:	Ptr to Disk Address Packet
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;	Return with Disk Address Packet in INTPACK:
;		.wSectorCount	Number of sectors read successfully
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH42h_HandlerForExtendedReadSectors:
	call	Prepare_ByLoadingDapToESSIandVerifyingForTransfer
	mov		ah, [cs:bx+g_rgbReadCommandLookup]
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
	call	Idepack_ConvertDapToIdepackAndIssueCommandFromAH
	; Fall to AH42h_ReturnFromInt13hAfterStoringErrorCodeFromAHandTransferredSectorsFromCX


;--------------------------------------------------------------------
; AH42h_ReturnFromInt13hAfterStoringErrorCodeFromAHandTransferredSectorsFromCX
;	Parameters:
;		AH:		INT 13h Error Code
;		CX:		Number of successfully transferred sectors
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		Nothing, jumps to Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
;	Corrupts registers:
;		SI, DS
;--------------------------------------------------------------------
AH42h_ReturnFromInt13hAfterStoringErrorCodeFromAHandTransferredSectorsFromCX:
	mov		ds, [bp+IDEPACK.intpack+INTPACK.ds]
	mov		si, [bp+IDEPACK.intpack+INTPACK.si]
	mov		[si+DAP.wSectorCount], cx
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
