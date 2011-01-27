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
;		AX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_TryToBootFromDL:
	push	bp
	mov		bp, sp

	mov		ax, g_szHardDrv
	test	dl, 80h
	eCMOVZ	ax, g_szFloppyDrv
	push	ax					; "Hard Drive" or "Floppy Drive"

	call	DriveXlate_ToOrBack
	push	dx					; Push untranslated drive number
	call	DriveXlate_ToOrBack
	push	dx					; Push translated drive number

	mov		si, g_szTryToBoot
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; BootPrint_BootSectorLoaded
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_BootSectorLoaded:
	push	bp
	mov		bp, sp
	ePUSH_T	ax, g_szBootSector
	ePUSH_T	ax, g_szFound
	jmp		SHORT PrintBootSectorResult

;--------------------------------------------------------------------
; BootPrint_FirstSectorNotBootable
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_FirstSectorNotBootable:
	push	bp
	mov		bp, sp
	ePUSH_T	ax, g_szBootSector
	ePUSH_T	ax, g_szNotFound
PrintBootSectorResult:
	mov		si, g_szSectRead
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; BootPrint_FailedToLoadFirstSector
;	Parameters:
;		AH:		INT 13h error code
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootPrint_FailedToLoadFirstSector:
	push	bp
	mov		bp, sp
	eMOVZX	cx, ah				; Error code to CX
	push	cx					; Push INT 13h error code
	mov		si, g_szReadError
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP
