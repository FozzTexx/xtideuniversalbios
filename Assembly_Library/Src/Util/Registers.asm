; Project name	:	Assembly Library
; Description	:	Functions for register operations.

;--------------------------------------------------------------------
; NORMALIZE_FAR_POINTER
;	Parameters:
;		%1:%2:		Far pointer to normalize
;		%3:			Scratch register
;		%4:			Scratch register
;	Returns:
;		%1:%2:		Normalized far pointer
;	Corrupts registers:
;		%3, %4
;--------------------------------------------------------------------
%macro NORMALIZE_FAR_POINTER 4
	mov		%4, %2				; Copy offset to scratch reg
	and		%2, BYTE 0Fh		; Clear offset bits 15...4
	eSHR_IM	%4, 4				; Divide offset by 16
	mov		%3, %1				; Copy segment to scratch reg
	add		%3, %4				; Add shifted offset to segment
	mov		%1, %3				; Set normalized segment
%endmacro


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Registers_NormalizeDSSI
; Registers_NormalizeESDI
;	Parameters
;		DS:SI or ES:DI:	Ptr to normalize
;	Returns:
;		DS:SI or ES:DI:	Normalized pointer
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Registers_NormalizeDSSI:
	push	dx
	push	ax
	NORMALIZE_FAR_POINTER ds, si, ax, dx
	pop		ax
	pop		dx
	ret

ALIGN JUMP_ALIGN
Registers_NormalizeESDI:
	push	dx
	push	ax
	NORMALIZE_FAR_POINTER es, di, ax, dx
	pop		ax
	pop		dx
	ret


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
%macro Registers_CopySSBPtoESDI 0
	push	ss
	pop		es
	mov		di, bp
%endmacro

%macro Registers_CopySSBPtoDSSI 0
	push	ss
	pop		ds
	mov		si, bp
%endmacro

%macro Registers_CopyDSSItoESDI 0
	push	ds
	pop		es
	mov		di, si
%endmacro

%macro Registers_CopyESDItoDSSI 0
	push	es
	pop		ds
	mov		si, di
%endmacro


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
