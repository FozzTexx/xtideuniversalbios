; Project name	:	XTIDE Univeral BIOS Configurator
; Description	:	Functions to access MENUPAGEITEM structs.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Prints MenuPageItem information string to bottom of menu window.
;
; MenuPageItem_PrintInfo
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_PrintInfo:
	push	cs
	pop		es
	eMOVZX	cx, BYTE [bp+MENUVARS.bInfoH]	; Info line count to CX
	call	MenuPageItem_PrintCommonInfoLines
	mov		di, [di+MENUPAGEITEM.szInfo]	; ES:DI now points to info string
	jmp		MenuDraw_MultilineStr

;--------------------------------------------------------------------
; Prints information lines that are common for all menuitems.
;
; MenuPageItem_PrintCommonInfoLines
;	Parameters:
;		ES:		String segment
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_PrintCommonInfoLines:
	push	di
	push	cx
	mov		di, g_szCommonInfo		; ES:DI now points common info string
	call	MenuDraw_MultilineStr	; Draw title string
	call	MenuDraw_NewlineStr		; Next line
	call	MenuDraw_NewlineStr		; Next line
	pop		cx
	pop		di
	ret


;--------------------------------------------------------------------
; Displays MenuPageItem help dialog.
;
; MenuPageItem_DisplayHelpDialog
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_DisplayHelpDialog:
	push	cs
	pop		es
	mov		di, [di+MENUPAGEITEM.szHelp]	; ES:DI now points to help string
	mov		bl, WIDTH_DLG					; Dialog width
	jmp		Menu_ShowMsgDlg


;--------------------------------------------------------------------
; Displays message for special function menupageitem.
;
; MenuPageItem_DisplaySpecialFunctionDialog
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_DisplaySpecialFunctionDialog:
	push	es
	push	di
	push	cx

	mov		di, [di+MENUPAGEITEM.szDialog]
	push	cs
	pop		es
	mov		bl, WIDTH_DLG					; Dialog width
	call	Menu_ShowMsgDlg

	pop		cx
	pop		di
	pop		es
	ret


;--------------------------------------------------------------------
; Asks unsigned byte from user.
;
; MenuPageItem_GetByteFromUser
; MenuPageItem_GetByteFromUserWithoutMarkingUnsaved
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if user data inputted succesfully
;				Cleared if cancel
;	Corrupts registers:
;		AX, BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_GetByteFromUser:
	call	MenuPageItem_GetByteFromUserWithoutMarkingUnsaved
	jc		SHORT MenuPageItem_MarkSettingsAsUnsaved
	ret
ALIGN JUMP_ALIGN
MenuPageItem_GetByteFromUserWithoutMarkingUnsaved:
	mov		cx, 10								; Numeric base
	mov		bx, [di+MENUPAGEITEM.szDialog]		; Dialog string
	call	MenuPageItem_ShowWordDialog
	jnc		SHORT .Return						; Return if cancel

	; Limit to min or max and store value
	MAX_U	ax, [di+MENUPAGEITEM.wValueMin]
	MIN_U	ax, [di+MENUPAGEITEM.wValueMax]
	mov		bx, [di+MENUPAGEITEM.pValue]
	mov		[bx], al
	stc
.Return:
	ret


;--------------------------------------------------------------------
; Asks unsigned word from user.
;
; MenuPageItem_GetWordFromUser
; MenuPageItem_GetWordFromUserWithoutMarkingUnsaved
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if user data inputted succesfully
;				Cleared if cancel
;	Corrupts registers:
;		AX, BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_GetWordFromUser:
	call	MenuPageItem_GetWordFromUserWithoutMarkingUnsaved
	jc		SHORT MenuPageItem_MarkSettingsAsUnsaved
	ret
ALIGN JUMP_ALIGN
MenuPageItem_GetWordFromUserWithoutMarkingUnsaved:
	mov		cx, 10								; Numeric base
	mov		bx, [di+MENUPAGEITEM.szDialog]		; Dialog string
	call	MenuPageItem_ShowWordDialog
	jnc		SHORT .Return						; Return if cancel

	; Limit to min or max and store value
	MAX_U	ax, [di+MENUPAGEITEM.wValueMin]
	MIN_U	ax, [di+MENUPAGEITEM.wValueMax]
	mov		bx, [di+MENUPAGEITEM.pValue]
	mov		[bx], ax
	stc
.Return:
	ret


;--------------------------------------------------------------------
; Asks hexadecimal byte from user.
;
; MenuPageItem_GetHexByteFromUser
; MenuPageItem_GetHexByteFromUserWithoutMarkingUnsaved
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if user data inputted succesfully
;				Cleared if cancel
;	Corrupts registers:
;		AX, BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_GetHexByteFromUser:
	call	MenuPageItem_GetHexByteFromUserWithoutMarkingUnsaved
	jc		SHORT MenuPageItem_MarkSettingsAsUnsaved
	ret
ALIGN JUMP_ALIGN
MenuPageItem_GetHexByteFromUserWithoutMarkingUnsaved:
	mov		cx, 16								; Numeric base
	mov		bx, [di+MENUPAGEITEM.szDialog]		; Dialog string
	call	MenuPageItem_ShowWordDialog
	jnc		SHORT .Return						; Return if cancel

	; Store value
	mov		bx, [di+MENUPAGEITEM.pValue]
	mov		[bx], al
.Return:
	ret


