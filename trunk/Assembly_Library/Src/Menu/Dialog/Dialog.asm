; File name		:	Dialog.asm
; Project name	:	Assembly Library
; Created date	:	6.8.2010
; Last update	:	22.11.2010
; Author		:	Tomi Tilli
; Description	:	Common functions for many dialogs.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Dialog_DisplayWithDialogInputInDSSIandHandlerInBX
;	Parameters:
;		BX:		Offset to menu event handler
;		DX:AX:	Optional user data
;		DS:SI:	Ptr to DIALOG_INPUT
;		SS:BP:	Ptr to parent MENU
;	Returns:
;		AX:		Selected item
;	Corrupts registers:
;		BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialog_DisplayWithDialogInputInDSSIandHandlerInBX:
	push	es
	push	ds
	mov		di, bp								; Backup parent MENU
	mov		cx, DIALOG_size
	eENTER_STRUCT cx

	call	Memory_ZeroSSBPwithSizeInCX
	mov		[bp+DIALOG.fpDialogIO], si
	mov		[bp+DIALOG.fpDialogIO+2], ds
	mov		[bp+DIALOG.pParentMenu], di

	call	MenuInit_EnterMenuWithHandlerInBXandUserDataInDXAX
	call	Dialog_RemoveFromScreenByRedrawingParentMenu
	call	Keyboard_RemoveAllKeystrokesFromBuffer

	mov		ax, [bp+MENUINIT.wHighlightedItem]
	eLEAVE_STRUCT DIALOG_size
	pop		ds
	pop		es
	ret


;--------------------------------------------------------------------
; Dialog_EventNotHandled
;	Parameters:
;		BX:		Menu event (anything from MENUEVENT struct)
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		CF:		Cleared since event not processed
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialog_EventNotHandled:
	clc
	ret


;--------------------------------------------------------------------
; Dialog_EventAnyThatClosesDialog
; Dialog_EventExitMenu
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		CF:		Set since event processed
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialog_EventAnyThatClosesDialog:
	call	MenuInit_CloseMenuWindow
ALIGN JUMP_ALIGN
Dialog_EventExitMenu:
	stc
	ret


;--------------------------------------------------------------------
; Dialog_EventInitializeMenuinitFromDSSIforSingleItemWithHighlightedItemInAX
;	Parameters:
;		AX:			Index of highlighted item
;		DS:SI:		Ptr to MENUINIT struct to initialize
;		SS:BP:		Ptr to DIALOG
;	Returns:
;		DS:SI:		Ptr to initialized MENUINIT struct
;		CF:			Set since event processed
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialog_EventInitializeMenuinitFromDSSIforSingleItemWithHighlightedItemInAX:
	les		di, [bp+DIALOG.fpDialogIO]
	mov		WORD [es:di+DIALOG_INPUT.fszItems], g_szSingleItem
	mov		[es:di+DIALOG_INPUT.fszItems+2], cs
	; Fall to Dialog_EventInitializeMenuinitFromDSSIwithHighlightedItemInAX

;--------------------------------------------------------------------
; Dialog_EventInitializeMenuinitFromDSSIwithHighlightedItemInAX
;	Parameters:
;		AX:			Index of highlighted item
;		DS:SI:		Ptr to MENUINIT struct to initialize
;		SS:BP:		Ptr to DIALOG
;	Returns:
;		DS:SI:		Ptr to initialized MENUINIT struct
;		CF:			Set since event processed
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialog_EventInitializeMenuinitFromDSSIwithHighlightedItemInAX:
	mov		[bp+MENUINIT.wHighlightedItem], ax
	les		di, [bp+DIALOG.fpDialogIO]
	call	.GetWidthBasedOnParentMenuToAL
	mov		[bp+MENUINIT.bWidth], al

	lds		si, [es:di+DIALOG_INPUT.fszTitle]
	call	ItemLineSplitter_GetLinesToAXforStringInDSSI
	mov		[bp+MENUINIT.bTitleLines], al

	lds		si, [es:di+DIALOG_INPUT.fszItems]
	call	ItemLineSplitter_GetLinesToAXforStringInDSSI
	mov		[bp+MENUINIT.wItems], ax

	lds		si, [es:di+DIALOG_INPUT.fszInfo]
	call	ItemLineSplitter_GetLinesToAXforStringInDSSI
	mov		[bp+MENUINIT.bInfoLines], al

	call	.GetHeightToAH				; Line counts are required
	mov		[bp+MENUINIT.bHeight], ah
	stc
	ret

