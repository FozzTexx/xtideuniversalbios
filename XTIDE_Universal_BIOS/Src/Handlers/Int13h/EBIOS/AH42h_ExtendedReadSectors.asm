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
;		CF:		0 if succesfull, 1 if error
;	Return with Disk Address Packet in INTPACK:
;		.bSectorCount	Number of sectors read successfully
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH42h_HandlerForExtendedReadSectors:
	call	AH42h_LoadDapToESSIandVerifyForTransfer
	call	CommandLookup_GetEbiosIndexToBX
	mov		ah, [cs:bx+g_rgbReadCommandLookup]
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRQ)
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	jmp		Idepack_ConvertDapToIdepackAndIssueCommandFromAH
%else
	call	Idepack_ConvertDapToIdepackAndIssueCommandFromAH
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif


;--------------------------------------------------------------------
; AH42h_LoadDapToESSIandVerifyForTransfer
;	Parameters:
;		SI:		Same as in INTPACK
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		DS:SI:	Ptr to Disk Address Packet
;	Returns:
;		ES:SI:	Ptr to Disk Address Packet (DAP)
;		Exits from INT 13h if invalid DAP
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH42h_LoadDapToESSIandVerifyForTransfer:
	mov		es, [bp+IDEPACK.intpack+INTPACK.ds]	; ES:SI to point Disk Address Packet
	cmp		BYTE [es:si+DAP.bSize], MINIMUM_DAP_SIZE
	jb		SHORT .DapContentsNotValid
	cmp		BYTE [es:si+DAP.bSectorCount], 0
	jle		SHORT .DapContentsNotValid			; Must be 1...127
	ret
.DapContentsNotValid:
	jmp		AH2h_ExitInt13hSinceSectorCountInIntpackIsZero
