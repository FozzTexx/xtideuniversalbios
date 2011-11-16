; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for printing boot related strings.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; BootPrint_FailedToLoadFirstSector
;	Parameters:
;		AH:		INT 13h error code
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_FailedToLoadFirstSector:
	push	bp
	mov		bp, sp
	eMOVZX	cx, ah
	push	cx					; Push INT 13h error code
	mov		si, g_szReadError
		
BootPrint_BootMenuPrint_FormatCSSIfromParamsInSSBP_Relay:		
	jmp		short BootMenuPrint_FormatCSSIfromParamsInSSBP_Relay
		

;--------------------------------------------------------------------
; BootPrint_TryToBootFromDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_TryToBootFromDL:
	push	bp
	mov		bp, sp

	mov		ax, g_szHDD
	test	dl, dl
	js		SHORT .NotFDD
	mov		ax, g_szFDD
.NotFDD:
	push	ax

	call	DriveXlate_ToOrBack
	push	dx					; Push untranslated drive number
	call	DriveXlate_ToOrBack
	push	dx					; Push translated drive number

	mov		si, g_szTryToBoot
	jmp		short BootPrint_BootMenuPrint_FormatCSSIfromParamsInSSBP_Relay		



