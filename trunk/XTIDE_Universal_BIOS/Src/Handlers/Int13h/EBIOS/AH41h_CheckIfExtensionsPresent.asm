; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=41h, Check if Extensions Present.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=41h, Check if Extensions Present.
;
; AH41h_HandlerForCheckIfExtensionsPresent
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		BX:		55AAh
;	Returns with INTPACK:
;		AH:		Major version of EBIOS extensions
;		BX:		55AAh
;		CX:		Support bits
;		CF:		0 if succesfull, 1 if error
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH41h_HandlerForCheckIfExtensionsPresent:
	cmp		WORD [bp+IDEPACK.intpack+INTPACK.bx], 55AAh
	jne		SHORT .EbiosNotSupported

	mov		WORD [bp+IDEPACK.intpack+INTPACK.cx], ENHANCED_DRIVE_ACCESS_SUPPORT
	mov		ah, EBIOS_VERSION
	and		BYTE [bp+IDEPACK.intpack+INTPACK.flags], ~FLG_FLAGS_CF	; Return with CF cleared
	jmp		Int13h_ReturnFromHandlerWithoutStoringErrorCode
.EbiosNotSupported:
	jmp		Int13h_UnsupportedFunction
