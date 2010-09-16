; File name		:	Memory.asm
; Project name	:	Assembly Library
; Created date	:	14.7.2010
; Last update	:	15.9.2010
; Author		:	Tomi Tilli
; Description	:	Functions for memory access.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Memory_ZeroDSSIbyWordsInCX
;	Parameters
;		CX:		Number of words to zero
;		DS:SI:	Ptr to buffer to zero
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_ZeroDSSIbyWordsInCX:
	call	Memory_ExchangeDSSIwithESDI
	call	Memory_ZeroESDIbyWordsInCX
	jmp		SHORT Memory_ExchangeDSSIwithESDI

;--------------------------------------------------------------------
; Memory_ZeroSSBPbyWordsInCX
;	Parameters
;		CX:		Number of words to zero
;		SS:BP:	Ptr to buffer to zero
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_ZeroSSBPbyWordsInCX:
	push	es
	push	di
	push	ax

	push	ss
	pop		es
	mov		di, bp
	call	Memory_ZeroESDIbyWordsInCX

	pop		ax
	pop		di
	pop		es
	ret

;--------------------------------------------------------------------
; Memory_ZeroESDIbyWordsInCX
;	Parameters
;		CX:		Number of words to zero
;		ES:DI:	Ptr to buffer to zero
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_ZeroESDIbyWordsInCX:
	xor		ax, ax
	; Fall to Memory_FillESDIwithAXbyCXtimes

;--------------------------------------------------------------------
; Memory_FillESDIwithAXbyCXtimes
;	Parameters
;		AX:		Word to use to fill buffer
;		CX:		Number of words to fill
;		ES:DI:	Ptr to buffer to fill
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_FillESDIwithAXbyCXtimes:
	cld
	push	di
	push	cx
	rep stosw
	pop		cx
	pop		di
	ret


;--------------------------------------------------------------------
; Memory_ExchangeDSSIwithESDI
;	Parameters
;		Nothing
;	Returns:
;		DS:SI and ES:DI are exchanged.
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_ExchangeDSSIwithESDI:
	xchg	si, di
	push	ds
	push	es
	pop		ds
	pop		es
	ret


;--------------------------------------------------------------------
; Memory_CopySSBPtoDSSI
; Memory_CopySSBPtoESDI
;	Parameters
;		Nothing
;	Returns:
;		DS:SI:		Same as SS:BP
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_CopySSBPtoDSSI:
	push	ss
	pop		ds
	mov		si, bp
	ret

ALIGN JUMP_ALIGN
Memory_CopySSBPtoESDI:
	push	ss
	pop		es
	mov		di, bp
	ret


;--------------------------------------------------------------------
; Memory_SetZFifNullPointerInDSSI
;	Parameters
;		DS:SI:	Far pointer
;	Returns:
;		ZF:		Set if NULL pointer in DS:SI
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_SetZFifNullPointerInDSSI:
	push	ax
	mov		ax, ds
	or		ax, si
	pop		ax
	ret


;--------------------------------------------------------------------
; Memory_ReserveCXbytesFromStackToDSSI
;	Parameters
;		CX:		Number of bytes to reserve
;	Returns:
;		DS:SI:	Ptr to reserved buffer
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_ReserveCXbytesFromStackToDSSI:
	pop		ax
	push	ss
	pop		ds
	sub		sp, cx
	mov		si, sp
	jmp		ax
