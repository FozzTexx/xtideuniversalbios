; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=1h, Read Disk Status.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=1h, Read Disk Status.
;
; AH1h_HandlerForReadDiskStatus
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Returns with INTPACK in SS:BP:
;		AH:		Int 13h floppy return status
;		CF:		0 if AH = RET_HD_SUCCESS, 1 otherwise (error)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH1h_HandlerForReadDiskStatus:
	LOAD_BDA_SEGMENT_TO	ds, ax, !
	xchg	ah, [BDA.bHDLastSt]		; Load and clear last error
	call	HError_SetErrorCodeToIntpackInSSBPfromAH
	jmp		Int13h_ReturnFromHandlerWithoutStoringErrorCode
