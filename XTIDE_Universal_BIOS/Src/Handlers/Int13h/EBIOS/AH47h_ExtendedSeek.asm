; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=47h, Extended Seek.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=47h, Extended Seek.
;
; AH47h_HandlerForExtendedSeek
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
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH47h_HandlerForExtendedSeek:
	; Note that there is no Seek command for LBA48 addressing!
	mov		es, [bp+IDEPACK.intpack+INTPACK.ds]	; ES:SI to point Disk Address Packet
	cmp		BYTE [es:si+DAP.bSize], MINIMUM_DAP_SIZE
	jb		SHORT .DapContentsNotValid

	mov		ah, COMMAND_SEEK
	mov		bx, TIMEOUT_AND_STATUS_TO_WAIT(TIMEOUT_DRQ, FLG_STATUS_DRDY)
%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	jmp		Idepack_ConvertDapToIdepackAndIssueCommandFromAH
%else
	call	Idepack_ConvertDapToIdepackAndIssueCommandFromAH
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif

.DapContentsNotValid:
	jmp		AH2h_ExitInt13hSinceSectorCountInIntpackIsZero
