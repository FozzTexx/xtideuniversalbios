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
;		SS:BP:	Ptr to IDEREGS_AND_INTPACK
;	Returns with INTPACK:
;		AH:		Int 13h floppy return status
;		CF:		0 if AH = RET_HD_SUCCESS, 1 otherwise (error)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH1h_HandlerForReadDiskStatus:
	LOAD_BDA_SEGMENT_TO	ds, ax, !

%ifdef MODULE_SERIAL_FLOPPY
	test	dl, dl
	js		.HardDisk
	mov		ah, [BDA.bFDRetST]	; Unlike for hard disks below, floppy version does not clear the status
	jmp		.done
.HardDisk:
%endif

	xchg	ah, [BDA.bHDLastSt]	; Load and clear last error (AH is cleared with the LOAD_BDA_SEGMENT_TO above)

.done:
%ifndef USE_186
	call	Int13h_SetErrorCodeToIntpackInSSBPfromAH
	jmp		Int13h_ReturnFromHandlerWithoutStoringErrorCode
%else
	push	Int13h_ReturnFromHandlerWithoutStoringErrorCode
	jmp		Int13h_SetErrorCodeToIntpackInSSBPfromAH
%endif
