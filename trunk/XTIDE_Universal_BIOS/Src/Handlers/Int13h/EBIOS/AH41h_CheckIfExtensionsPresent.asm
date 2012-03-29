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
;		BX:		AA55h
;		CX:		Support bits
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
AH41h_HandlerForCheckIfExtensionsPresent:
	cmp		WORD [bp+IDEPACK.intpack+INTPACK.bx], 55AAh
	jne		SHORT .EbiosNotSupported

	mov		BYTE [bp+IDEPACK.intpack+INTPACK.ah], EBIOS_VERSION
	mov		WORD [bp+IDEPACK.intpack+INTPACK.bx], 0AA55h
	mov		WORD [bp+IDEPACK.intpack+INTPACK.cx], ENHANCED_DRIVE_ACCESS_SUPPORT
	and		BYTE [bp+IDEPACK.intpack+INTPACK.flags], ~FLG_FLAGS_CF	; Return with CF cleared
	jmp		Int13h_ReturnFromHandlerWithoutStoringErrorCode
.EbiosNotSupported:
	jmp		Int13h_UnsupportedFunction
