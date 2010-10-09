; File name		:	Memory.asm
; Project name	:	Assembly Library
; Created date	:	14.7.2010
; Last update	:	9.10.2010
; Author		:	Tomi Tilli
; Description	:	Functions for memory access.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; OPTIMIZE_STRING_OPERATION
;	Parameters
;		%1:		Repeat instruction
;		%2:		String instruction without size (for example MOVS and not MOVSB or MOVSW)
;		CX:		Number of BYTEs to operate
;		DS:SI:	Ptr to source data
;		ES:DI:	Ptr to destination
;	Returns:
;		SI, DI:	Updated by number of bytes operated
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro OPTIMIZE_STRING_OPERATION 2
	push	cx

	shr		cx, 1			; Operate with WORDs for performance
	jcxz	%%HandleRemainingByte
	%1		%2w
%%HandleRemainingByte:
	jnc		SHORT %%OperationCompleted
	%2b

ALIGN JUMP_ALIGN
%%OperationCompleted:
	pop		cx
%endmacro


;--------------------------------------------------------------------
; Memory_CopyCXbytesFromDSSItoESDI
;	Parameters
;		CX:		Number of bytes to copy
;		DS:SI:	Ptr to source data
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		SI, DI:	Updated by number of bytes copied
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_CopyCXbytesFromDSSItoESDI:
	OPTIMIZE_STRING_OPERATION rep, movs
	ret


;--------------------------------------------------------------------
; Memory_ZeroSSBPwithSizeInCX
;	Parameters
;		CX:		Number of bytes to zero
;		SS:BP:	Ptr to buffer to zero
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_ZeroSSBPwithSizeInCX:
	push	es
	push	di
	push	ax
	call	Memory_CopySSBPtoESDI
	call	Memory_ZeroESDIwithSizeInCX
	pop		ax
	pop		di
	pop		es
	ret

;--------------------------------------------------------------------
; Memory_ZeroESDIwithSizeInCX
;	Parameters
;		CX:		Number of bytes to zero
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		DI:		Updated by number of BYTEs stored
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_ZeroESDIwithSizeInCX:
	xor		ax, ax
	; Fall to Memory_StoreCXbytesFromAccumToESDI

;--------------------------------------------------------------------
; Memory_StoreCXbytesFromAccumToESDI
;	Parameters
;		AX:		Word to use to fill buffer
;		CX:		Number of BYTEs to store
;		ES:DI:	Ptr to destination buffer
;	Returns:
;		DI:		Updated by number of BYTEs stored
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_StoreCXbytesFromAccumToESDI:
	OPTIMIZE_STRING_OPERATION rep, stos
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
	push	ds
	push	es
	pop		ds
	pop		es
	xchg	si, di
	ret


;--------------------------------------------------------------------
; Memory_CopySSBPtoESDI
; Memory_CopySSBPtoDSSI
; Memory_CopyESDItoDSSI
;	Parameters
;		Nothing
;	Returns:
;		Copies farm pointer to different segment/pointer register pair
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Memory_CopySSBPtoESDI:
	push	ss
	pop		es
	mov		di, bp
	ret

ALIGN JUMP_ALIGN
Memory_CopySSBPtoDSSI:
	push	ss
	pop		ds
	mov		si, bp
	ret

ALIGN JUMP_ALIGN
Memory_CopyESDItoDSSI:
	push	es
	pop		ds
	mov		si, di
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
