; Project name	:	Assembly Library
; Description	:	Functions for initializing menu system.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuInit_DisplayMenuWithHandlerInBXandUserDataInDXAX
;	Parameters
;		DX:AX:	User specified data
;		BX:		Menu event handler
;	Returns:
;		AX:		Index of selected item or NO_ITEM_SELECTED
;	Corrupts registers:
;		All except segments
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuInit_DisplayMenuWithHandlerInBXandUserDataInDXAX:
	push	es
	push	ds
	LOAD_BDA_SEGMENT_TO ds, cx, !
	push	WORD [BDA.wVidCurShape]
	mov		cl, MENU_size
	eENTER_STRUCT cx

	call	Memory_ZeroSSBPwithSizeInCX
	call	MenuInit_EnterMenuWithHandlerInBXandUserDataInDXAX
	mov		dx, [bp+MENUINIT.wHighlightedItem]

	eLEAVE_STRUCT MENU_size
	pop		ax
	CALL_DISPLAY_LIBRARY SetCursorShapeFromAX
	xchg	ax, dx			; Return highlighted item in AX
	pop		ds
	pop		es
	ret


;--------------------------------------------------------------------
; MenuInit_EnterMenuWithHandlerInBXandUserDataInDXAX
;	Parameters
;		DX:AX:	User specified data
;		BX:		Menu event handler
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except SS:BP
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuInit_EnterMenuWithHandlerInBXandUserDataInDXAX:
	mov		[bp+MENU.fnEventHandler], bx
	mov		[bp+MENU.dwUserData], ax
	mov		[bp+MENU.dwUserData+2], dx

	mov		ax, CURSOR_HIDDEN
	CALL_DISPLAY_LIBRARY SetCursorShapeFromAX
	call	MenuEvent_InitializeMenuinit	; User initialization
%ifndef USE_186
	call	MenuInit_RefreshMenuWindow
	jmp		MenuLoop_Enter
%else
	push	MenuLoop_Enter
	; Fall to MenuInit_RefreshMenuWindow
%endif


;--------------------------------------------------------------------
; MenuInit_RefreshMenuWindow
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuInit_RefreshMenuWindow:
	call	MenuBorders_RefreshAll			; Draw borders
	call	MenuText_RefreshTitle			; Draw title strings
	call	MenuText_RefreshAllItems		; Draw item strings
	jmp		MenuText_RefreshInformation		; Draw information strings


;--------------------------------------------------------------------
; MenuInit_CloseMenuWindow
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuInit_CloseMenuWindow:
	or		BYTE [bp+MENU.bFlags], FLG_MENU_EXIT
	ret


;--------------------------------------------------------------------
; MenuInit_HighlightItemFromAX
;	Parameters
;		AX:		Item to highlight
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuInit_HighlightItemFromAX:
	sub		ax, [bp+MENUINIT.wHighlightedItem]
	jmp		MenuScrollbars_MoveHighlightedItemByAX

;--------------------------------------------------------------------
; MenuInit_GetHighlightedItemToAX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Index of highlighted item or NO_ITEM_HIGHLIGHTED
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN JUMP_ALIGN
MenuInit_GetHighlightedItemToAX:
	mov		ax, [bp+MENUINIT.wHighlightedItem]
	ret
%endif


;--------------------------------------------------------------------
; MenuInit_SetTitleHeightFromAL
; MenuInit_SetInformationHeightFromAL
; MenuInit_SetTotalItemsFromAX
;	Parameters
;		AX/AL:	Parameter
;		SS:BP:		Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN JUMP_ALIGN
MenuInit_SetTitleHeightFromAL:
	mov		[bp+MENUINIT.bTitleLines], al
	ret

ALIGN JUMP_ALIGN
MenuInit_SetInformationHeightFromAL:
	mov		[bp+MENUINIT.bInfoLines], al
	ret

ALIGN JUMP_ALIGN
MenuInit_SetTotalItemsFromAX:
	mov		[bp+MENUINIT.wItems], ax
	ret
%endif


;--------------------------------------------------------------------
; MenuInit_SetUserDataFromDSSI
; MenuInit_GetUserDataToDSSI
;	Parameters
;		DS:SI:	User data (MenuInit_SetUserDataFromDSSI)
;		SS:BP:	Ptr to MENU
;	Returns:
;		DS:SI:	User data (MenuInit_GetUserDataToDSSI)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN JUMP_ALIGN
MenuInit_SetUserDataFromDSSI:
	mov		[bp+MENU.dwUserData], si
	mov		[bp+MENU.dwUserData+2], ds
	ret

ALIGN JUMP_ALIGN
MenuInit_GetUserDataToDSSI:
	lds		si, [bp+MENU.dwUserData]
	ret
%endif
