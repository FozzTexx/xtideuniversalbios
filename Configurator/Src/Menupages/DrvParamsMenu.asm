; Project name	:	XTIDE Universal BIOS Configurator
; Description	:	Menu for configuring DRVPARAMS.

; Section containing initialized data
SECTION .data

; -Back to previous menu
; Block Mode Transfers (Y)
; User Specified CHS (Y)
; Cylinders (16383)
; Heads (16)
; Sectors per track (63)

ALIGN WORD_ALIGN
g_MenuPageDrvParams:
istruc MENUPAGE
	at	MENUPAGE.bItemCnt,			db	6
iend
istruc MENUPAGEITEM	; Back to previous menu
	at	MENUPAGEITEM.fnActivate,	dw	MainPageItem_ActivateLeaveSubmenu
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.szName,		dw	g_szPreviousMenu
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoDrvBack
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoDrvBack
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_BACK
iend
g_MenuPageItemDrvBlockMode:
istruc MENUPAGEITEM	; Block Mode Transfers
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetBoolFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.wValueMask,	dw	FLG_DRVPARAMS_BLOCKMODE
	at	MENUPAGEITEM.szName,		dw	g_szItemDrvBlockMode
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoDrvBlockMode
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpDrvBlockMode
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgDrvBlockMode
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_FLAG
iend
g_MenuPageItemDrvUserCHS:
istruc MENUPAGEITEM	; User Specified CHS
	at	MENUPAGEITEM.fnActivate,	dw	DrvParamsMenu_ActivateUserCHS
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.wValueMask,	dw	FLG_DRVPARAMS_USERCHS
	at	MENUPAGEITEM.szName,		dw	g_szItemDrvUserCHS
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoDrvUserCHS
	at	MENUPAGEITEM.szHelp,		dw	g_szHelpDrvUserCHS
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgDrvUserCHS
	at	MENUPAGEITEM.bFlags,		db	FLG_MENUPAGEITEM_VISIBLE
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_FLAG
iend
g_MenuPageItemDrvCyls:
istruc MENUPAGEITEM	; Cylinders
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetWordFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.wValueMin,		dw	1
	at	MENUPAGEITEM.wValueMax,		dw	16383
	at	MENUPAGEITEM.szName,		dw	g_szItemDrvCyls
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoDrvCyls
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoDrvCyls
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgDrvCyls
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_UNSIGNED_WORD
iend
g_MenuPageItemDrvHeads:
istruc MENUPAGEITEM	; Heads
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetByteFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.wValueMin,		dw	1
	at	MENUPAGEITEM.wValueMax,		dw	16
	at	MENUPAGEITEM.szName,		dw	g_szItemDrvHeads
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoDrvHeads
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoDrvHeads
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgDrvHeads
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_UNSIGNED_BYTE
iend
g_MenuPageItemDrvSect:
istruc MENUPAGEITEM	; Sectors per track
	at	MENUPAGEITEM.fnActivate,	dw	MenuPageItem_GetByteFromUser
	at	MENUPAGEITEM.fnNameFormat,	dw	MenuPageItemFormat_NameForAnyType
	at	MENUPAGEITEM.wValueMin,		dw	1
	at	MENUPAGEITEM.wValueMax,		dw	63
	at	MENUPAGEITEM.szName,		dw	g_szItemDrvSect
	at	MENUPAGEITEM.szInfo,		dw	g_szNfoDrvSect
	at	MENUPAGEITEM.szHelp,		dw	g_szNfoDrvSect
	at	MENUPAGEITEM.szDialog,		dw	g_szDlgDrvSect
	at	MENUPAGEITEM.bType,			db	TYPE_MENUPAGEITEM_UNSIGNED_BYTE
iend


; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Stores DRVPARAMS specific pointers to MENUPAGEITEM structs.
;
; DrvParamsMenu_SetDrvParamsOffset
;	Parameters:
;		AX:		Offset to DRVPARAMS
;		DS:		CS
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrvParamsMenu_SetDrvParamsOffset:
	eMOVZX	cx, [g_MenuPageDrvParams+MENUPAGE.bItemCnt]
	dec		cx
	mov		bx, g_MenuPageItemDrvBlockMode+MENUPAGEITEM.pValue
ALIGN JUMP_ALIGN
.StoreIdevarsLoop:
	mov		[bx], ax
	add		bx, MENUPAGEITEM_size
	loop	.StoreIdevarsLoop

	; Add offsets to values
	add		WORD [g_MenuPageItemDrvBlockMode+MENUPAGEITEM.pValue], BYTE DRVPARAMS.wFlags
	add		WORD [g_MenuPageItemDrvUserCHS+MENUPAGEITEM.pValue], BYTE DRVPARAMS.wFlags
	add		WORD [g_MenuPageItemDrvCyls+MENUPAGEITEM.pValue], BYTE DRVPARAMS.wCylinders
	add		WORD [g_MenuPageItemDrvHeads+MENUPAGEITEM.pValue], BYTE DRVPARAMS.bHeads
	add		WORD [g_MenuPageItemDrvSect+MENUPAGEITEM.pValue], BYTE DRVPARAMS.bSect
	ret


;--------------------------------------------------------------------
; DrvParamsMenu_ActivateUserCHS
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
DrvParamsMenu_ActivateUserCHS:
	call	MenuPageItem_GetBoolFromUser
	jc		SHORT DrvParamsMenu_SetMenuitemVisibilityAndDrawChanges
	ret


;--------------------------------------------------------------------
; DrvParamsMenu_SetMenuitemVisibilityAndDrawChanges
;	Parameters:
;		DS:SI:	Ptr to MENUPAGE
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Cleared since no need to draw changes
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrvParamsMenu_SetMenuitemVisibilityAndDrawChanges:
	call	DrvParamsMenu_SetMenuitemVisibility
	call	MenuPage_InvalidateItemCount
	clc		; No need to redraw Full Mode menuitem
	ret

;--------------------------------------------------------------------
; Enables or disables menuitems based on current configuration.
;
; DrvParamsMenu_SetMenuitemVisibility
;	Parameters:
;		DS:		CS
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrvParamsMenu_SetMenuitemVisibility:
	jmp		SHORT DrvParamsMenu_SetChsVisibility

ALIGN JUMP_ALIGN
DrvParamsMenu_SetChsVisibility:
	mov		bx, [g_MenuPageItemDrvUserCHS+MENUPAGEITEM.pValue]
	test	WORD [bx], FLG_DRVPARAMS_USERCHS
	jz		SHORT .DisableUserCHS
	or		BYTE [g_MenuPageItemDrvCyls+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
	or		BYTE [g_MenuPageItemDrvHeads+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
	or		BYTE [g_MenuPageItemDrvSect+MENUPAGEITEM.bFlags], FLG_MENUPAGEITEM_VISIBLE
	ret
ALIGN JUMP_ALIGN
.DisableUserCHS:
	and		BYTE [g_MenuPageItemDrvCyls+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	and		BYTE [g_MenuPageItemDrvHeads+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	and		BYTE [g_MenuPageItemDrvSect+MENUPAGEITEM.bFlags], ~FLG_MENUPAGEITEM_VISIBLE
	ret
