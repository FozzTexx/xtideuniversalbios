; File name		:	menudraw.asm
; Project name	:	Menu library
; Created date	:	9.11.2009
; Last update	:	25.5.2010
; Author		:	Tomi Tilli
; Description	:	ASM library to menu system.
;					Contains menu drawing functions.

;--------------- Equates -----------------------------



;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data

g_strTimeout:	db	B_LL,BHL_TVR,"Selection Timeout %us",TVL_BHR,STOP


;-------------- Public functions ---------------------
; Section containing code
SECTION .text


;--------------------------------------------------------------------
; Clears screen.
;
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDraw_ClrScr:
	xor		dx, dx						; Cursor to (0,0)
	call	MenuCrsr_SetCursor
	mov		ah, 0Fh						; Get Current Video Mode
	int		10h
	mov		al, CNT_SCRN_ROW			; Load row count
	mul		ah							; AX=Column count * row count
	mov		cx, ax						; Copy char count to CX
	mov		bx, ATTR_MDA_NORMAL			; Page zero, normal attribute
	mov		ax, 0920h					; Write Char and attr, space char
	int		10h
	ret


;--------------------------------------------------------------------
; Changes line. When printing menu strings, this function must be
; called instead of normal Print_Newline.
;
; MenuDraw_NewlineStrClrLn	Clear current line from cursor pos before newline
; MenuDraw_NewlineStr
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDraw_NewlineStrClrLn:
	push	cx
	call	MenuCrsr_GetCursor				; Get current cursor to DX
	eMOVZX	cx, BYTE [bp+MENUVARS.bWidth]	; Load menu width
	add		cl, [bp+MENUVARS.bInitX]		; Add menu start X coord
	sub		cl, W_OFF_CRSR_STR & 0FFh		; Subtract right borders
	sub		cl, dl							; Subtract current X coord
	mov		dl, ' '							; Clear with space
	call	Print_Repeat					; Clear line to the end
	pop		cx
ALIGN JUMP_ALIGN
MenuDraw_NewlineStr:
	push	cx
	call	MenuCrsr_GetCursor				; Get current cursor to DX
	mov		dl, [bp+MENUVARS.bInitX]		; Load X offset to border
	add		dx, W_OFF_CRSR_STR				; Inc X and Y
	call	MenuCrsr_SetCursor				; Set new cursor
	pop		cx
	ret


;--------------------------------------------------------------------
; Draws multiline Title or Info string.
;
; MenuDraw_MultilineStr
;	Parameters:
;		CX:		Max Title or Info line count (menu initialization params)
;		ES:DI:	Ptr to STOP terminated string to display
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
%ifdef USE_MENU_DIALOGS
ALIGN JUMP_ALIGN
MenuDraw_MultilineStr:
	push	si
	xor		si, si
ALIGN JUMP_ALIGN
.LineLoop:
	xchg	cx, si							; Idx to CX, count to SI
	push	cx
	call	MenuMsg_WriteLine				; Write line
	pop		cx
	jc		.Return							;  Return if last token written
	call	MenuDraw_NewlineStr				; Cursor to next line
	inc		cx								; Increment line index
	xchg	cx, si							; Count to CX, idx to SI
	loop	.LineLoop						; Loop while lines left
ALIGN JUMP_ALIGN
.Return:
	pop		si
	ret
%endif ; USE_MENU_DIALOGS


;--------------------------------------------------------------------
; Draws menu component.
;
; MenuDraw_Title			Draws Title borders and user string
; MenuDraw_Info				Draws Info borders and user string
; MenuDraw_AllItems			Draws Item borders and all user menuitems
; MenuDraw_TitleNoBord		MenuDraw_Title without clearing old chars
; MenuDraw_InfoNoBord		MenuDraw_Info without clearing old chars
; MenuDraw_AllItemsNoBord	MenuDraw_AllItems without clearing old chars
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
;MenuDraw_Title:
;	call	MenuDraw_TitleBorders			; Draw borders to clear old strings
ALIGN JUMP_ALIGN
MenuDraw_TitleNoBord:
	cmp		BYTE [bp+MENUVARS.bTitleH], 0	; Any title strings?
	jz		MenuDraw_NothingToDraw			;  If not, return
	call	MenuCrsr_PointTitle				; Set cursor position
	mov		dl, MFL_UPD_TITLE				; Update title string
	jmp		MenuDraw_SendEvent

