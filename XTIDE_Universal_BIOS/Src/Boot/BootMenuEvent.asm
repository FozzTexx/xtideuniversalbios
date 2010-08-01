; File name		:	BootMenuEvent.asm
; Project name	:	IDE BIOS
; Created date	:	26.3.2010
; Last update	:	1.4.2010
; Author		:	Tomi Tilli
; Description	:	Boot Menu event handler for menu library callbacks.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Boot Menu event handler.
;
; BootMenuEvent_Handler
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
BootMenuEvent_Handler:
	push	es
	push	ds
	push	di
	push	si

	xor		ax, ax									; Event not processed
	cmp		bx, BYTE EVNT_MNU_GETDEF				; Event in jump table?
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
	dw		BootMenuEvent_Exit						; 0, EVNT_MNU_EXIT (Menu will quit)
	dw		BootMenuEvent_EventItemSelectionChanged	; 1, EVNT_MMU_SELCHG (Menuitem selection changed (with arrows))
	dw		BootMenuEvent_EventItemSelected			; 2, EVNT_MNU_SELSET (Menuitem selected (with Enter))
	dw		BootMenuEvent_EventKeyPressed			; 3, EVNT_MNU_KEY (Keyboard key pressed)
	dw		BootMenuEvent_EventMenuDraw				; 4, EVNT_MNU_UPD (Menu needs to be updated)
	dw		BootMenuEvent_EventGetDefaultMenuitem	; 5, EVNT_MNU_GETDEF (Request menuitem to be selected by default)


;--------------------------------------------------------------------
; Boot Menu event handler.
; Handles Menu Exit notification (EVNT_MNU_EXIT).
;
; BootMenuEvent_Exit
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
BootMenuEvent_Exit:
	mov		ax, 1					; Event handled
	ret


;--------------------------------------------------------------------
; Boot Menu event handler.
; Handles Menuitem Selection Changed notification (EVNT_MMU_SELCHG).
;
; BootMenuEvent_EventItemSelectionChanged
;	Parameters:
;		CX:		Index of selected Menuitem
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		1 = Event processed
;	Corrupts registers:
;		BX, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuEvent_EventItemSelectionChanged:
	call	RamVars_GetSegmentToDS
	call	DriveXlate_Reset
	call	BootMenu_ConvertMenuitemToDriveOrFunction
	jc		SHORT BootMenuEvent_UpdateAllMenuitems	; Selection changed to a function
	call	DriveXlate_SetDriveToSwap
	; Fall to BootMenuEvent_UpdateAllMenuitems

;--------------------------------------------------------------------
; Redraws all menuitems.
;
; BootMenuEvent_UpdateAllMenuitems
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		1 = Event processed
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuEvent_UpdateAllMenuitems:
	mov		cx, -1					; Update all items
	mov		dl, MFL_UPD_ITEM | MFL_UPD_NFO | MFL_UPD_NOCLEAR
	call	Menu_Invalidate
	mov		ax, 1					; Event handled
	ret


;--------------------------------------------------------------------
; Boot Menu event handler.
; Handles Menuitem Selected notification (EVNT_MNU_SELSET).
;
; BootMenuEvent_EventItemSelected
;	Parameters:
;		CX:		Index of selected Menuitem
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		1 = Event processed
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuEvent_EventItemSelected:
	call	Menu_Exit				; Exit from menu
	mov		ax, 1					; Event handled
	ret


;--------------------------------------------------------------------
; Boot Menu event handler.
; Handles Key pressed notification (EVNT_MNU_KEY).
;
; BootMenuEvent_EventKeyPressed
;	Parameters:
;		CX:		Index of currently selected Menuitem
;		DL:		ASCII character
;		DH:		BIOS Scan Code
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		1 = Event processed
;	Corrupts registers:
;		BX, CX, DX, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuEvent_EventKeyPressed:
	mov		al, dl					; Copy ASCII char to AL
	sub		al, 'a'-'A'				; To upper case character
	cmp		al, 'A'					; First possible drive letter?
	jb		SHORT .Return			;  If below, return
	cmp		al, 'Z'					; Last possible drive letter?
	ja		SHORT .Return			;  If above, return
	LOAD_BDA_SEGMENT_TO	ds, dx
	mov		[BOOTVARS.bMenuHotkey], al
	jmp		SHORT BootMenuEvent_EventItemSelected
