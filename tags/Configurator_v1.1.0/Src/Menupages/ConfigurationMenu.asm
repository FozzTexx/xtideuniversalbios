; File name		:	ConfigurationMenu.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	21.4.2010
; Last update	:	2.5.2010
; Author		:	Tomi Tilli
; Description	:	XTIDE Universal BIOS configuration menu.

; Section containing initialized data
SECTION .data

; -Back to previous menu
; +Primary IDE
; ...
; +Last IDE
; +Boot Menu settings
; Boot loader type (None, Simple, Menu)
; Late Initialization (N)
; Maximize Disk Size (Y)
; Full Operating Mode  (Y)
; KiB to steal from base RAM (1)
; Number of IDE controllers (5)

ALIGN WORD_ALIGN
g_MenuPageCfg:
istruc MENUPAGE
	at	MENUPAGE.bItemCnt,	db	13
iend
istruc MENUPAGEITEM	; Back to previous menu
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szPreviousMenu
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgBack
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoCfgBack
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
g_MenuPageItemCfgIde1:
istruc MENUPAGEITEM	; Primary IDE
	at	MENUPAGEITEM.fnActivate,	dw	ConfigurationMenu_ActivateIdeController
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.ideVars0
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageIdeVars
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgIde1
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgIde
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoCfgIde
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
g_MenuPageItemCfgIde2:
istruc MENUPAGEITEM
	at	MENUPAGEITEM.fnActivate,	dw	ConfigurationMenu_ActivateIdeController
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.ideVars1
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageIdeVars
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgIde2
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgIde
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoCfgIde
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
g_MenuPageItemCfgIde3:
istruc MENUPAGEITEM
	at	MENUPAGEITEM.fnActivate,	dw	ConfigurationMenu_ActivateIdeController
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.ideVars2
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageIdeVars
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgIde3
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgIde
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoCfgIde
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
g_MenuPageItemCfgIde4:
istruc MENUPAGEITEM
	at	MENUPAGEITEM.fnActivate,	dw	ConfigurationMenu_ActivateIdeController
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.ideVars3
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageIdeVars
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgIde4
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgIde
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoCfgIde
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
g_MenuPageItemCfgIde5:
istruc MENUPAGEITEM
	at	MENUPAGEITEM.fnActivate,	dw	ConfigurationMenu_ActivateIdeController
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.ideVars4
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageIdeVars
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgIde5
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgIde
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoCfgIde
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
g_MenuPageItemCfgBootMenu:
istruc MENUPAGEITEM	; Boot menu settings
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageBootMenu
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgBootMenu
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgBootMenu
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoCfgBootMenu
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
istruc MENUPAGEITEM	; Boot Loader type
	at	MENUPAGEITEM.fnActivate,	dw	ConfigurationMenu_ActivateBootLoaderType
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_LookupString
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.bBootLdrType
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageBootLoaderType
	at	MENUPAGEITEM.rgszLookup,	dw	g_rgszBootLoaderValueToString
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgBootLoader
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgBootLoader
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoCfgBootLoader
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
istruc MENUPAGEITEM	; Late initialization
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetBoolFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.wFlags
	at	MENUPAGEITEM.wValueMask,	dw	FLG_ROMVARS_LATE
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgLateInit
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgLateInit
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpCfgLateInit
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgCfgLateInit
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_FLAG
iend
istruc MENUPAGEITEM	; Maximize disk size
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetBoolFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.wFlags
	at	MENUPAGEITEM.wValueMask,	dw	FLG_ROMVARS_MAXSIZE
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgMaxSize
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgMaxSize
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpCfgMaxSize
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgCfgMaxSize
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_FLAG
iend
istruc MENUPAGEITEM	; Full operating mode
	at	MENUPAGEITEM.fnActivate,	dw	ConfigurationMenu_ActivateFullMode
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.wFlags
	at	MENUPAGEITEM.wValueMask,	dw	FLG_ROMVARS_FULLMODE
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgFullMode
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgFullMode
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpCfgFullMode
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgCfgFullMode
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_FLAG
iend
g_MenuPageItemCfgStealRam:
istruc MENUPAGEITEM	; kiB to steal from base RAM
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetByteFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.bStealSize
	at	MENUPAGEITEM.wValueMin,		dw	1
	at	MENUPAGEITEM.wValueMax,		dw	255
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgStealSize
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgStealSize
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpCfgStealSize
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgCfgStealSize
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_UNSIGNED_BYTE
iend
g_MenuPageItemCfgIdeCnt:
istruc MENUPAGEITEM	; Number of IDE controllers
	at	MENUPAGEITEM.fnActivate,	dw	ConfigurationMenu_ActivateControllerCount
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pValue,		dw	g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.bIdeCnt
	at	MENUPAGEITEM.wValueMin,		dw	1
	at	MENUPAGEITEM.wValueMax,		dw	5
	at	MENUPAGEITEM.szName,		dw	g_szItemCfgIdeCnt
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoCfgIdeCnt
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoCfgIdeCnt
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgCfgIdeCnt
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_UNSIGNED_BYTE
iend


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; ConfigurationMenu_ActivateIdeController
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if menuitem changed
;				Cleared if no changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConfigurationMenu_ActivateIdeController:
	mov		ax, [di+MENUPAGEITEM.pValue]	; AX=Offset to IDEVARS
	call	IdeControllerMenu_SetIdevarsOffset
	call	IdeControllerMenu_SetMenuitemVisibility
	jmp		MainPageItem_ActivateSubmenu