;ALIGN JUMP_ALIGN
;MenuDraw_Info:
;	call	MenuDraw_InfoBorders			; Draw borders to clear old strings
ALIGN JUMP_ALIGN
MenuDraw_InfoNoBord:
	cmp		BYTE [bp+MENUVARS.bInfoH], 0	; Any info strings?
	jz		MenuDraw_NothingToDraw			;  If not, return
	test	BYTE [bp+MENUVARS.bFlags], FLG_MNU_HIDENFO
	jnz		MenuDraw_NothingToDraw			; Return if info is hidden
	call	MenuCrsr_PointInfo				; Set cursor position
	mov		dl, MFL_UPD_NFO					; Update title string
	jmp		MenuDraw_SendEvent

;ALIGN JUMP_ALIGN
;MenuDraw_AllItems:
;	call	MenuDraw_ItemBorders			; Draw borders to clear old strings
ALIGN JUMP_ALIGN
MenuDraw_AllItemsNoBord:	
	cmp		WORD [bp+MENUVARS.wItemCnt], 0	; Any items to draw?
	jz		MenuDraw_NothingToDraw			;  If not, return
	call	MenuCrsr_Point1stItem			; Set cursor position
	mov		cx, [bp+MENUVARS.wItemTop]		; Load idx of first menuitem to draw
	eMOVZX	dx, BYTE [bp+MENUVARS.bVisCnt]	; Load number of visible menuitems
	MIN_U	dx, [bp+MENUVARS.wItemCnt]		; Limit to item count
	add		dx, cx							; One past last menuitem to draw
ALIGN JUMP_ALIGN
.DrawLoop:
	push	dx
	call	MenuDraw_Item					; Draw menuitem
	pop		dx
	inc		cx								; Increment menuitem index
	cmp		cx, dx							; More items left?
	jb		.DrawLoop						;  If so, loop
	jmp		MenuDraw_NothingToDraw

ALIGN JUMP_ALIGN
MenuDraw_SendEvent:
	mov		bx, EVNT_MNU_UPD				; Update string
	call	MenuLoop_SendEvent
ALIGN JUMP_ALIGN
MenuDraw_NothingToDraw:
	call	MenuCrsr_PointBelowBrdr			; Cursor to safe location
	ret


;--------------------------------------------------------------------
; Draws Menuitem without borders.
; This function does not set initial cursor position but does
; change line for next menuitem!
;
; MenuDraw_Item
;	Parameters:
;		CX:		Index of menuitem to draw
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AL:		1=Menuitem drawed by user event handler
;				0=Menuitem not drawed by user event handler
;	Corrupts registers:
;		AH, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDraw_Item:
	push	cx
	test	BYTE [bp+MENUVARS.bFlags], FLG_MNU_NOARRW
	jnz		.DrawString					; Don't draw arrow unless wanted
	mov		dl, RARROW					; Prepare to draw selection arrow
	cmp		cx, [bp+MENUVARS.wItemSel]	; Drawing selected item?
	je		.DrawArrow					;  If so, jump to draw arrow
	mov		dl, ' '						; Load space instead of arrow
ALIGN JUMP_ALIGN
.DrawArrow:
	PRINT_CHAR
	mov		dl, ' '						; Draw space before user str
	PRINT_CHAR
ALIGN JUMP_ALIGN
.DrawString:
	mov		dl, MFL_UPD_ITEM			; Draw item string
	mov		bx, EVNT_MNU_UPD			; Update string
	call	[bp+MENUVARS.fnEvent]		; Send event
	call	MenuDraw_NewlineStr			; Move cursor to next menuitem
	pop		cx
	ret


;-------------- Private functions --------------------

;--------------------------------------------------------------------
; Changes line. When printing menu borders, this function must be
; called instead of normal Print_Newline.
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDraw_NewlineBrdr:
	call	MenuCrsr_GetCursor			; Get current cursor to DX
	mov		dl, [bp+MENUVARS.bInitX]	; Load X offset to border
	inc		dh							; Increment Y coordinate
	jmp		MenuCrsr_SetCursor			; Set new cursor


