; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for printing boot related strings.

; Section containing code
SECTION .text

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
	test	dl, 80h
	eCMOVZ	ax, g_szFDD
	push	ax

	call	DriveXlate_ToOrBack
	push	dx					; Push untranslated drive number
	call	DriveXlate_ToOrBack
	push	dx					; Push translated drive number

	mov		si, g_szTryToBoot
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; BootPrint_BootSectorResultStringFromBX
;	Parameters:
;		CS:BX:	Ptr to "found" or "not found"
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_BootSectorResultStringFromBX:
	push	bp
	mov		bp, sp
	ePUSH_T	ax, g_szBootSector
	push	bx			; "found" or "not found"
	mov		si, g_szSectRead
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; BootPrint_FailedToLoadFirstSector
;	Parameters:
;		AH:		INT 13h error code
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_FailedToLoadFirstSector:
	push	bp
	mov		bp, sp
	eMOVZX	bx, ah
	push	bx					; Push INT 13h error code
	mov		si, g_szReadError
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP
