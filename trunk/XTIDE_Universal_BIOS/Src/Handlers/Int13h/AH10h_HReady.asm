; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=10h, Check Drive Ready.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=10h, Check Drive Ready.
;
; AH10h_HandlerForCheckDriveReady
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Returns with INTPACK in SS:BP:
;		AH:		Int 13h return status
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH10h_HandlerForCheckDriveReady:
	call	HStatus_WaitRdyDefTime
	xor		ah, ah
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
