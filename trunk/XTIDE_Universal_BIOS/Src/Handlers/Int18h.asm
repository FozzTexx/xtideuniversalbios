; Project name	:	XTIDE Universal BIOS
; Description	:	Int 18h BIOS functions (ROM boot and Boot error).

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 18h software interrupt handler.
; Enters boot menu again after displaying callback message.
;
; Int18h_BootError
;	Parameters:
;		Nothing
;	Returns:
;		Nothing (jumps to Int19hMenu_Display)
;	Corrupts registers:
;		Doesn't matter
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int18h_BootError:
	mov		si, g_sz18hCallback
	call	PrintNullTerminatedStringFromCSSIandSetCF
	jmp		Int19hMenu_Display		; Return to boot menu
