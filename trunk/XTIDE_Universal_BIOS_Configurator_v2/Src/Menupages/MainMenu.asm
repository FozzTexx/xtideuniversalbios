; File name		:	MainMenu.asm
; Project name	:	XTIDE Universal BIOS Configurator v2
; Created date	:	6.10.2010
; Last update	:	19.11.2010
; Author		:	Tomi Tilli
; Description	:	Main menu structs and functions.

; Section containing initialized data
SECTION .data

ALIGN WORD_ALIGN
g_MenupageForMainMenu:
istruc MENUPAGE
	at	MENUPAGE.fnEnter,			dw	MainMenu_EnterMenuOrModifyItemVisibility
	at	MENUPAGE.fnBack,			dw	ExitToDos
	at	MENUPAGE.wMenuitems,		dw	6
iend

g_MenuitemMainMenuExitToDos:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	ExitToDos
	at	MENUITEM.szName,			dw	g_szItemMainExitToDOS
	at	MENUITEM.szQuickInfo,		dw	g_szNfoMainExitToDOS
	at	MENUITEM.szHelp,			dw	g_szNfoMainExitToDOS
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGEBACK
iend

g_MenuitemMainMenuLoadBiosFromFile:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	LoadBiosFromFile
	at	MENUITEM.szName,			dw	g_szItemMainLoadFile
	at	MENUITEM.szQuickInfo,		dw	g_szNfoMainLoadFile
	at	MENUITEM.szHelp,			dw	g_szNfoMainLoadFile
	at	MENUITEM.bFlags,			db	FLG_MENUITEM_VISIBLE
	at	MENUITEM.bType,				db	TYPE_MENUITEM_ACTION
iend

g_MenuitemMainMenuLoadXtideUniversalBiosFromRom:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	LoadXtideUniversalBiosFromRom
	at	MENUITEM.szName,			dw	g_szItemMainLoadROM
	at	MENUITEM.szQuickInfo,		dw	g_szNfoMainLoadROM
	at	MENUITEM.szHelp,			dw	g_szNfoMainLoadROM
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_ACTION
iend

g_MenuitemMainMenuLoadOldSettingsFromEeprom:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	LoadOldSettingsFromEeprom
	at	MENUITEM.szName,			dw	g_szItemMainLoadStngs
	at	MENUITEM.szQuickInfo,		dw	g_szNfoMainLoadStngs
	at	MENUITEM.szHelp,			dw	g_szNfoMainLoadStngs
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_ACTION
iend

g_MenuitemMainMenuConfigureXtideUniversalBios:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	ConfigurationMenu_EnterMenuOrModifyItemVisibility
	at	MENUITEM.szName,			dw	g_szItemMainConfigure
	at	MENUITEM.szQuickInfo,		dw	g_szNfoMainConfigure
	at	MENUITEM.szHelp,			dw	g_szNfoMainConfigure
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGENEXT
iend

g_MenuitemMainMenuFlashEeprom:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	FlashMenu_EnterMenuOrModifyItemVisibility
	at	MENUITEM.szName,			dw	g_szItemMainFlash
	at	MENUITEM.szQuickInfo,		dw	g_szNfoMainFlash
	at	MENUITEM.szHelp,			dw	g_szNfoMainFlash
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	TYPE_MENUITEM_PAGENEXT
iend

%if FALSE
g_Menuitem:
istruc MENUITEM
	at	MENUITEM.fnActivate,		dw	NULL
	at	MENUITEM.fnFormatValue,		dw	NULL
	at	MENUITEM.szName,			dw	NULL
	at	MENUITEM.szQuickInfo,		dw	NULL
	at	MENUITEM.szHelp,			dw	NULL
	at	MENUITEM.bFlags,			db	NULL
	at	MENUITEM.bType,				db	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.wRomvarsValueOffset,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szDialogTitle,				dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.szMultichoise,				dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.rgwChoiseToValueLookup,		dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.rgszValueToStringLookup,	dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.wMinValue,					dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.wMaxValue,					dw	NULL
	at	MENUITEM.itemValue + ITEM_VALUE.wValueBitmask,				dw	NULL
iend
%endif


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MainMenu_EnterMenuOrModifyItemVisibility
;	Parameters:
;		SS:BP:	Menu handle
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MainMenu_EnterMenuOrModifyItemVisibility:
	push	cs
	pop		ds
	call	.EnableOrDisableXtideRomItems
	call	.EnableOrDisableConfigureXtideUniversalBios
	call	.EnableOrDisableFlashEeprom
	mov		si, g_MenupageForMainMenu
	jmp		Menupage_ChangeToNewMenupageInDSSI

