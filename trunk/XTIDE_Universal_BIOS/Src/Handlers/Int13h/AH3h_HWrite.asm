; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=3h, Write Disk Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=3h, Write Disk Sectors.
;
; AH3h_HandlerForWriteDiskSectors
;	Parameters:
;		AL, CX, DH, ES:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Parameters on INTPACK in SS:BP:
;		AL:		Number of sectors to write
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		ES:BX:	Pointer to source data
;	Returns with INTPACK in SS:BP:
;		AH:		Int 13h/40h floppy return status
;		CF:		0 if successfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH3h_HandlerForWriteDiskSectors:
	test	al, al						; Invalid sector count?
	jz		SHORT AH2h_ZeroCntErr		;  If so, return with error

	; Select sector or block mode command
	mov		ah, HCMD_WRITE_SECT			; Load sector mode command
	cmp		BYTE [di+DPT.bSetBlock], 1	; Block mode enabled?
	eCMOVA	ah, HCMD_WRITE_MUL			; Load block mode command

	; Transfer data
	call	HCommand_OutputCountAndLCHSandCommand
	jc		SHORT .ReturnWithErrorCodeInAH
	mov		bx, [bp+INTPACK.bx]
	call	HPIO_WriteBlock				; Write data to IDE-controller
.ReturnWithErrorCodeInAH:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
