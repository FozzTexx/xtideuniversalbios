; File name		:	MainMenu.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	19.4.2010
; Last update	:	2.5.2010
; Author		:	Tomi Tilli
; Description	:	Main menu.

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_MenuPageMain:
istruc MENUPAGE
	at	MENUPAGE.bItemCnt,	db	6
iend
istruc MENUPAGEITEM	; Exit to DOS
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemMainExitToDOS
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoMainExitToDOS
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoMainExitToDOS
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
istruc MENUPAGEITEM	; Load BIOS from file
	at	MENUPAGEITEM.fnActivate,	dw	MainMenu_ActivateLoadBiosFromFile
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemMainLoadFile
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoMainLoadFile
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoMainLoadFile
	at	MENUPAGEITEM.szDialog,		dw	g_szNfoMainLoadFile
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
g_MenuPageInfoMainLoadFromROM:
istruc MENUPAGEITEM	; Load XTIDE Universal BIOS from ROM
	at	MENUPAGEITEM.fnActivate,	dw	MainMenu_ActivateLoadBiosFromRom
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemMainLoadROM
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoMainLoadROM
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoMainLoadROM
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgMainLoadROM
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_SPECIAL
iend
g_MenuPageInfoMainLoadSettingsFromROM:
istruc MENUPAGEITEM	; Load old settings from ROM
	at	MENUPAGEITEM.fnActivate,	dw	MainMenu_ActivateLoadSettingsFromRom
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemMainLoadStngs
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoMainLoadStngs
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoMainLoadStngs
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgMainLoadStngs
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_SPECIAL
iend
g_MenuPageInfoMainConfigureBios:
istruc MENUPAGEITEM	; Configure XTIDE Universal BIOS
	at	MENUPAGEITEM.fnActivate,	dw	MainMenu_ActivateConfigureBios
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageCfg
	at	MENUPAGEITEM.szName,		dw	g_szItemMainConfigure
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoMainConfigure
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoMainConfigure
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
g_MenuPageInfoMainFlash:
istruc MENUPAGEITEM	; Flash EEPROM
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageFlash
	at	MENUPAGEITEM.szName,		dw	g_szItemMainFlash
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoMainFlash
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoMainFlash
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MainMenu_ActivateLoadBiosFromFile
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if menuitem changed
;				Cleared if no changes
;	Corrupts registers:
;		All
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MainMenu_ActivateLoadBiosFromFile:
	push	si
	call	BiosFile_SaveUnsavedChanges
	call	BiosFile_SelectFile						; Let user select file
	jc		SHORT .LoadUserSelectedFile
	pop		si
	ret												; User cancellation
ALIGN JUMP_ALIGN
.LoadUserSelectedFile:
	push	cs
	pop		es
	mov		di, g_cfgVars+CFGVARS.rgbEepromBuffers	; ES:DI points to destination buffer
	call	BiosFile_LoadFile						; Get file size to CX
	pop		si
	mov		ax, FLG_CFGVARS_FILELOADED				; Loaded file instead of ROM
	jmp		SHORT MainMenu_NewBiosLoaded


;--------------------------------------------------------------------
; MainMenu_ActivateLoadBiosFromRom
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if menuitem changed
;				Cleared if no changes
;	Corrupts registers:
;		All
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MainMenu_ActivateLoadBiosFromRom:
	call	BiosFile_SaveUnsavedChanges
	call	EEPROM_LoadBiosFromROM
	call	MenuPageItem_DisplaySpecialFunctionDialog
	mov		ax, FLG_CFGVARS_ROMLOADED	; Loaded ROM instead of file
	jmp		SHORT MainMenu_NewBiosLoaded


;--------------------------------------------------------------------
; MainMenu_ActivateLoadSettingsFromRom
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if menuitem changed
;				Cleared if no changes
;	Corrupts registers:
;		All
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MainMenu_ActivateLoadSettingsFromRom:
	or		WORD [cs:g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_UNSAVED
	call	EEPROM_LoadSettingsFromRomToRam
	call	FormatTitle_RedrawMenuTitle
	call	MenuPageItem_DisplaySpecialFunctionDialog
	clc
	ret


;--------------------------------------------------------------------
; MainMenu_ActivateConfigureBios
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if menuitem changed
;				Cleared if no changes
;	Corrupts registers:
;		All
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MainMenu_ActivateConfigureBios:
	call	ConfigurationMenu_SetMenuitemVisibility
	jmp		MainPageItem_ActivateSubmenu


;--------------------------------------------------------------------
; MainMenu_NewBiosLoaded
;	Parameters:
;		AX:		EEPROM source (FLG_CFGVARS_FILELOADED or FLG_CFGVARS_ROMLOADED)
;		CX:		EEPROM size in bytes
;		DS:SI:	Ptr to MENUPAGE
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Cleared since no need to draw changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MainMenu_NewBiosLoaded:
	call	EEPROM_NewBiosLoadedFromFileOrROM
	call	FormatTitle_RedrawMenuTitle
	; Fall to Main_SetMenuitemVisibilityAndDrawChanges

;--------------------------------------------------------------------
; Main_SetMenuitemVisibilityAndDrawChanges
;	Parameters:
;		DS:SI:	Ptr to MENUPAGE
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Cleared since no need to draw changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Main_SetMenuitemVisibilityAndDrawChanges:
	call	MainMenu_SetMenuitemVisibility
	call	MenuPage_InvalidateItemCount
	clc		; No need to redraw Full Mode menuitem
	ret


;--------------------------------------------------------------------
; Enables or disables menuitems based on current configuration.
;
; MainMenu_SetMenuitemVisibility
;	Parameters:
;		DS:		CS
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MainMenu_SetMenuitemVisibility:
	call	MainMenu_SetLoadBiosFromRomVisibility
	call	MainMenu_SetConfigureXtideUniversalBiosVisibility
	jmp		SHORT MainMenu_SetFlashVisibility

ALIGN JUMP_ALIGN
MainMenu_SetLoadBiosFromRomVisibility:
	push	es
	call	EEPROM_FindXtideUniversalBiosROM
	pop		es
	jnc		SHORT .XtideUniversalBiosNotFound
	or		BYTE [g_MenuPageInfoMainLoadFromROM+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
	call	EEPROM_IsXtideUniversalBiosLoaded
	jne		SHORT .Return
	or		BYTE [g_MenuPageInfoMainLoadSettingsFromROM+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
ALIGN JUMP_ALIGN
.Return:
	ret
ALIGN JUMP_ALIGN
.XtideUniversalBiosNotFound:
	and		BYTE [g_MenuPageInfoMainLoadFromROM+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	and		BYTE [g_MenuPageInfoMainLoadSettingsFromROM+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	ret

ALIGN JUMP_ALIGN
MainMenu_SetConfigureXtideUniversalBiosVisibility:
	call	EEPROM_IsXtideUniversalBiosLoaded
	jne		SHORT .XtideUniversalBiosNotLoaded
	or		BYTE [g_MenuPageInfoMainConfigureBios+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
	ret
ALIGN JUMP_ALIGN
.XtideUniversalBiosNotLoaded:
	and		BYTE [g_MenuPageInfoMainConfigureBios+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	ret

ALIGN JUMP_ALIGN
MainMenu_SetFlashVisibility:
	test	WORD [cs:g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_FILELOADED | FLG_CFGVARS_ROMLOADED
	jz		SHORT .BiosNotLoaded
	or		BYTE [g_MenuPageInfoMainFlash+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
	ret
ALIGN JUMP_ALIGN
.BiosNotLoaded:
	and		BYTE [g_MenuPageInfoMainFlash+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	ret
