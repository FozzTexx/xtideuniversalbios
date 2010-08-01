; File name		:	menucrsr.asm
; Project name	:	Menu library
; Created date	:	10.11.2009
; Last update	:	17.1.2010
; Author		:	Tomi Tilli
; Description	:	ASM library to menu system.
;					Contains menu cursor functions.

;--------------- Equates -----------------------------

W_OFF_CRSR_STR	EQU		0102h	; User string cursor offset


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data


;-------------- Public functions ---------------------
; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Returns X and Y coordinates for menu top left corner.
; This function is used for calculating initial coordinates when
; initializing menu for first time.
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		DL:		X coordinate for centered menu
;		DH:		Y coordinate for centered menu
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCrsr_GetCenter:
	mov		ah, 0Fh						; Get Current Video Mode
	int		10h
	mov		dl, ah						; Copy column count to DL
	sub		dl, [bp+MENUVARS.bWidth]	; Subtract menu width from columns
	shr		dl, 1						; Divide by 2 for start X
	mov		dh, CNT_SCRN_ROW			; Load row count
	sub		dh, [bp+MENUVARS.bHeight]	; Subtract menu height from rows
	shr		dh, 1						; Divide by 2 for start y
	ret


;--------------------------------------------------------------------
; Sets cursor to start of menu string.
; MenuCrsr_Point1stItem		Sets cursor to first menuitem string
; MenuCrsr_PointInfo		Sets cursor to info string
; MenuCrsr_PointTitle		Sets cursor to title string
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCrsr_Point1stItem:
	xor		dx, dx						; Zero DX
	call	MenuCrsr_PointItemBrdr		; Point to item border (left)
	mov		cx, W_OFF_CRSR_STR & 0FFh	; Offset to user string (move X only)
	jmp		MenuCrsr_Move				; Move cursor
ALIGN JUMP_ALIGN
MenuCrsr_PointInfo:
	xor		dx, dx						; Zero DX
	call	MenuCrsr_PointNfoBrdr		; Point to Info border (top left)
	mov		cx, W_OFF_CRSR_STR			; Movement from border to user str
	jmp		MenuCrsr_Move				; Move cursor
ALIGN JUMP_ALIGN
MenuCrsr_PointTitle:
	xor		dx, dx						; Zero DX
	call	MenuCrsr_PointTitleBrdr		; Point to Title border (top left)
	mov		cx, W_OFF_CRSR_STR			; Movement from border to user str
	jmp		MenuCrsr_Move				; Move cursor


;--------------------------------------------------------------------
; Sets cursor to start of wanted menuitem string.
;
; MenuCrsr_PointNthItem
;	Parameters:
;		CX:		Menuitem index where to set cursor
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCrsr_PointNthItem:
	push	cx
	push	cx
	call	MenuCrsr_Point1stItem		; Point to topmost menuitem
	pop		cx
	sub		cx, [bp+MENUVARS.wItemTop]	; Number of newlines needed
	jcxz	.Return
ALIGN JUMP_ALIGN
.NewLineLoop:
	call	MenuDraw_NewlineStr
	loop	.NewLineLoop
ALIGN JUMP_ALIGN
.Return:
	pop		cx
	ret


;--------------------------------------------------------------------
; Sets cursor to start of menu border.
; MenuCrsr_PointBelowBrdr	Sets cursor to below menu bottom border
; MenuCrsr_PointNfoBrdr		Sets cursor to top left corner of info borders
; MenuCrsr_PointItemBrdr	Sets cursor to first menuitem left border
; MenuCrsr_PointTitleBrdr	Sets cursor to top left corner of title borders
;	Parameters:
;		DX:		0
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCrsr_PointBelowBrdr:
	mov		dh, [bp+MENUVARS.bInfoH]	; Load info height without borders
	test	dh, dh						; Info displayed?
	jz		.BottomOnly					; If not, continue
	inc		dh							; Increment Y for top border
ALIGN JUMP_ALIGN
.BottomOnly:
	inc		dh							; Increment Y for bottom border
ALIGN JUMP_ALIGN
MenuCrsr_PointNfoBrdr:
	add		dh, [bp+MENUVARS.bVisCnt]	; Load max number of visible menuitems
ALIGN JUMP_ALIGN
MenuCrsr_PointItemBrdr:
	inc		dh							; Add title top border
	mov		al, [bp+MENUVARS.bTitleH]	; Load title height
	add		dh, al						; Add title height to DH
	test	al, al						; Title visible?
	jz		MenuCrsr_PointTitleBrdr		;  If not, jump to set cursor
	inc		dh							; Title bottom border
ALIGN JUMP_ALIGN
MenuCrsr_PointTitleBrdr:
	add		dx, [bp+MENUVARS.wInitCrsr]	; Add initial cursor position
	; Fall to MenuCrsr_SetCursor


;--------------------------------------------------------------------
; Sets cursor position in DX.
;	Parameters:
;		DL:		Cursor X coordinate
;		DH:		Cursor Y coordinate
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCrsr_SetCursor:
	xor		bx, bx						; Zero page
	mov		ah, 02h						; Set Cursor Position and Size
	int		10h
	ret


;--------------------------------------------------------------------
; Return cursor position in DX.
;	Parameters:
;		Nothing
;	Returns:
;		CL:		Cursor start scan line
;		CH:		Cursor end scan line
;		DL:		Cursor X coordinate
;		DH:		Cursor Y coordinate
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCrsr_GetCursor:
	xor		bx, bx						; Zero page
	mov		ah, 03h						; Get Cursor Position and Size
	int		10h
	ret


;--------------------------------------------------------------------
; Moves cursor from current location.
;	Parameters:
;		CL:		Cursor X coordinate movement (can be negative)
;		CH:		Cursor Y coordinate movement (can be negative)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCrsr_Move:
	push	cx
	call	MenuCrsr_GetCursor			; Get cursor position to DX
	pop		cx
	add		dl, cl						; Move X
	add		dh, ch						; Move Y
	jmp		MenuCrsr_SetCursor


;--------------------------------------------------------------------
; Shows cursor that has been hidden.
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCrsr_Show:
	mov		cx, 0607h		; Two line cursor near or at the bottom of cell
	jmp		MenuCrsr_SetShape


;--------------------------------------------------------------------
; Hides cursor.
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCrsr_Hide:
	mov		cx, 2000h
	; Fall to MenuCrsr_SetShape

;--------------------------------------------------------------------
; Sets cursor shape.
;	Parameters:
;		CL:		Cursor start scan line
;		CH:		Cursor end scan line
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuCrsr_SetShape:
	mov		ax, 0103h		; Set Text-Mode Cursor Shape
							; AL=assumed video mode to prevent lock ups on some BIOSes
	int		10h
	ret