;--------------------------------------------------------------------
; Asks hexadecimal word from user.
;
; MenuPageItem_GetHexWordFromUser
; MenuPageItem_GetHexWordFromUserWithoutMarkingUnsaved
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if user data inputted succesfully
;				Cleared if cancel
;	Corrupts registers:
;		AX, BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_GetHexWordFromUser:
	call	MenuPageItem_GetHexWordFromUserWithoutMarkingUnsaved
	jc		SHORT MenuPageItem_MarkSettingsAsUnsaved
	ret
ALIGN JUMP_ALIGN
MenuPageItem_GetHexWordFromUserWithoutMarkingUnsaved:
	mov		cx, 16								; Numeric base
	mov		bx, [di+MENUPAGEITEM.szDialog]		; Dialog string
	call	MenuPageItem_ShowWordDialog
	jnc		SHORT .Return						; Return if cancel

	; Store value
	mov		bx, [di+MENUPAGEITEM.pValue]
	mov		[bx], ax
.Return:
	ret


;--------------------------------------------------------------------
; Called when any BIOS setting is modified.
;
; MenuPageItem_MarkSettingsAsUnsaved
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set since user data inputted succesfully
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_MarkSettingsAsUnsaved:
	or		WORD [cs:g_cfgVars+CFGVARS.wFlags], FLG_CFGVARS_UNSAVED
	call	FormatTitle_RedrawMenuTitle
	stc
	ret


;--------------------------------------------------------------------
; Shows dialog that asks WORD from user.
;
; MenuPageItem_ShowWordDialog
;	Parameters:
;		CX:		Numberic base (10=dec, 16=hex)
;		DS:BX:	Ptr to dialog string
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		16-bit unsigned word inputted by user
;		CF:		Set if user data inputted succesfully
;				Cleared if cancel
;	Corrupts registers:
;		BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_ShowWordDialog:
	push	di

	push	cs
	pop		es
	mov		di, bx				; Dialog string now in ES:DI
	mov		bl, WIDTH_DLG		; Dialog width
	call	Menu_ShowDWDlg

	pop		di
	ret


;--------------------------------------------------------------------
; Asks boolean value (Y/N) from user.
;
; MenuPageItem_GetBoolFromUser
; MenuPageItem_GetBoolFromUserWithoutMarkingUnsaved
;	Parameters:
;		DS:DI:	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if user data inputted succesfully
;				Cleared if cancel
;	Corrupts registers:
;		AX, BX, CX, DX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuPageItem_GetBoolFromUser:
	call	MenuPageItem_GetBoolFromUserWithoutMarkingUnsaved
	jc		SHORT MenuPageItem_MarkSettingsAsUnsaved
	ret
ALIGN JUMP_ALIGN
MenuPageItem_GetBoolFromUserWithoutMarkingUnsaved:
	push	di
	push	cs
	pop		es
	mov		di, [di+MENUPAGEITEM.szDialog]		; Dialog string
	mov		bl, WIDTH_DLG						; Dialog width
	call	Menu_ShowYNDlg
	pop		di
	jz		SHORT .Cancelled					; Return if cancelled
	mov		bx, [di+MENUPAGEITEM.pValue]
	mov		ax, [di+MENUPAGEITEM.wValueMask]
	jc		SHORT .UserSelectedY

	; User selected 'N'
	not		ax
	and		[bx], ax
	stc
	ret
ALIGN JUMP_ALIGN
.UserSelectedY:
	or		[bx], ax
	stc
	ret
.Cancelled:
	clc
	ret


;--------------------------------------------------------------------
; Activates new submenu for getting lookup value selected by user.
;
; MainPageItem_ActivateSubmenuForGettingLookupValue
; MainPageItem_ActivateSubmenuForGettingLookupValueWithoutMarkingUnsaved
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
MainPageItem_ActivateSubmenuForGettingLookupValue:
	call	MainPageItem_ActivateSubmenuForGettingLookupValueWithoutMarkingUnsaved
	jc		SHORT MenuPageItem_MarkSettingsAsUnsaved
	ret
ALIGN JUMP_ALIGN
MainPageItem_ActivateSubmenuForGettingLookupValueWithoutMarkingUnsaved:
	call	MainPageItem_ActivateSubmenu
	test	cx, cx								; Clears CF
	js		SHORT .Return						; User cancellation
	push	si
	mov		si, [di+MENUPAGEITEM.pSubMenuPage]	; DS:SI points to value MENUPAGE
	mov		bx, [si+MENUPAGE.prgbItemToVal]		; Load offset to lookup table
	add		bx, cx								; Add menuitem index
	mov		al, [bx]							; Load value
	mov		bx, [di+MENUPAGEITEM.pValue]		; Load pointer to value
	mov		[bx], al							; Store value
	pop		si
	stc											; Changes so redraw
.Return:
	ret


;--------------------------------------------------------------------
; Activates new submenu.
;
; MainPageItem_ActivateSubmenu
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CX:		Index of last pointed Menuitem (not necessary selected with ENTER)
;				FFFFh if cancelled with ESC
;		CF:		Set if menuitem changed
;				Cleared if no changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MainPageItem_ActivateSubmenu:
	push	di
	push	si
	mov		si, [di+MENUPAGEITEM.pSubMenuPage]	; DS:SI points to new MENUPAGE
	call	Main_EnterMenu
	call	Menu_RefreshMenu
	pop		si
	pop		di
	clc
	ret


;--------------------------------------------------------------------
; Leaves submenu.
;
; MainPageItem_ActivateLeaveSubmenu
;	Parameters:
; 		DS:SI 	Ptr to MENUPAGE
;		DS:DI	Ptr to MENUPAGEITEM
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Cleared since no need to redraw
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MainPageItem_ActivateLeaveSubmenu:
	call	Menu_Exit
	clc
	ret
