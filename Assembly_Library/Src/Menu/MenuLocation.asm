; File name		:	MenuLocation.asm
; Project name	:	Assembly Library
; Created date	:	14.7.2010
; Last update	:	25.11.2010
; Author		:	Tomi Tilli
; Description	:	Functions for calculation menu window dimensions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; MenuLocation_GetScrollbarCoordinatesToAXforItemInAX
;	Parameters
;		AX:		Item index
;		SS:BP:	Ptr to MENU
;	Returns:
;		AL:		Column (X)
;		AH:		Row (Y)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuLocation_GetScrollbarCoordinatesToAXforItemInAX:
	call	MenuLocation_GetTextCoordinatesToAXforItemInAX
	add		al, [bp+MENUINIT.bWidth]
	sub		al, MENU_TEXT_COLUMN_OFFSET*2
	ret


;--------------------------------------------------------------------
; MenuLocation_GetTitleTextTopLeftCoordinatesToAX
; MenuLocation_GetInformationTextTopLeftCoordinatesToAX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AL:		Column (X)
;		AH:		Row (Y)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuLocation_GetTitleTextTopLeftCoordinatesToAX:
	mov		ax, (MENU_TEXT_ROW_OFFSET<<8) | MENU_TEXT_COLUMN_OFFSET
	jmp		SHORT MenuLocation_AddTitleBordersTopLeftCoordinatesToAX

ALIGN JUMP_ALIGN
MenuLocation_GetInformationTextTopLeftCoordinatesToAX:
	mov		ax, (MENU_TEXT_ROW_OFFSET<<8) | MENU_TEXT_COLUMN_OFFSET
	jmp		SHORT AddInformationBordersTopLeftCoordinatesToAX


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
ALIGN JUMP_ALIGN
MenuLocation_GetTextCoordinatesToAXforItemInAX:
	sub		ax, [bp+MENU.wFirstVisibleItem]		; Item to line
	xchg	al, ah								; Line to AH, clear AL
	add		ax, (MENU_TEXT_ROW_OFFSET<<8) | MENU_TEXT_COLUMN_OFFSET
	jmp		SHORT AddItemBordersTopLeftCoordinatesToAX


;--------------------------------------------------------------------
; MenuLocation_GetTitleBordersTopLeftCoordinatesToAX
; MenuLocation_GetItemBordersTopLeftCoordinatesToAX
; MenuLocation_GetInformationBordersTopLeftCoordinatesToAX
; MenuLocation_GetBottomBordersTopLeftCoordinatesToAX
;	Parameters
;		SS:BP:	Ptr to MENU
;	Returns:
;		AL:		Column (X)
;		AH:		Row (Y)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuLocation_GetTitleBordersTopLeftCoordinatesToAX:
	xor		ax, ax
	jmp		SHORT MenuLocation_AddTitleBordersTopLeftCoordinatesToAX

ALIGN JUMP_ALIGN
MenuLocation_GetItemBordersTopLeftCoordinatesToAX:
	xor		ax, ax
	jmp		SHORT AddItemBordersTopLeftCoordinatesToAX

ALIGN JUMP_ALIGN
MenuLocation_GetInformationBordersTopLeftCoordinatesToAX:
	xor		ax, ax
	jmp		SHORT AddInformationBordersTopLeftCoordinatesToAX

ALIGN JUMP_ALIGN
MenuLocation_GetBottomBordersTopLeftCoordinatesToAX:
	xor		ax, ax
	; Fall to AddBottomBordersTopLeftCoordinatesToAX

;--------------------------------------------------------------------
; AddBottomBordersTopLeftCoordinatesToAX
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
ALIGN JUMP_ALIGN
AddBottomBordersTopLeftCoordinatesToAX:
	stc							; Compensate for Information top border
	adc		ah, [bp+MENUINIT.bInfoLines]
ALIGN JUMP_ALIGN
AddInformationBordersTopLeftCoordinatesToAX:
	push	cx
	call	MenuScrollbars_GetMaxVisibleItemsOnPageToCX
	inc		cx					; Compensate for Items top border
	add		ah, cl
	pop		cx
ALIGN JUMP_ALIGN
AddItemBordersTopLeftCoordinatesToAX:
	stc							; Compensate for Title top border
	adc		ah, [bp+MENUINIT.bTitleLines]
ALIGN JUMP_ALIGN
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
ALIGN JUMP_ALIGN
MenuLocation_GetMaxTextLineLengthToAX:
	eMOVZX	ax, BYTE [bp+MENUINIT.bWidth]
	sub		ax, BYTE MENU_HORIZONTAL_BORDER_LINES + MENU_TEXT_COLUMN_OFFSET
	ret


;--------------------------------------------------------------------
; MenuLocation_MoveCursorByALcolumnsAndAHrows
;	Parameters
;		AL:		Number of columns to move
;		AH:		Numver of rows to move
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuLocation_MoveCursorByALcolumnsAndAHrows:
	push	ax
	CALL_DISPLAY_LIBRARY GetSoftwareCoordinatesToAX
	pop		di
	add		ax, di
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	ret