;--------------------------------------------------------------------
; Draws menu borders. User strings will be cleared.
;
; MenuDraw_TitleBorders		Draws Title borders
; MenuDraw_InfoBorders		Draws Info borders
; MenuDraw_ItemBorders		Draws Item borders
; MenuDraw_Timeout			Draw timeout border (not whole InfoBorders)
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDraw_TitleBorders:
	xor		dx, dx							; Zero DX
	call	MenuCrsr_PointTitleBrdr			; Set cursor
	call	MenuDraw_TopBorder				; Draw top border
	call	MenuDraw_NewlineBrdr			; Change line
	eMOVZX	cx, BYTE [bp+MENUVARS.bTitleH]	; Load number of title strings
	jcxz	.Return							; Return if no title strings
ALIGN JUMP_ALIGN
.LineLoop:
	push	cx
	call	MenuDraw_StringBorder
	call	MenuDraw_NewlineBrdr
	pop		cx
	loop	.LineLoop
	jmp		MenuDraw_MiddleBorder			; Thin border before menuitems
ALIGN JUMP_ALIGN
.Return:
	ret

ALIGN JUMP_ALIGN
MenuDraw_InfoBorders:
	xor		dx, dx							; Zero DX
	call	MenuCrsr_PointNfoBrdr			; Set cursor
	eMOVZX	cx, BYTE [bp+MENUVARS.bInfoH]	; Load number of info strings
	test	BYTE [bp+MENUVARS.bFlags], FLG_MNU_HIDENFO	; Information hidden?
	jnz		SHORT .JumpToBottomBorder
	test	cx, cx							; Any info strings?
	jz		SHORT MenuDraw_BottomBorder
	push	cx
	call	MenuDraw_MiddleBorder			; Draw middle border
	call	MenuDraw_NewlineBrdr			; Change line
	pop		cx
ALIGN JUMP_ALIGN
.LineLoop:
	push	cx
	call	MenuDraw_StringBorder
	call	MenuDraw_NewlineBrdr
	pop		cx
	loop	.LineLoop
ALIGN JUMP_ALIGN
.JumpToBottomBorder:
	jmp		SHORT MenuDraw_BottomBorder

ALIGN JUMP_ALIGN
MenuDraw_Timeout:
	xor		dx, dx							; Zero DX
	call	MenuCrsr_PointNfoBrdr			; Set cursor
	mov		ch, [bp+MENUVARS.bInfoH]		; Load info str count to CH
	and		cx, 0FF00h						; Any info strings? (clears CL)
	jz		SHORT MenuDraw_BottomBorder		;  If not, draw bottom border
	inc		ch								; Increment for info top border
	call	MenuCrsr_Move					; Move cursor
	jmp		SHORT MenuDraw_BottomBorder

ALIGN JUMP_ALIGN
MenuDraw_ItemBorders:
	cmp		WORD [bp+MENUVARS.wItemCnt], BYTE 0	; Any items?
	jz		SHORT .Return					;  If not, return
	xor		dx, dx							; Zero DX
	call	MenuCrsr_PointItemBrdr			; Set cursor
	eMOVZX	cx, BYTE [bp+MENUVARS.bVisCnt]	; Load max number of item strings
ALIGN JUMP_ALIGN
.LineLoop:
	push	cx
	call	MenuDraw_ScrollBorder
	call	MenuDraw_NewlineBrdr
	pop		cx
	loop	.LineLoop
.Return:
	ret


;--------------------------------------------------------------------
; Draw horizontal border line to current cursor location.
; MenuDraw_TopBorder	Draw thick top menu border
; MenuDraw_StringBorder	Draw thick user string border
; MenuDraw_ScrollBorder	Draw scrolling border for menuitems
; MenuDraw_MiddleBorder	Draw thin middle menu border
; MenuDraw_BottomBorder	Draw thick bottom menu border with timeout if set
;	Parameters:
;		CX:		Loop counter (Items left, MenuDraw_ScrollBorder only)
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDraw_TopBorder:
	mov		bh, B_TL
	mov		bl, B_H
	mov		dh, B_TR
	jmp		SHORT MenuDraw_BorderChars
	
