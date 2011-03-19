; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=15h, Read Disk Drive Size.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=15h, Read Disk Drive Size.
;
; AH15h_HandlerForReadDiskDriveSize
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Returns with INTPACK in SS:BP:
;		If succesfull:
;			AH:		3 (Hard disk accessible)
;			CX:DX:	Total number of sectors
;			CF:		0
;		If failed:
;			AH:		0 (Drive not present)
;			CX:DX:	0
;			CF:		1
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH15h_HandlerForReadDiskDriveSize:
	call	HCapacity_GetSectorCountFromOurAH08h		; Sector count to DX:AX
	mov		[bp+INTPACK.cx], dx							; HIWORD to CX
	mov		[bp+INTPACK.dx], ax							; LOWORD to DX

	xor		ah, ah
	call	HError_SetErrorCodeToIntpackInSSBPfromAH	; Store success to BDA and CF
	mov		BYTE [bp+INTPACK.ah], 3						; Type code = Hard disk
	jmp		Int13h_ReturnFromHandlerWithoutStoringErrorCode
