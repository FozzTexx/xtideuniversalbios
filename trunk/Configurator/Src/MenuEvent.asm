; File name		:	MenuEvent.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	16.4.2010
; Last update	:	29.4.2010
; Author		:	Tomi Tilli
; Description	:	Handlers for menu library events.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Main event handler for all incoming events.
;
; MenuEvent_Handler
;	Parameters:
;		BX:		Callback event
;		CX:		Menuitem index (usually index of selected Menuitem)
;		DX:		Event parameter (event specific)
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AH:		Event specific or unused. Set to 0 if unused.
;		AL:		1=Event processed
;				0=Event not processed (default action if any)
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_Handler:
	push	es
	push	ds
	push	di
	push	si

	xor		ax, ax									; Event not processed
	cmp		bx, BYTE EVNT_MNU_INITDONE				; Event in jump table?
	ja		SHORT .Return
	shl		bx, 1
	call	[cs:bx+.rgwEventJmp]
.Return:
	pop		si
	pop		di
	pop		ds
	pop		es
	ret
ALIGN WORD_ALIGN
.rgwEventJmp:
	dw		MenuEvent_Exit						; 0, EVNT_MNU_EXIT (Menu will quit)
	dw		MenuEvent_EventItemSelectionChanged	; 1, EVNT_MMU_SELCHG (Menuitem selection changed (with arrows))
	dw		MenuEvent_EventItemSelected			; 2, EVNT_MNU_SELSET (Menuitem selected (with Enter))
	dw		MenuEvent_EventKeyPressed			; 3, EVNT_MNU_KEY (Keyboard key pressed)
	dw		MenuEvent_EventMenuDraw				; 4, EVNT_MNU_UPD (Menu needs to be updated)
	dw		MenuEvent_EventGetDefaultMenuitem	; 5, EVNT_MNU_GETDEF (Request menuitem to be selected by default)
	dw		MenuEvent_EventMenuInitDone			; 6, EVNT_MNU_INITDONE (Menu has been initialized but not yet drawn)


;--------------------------------------------------------------------
; Handles Menu Exit notification (EVNT_MNU_EXIT).
;
; MenuEvent_Exit
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AH:		1 to cancel exit
;				0 to allow menu exit
;		AL:		1 = Event processed
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_Exit:
	cmp		WORD [bp+MENUVARS.user], g_MenuPageMain	; Exiting main menu?
	je		SHORT .AskUserAboutQuitting
	mov		ax, 1					; Event handled
	ret
ALIGN JUMP_ALIGN
.AskUserAboutQuitting:
	call	BiosFile_SaveUnsavedChanges
	mov		ax, 1					; Event handled
	ret


;--------------------------------------------------------------------
; Handles Menuitem Selection Changed notification (EVNT_MMU_SELCHG).
;
; MenuEvent_EventItemSelectionChanged
;	Parameters:
;		CX:		Index of selected Menuitem
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		1 = Event processed
;	Corrupts registers:
;		BX, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_EventItemSelectionChanged:
	mov		dl, MFL_UPD_NFO
	call	Menu_Invalidate			; Invalidate info message
	mov		ax, 1					; Event handled
	ret


;--------------------------------------------------------------------
; Handles Menuitem Selected notification (EVNT_MNU_SELSET).
;
; MenuEvent_EventItemSelected
;	Parameters:
;		CX:		Index of selected Menuitem
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		1 = Event processed
;	Corrupts registers:
;		BX, CX, DX, SI, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_EventItemSelected:
	lds		si, [bp+MENUVARS.user]					; DS:SI now points to MENUPAGE
	call	MenuPage_GetMenuPageItemForVisibleIndex	; DS:DI now points to MENUPAGEITEM
	jnc		SHORT .Return
	push	cx
	call	[di+MENUPAGEITEM.fnActivate]
	pop		cx
	jnc		SHORT .Return							; No changes
	mov		dl, MFL_UPD_ITEM | MFL_UPD_NOCLEAR
	call	Menu_Invalidate							; Invalidate menuitem
