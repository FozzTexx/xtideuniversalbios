; Project name	:	Assembly Library
; Description	:	Functions for rebooting computer.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Reboot_ComputerWithBootFlagInAX
;	Parameters:
; 		AX:		Boot Flag
;	Returns:
;		Nothing, function never returns
;--------------------------------------------------------------------
Reboot_ComputerWithBootFlagInAX:
	LOAD_BDA_SEGMENT_TO	dx, bx
	mov		[BDA.wBoot], ax			; Store boot flag
	; Fall to Reboot_AT


;--------------------------------------------------------------------
; Reboot_AT
;	Parameters:
; 		Nothing
;	Returns:
;		Nothing, function never returns
;--------------------------------------------------------------------
Reboot_AT:
	mov		al, 0FEh				; System reset (AT+ keyboard controller)
	out		64h, al					; Reset computer (AT+)
	mov		al, 10
	call	Delay_MicrosecondsFromAX
	; Fall to Reboot_XT


;--------------------------------------------------------------------
; Reboot_XT
;	Parameters:
; 		Nothing
;	Returns:
;		Nothing, function never returns
;--------------------------------------------------------------------
Reboot_XT:
	xor		ax, ax
	push	ax
	popf							; Clear FLAGS (disables interrupt)
	mov		ds, ax
	mov		es, ax
	mov		ss, ax
	jmp		WORD 0FFFFh:0h			; XT reset
