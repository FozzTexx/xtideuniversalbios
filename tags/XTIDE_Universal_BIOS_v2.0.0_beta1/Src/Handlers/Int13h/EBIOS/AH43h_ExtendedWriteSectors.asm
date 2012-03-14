; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=43h, Extended Write Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=43h, Extended Write Sectors.
;
; AH43h_HandlerForExtendedWriteSectors
;	Parameters:
;		SI:		Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		AL:		0 or 1 to write with verify off
;				2 to write with verify (if supported)
;		DS:SI:	Ptr to Disk Address Packet
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;	Return with Disk Address Packet in INTPACK:
;		.wSectorCount	Number of sectors written successfully
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH43h_HandlerForExtendedWriteSectors:
	cmp		BYTE [bp+IDEPACK.intpack+INTPACK.al], 2	; Verify requested?
	jae		SHORT Prepare_ReturnFromInt13hWithInvalidFunctionError

	call	Prepare_ByLoadingDapToESSIandVerifyingForTransfer
	mov		ah, [cs:bx+g_rgbWriteCommandLookup]
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
%ifdef USE_186
	push	AH42h_ReturnFromInt13hAfterStoringErrorCodeFromAHandTransferredSectorsFromCX
	jmp		Idepack_ConvertDapToIdepackAndIssueCommandFromAH
%else
	call	Idepack_ConvertDapToIdepackAndIssueCommandFromAH
	jmp		SHORT AH42h_ReturnFromInt13hAfterStoringErrorCodeFromAHandTransferredSectorsFromCX
%endif
