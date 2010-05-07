; File name		:	FormatTitle.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	19.4.2010
; Last update	:	20.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions for printing menu title strings.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Redraws menu title strings.
;
; FormatTitle_RedrawMenuTitle
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FormatTitle_RedrawMenuTitle:
	mov		dl, MFL_UPD_TITLE						; Invalidate Title strings
	jmp		Menu_Invalidate


;--------------------------------------------------------------------
; Prints title strings for menu system.
;
; FormatTitle_String
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FormatTitle_String:
	mov		ax, cs
	mov		ds, ax
	mov		es, ax
	call	FormatTitle_PrintProgramName
	call	FormatTitle_PrintImageSource
	jmp		SHORT FormatTitle_PrintUnsavedChanges


;--------------------------------------------------------------------
; Prints program name.
;
; FormatTitle_PrintProgramName
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;		DS=ES:	String segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FormatTitle_PrintProgramName:
	mov		di, g_szTitleProgramName
	mov		cx, CNT_TITLE_LINES
	call	MenuDraw_MultilineStr
	call	MenuDraw_NewlineStr
	jmp		MenuDraw_NewlineStr


;--------------------------------------------------------------------
; Prints where BIOS image is loaded from.
;
; FormatTitle_PrintImageSource
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;		DS=ES:	String segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FormatTitle_PrintImageSource:
	test	WORD [g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_FILELOADED | FLG_CFGVARS_ROMLOADED
	jz		SHORT FormatTitle_NothingLoaded
	mov		dx, g_szImageSource
	PRINT_STR
	test	WORD [g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_FILELOADED
	jnz		SHORT FormatTitle_FileLoaded
	; Fall to FormatTitle_RomLoaded

;--------------------------------------------------------------------
; FormatTitle_RomLoaded
; FormatTitle_FileLoaded
; FormatTitle_NothingLoaded
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;		DS=ES:	String segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
FormatTitle_RomLoaded:
	mov		dx, g_szRomLoaded
	PRINT_STR
	ret

ALIGN JUMP_ALIGN
FormatTitle_FileLoaded:
	mov		dx, 80h + DTA.szFile	; DTA starts at DOS PSP:80h
	PRINT_STR
	ret

ALIGN JUMP_ALIGN
FormatTitle_NothingLoaded:
	mov		dx, g_szNoBiosLoaded
	PRINT_STR
	ret


;--------------------------------------------------------------------
; Prints unsaved changes.
;
; FormatTitle_PrintUnsavedChanges
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;		DS=ES:	String segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FormatTitle_PrintUnsavedChanges:
	test	WORD [g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_UNSAVED
	jz		SHORT .Return
	mov		dl, '*'
	PRINT_CHAR
ALIGN JUMP_ALIGN
.Return:
	ret
