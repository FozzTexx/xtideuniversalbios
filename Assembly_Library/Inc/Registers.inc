; Project name	:	Assembly Library
; Description	:	Register related macros.
%ifndef REGISTERS_INC
%define REGISTERS_INC

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
