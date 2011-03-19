; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=2h, Read Disk Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=2h, Read Disk Sectors.
;
; AH2h_HandlerForReadDiskSectors
;	Parameters:
;		AL, CX, DH, ES:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Parameters on INTPACK in SS:BP:
;		AL:		Number of sectors to read (1...255)
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		ES:BX:	Pointer to buffer recieving data
;	Returns with INTPACK in SS:BP:
;		AH:		Int 13h/40h floppy return status
;		AL:		Burst error length if AH returns 11h, undefined otherwise
;		CF:		0 if successfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH2h_HandlerForReadDiskSectors:
	test	al, al						; Invalid sector count?
	jz		SHORT AH2h_ZeroCntErr		;  If so, return with error

	; Select sector or block mode command
	mov		ah, HCMD_READ_SECT			; Load sector mode command
	cmp		BYTE [di+DPT.bSetBlock], 1	; Block mode enabled?
	eCMOVA	ah, HCMD_READ_MUL			; Load block mode command

	; Transfer data
	call	HCommand_OutputCountAndLCHSandCommand
	jc		SHORT .ReturnWithErrorCodeInAH
	mov		bx, [bp+INTPACK.bx]
	call	HPIO_ReadBlock				; Read data from IDE-controller
.ReturnWithErrorCodeInAH:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH

; Invalid sector count (also for AH=3h and AH=4h)
AH2h_ZeroCntErr:
	mov		ah, RET_HD_INVALID			; Invalid value passed
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