ALIGN JUMP_ALIGN
MenuDraw_StringBorder:
	mov		bh, B_V
	mov		bl, ' '
	mov		dh, B_V
	jmp		SHORT MenuDraw_BorderChars

ALIGN JUMP_ALIGN
MenuDraw_ScrollBorder:
	call	MenuDraw_GetScrollChar			; Load scroll char to DH
	mov		bh, B_V
	mov		bl, ' '
	jmp		SHORT MenuDraw_BorderChars

ALIGN JUMP_ALIGN
MenuDraw_MiddleBorder:
	mov		bh, BVL_THR
	mov		bl, T_H
	mov		dh, THL_BVR

ALIGN JUMP_ALIGN
MenuDraw_BorderChars:
	mov		dl, bh							; Leftmost
	PRINT_CHAR
	eMOVZX	cx, BYTE [bp+MENUVARS.bWidth]
	times 2 dec cx							; Subtract borders
	mov		dl, bl							; Middle
	call	Print_Repeat
	mov		dl, dh							; Rightmost
	PRINT_CHAR
	ret

ALIGN JUMP_ALIGN
MenuDraw_BottomBorder:
	mov		bh, B_LL
	mov		bl, B_H
	mov		dh, B_LR
	cmp		WORD [bp+MENUVARS.wTimeInit], 0	; Timeout enabled?
	jz		MenuDraw_BorderChars			;  If not, draw normal

	; Print timeout value
	push	ds
	push	si
	push	cs
	pop		ds								; Copy CS to DS
	mov		si, g_strTimeout				; Load ptr to timeout str (DS:SI)
	mov		ax, 55							; 1 timer tick = 54.945ms
	mul		WORD [bp+MENUVARS.wTimeout]		; DX:AX = millisecs
	eSHR_IM	ax, 10							; ms to s (close enough to 1000)
	push	ax								; Push seconds
	call	Print_Format					; Print timeout
	add		sp, 2							; Clean stack
	pop		si
	pop		ds

	; Print remaining border chars
	call	MenuCrsr_GetCursor				; Get cursor location to DX
	sub		dl, [bp+MENUVARS.bInitX]		; Compensate for start X...
	inc		dx								; ...and lower right corner
	mov		dh, [bp+MENUVARS.bWidth]		; Load menu width to DH
	sub		dh, dl							; Subtract current X coordinate
	eMOVZX	cx, dh							; Number of border chars needed
	mov		dl, B_H
	call	Print_Repeat
	mov		dl, B_LR
	PRINT_CHAR
	ret


;--------------------------------------------------------------------
; Returns character for scroll bars if needed.
; If scroll bars are not needed, normal border character will be returned.
;
; Note! Current implementation doesn't always return thumb character
;		if there are a lot of pages. Checking last char only is not enough.
;
; MenuDraw_GetScrollChar
;	Parameters:
;		CX:		Loop counter (Items left, MenuDraw_ScrollBorder only)
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		DH:		Scroll bar character
;	Corrupts registers:
;		AX, BX, CX, DL
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDraw_GetScrollChar:
	mov		dh, B_V						; Assume no scroll bars needed
	mov		ax, [bp+MENUVARS.wItemCnt]	; Load menuitem count to AX
	eMOVZX	bx, BYTE [bp+MENUVARS.bVisCnt]	; Load visible menuitems to BX
	cmp		ax, bx						; Need scroll bars?
	jbe		.Return						;  If not, return
	
	; Calculate last menuitem index for thumb char on this line
	push	bx							; Store number of visible menuitems
	sub		bx, cx						; Calculate Line index
	inc		bx							; Increment for next line index
	mul		bx							; DX:AX=Total item count * Next line idx
	pop		bx							; Pop number of visible menuitems
	div		bx							; AX=First Menuitem for next string line
	dec		ax							; AX=Last Menuitem for this string line

	; Draw thumb or track
	mov		dh, FULL_BLCK				; Assume thumb line
	call	Menu_IsItemVisible			; Is thumb menuitem visible?
	jc		.Return						;  If so, draw thumb
	mov		dh, T_V						; Load track character
ALIGN JUMP_ALIGN
.Return:
	ret
