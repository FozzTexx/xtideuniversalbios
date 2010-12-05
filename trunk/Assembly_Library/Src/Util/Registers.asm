; File name		:	Registers.asm
; Project name	:	Assembly Library
; Created date	:	24.10.2010
; Last update	:	24.10.2010
; Author		:	Tomi Tilli
; Description	:	Functions for register operations.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Registers_ExchangeDSSIwithESDI
;	Parameters
;		Nothing
;	Returns:
;		DS:SI and ES:DI are exchanged.
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Registers_ExchangeDSSIwithESDI:
	push	ds
	push	es
	pop		ds
	pop		es
	xchg	si, di
	ret


;--------------------------------------------------------------------
; Registers_CopySSBPtoESDI
; Registers_CopySSBPtoDSSI
; Registers_CopyDSSItoESDI
; Registers_CopyESDItoDSSI
;	Parameters
;		Nothing
;	Returns:
;		Copies farm pointer to different segment/pointer register pair
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Registers_CopySSBPtoESDI:
	push	ss
	pop		es
	mov		di, bp
	ret

ALIGN JUMP_ALIGN
Registers_CopySSBPtoDSSI:
	push	ss
	pop		ds
	mov		si, bp
	ret

ALIGN JUMP_ALIGN
Registers_CopyDSSItoESDI:
	push	ds
	pop		es
	mov		di, si
	ret

ALIGN JUMP_ALIGN
Registers_CopyESDItoDSSI:
	push	es
	pop		ds
	mov		si, di
	ret


;--------------------------------------------------------------------
; Registers_SetZFifNullPointerInDSSI
;	Parameters
;		DS:SI:	Far pointer
;	Returns:
;		ZF:		Set if NULL pointer in DS:SI
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Registers_SetZFifNullPointerInDSSI:
	push	ax
	mov		ax, ds
	or		ax, si
	pop		ax
	ret

	
ALIGN JUMP_ALIGN
Registers_SetCFifCXisZero:
	