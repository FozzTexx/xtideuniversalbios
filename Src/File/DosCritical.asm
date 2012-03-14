; File name		:	DosCritical.asm
; Project name	:	Assembly Library
; Created date	:	1.9.2010
; Last update	:	2.9.2010
; Author		:	Tomi Tilli
; Description	:	DOS Critical Error Handler (24h) replacements.

; DOS Critical Error Handler return values
struc CRITICAL_ERROR_ACTION
	.ignoreErrorAndContinueProcessingRequest	resb	1
	.retryOperation								resb	1
	.terminateProgramAsThoughInt21hAH4ChCalled	resb	1
	.failSystemCallInProgress					resb	1
endstruc


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DosCritical_InstallNewHandlerFromCSDX
;	Parameters:
;		CS:DX:	New Critical Error Handler
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DosCritical_InstallNewHandlerFromCSDX:
	push	ds

	push	cs
	pop		ds
	mov		ax, (SET_INTERRUPT_VECTOR<<8) | DOS_CRITICAL_ERROR_HANDLER_24h
	int		DOS_INTERRUPT_21h

	pop		ds
	ret


;--------------------------------------------------------------------
; DosCritical_RestoreDosHandler
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DosCritical_RestoreDosHandler:
	push	ds
	push	dx
	push	ax

	lds		dx, [cs:PSP.fpInt24hCriticalError]
	mov		ax, (SET_INTERRUPT_VECTOR<<8) | DOS_CRITICAL_ERROR_HANDLER_24h
	int		DOS_INTERRUPT_21h

	pop		ax
	pop		dx
	pop		ds
	ret


;--------------------------------------------------------------------
; DosCritical_HandlerToIgnoreAllErrors
;	Parameters:
;		Nothing
;	Returns:
;		AL:		CRITICAL_ERROR_ACTION
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------	
ALIGN JUMP_ALIGN
DosCritical_HandlerToIgnoreAllErrors:
	mov		al, CRITICAL_ERROR_ACTION.ignoreErrorAndContinueProcessingRequest
	iret