;--------------------------------------------------------------------
; .GetWidthBasedOnParentMenuToAL
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		AX:		Width for dialog
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetWidthBasedOnParentMenuToAL:
	mov		bx, [bp+DIALOG.pParentMenu]
	mov		al, [ss:bx+MENUINIT.bWidth]
	sub		al, DIALOG_DELTA_WIDTH_FROM_PARENT
	MIN_U	al, DIALOG_MAX_WIDTH
	ret

;--------------------------------------------------------------------
; .GetHeightToAH
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		AH:		Height for dialog
;	Corrupts registers:
;		AL, BX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetHeightToAH:
	CALL_DISPLAY_LIBRARY GetColumnsToALandRowsToAH
	xchg	bx, ax
	mov		ah, [bp+MENUINIT.bTitleLines]
	add		ah, [bp+MENUINIT.wItems]
	add		ah, [bp+MENUINIT.bInfoLines]
	add		ah, BYTE MENU_VERTICAL_BORDER_LINES
	MIN_U	ah, bh
	MIN_U	ah, DIALOG_MAX_HEIGHT
	ret


;--------------------------------------------------------------------
; Dialog_EventRefreshTitle
; Dialog_EventRefreshInformation
;	Parameters:
;		SS:BP:		Ptr to DIALOG
;	Returns:
;		CF:			Set since event processed
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialog_EventRefreshTitle:
	lds		si, [bp+DIALOG.fpDialogIO]
	lds		si, [si+DIALOG_INPUT.fszTitle]
	jmp		SHORT PrintTitleOrInfoLine

ALIGN JUMP_ALIGN
Dialog_EventRefreshInformation:
	lds		si, [bp+DIALOG.fpDialogIO]
	lds		si, [si+DIALOG_INPUT.fszInfo]
	; Fall to PrintTitleOrInfoLine

ALIGN JUMP_ALIGN
PrintTitleOrInfoLine:
	mov		bx, ds
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromBXSI
	stc
	ret


;--------------------------------------------------------------------
; Dialog_EventRefreshItemFromCX
;	Parameters:
;		CX:			Item to refresh
;		SS:BP:		Ptr to DIALOG
;	Returns:
;		CF:			Set since event processed
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialog_EventRefreshItemFromCX:
	lds		si, [bp+DIALOG.fpDialogIO]
	lds		si, [si+DIALOG_INPUT.fszItems]
	call	ItemLineSplitter_GetLineToDSSIandLengthToCXfromStringInDSSIwithIndexInCX
	jnc		SHORT .LineNotFound

	mov		bx, ds
	CALL_DISPLAY_LIBRARY PrintCharBufferFromBXSIwithLengthInCX
.LineNotFound:
	stc
	ret


;--------------------------------------------------------------------
; Dialog_RemoveFromScreenByRedrawingParentMenu
;	Parameters:
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialog_RemoveFromScreenByRedrawingParentMenu:
	mov		si, [bp+DIALOG.pParentMenu]	; SS:SI points to parent MENU
	call	.GetParentTitleBorderCoordinatesToDX
	call	MenuLocation_GetTitleBordersTopLeftCoordinatesToAX
	cmp		ah, dh		; Dialog taller than parent?
	jb		SHORT .RedrawDialogAreaAndWholeParentWindow
	jmp		SHORT .RedrawWholeParentWindow

;--------------------------------------------------------------------
; .GetParentTitleBorderCoordinatesToDX
;	Parameters:
;		SS:SI:	Ptr to parent MENU
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		DL:		Parent border column (X)
;		DH:		Parent border row (Y)
;	Corrupts:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.GetParentTitleBorderCoordinatesToDX:
	xchg	si, bp
	call	MenuLocation_GetTitleBordersTopLeftCoordinatesToAX
	xchg	bp, si
	xchg	dx, ax
	ret

;--------------------------------------------------------------------
; .RedrawDialogAreaAndWholeParentWindow
; .RedrawWholeParentWindow
;	Parameters:
;		SS:SI:	Ptr to parent MENU
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.RedrawDialogAreaAndWholeParentWindow:
	push	si
	call	MenuBorders_AdjustDisplayContextForDrawingBorders
	pop		si
	mov		al, SCREEN_BACKGROUND_ATTRIBUTE
	CALL_DISPLAY_LIBRARY SetCharacterAttributeFromAL
	mov		ax, [bp+MENUINIT.wWidthAndHeight]
	CALL_DISPLAY_LIBRARY ClearAreaWithHeightInAHandWidthInAL
	; Fall to .RedrawWholeParentWindow

ALIGN JUMP_ALIGN
.RedrawWholeParentWindow:
	push	bp
	mov		bp, si
	call	MenuInit_RefreshMenuWindow
	pop		bp
	ret