;--------------------------------------------------------------------
; ConfigurationMenu_ActivateFullMode
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if menuitem changed
;				Cleared if no changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConfigurationMenu_ActivateFullMode:
	call	MenuPageItem_GetBoolFromUser
	jc		SHORT ConfigurationMenu_SetMenuitemVisibilityAndDrawChanges
	ret


;--------------------------------------------------------------------
; ConfigurationMenu_ActivateControllerCount
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if user data inputted succesfully
;				Cleared if cancel
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConfigurationMenu_ActivateControllerCount:
	call	MenuPageItem_GetByteFromUser
	jc		SHORT ConfigurationMenu_SetMenuitemVisibilityAndDrawChanges
	ret


;--------------------------------------------------------------------
; ConfigurationMenu_ActivateBootLoaderType
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if user data inputted succesfully
;				Cleared if cancel
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConfigurationMenu_ActivateBootLoaderType:
	call	MainPageItem_ActivateSubmenuForGettingLookupValue
	jc		SHORT ConfigurationMenu_SetMenuitemVisibilityAndDrawChanges
	ret


;--------------------------------------------------------------------
; ConfigurationMenu_SetMenuitemVisibilityAndDrawChanges
;	Parameters:
;		DS:SI:	Ptr to MENUPAGE
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Cleared since no need to draw changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConfigurationMenu_SetMenuitemVisibilityAndDrawChanges:
	call	ConfigurationMenu_SetMenuitemVisibility
	call	MenuPage_InvalidateItemCount
	clc		; No need to redraw Full Mode menuitem
	ret


;--------------------------------------------------------------------
; Enables or disables menuitems based on current configuration.
;
; ConfigurationMenu_SetMenuitemVisibility
;	Parameters:
;		DS:		CS
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConfigurationMenu_SetMenuitemVisibility:
	call	ConfigurationMenu_SetBootMenuVisibility
	call	ConfigurationMenu_SetFullModeVisibility
	jmp		SHORT ConfigurationMenu_SetControllerCountVisibility

ALIGN JUMP_ALIGN
ConfigurationMenu_SetBootMenuVisibility:
	cmp		BYTE [g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.bBootLdrType], BOOTLOADER_TYPE_MENU
	jne		SHORT .DisableBootMenuSettings
	or		BYTE [g_MenuPageItemCfgBootMenu+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
	ret
ALIGN JUMP_ALIGN
.DisableBootMenuSettings:
	and		BYTE [g_MenuPageItemCfgBootMenu+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	ret

ALIGN JUMP_ALIGN
ConfigurationMenu_SetFullModeVisibility:
	test	WORD [g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .DisableFullModeMenuitems
	or		BYTE [g_MenuPageItemCfgStealRam+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
	or		BYTE [g_MenuPageItemCfgIdeCnt+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
	ret
ALIGN JUMP_ALIGN
.DisableFullModeMenuitems:
	and		BYTE [g_MenuPageItemCfgStealRam+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	and		BYTE [g_MenuPageItemCfgIdeCnt+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	ret

ALIGN JUMP_ALIGN
ConfigurationMenu_SetControllerCountVisibility:
	call	ConfigurationMenu_HideAdditionalIdeControllers
	jmp		SHORT ConfigurationMenu_ShowAdditionalIdeControllers

;--------------------------------------------------------------------
; Hides all additional (not primary) IDE controller menuitems.
;
; ConfigurationMenu_HideAdditionalIdeControllers
;	Parameters:
;		DS:		CS
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConfigurationMenu_HideAdditionalIdeControllers:
	mov		bx, g_MenuPageItemCfgIde2+MENUPAGEITEM.bFlags
	mov		cx, CNT_MAX_CTRLS-1
ALIGN JUMP_ALIGN
.FlagLoop:
	and		BYTE [bx], ~FLG_MENUPAGEITEM_VISIBLE
	add		bx, MENUPAGEITEM_size
	loop	.FlagLoop
	ret

;--------------------------------------------------------------------
; Sets all additional (after primary) IDE controller menuitems visible.
;
; ConfigurationMenu_ShowAdditionalIdeControllers
;	Parameters:
;		DS:		CS
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConfigurationMenu_ShowAdditionalIdeControllers:
	call	ConfigurationMenu_GetNumberOfIdeControllers
	dec		cx					; First always visible
	jcxz	.Return
	mov		bx, g_MenuPageItemCfgIde2+MENUPAGEITEM.bFlags
ALIGN JUMP_ALIGN
.FlagLoop:
	or		BYTE [bx], FLG_MENUPAGEITEM_VISIBLE
	add		bx, MENUPAGEITEM_size
	loop	.FlagLoop
.Return:
	ret

;--------------------------------------------------------------------
; Returns number of IDE controllers to set visible.
;
; ConfigurationMenu_GetNumberOfIdeControllers
;	Parameters:
;		DS:		CS
;	Returns:
;		CX:		Number of selected IDE controllers
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ConfigurationMenu_GetNumberOfIdeControllers:
	test	WORD [g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .ReturnOneControllerForLiteMode
	eMOVZX	cx, BYTE [g_cfgVars+CFGVARS.rgbEepromBuffers+ROMVARS.bIdeCnt]
	ret
ALIGN JUMP_ALIGN
.ReturnOneControllerForLiteMode:
	mov		cx, 1
	ret