;--------------------------------------------------------------------
; .EnableOrDisableXtideRomItems
;	Parameters:
;		DS:		CFGVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableXtideRomItems:
	call	EEPROM_FindXtideUniversalBiosROMtoESDI
	jnc		SHORT .DisableAllRomItems
	or		BYTE [g_MenuitemMainMenuLoadXtideUniversalBiosFromRom+MENUITEM.bFlags], FLG_MENUITEM_VISIBLE
	call	Buffers_IsXtideUniversalBiosLoaded
	jne		SHORT .DisableLoadSettingFromRom
	or		BYTE [g_MenuitemMainMenuLoadOldSettingsFromEeprom+MENUITEM.bFlags], FLG_MENUITEM_VISIBLE
	ret

ALIGN JUMP_ALIGN
.DisableAllRomItems:
	and		BYTE [g_MenuitemMainMenuLoadXtideUniversalBiosFromRom+MENUITEM.bFlags], ~FLG_MENUITEM_VISIBLE
.DisableLoadSettingFromRom:
	and		BYTE [g_MenuitemMainMenuLoadOldSettingsFromEeprom+MENUITEM.bFlags], ~FLG_MENUITEM_VISIBLE
	ret

;--------------------------------------------------------------------
; .EnableOrDisableConfigureXtideUniversalBios
;	Parameters:
;		DS:		CFGVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		CX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableConfigureXtideUniversalBios:
	call	Buffers_IsXtideUniversalBiosLoaded
	jne		SHORT .DisableConfigureXtideUniversalBios
	or		BYTE [g_MenuitemMainMenuConfigureXtideUniversalBios+MENUITEM.bFlags], FLG_MENUITEM_VISIBLE
	ret

ALIGN JUMP_ALIGN
.DisableConfigureXtideUniversalBios:
	and		BYTE [g_MenuitemMainMenuConfigureXtideUniversalBios+MENUITEM.bFlags], ~FLG_MENUITEM_VISIBLE
	ret

;--------------------------------------------------------------------
; .EnableOrDisableFlashEeprom
;	Parameters:
;		DS:		CFGVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EnableOrDisableFlashEeprom:
	test	WORD [g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_FILELOADED | FLG_CFGVARS_ROMLOADED
	jz		SHORT .DisableFlashEeprom
	or		BYTE [g_MenuitemMainMenuFlashEeprom+MENUITEM.bFlags], FLG_MENUITEM_VISIBLE
	ret

ALIGN JUMP_ALIGN
.DisableFlashEeprom:
	and		BYTE [g_MenuitemMainMenuFlashEeprom+MENUITEM.bFlags], ~FLG_MENUITEM_VISIBLE
	ret



;--------------------------------------------------------------------
; MENUITEM activation functions (.fnActivate)
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except segments
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ExitToDos:
	CALL_MENU_LIBRARY Close
	ret


ALIGN JUMP_ALIGN
LoadBiosFromFile:
	call	Buffers_SaveChangesIfFileLoaded
	mov		cx, FILE_DIALOG_IO_size
	call	Memory_ReserveCXbytesFromStackToDSSI
	call	Dialogs_DisplayFileDialogWithDialogIoInDSSI
	cmp		BYTE [si+FILE_DIALOG_IO.bUserCancellation], TRUE
	je		SHORT .CancelFileLoading

	add		si, BYTE FILE_DIALOG_IO.szFile
	call	BiosFile_LoadFileFromDSSItoRamBuffer
	call	MainMenu_EnterMenuOrModifyItemVisibility
.CancelFileLoading:
	add		sp, BYTE FILE_DIALOG_IO_size
	ret


ALIGN JUMP_ALIGN
LoadXtideUniversalBiosFromRom:
	call	Buffers_SaveChangesIfFileLoaded
	call	EEPROM_LoadXtideUniversalBiosFromRomToRamBuffer
	mov		ax, FLG_CFGVARS_ROMLOADED
	call	Buffers_NewBiosWithSizeInCXandSourceInAXhasBeenLoadedForConfiguration
	push	cs
	pop		ds
	mov		si, g_szDlgMainLoadROM
	CALL_MENU_LIBRARY DisplayMessageWithInputInDSSI
	ret


ALIGN JUMP_ALIGN
LoadOldSettingsFromEeprom:
	call	Buffers_SaveChangesIfFileLoaded
	call	EEPROM_LoadOldSettingsFromRomToRamBuffer
	and		WORD [g_cfgVars+CFGVARS.wFlags], ~FLG_CFGVARS_UNSAVED
	push	cs
	pop		ds
	mov		si, g_szDlgMainLoadStngs
	CALL_MENU_LIBRARY DisplayMessageWithInputInDSSI
	ret
