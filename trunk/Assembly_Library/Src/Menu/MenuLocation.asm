; Project name	:	Assembly Library
; Description	:	Functions for calculation menu window dimensions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuLocation_GetTextCoordinatesToAXforItemInAX
;	Parameters
;		AX:		Item index
;		SS:BP:	Ptr to MENU
;	Returns:
;		AL:		Column (X)
;		AH:		Row (Y)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuLocation_GetTextCoordinatesToAXforItemInAX:
	sub		ax, [bp+MENU.wFirstVisibleItem]		; Item to line
	xchg	al, ah								; Line to AH, clear AL
	add		ax, (MENU_TEXT_ROW_OFFSET<<8) | MENU_TEXT_COLUMN_OFFSET
	SKIP2B	f	; cmp ax, <next instruction>
	; Fall to MenuLocation_GetItemBordersTopLeftCoordinatesToAX

;--------------------------------------------------------------------
; MenuLocation_GetItemBordersTopLeftCoordinatesToAX
; MenuLocation_GetTitleTextTopLeftCoordinatesToAX
; MenuLocation_GetTitleBordersTopLeftCoordinatesToAX
; MenuLocation_GetInformationTextTopLeftCoordinatesToAX
; MenuLocation_GetBottomBordersTopLeftCoordinatesToAX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AL:		Column (X)
;		AH:		Row (Y)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
MenuLocation_GetItemBordersTopLeftCoordinatesToAX:
	xor		ax, ax
	jmp		SHORT AddItemBordersTopLeftCoordinatesToAX

ALIGN MENU_JUMP_ALIGN
MenuLocation_GetTitleTextTopLeftCoordinatesToAX:
	mov		ax, (MENU_TEXT_ROW_OFFSET<<8) | MENU_TEXT_COLUMN_OFFSET
	SKIP2B	f	; cmp ax, <next instruction>
MenuLocation_GetTitleBordersTopLeftCoordinatesToAX:
	xor		ax, ax
	jmp		SHORT MenuLocation_AddTitleBordersTopLeftCoordinatesToAX

ALIGN MENU_JUMP_ALIGN
MenuLocation_GetInformationTextTopLeftCoordinatesToAX:
	mov		ax, (MENU_TEXT_ROW_OFFSET<<8) | MENU_TEXT_COLUMN_OFFSET
	jmp		SHORT AddInformationBordersTopLeftCoordinatesToAX

ALIGN MENU_JUMP_ALIGN
MenuLocation_GetBottomBordersTopLeftCoordinatesToAX:
	xor		ax, ax
	; Fall to .AddBottomBordersTopLeftCoordinatesToAX

;--------------------------------------------------------------------
; .AddBottomBordersTopLeftCoordinatesToAX
; AddInformationBordersTopLeftCoordinatesToAX
; AddItemBordersTopLeftCoordinatesToAX
; MenuLocation_AddTitleBordersTopLeftCoordinatesToAX
;	Parameters
;		AX:		Zero of offset
;		SS:BP:	Ptr to MENU
;	Returns:
;		AL:		Column (X)
;		AH:		Row (Y)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
.AddBottomBordersTopLeftCoordinatesToAX:
	stc							; Compensate for Information top border
	adc		ah, [bp+MENUINIT.bInfoLines]
ALIGN MENU_JUMP_ALIGN
AddInformationBordersTopLeftCoordinatesToAX:
	push	cx
	call	MenuScrollbars_GetMaxVisibleItemsOnPageToCX
	inc		cx					; Compensate for Items top border
	add		ah, cl
	pop		cx
ALIGN MENU_JUMP_ALIGN
AddItemBordersTopLeftCoordinatesToAX:
	stc							; Compensate for Title top border
	adc		ah, [bp+MENUINIT.bTitleLines]
ALIGN MENU_JUMP_ALIGN
MenuLocation_AddTitleBordersTopLeftCoordinatesToAX:
	push	di
	push	ax
	CALL_DISPLAY_LIBRARY GetColumnsToALandRowsToAH
	sub		al, [bp+MENUINIT.bWidth]
	sub		ah, [bp+MENUINIT.bHeight]
	shr		al, 1
	shr		ah, 1
	pop		di					; Old AX to DI
	add		ax, di				; Add old AX to menu top left coordinates
	pop		di
	ret


;--------------------------------------------------------------------
; MenuLocation_GetMaxTextLineLengthToAX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AX:		Maximum text line length in characters
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuLocation_GetMaxTextLineLengthToAX:
	eMOVZX	ax, [bp+MENUINIT.bWidth]
	sub		ax, BYTE MENU_HORIZONTAL_BORDER_LINES + MENU_TEXT_COLUMN_OFFSET
	ret
