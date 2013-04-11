; Project name	:	Assembly Library
; Description	:	Register related macros.
%ifndef REGISTERS_INC
%define REGISTERS_INC

struc INTPACK
%ifdef USE_386
;	.gs				resb	2
;	.fs				resb	2
%endif
	.es				resb	2
	.ds				resb	2
	.di				resb	2
	.si				resb	2
	.bp				resb	2
	.sp				resb	2
	.bx:
	.bl				resb	1
	.bh				resb	1
	.dx:
	.dl				resb	1
	.dh				resb	1
	.cx:
	.cl				resb	1
	.ch				resb	1
	.ax:
	.al				resb	1
	.ah				resb	1
	.ip				resb	2
	.cs				resb	2
	.flags			resb	2
endstruc

; 8086/8088 FLAGS
FLG_FLAGS_CF		EQU (1<<0)
FLG_FLAGS_PF		EQU (1<<2)
FLG_FLAGS_AF		EQU (1<<4)
FLG_FLAGS_ZF		EQU (1<<6)
FLG_FLAGS_SF		EQU (1<<7)
FLG_FLAGS_TF		EQU (1<<8)
FLG_FLAGS_IF		EQU (1<<9)
FLG_FLAGS_DF		EQU (1<<10)
FLG_FLAGS_OF		EQU (1<<11)


;--------------------------------------------------------------------
; This macro must be the first thing to call on Interrupt Service Routine.
;
; CREATE_INTPACK_TO_SSBP
;	Parameters
;		Nothing
;	Returns:
;		SS:BP:	Points to INTPACK
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro CREATE_INTPACK_TO_SSBP 0
	ePUSHA
	push	ds
	push	es
%ifdef USE_386
;	push	fs
;	push	gs
%endif
	mov		bp, sp
%endmacro

;--------------------------------------------------------------------
; This macro must be the last thing to call on Interrupt Service Routine.
;
; RESTORE_INTPACK_FROM_SSBP
;	Parameters
;		SS:BP:	Ptr to INTPACK
;	Returns:
;		All Registers will be loaded from INTPACK
;--------------------------------------------------------------------
%macro RESTORE_INTPACK_FROM_SSBP 0
%ifdef USE_386
;	pop		gs
;	pop		fs
%endif
	pop		es
	pop		ds
	ePOPA
	iret
%endmacro


;--------------------------------------------------------------------
; This macro must be the first thing to call on Interrupt Service Routine.
;
; CREATE_FRAME_INTPACK_TO_SSBP
;	Parameters
;		%1:		Number of extra bytes to reserve before INTPACK
;	Returns:
;		SS:BP:	Points to INTPACK
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro CREATE_FRAME_INTPACK_TO_SSBP 1
	ePUSHA
	push	ds
	push	es
%ifdef USE_386
;	push	fs
;	push	gs
%endif
	sub		sp, BYTE %1
	mov		bp, sp
%endmacro

;--------------------------------------------------------------------
; This macro must be the last thing to call on Interrupt Service Routine.
;
; RESTORE_FRAME_INTPACK_FROM_SSBP
;	Parameters
;		%1:		Number of extra bytes in INTPACK
;		SS:BP:	Ptr to INTPACK
;	Returns:
;		All Registers will be loaded from INTPACK
;--------------------------------------------------------------------
%macro RESTORE_FRAME_INTPACK_FROM_SSBP 1
	add		sp, BYTE %1
%ifdef USE_386
;	pop		gs
;	pop		fs
%endif
	pop		es
	pop		ds
	ePOPA
	iret
%endmacro


;--------------------------------------------------------------------
; NORMALIZE_FAR_POINTER
;	Parameters:
;		%1:%2:		Far pointer to normalize
;		%3:			Scratch register
;		%4:			Scratch register
;	Returns:
;		%1:%2:		Normalized far pointer
;		CF:			Set if overflow in (segment) normalization
;					Clear if normalized successfully
;	Corrupts registers:
;		%3, %4
;--------------------------------------------------------------------
%macro NORMALIZE_FAR_POINTER 4
	mov		%4, %2			; Copy offset to scratch reg
	and		%2, BYTE 0Fh	; Clear offset bits 15...4
	eSHR_IM	%4, 4			; Divide offset by 16
	mov		%3, %1			; Copy segment to scratch reg
	add		%3, %4			; Add shifted offset to segment (sets or clears CF)
	mov		%1, %3			; Set normalized segment
%endmacro


;--------------------------------------------------------------------
; COPY_SSBP_TO_ESDI
; COPY_SSBP_TO_DSSI
; COPY_DSSI_TO_ESDI
; COPY_ESDI_to_DSSI
;	Parameters
;		Nothing
;	Returns:
;		Copies farm pointer to different segment/pointer register pair
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro COPY_SSBP_TO_ESDI 0
	push	ss
	pop		es
	mov		di, bp
%endmacro

%macro COPY_SSBP_TO_DSSI 0
	push	ss
	pop		ds
	mov		si, bp
%endmacro

%macro COPY_DSSI_TO_ESDI 0
	push	ds
	pop		es
	mov		di, si
%endmacro

%macro COPY_ESDI_to_DSSI 0
	push	es
	pop		ds
	mov		si, di
%endmacro



%endif ; REGISTERS_INC
