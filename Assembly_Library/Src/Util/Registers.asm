; Project name	:	Assembly Library
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
	COPY_SSBP_TO_ESDI
	ret

%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN JUMP_ALIGN
Registers_CopySSBPtoDSSI:
	COPY_SSBP_TO_DSSI
	ret

ALIGN JUMP_ALIGN
Registers_CopyDSSItoESDI:
	COPY_DSSI_TO_ESDI
	ret

ALIGN JUMP_ALIGN
Registers_CopyESDItoDSSI:
	COPY_ESDI_to_DSSI
	ret
%endif


;--------------------------------------------------------------------
; Registers_NormalizeESSI
; Registers_NormalizeESDI
;	Parameters
;		DS:SI or ES:DI:	Ptr to normalize
;	Returns:
;		DS:SI or ES:DI:	Normalized pointer
;	Corrupts registers:
;		AX, CX
; 
; Inline of NORMALIZE_FAR_POINTER so that we can share the last 2/3 of the 
; routine with Registers_NormalizeFinish.
; 
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Registers_NormalizeESSI:
	mov			cx, si
	and			si, byte 0fh
	jmp			Registers_NormalizeFinish

ALIGN JUMP_ALIGN
Registers_NormalizeESDI:
	mov			cx, di
	and			di, byte 0fh
;;; fall-through

ALIGN JUMP_ALIGN		
Registers_NormalizeFinish:		
	eSHR_IM		cx, 4
	mov			ax, es
	add			ax, cx
	mov			es, ax
	ret
		

;--------------------------------------------------------------------
; Registers_SetZFifNullPointerInDSSI (commented to save bytes)
;	Parameters
;		DS:SI:	Far pointer
;	Returns:
;		ZF:		Set if NULL pointer in DS:SI
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
;Registers_SetZFifNullPointerInDSSI:
;	push	ax
;	mov		ax, ds
;	or		ax, si
;	pop		ax
;	ret