.Return:
	mov		ax, 1
	ret


;--------------------------------------------------------------------
; Boot Menu event handler.
; Handles Menu Update notification (EVNT_MNU_UPD).
;
; BootMenuEvent_EventMenuDraw
;	Parameters:
;		CX: 	Index of Menuitem to update (if MFL_UPD_ITEM set)
;		DL:		Update flag (only one):
;					MFL_UPD_TITLE	Update Menu Title string(s)
;					MFL_UPD_NFO		Update Menu Info string(s)
;					MFL_UPD_ITEM	Update Menuitem string
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;	Corrupts registers:
;		BX, CX, DX, SI, DI, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuEvent_EventMenuDraw:
	test	dl, MFL_UPD_ITEM		; Need to update Menuitem?
	jnz		SHORT BootMenuEvent_DrawMenuitem
	test	dl, MFL_UPD_NFO			; Need to update Info String(s)?
	jnz		SHORT BootMenuEvent_DrawInfo
	test	dl, MFL_UPD_TITLE		; Need to update Title String(s)?
	jnz		SHORT BootMenuEvent_DrawTitle
	xor		ax, ax
	ret

;--------------------------------------------------------------------
; Draws Menuitem string. Cursor is set to a menuitem location.
;
; BootMenuEvent_DrawMenuitem
;	Parameters:
;		CX: 	Index of Menuitem to draw
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;	Corrupts registers:
;		BX, CX, DX, SI, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuEvent_DrawMenuitem:
	call	RamVars_GetSegmentToDS
	call	BootMenu_ConvertMenuitemToDriveOrFunction
	jc		SHORT .DrawFunctionItem
	call	BootMenuPrint_TranslatedDriveNumber
	test	dl, 80h					; Floppy drive?
	jz		SHORT .DrawFloppyDriveItem
	jmp		BootMenuPrint_HardDiskMenuitem
ALIGN JUMP_ALIGN
.DrawFunctionItem:
	jmp		BootMenuPrint_FunctionMenuitem
ALIGN JUMP_ALIGN
.DrawFloppyDriveItem:
	jmp		BootMenuPrint_FloppyMenuitem

;--------------------------------------------------------------------
; Draws information strings. Cursor is set to a first information line.
;
; BootMenuEvent_DrawInfo
;	Parameters:
;		CX: 	Index of selected menuitem
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;	Corrupts registers:
;		BX, CX, DX, SI, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuEvent_DrawInfo:
	call	RamVars_GetSegmentToDS
	call	BootMenu_ConvertMenuitemToDriveOrFunction
	jc		SHORT .DrawFunctionInfo
	test	dl, 80h					; Floppy drive?
	jz		SHORT .DrawFloppyDriveInfo
	jmp		BootMenuPrint_HardDiskMenuitemInformation
ALIGN JUMP_ALIGN
.DrawFunctionInfo:
	jmp		BootMenuPrint_FunctionMenuitemInformation
ALIGN JUMP_ALIGN
.DrawFloppyDriveInfo:
	jmp		BootMenuPrint_FloppyMenuitemInformation

;--------------------------------------------------------------------
; Draws title strings. Cursor is set to a first title line.
;
; BootMenuEvent_DrawTitle
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;	Corrupts registers:
;		CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuEvent_DrawTitle:
	jmp		BootMenuPrint_TitleStrings


;--------------------------------------------------------------------
; Boot Menu event handler.
; Handles Get Default Menuitem notification (EVNT_MNU_GETDEF).
;
; BootMenuEvent_EventGetDefaultMenuitem
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AX:		Was event processed
;		CX:		Index of menuitem to set selected
;	Corrupts registers:
;		BX, CX, DX, DI, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuEvent_EventGetDefaultMenuitem:
	call	RamVars_GetSegmentToDS
	mov		dl, [cs:ROMVARS.bBootDrv]	; Default boot drive
	call	BootMenu_IsDriveInSystem
	jnc		SHORT .DoNotSetDefaultMenuitem
	call	DriveXlate_SetDriveToSwap
	call	BootMenu_ConvertDriveToMenuitem
	mov		ax, 1
	ret
ALIGN JUMP_ALIGN
.DoNotSetDefaultMenuitem:
	xor		ax, ax
	ret
