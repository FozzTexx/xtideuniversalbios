; Project name	:	XTIDE Universal BIOS
; Description	:	Various floppy drive related functions that
;					Boot Menu uses.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Checks is floppy drive handler installed to interrupt vector 40h.
;
; FloppyDrive_IsInt40hInstalled
;	Parameters:
;		ES:		BDA and Interrupt Vector segment (zero)
;	Returns:
;		CF:		Set if INT 40h is installed
;				Cleared if INT 40h is not installed
;	Corrupts registers:
;		BX, CX, DI
;--------------------------------------------------------------------
FloppyDrive_IsInt40hInstalled:
	cmp		WORD [es:BIOS_DISKETTE_INTERRUPT_40h*4+2], 0C000h	; Any ROM segment?
%ifdef USE_AT	; No need to verify on XT systems.
	jb		SHORT .Int40hHandlerIsNotInstalled
	call	.VerifyInt40hHandlerSinceSomeBiosesSimplyReturnFromInt40h
.Int40hHandlerIsNotInstalled:
%endif
	cmc
	ret

;--------------------------------------------------------------------
; .VerifyInt40hHandlerSinceSomeBiosesSimplyReturnFromInt40h
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Cleared if INT 40h is installed
;				Set if INT 40h is not installed
;	Corrupts registers:
;		BX, CX, DI
;--------------------------------------------------------------------
%ifdef USE_AT
.VerifyInt40hHandlerSinceSomeBiosesSimplyReturnFromInt40h:
	push	es
	push	dx
	push	ax

	call	.LoadInt40hVerifyParameters
	int		BIOS_DISK_INTERRUPT_13h
	jc		SHORT .Int40hIsInstalled	; Maybe there are not any floppy drives at all
	push	es
	push	di

	call	.LoadInt40hVerifyParameters
	int		BIOS_DISKETTE_INTERRUPT_40h

	pop		dx
	pop		cx
	cmp		dx, di						; Difference in offsets?
	jne		SHORT .Int40hNotInstalled
	mov		dx, es
	cmp		cx, dx						; Difference in segments?
	je		SHORT .Int40hIsInstalled
.Int40hNotInstalled:
	stc
.Int40hIsInstalled:
	pop		ax
	pop		dx
	pop		es
	ret

;--------------------------------------------------------------------
; .LoadInt40hVerifyParameters
;	Parameters:
;		Nothing
;	Returns:
;		AH:		08h (Get Drive Parameters)
;		DL:		00h (floppy drive)
;		ES:DI:	0:0h (to guard against BIOS bugs)
;	Corrupts registers:
;		DH
;--------------------------------------------------------------------
.LoadInt40hVerifyParameters:
	mov		ah, 08h				; Get Drive Parameters
	cwd							; Floppy drive 0
	mov		di, dx
	mov		es, dx				; ES:DI = 0000:0000h to guard against BIOS bugs
	ret
%endif


;--------------------------------------------------------------------
; Returns floppy drive type.
; PC/XT system do not support AH=08h but FLOPPY_TYPE_525_OR_35_DD
; is still returned for them.
;
; FloppyDrive_GetType
;	Parameters:
;		DL:		Floppy Drive number
;	Returns:
;		BX:		Floppy Drive Type:
;					FLOPPY_TYPE_525_OR_35_DD
;					FLOPPY_TYPE_525_DD
;					FLOPPY_TYPE_525_HD
;					FLOPPY_TYPE_35_DD
;					FLOPPY_TYPE_35_HD
;					FLOPPY_TYPE_35_ED
;		CF:		Set if AH=08h not supported (XT systems) or error
;				Cleared if type read correctly (AT systems)
;	Corrupts registers:
;		AX, CX, DX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FloppyDrive_GetType:
	mov		ah, 08h			; Get Drive Parameters
	xor		bx, bx			; FLOPPY_TYPE_525_OR_35_DD when function not supported
	int		BIOS_DISKETTE_INTERRUPT_40h
	ret


;--------------------------------------------------------------------
; Returns number of Floppy Drives in system.
;
; FloppyDrive_GetCountToAX
;	Parameters:
;		DS:		RAMVARS Segment
;	Returns:
;		AX:		Number of Floppy Drives
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FloppyDrive_GetCountToAX:		
%ifdef MODULE_SERIAL_FLOPPY
	call	RamVars_UnpackFlopCntAndFirstToAL
	js		.UseBIOSorBDA				; We didn't add in any drives, counts here are not valid
		
	adc		al,1						; adds in the drive count bit, and adds 1 for count vs. 0-index, 
	jmp		.FinishCalc					; need to clear AH on the way out, and add in minimum drive numbers

.UseBIOSorBDA:	
%endif
	call	FloppyDrive_GetCountFromBIOS_or_BDA

.FinishCalc:	
	mov		ah, [cs:ROMVARS.bMinFddCnt]
	MAX_U	al, ah
	cbw
		
	ret

ALIGN JUMP_ALIGN		
FloppyDrive_GetCountFromBIOS_or_BDA:
	push	es

;--------------------------------------------------------------------
; Reads Floppy Drive Count from BIOS.
; Does not work on most XT systems. Call FloppyDrive_GetCountFromBDA
; if this function fails.
;
; GetCountFromBIOS
;	Parameters:
;		Nothing
;	Returns:
;		CL:		Number of Floppy Drives
;		CF:		Cleared if successfull
;				Set if BIOS function not supported
;	Corrupts registers:
;		CH, ES
;--------------------------------------------------------------------
%ifdef USE_AT
ALIGN JUMP_ALIGN
.GetCountFromBIOS:
	push	di
	push	dx
	push	bx

	mov		ah, 08h					; Get Drive Parameters
	cwd								; Floppy Drive 00h
	int		BIOS_DISKETTE_INTERRUPT_40h
	mov		al, dl					; Number of Floppy Drives to AL

	pop		bx
	pop		dx
	pop		di
%endif

;--------------------------------------------------------------------
; Reads Floppy Drive Count (0...4) from BIOS Data Area.
; This function should be used only if FloppyDrive_GetCountFromBIOS fails.
;
; GetCountFromBDA
;	Parameters:
;		Nothing
;	Returns:
;		CL:		Number of Floppy Drives
;	Corrupts registers:
;		CH, ES
;--------------------------------------------------------------------
%ifndef USE_AT
ALIGN JUMP_ALIGN
.GetCountFromBDA:
	LOAD_BDA_SEGMENT_TO	es, ax
	mov		al, [es:BDA.wEquipment]			; Load Equipment WORD low byte
	mov		ah, al							; Copy it to CH
	and		ax, 0C001h						; Leave bits 15..14 and 0
	eROL_IM	ah, 2							; EW low byte bits 7..6 to 1..0
	add		al, ah							; CL = Floppy Drive count
%endif

	pop		es
	ret
		