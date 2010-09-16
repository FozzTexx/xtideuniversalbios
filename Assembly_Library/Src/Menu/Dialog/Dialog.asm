; File name		:	Dialog.asm
; Project name	:	Assembly Library
; Created date	:	6.8.2010
; Last update	:	16.9.2010
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
	eENTER_STRUCT DIALOG_size

	mov		cx, DIALOG_size / 2
	call	Memory_ZeroSSBPbyWordsInCX
	mov		[bp+DIALOG.fpDialogIO], si
	mov		[bp+DIALOG.fpDialogIO+2], ds
	mov		[bp+DIALOG.pParentMenu], di

	call	MenuInit_EnterMenuWithHandlerInBXandUserDataInDXAX
	call	Dialog_RemoveFromScreenByRedrawingParentMenu
	call	Keyboard_RemoveAllKeystrokesFromBuffer

	mov		ax, [bp+MENU.wHighlightedItem]
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
	stc
	ret


;--------------------------------------------------------------------
; Dialog_EventInitializeMenuinitFromDSSIforSingleItem
;	Parameters:
;		DS:SI:		Ptr to MENUINIT struct to initialize
;		SS:BP:		Ptr to DIALOG
;	Returns:
;		DS:SI:		Ptr to initialized MENUINIT struct
;		CF:			Set since event processed
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialog_EventInitializeMenuinitFromDSSIforSingleItem:
	les		di, [bp+DIALOG.fpDialogIO]
	mov		WORD [es:di+DIALOG_INPUT.fszItems], g_szSingleItem
	mov		[es:di+DIALOG_INPUT.fszItems+2], cs
	; Fall to Dialog_EventInitializeMenuinitFromDSSI

;--------------------------------------------------------------------
; Dialog_EventInitializeMenuinitFromDSSI
;	Parameters:
;		DS:SI:		Ptr to MENUINIT struct to initialize
;		SS:BP:		Ptr to DIALOG
;	Returns:
;		DS:SI:		Ptr to initialized MENUINIT struct
;		CF:			Set since event processed
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Dialog_EventInitializeMenuinitFromDSSI:
	les		di, [bp+DIALOG.fpDialogIO]
	call	.GetWidthBasedOnParentMenuToAL
	mov		[bp+MENUINIT.bWidth], al

	call	MenuLocation_GetMaxTextLineLengthToAX
	mov		bx, ax
	lds		si, [es:di+DIALOG_INPUT.fszTitle]
	call	LineSplitter_SplitStringFromDSSIwithMaxLineLengthInAXandGetLineCountToAX
	mov		[bp+MENUINIT.bTitleLines], al

	mov		ax, bx
	lds		si, [es:di+DIALOG_INPUT.fszItems]
	call	LineSplitter_SplitStringFromDSSIwithMaxLineLengthInAXandGetLineCountToAX
	mov		[bp+MENUINIT.wItems], ax

	xchg	ax, bx
	lds		si, [es:di+DIALOG_INPUT.fszInfo]
	call	LineSplitter_SplitStringFromDSSIwithMaxLineLengthInAXandGetLineCountToAX
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
	mov		dl, [bp+MENUINIT.bTitleLines]
	lds		si, [bp+DIALOG.fpDialogIO]
	les		di, [si+DIALOG_INPUT.fszTitle]
	jmp		SHORT PrintDLlinesFromESDI

ALIGN JUMP_ALIGN
Dialog_EventRefreshInformation:
	mov		dl, [bp+MENUINIT.bInfoLines]
	lds		si, [bp+DIALOG.fpDialogIO]
	les		di, [si+DIALOG_INPUT.fszInfo]
	; Fall to PrintDLlinesFromESDI

ALIGN JUMP_ALIGN
PrintDLlinesFromESDI:
	xor		cx, cx				; Start from line zero
	mov		dh, cl				; Line count now in DX
ALIGN JUMP_ALIGN
.PrintNextLine:
	call	LineSplitter_PrintLineInCXfromStringInESDI
	push	di
	CALL_DISPLAY_LIBRARY PrintNewlineCharacters
	pop		di
	inc		cx
	dec		dx
	jnz		SHORT .PrintNextLine
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
	les		di, [si+DIALOG_INPUT.fszItems]
	call	LineSplitter_PrintLineInCXfromStringInESDI
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
	call	.ResetSelectionTimeoutFromParentMenuInSSSI
	call	.GetParentTitleBorderCoordinatesToDX
	call	MenuLocation_GetTitleBordersTopLeftCoordinatesToAX
	cmp		ah, dh		; Dialog taller than parent?
	jb		SHORT .RedrawDialogAreaAndWholeParentWindow
	jmp		SHORT .RedrawWholeParentWindow

;--------------------------------------------------------------------
; .ResetSelectionTimeoutFromParentMenuInSSSI
;	Parameters:
;		SS:SI:	Ptr to parent MENU
;	Returns:
;		Nothing
;	Corrupts:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ResetSelectionTimeoutFromParentMenuInSSSI:
	xchg	bp, si
	call	MenuTime_RestartSelectionTimeout	; Restart timeout for parent MENU
	xchg	si, bp
	ret

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
	mov		al, MONO_NORMAL
	CALL_DISPLAY_LIBRARY SetCharacterAttributeFromAL
	call	MenuLocation_GetTitleBordersTopLeftCoordinatesToAX
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
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
