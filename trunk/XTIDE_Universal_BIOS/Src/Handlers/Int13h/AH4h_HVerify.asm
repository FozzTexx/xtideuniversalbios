; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=4h, Verify Disk Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=4h, Verify Disk Sectors.
;
; AH4h_HandlerForVerifyDiskSectors
;	Parameters:
;		AL, CX, DH:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to INTPACK
;	Parameters on INTPACK in SS:BP:
;		AL:		Number of sectors to verify
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;	Returns with INTPACK in SS:BP:
;		AH:		Int 13h/40h floppy return status
;		CF:		0 if successfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH4h_HandlerForVerifyDiskSectors:
	test	al, al						; Invalid sector count?
	jz		SHORT AH2h_ZeroCntErr		;  If so, return with error

	mov		ah, HCMD_VERIFY_SECT		; Load command to AH
	call	HCommand_OutputCountAndLCHSandCommand
	jc		SHORT .ReturnWithErrorCodeInAH
	mov		bx, di						; DS:BX now points to DPT
	call	HStatus_WaitIrqOrRdy		; Wait for IRQ or RDY
.ReturnWithErrorCodeInAH:
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
