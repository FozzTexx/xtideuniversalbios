; Project name	:	XTIDE Universal BIOS Configurator
; Description	:	Menu for configuring IDEVARS.

; Section containing initialized data
SECTION .data

; -Back to previous menu
; +Master Drive
; +Slave Drive
; Command Block (base port) address (01F0h)
; Control Block address (03F0h)
; Bus type (16-bit)
; Enable Interrupt (Y)
; IRQ (14)

ALIGN WORD_ALIGN
g_MenuPageIdeVars:
istruc MENUPAGE
	at	MENUPAGE.bItemCnt,			db	8
iend
istruc MENUPAGEITEM	; Back to previous menu
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szPreviousMenu
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoIdeBack
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoIdeBack
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
g_MenuPageItemIdeMaster:
istruc MENUPAGEITEM	; Master Drive
	at	MENUPAGEITEM.fnActivate,	dw	IdeControllerMenu_ActivateMasterOrSlaveMenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageDrvParams
	at	MENUPAGEITEM.szName,		dw	g_szItemIdeMaster
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoIdeMaster
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoIdeMaster
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
g_MenuPageItemIdeSlave:
istruc MENUPAGEITEM	; Slave Drive
	at	MENUPAGEITEM.fnActivate,	dw	IdeControllerMenu_ActivateMasterOrSlaveMenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageDrvParams
	at	MENUPAGEITEM.szName,		dw	g_szItemIdeSlave
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoIdeSlave
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoIdeSlave
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
g_MenuPageItemIdeBusType:
istruc MENUPAGEITEM	; Bus type
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateSubmenuForGettingLookupValue
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_LookupString
	at	MENUPAGEITEM.pSubMenuPage,	dw	g_MenuPageBusType
	at	MENUPAGEITEM.rgszLookup,	dw	g_rgszBusTypeValueToString
	at	MENUPAGEITEM.szName,		dw	g_szItemIdeBusType
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoIdeBusType
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoIdeBusType
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_NEXT
iend
g_MenuPageItemIdeCmdPort:
istruc MENUPAGEITEM	; Command Block (base port) address
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetHexWordFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemIdeCmdPort
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoIdeCmdPort
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpIdeCmdPort
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgIdeCmdPort
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_HEX_WORD
iend
g_MenuPageItemIdeCtrlPort:
istruc MENUPAGEITEM	; Control Block address (03F0h)
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetHexWordFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szItemIdeCtrlPort
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoIdeCtrlPort
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpIdeCtrlPort
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgIdeCtrlPort
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_HEX_WORD
iend
g_MenuPageItemIdeEnIRQ:
istruc MENUPAGEITEM	; Enable interrupt
	at	MENUPAGEITEM.fnActivate,	dw	IdeControllerMenu_ActivateEnableInterrupt
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.wValueMask,	dw	000Fh
	at	MENUPAGEITEM.szName,		dw	g_szItemIdeEnIRQ
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoIdeEnIRQ
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpIdeEnIRQ
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgIdeEnIRQ
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_FLAG
iend
g_MenuPageItemIdeIRQ:
istruc MENUPAGEITEM	; IRQ
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetByteFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.wValueMin,		dw	2
	at	MENUPAGEITEM.wValueMax,		dw	15
	at	MENUPAGEITEM.szName,		dw	g_szItemIdeIRQ
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoIdeIRQ
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpIdeIRQ
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgIdeIRQ
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_UNSIGNED_BYTE
iend


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Stores IDEVARS specific pointers to IDE Controller Menu
; MENUPAGEITEM structs.
;
; IdeControllerMenu_SetIdevarsOffset
;	Parameters:
;		AX:		Offset to IDEVARS
;		DS:		CS
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeControllerMenu_SetIdevarsOffset:
	eMOVZX	cx, [g_MenuPageIdeVars+MENUPAGE.bItemCnt]
	dec		cx
	mov		bx, g_MenuPageItemIdeMaster+MENUPAGEITEM.pValue
ALIGN JUMP_ALIGN
.StoreIdevarsLoop:
	mov		[bx], ax
	add		bx, MENUPAGEITEM_size
	loop	.StoreIdevarsLoop

	; Add offsets to values
	add		WORD [g_MenuPageItemIdeMaster+MENUPAGEITEM.pValue], BYTE IDEVARS.drvParamsMaster
	add		WORD [g_MenuPageItemIdeSlave+MENUPAGEITEM.pValue], BYTE IDEVARS.drvParamsSlave
	add		WORD [g_MenuPageItemIdeBusType+MENUPAGEITEM.pValue], BYTE IDEVARS.bBusType
	add		WORD [g_MenuPageItemIdeCmdPort+MENUPAGEITEM.pValue], BYTE IDEVARS.wPort
	add		WORD [g_MenuPageItemIdeCtrlPort+MENUPAGEITEM.pValue], BYTE IDEVARS.wPortCtrl
	add		WORD [g_MenuPageItemIdeEnIRQ+MENUPAGEITEM.pValue], BYTE IDEVARS.bIRQ
	add		WORD [g_MenuPageItemIdeIRQ+MENUPAGEITEM.pValue], BYTE IDEVARS.bIRQ
	ret


;--------------------------------------------------------------------
; IdeControllerMenu_ActivateMasterOrSlaveMenu
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
IdeControllerMenu_ActivateMasterOrSlaveMenu:
	mov		ax, [di+MENUPAGEITEM.pValue]	; AX=Offset to DRVPARAMS
	call	DrvParamsMenu_SetDrvParamsOffset
	call	DrvParamsMenu_SetMenuitemVisibility
	jmp		MainPageItem_ActivateSubmenu


;--------------------------------------------------------------------
; IdeControllerMenu_ActivateEnableInterrupt
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
IdeControllerMenu_ActivateEnableInterrupt:
	call	MenuPageItem_GetBoolFromUser
	jc		SHORT IdeControllerMenu_SetMenuitemVisibilityAndDrawChanges
	ret


;--------------------------------------------------------------------
; IdeControllerMenu_SetMenuitemVisibilityAndDrawChanges
;	Parameters:
;		DS:SI:	Ptr to MENUPAGE
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Cleared since no need to draw changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeControllerMenu_SetMenuitemVisibilityAndDrawChanges:
	call	IdeControllerMenu_SetMenuitemVisibility
	call	MenuPage_InvalidateItemCount
	clc		; No need to redraw Full Mode menuitem
	ret

;--------------------------------------------------------------------
; Enables or disables menuitems based on current configuration.
;
; IdeControllerMenu_SetMenuitemVisibility
;	Parameters:
;		DS:		CS
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeControllerMenu_SetMenuitemVisibility:
	jmp		SHORT IdeControllerMenu_EnableOrDisableIrqSelect

ALIGN JUMP_ALIGN
IdeControllerMenu_EnableOrDisableIrqSelect:
	mov		bx, [g_MenuPageItemIdeIRQ+MENUPAGEITEM.pValue]
	cmp		BYTE [bx], 0				; Interrupts disabled?
	je		SHORT .DisableIrqMenuitem
	or		BYTE [g_MenuPageItemIdeIRQ+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
	ret
ALIGN JUMP_ALIGN
.DisableIrqMenuitem:
	and		BYTE [g_MenuPageItemIdeIRQ+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	ret