.Return:
	mov		ax, 1									; Event handled
	ret


;--------------------------------------------------------------------
; Handles Key pressed notification (EVNT_MNU_KEY).
;
; MenuEvent_EventKeyPressed
;	Parameters:
;		CX:		Index of currently selected Menuitem
;		DL:		ASCII character
;		DH:		BIOS Scan Code
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		1 = Event processed
;	Corrupts registers:
;		BX, CX, DX, SI, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_EventKeyPressed:
	lds		si, [bp+MENUVARS.user]					; DS:SI now points to MENUPAGE
	call	MenuPage_GetMenuPageItemForVisibleIndex	; DS:DI now points to MENUPAGEITEM
	jnc		SHORT .Return
	call	MenuEventHotkey_Pressed
.Return:
	mov		ax, 1
	ret


;--------------------------------------------------------------------
; Handles Menu Update notification (EVNT_MNU_UPD).
;
; MenuEvent_EventMenuDraw
;	Parameters:
;		CX: 	Index of Menuitem to update (if MFL_UPD_ITEM or MFL_UPD_NFO set)
;		DL:		Update flag (only one):
;					MFL_UPD_TITLE	Update Menu Title string(s)
;					MFL_UPD_NFO		Update Menu Info string(s)
;					MFL_UPD_ITEM	Update Menuitem string
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;	Corrupts registers:
;		BX, CX, DX, SI, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_EventMenuDraw:
	test	dl, MFL_UPD_ITEM		; Need to update Menuitem?
	jnz		SHORT MenuEvent_DrawMenuitem
	test	dl, MFL_UPD_NFO			; Need to update Info String(s)?
	jnz		SHORT MenuEvent_DrawInfo
	test	dl, MFL_UPD_TITLE		; Need to update Title String(s)?
	jnz		SHORT MenuEvent_DrawTitle
	xor		ax, ax
	ret

;--------------------------------------------------------------------
; Draws Menuitem string. Cursor is set to a menuitem location.
;
; MenuEvent_DrawMenuitem
;	Parameters:
;		CX: 	Index of Menuitem to draw
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;	Corrupts registers:
;		BX, CX, DX, SI, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_DrawMenuitem:
	lds		si, [bp+MENUVARS.user]					; DS:SI now points to MENUPAGE
	call	MenuPage_GetMenuPageItemForVisibleIndex	; DS:DI now points to MENUPAGEITEM
	jnc		SHORT .Return
	call	[di+MENUPAGEITEM.fnNameFormat]
.Return:
	mov		ax, 1
	ret

;--------------------------------------------------------------------
; Draws information strings. Cursor is set to a first information line.
;
; MenuEvent_DrawInfo
;	Parameters:
;		CX: 	Index of selected menuitem
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;	Corrupts registers:
;		BX, CX, DX, SI, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_DrawInfo:
	lds		si, [bp+MENUVARS.user]					; DS:SI now points to MENUPAGE
	call	MenuPage_GetMenuPageItemForVisibleIndex	; DS:DI now points to MENUPAGEITEM
	jnc		SHORT .Return
	call	MenuPageItem_PrintInfo
.Return:
	mov		ax, 1
	ret

;--------------------------------------------------------------------
; Draws title strings. Cursor is set to a first title line.
;
; MenuEvent_DrawTitle
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;	Corrupts registers:
;		BX, CX, DX, SI, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_DrawTitle:
	call	FormatTitle_String
	mov		ax, 1
	ret


;--------------------------------------------------------------------
; Handles Get Default Menuitem notification (EVNT_MNU_GETDEF).
;
; MenuEvent_EventGetDefaultMenuitem
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;		CX:		Index of menuitem to set selected
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_EventGetDefaultMenuitem:
	xor		ax, ax		; Not processed, default to menuitem 0
	ret


;--------------------------------------------------------------------
; Handles Menu Initialized notification (EVNT_MNU_INITDONE).
;
; MenuEvent_EventMenuInitDone
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuEvent_EventMenuInitDone:
	mov		ax, 1
	ret
