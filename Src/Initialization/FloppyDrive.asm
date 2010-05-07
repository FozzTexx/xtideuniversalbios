; File name		:	FloppyDrive.asm
; Project name	:	IDE BIOS
; Created date	:	25.3.2010
; Last update	:	2.5.2010
; Author		:	Tomi Tilli
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
ALIGN JUMP_ALIGN
FloppyDrive_IsInt40hInstalled:
	cmp		WORD [es:INTV_FLOPPY_FUNC*4+2], 0C000h	; Any ROM segment?
	jae		SHORT .Int40hIsAlreadyInstalled
	clc
	ret
ALIGN JUMP_ALIGN
.Int40hIsAlreadyInstalled:
	stc
	ret


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
	int		INTV_FLOPPY_FUNC
	ret


;--------------------------------------------------------------------
; Returns number of Floppy Drives in system.
;
; FloppyDrive_GetCount
;	Parameters:
;		Nothing
;	Returns:
;		CX:		Number of Floppy Drives
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FloppyDrive_GetCount:
	push	es
	call	FloppyDrive_GetCountFromBIOS
	jnc		SHORT .CompareToUserMinimum
	call	FloppyDrive_GetCountFromBDA
ALIGN JUMP_ALIGN
.CompareToUserMinimum:
	MAX_U	cl, [cs:ROMVARS.bMinFddCnt]
	xor		ch, ch
	pop		es
	ret


;--------------------------------------------------------------------
; Reads Floppy Drive Count from BIOS.
; Does not work on most XT systems. Call FloppyDrive_GetCountFromBDA
; if this function fails.
;
; FloppyDrive_GetCountFromBIOS
;	Parameters:
;		Nothing
;	Returns:
;		CL:		Number of Floppy Drives
;		CF:		Cleared if successfull
;				Set if BIOS function not supported
;	Corrupts registers:
;		CH, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FloppyDrive_GetCountFromBIOS:
	push	di
	push	dx
	push	bx
	push	ax

	mov		ah, 08h					; Get Drive Parameters
	xor		dx, dx					; Floppy Drive 00h
	int		INTV_FLOPPY_FUNC
	mov		cl, dl					; Number of Floppy Drives to CL

	pop		ax
	pop		bx
	pop		dx
	pop		di
	ret


;--------------------------------------------------------------------
; Reads Floppy Drive Count (0...4) from BIOS Data Area.
; This function should be used only if FloppyDrive_GetCountFromBIOS fails.
;
; FloppyDrive_GetCountFromBDA
;	Parameters:
;		Nothing
;	Returns:
;		CL:		Number of Floppy Drives
;	Corrupts registers:
;		CH, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FloppyDrive_GetCountFromBDA:
	LOAD_BDA_SEGMENT_TO	es, cx
	mov		cl, [es:BDA.wEquipment]			; Load Equipment WORD low byte
	mov		ch, cl							; Copy it to CH
	and		cx, 0C001h						; Leave bits 15..14 and 0
	eROL_IM	ch, 2							; EW low byte bits 7..6 to 1..0
	add		cl, ch							; CL = Floppy Drive count
	ret
