; File name		:	menuloop.asm
; Project name	:	Menu library
; Created date	:	11.11.2009
; Last update	:	25.5.2010
; Author		:	Tomi Tilli
; Description	:	ASM library to menu system.
;					Contains event dispatching loop.

;--------------- Equates -----------------------------

; BIOS scan codes
KEY_ENTER		EQU		1Ch
KEY_ESC			EQU		01h
KEY_UP			EQU		48h
KEY_DOWN		EQU		50h
KEY_PGUP		EQU		49h
KEY_PGDN		EQU		51h
KEY_HOME		EQU		47h
KEY_END			EQU		4Fh
CNT_MENU_KEYS	EQU		8		; Number of menukeys


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data


;-------------- Public functions ---------------------
; Section containing code
SECTION .text


;--------------------------------------------------------------------
; Waits keyboard input, updates timeout and dispatch event for
; user handler.
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuLoop_Enter:
	; Get current time for timeout
	call	Menu_GetTime					; Get system time ticks to CX:DX
	mov		[bp+MENUVARS.wTimeLast], dx		; Store last read time

	; Check if menu operation should be continued
ALIGN JUMP_ALIGN
.CheckExit:
	test	BYTE [bp+MENUVARS.bFlags], FLG_MNU_EXIT
	jnz		.Return							; Return if exit flag set

	; Check if keystroke available
	call	Keys_GetStroke					; Get keystroke to AX
	jz		.CheckTimeout					; If no keystroke, jump to check timeout
	call	MenuLoop_ProcessKey				; Convert keystroke to events

	; Check if timeout needs updating
ALIGN JUMP_ALIGN
.CheckTimeout:
	cmp		WORD [bp+MENUVARS.wTimeInit], 0	; Timeout enabled?
	jz		.CheckExit						;  If not, loop
	call	Menu_GetTime					; Get system time ticks to CX:DX
	mov		cx, dx							; Copy time loword to CX
	sub		dx, [bp+MENUVARS.wTimeLast]		; Has time changed?
	je		.CheckExit						;  If not, loop

	; Update timeout
	mov		[bp+MENUVARS.wTimeLast], cx		; Store last update time
	sub		[bp+MENUVARS.wTimeout], dx		; Update timeout
	ja		.PrintTimeout					;  If time left, just print new value
	call	MenuLoop_SendSelEvent			; Send selection event

	; Print timeout value
ALIGN JUMP_ALIGN
.PrintTimeout:
	call	MenuDraw_Timeout
	xor		dx, dx
	call	MenuCrsr_PointBelowBrdr
	jmp		.CheckExit

ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; Sends Menu event to user handler (MENUVARS.fnEvent).
; MenuLoop_SendSelEvent		Sends Menuitem Selected event to user event handler
; MenuLoop_SendEvent		Sends any event to user event handler
;	Parameters:
;		BX:		Event code (MenuLoop_SendEvent only)
;		DX:		Event parameter (event specific)
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		AH:		Event specific or unused
;		AL:		1=Event processed
;				0=Event not processed (default action if any)
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuLoop_SendSelEvent:
	mov		bx, EVNT_MNU_SELSET
ALIGN JUMP_ALIGN
MenuLoop_SendEvent:
	mov		cx, [bp+MENUVARS.wItemSel]
	call	[bp+MENUVARS.fnEvent]
	ret


;-------------- Private functions ---------------------


;--------------------------------------------------------------------
; Processed menu key input.
; Menu keys will be handled and other keys dispatched as key events.
;	Parameters:
;		AH:		BIOS Scan Code for key
;		AL:		ASCII character
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuLoop_ProcessKey:
	push	es
	push	di

	; Check if wanted key
	push	cs
	pop		es					; Copy CS to ES
	mov		cx, CNT_MENU_KEYS	; Load number of menu keys
	mov		di, .rgbKeyToIdx	; Load offset to translation table
	xchg	al, ah				; Scan code to AL
	cld							; SCASB to increment DI
	repne scasb					; Compare [ES:DI] to AL until match
	jne		.Dispatch			; If not menukey, jump to dispatch

	; Jump to process menu key
	mov		di, CNT_MENU_KEYS-1	; Convert CX...	
	sub		di, cx				; ...to lookup index
	shl		di, 1				; Prepare for word lookup
	jmp		[cs:di+.rgwMenuKeyJmp]

	; Dispatch key event
ALIGN JUMP_ALIGN
.Dispatch:
	xchg	al, ah				; Restore AX
	mov		bx, EVNT_MNU_KEY
	mov		dx, ax				; Copy keys to DX
	call	MenuLoop_SendEvent
ALIGN JUMP_ALIGN
.Return:
	pop		di
	pop		es
	ret

	;;;;;;;;;;;;;;;;;;;;;
	; Menu key handlers ;
	;;;;;;;;;;;;;;;;;;;;;

	; ENTER pressed
ALIGN JUMP_ALIGN
.KeyEnter:
	call	MenuLoop_SendSelEvent			; Send selection event
	jmp		.Return

	; ESC pressed
ALIGN JUMP_ALIGN
.KeyEsc:
	call	Menu_Exit
	jc		.Return							; User cancelled exit
	mov		WORD [bp+MENUVARS.wItemSel], -1
	jmp		.Return

	; UP pressed
ALIGN JUMP_ALIGN
.KeyUp:
%ifdef USE_MENU_DIALOGS
	test	BYTE [bp+MENUVARS.bFlags], FLG_MNU_NOARRW	; Message dialog mode?
	jnz		.TextScrollUp					;  If so, go to text scrolling
%endif
	mov		ax, [bp+MENUVARS.wItemSel]		; Load selected index 
	test	ax, ax							; Already at top?
	jz		.KeyEnd							;  If so, go to end
	mov		dx, ax							; Copy selected index to DX
	dec		ax								; Decrement menuitem index
	mov		[bp+MENUVARS.wItemSel], ax		; Store new index
	cmp		ax, [bp+MENUVARS.wItemTop]		; Need to scroll?
	jb		SHORT .ScrollUp
	jmp		.DrawSelection					;  If not, go to draw selection
ALIGN JUMP_ALIGN
.ScrollUp:
	dec		WORD [bp+MENUVARS.wItemTop]		; Scroll
	jmp		.ScrollMenu

%ifdef USE_MENU_DIALOGS
ALIGN JUMP_ALIGN
.TextScrollUp:
	cmp		WORD [bp+MENUVARS.wItemTop], 0	; Already at the top?
	jz		.Return							;  If so, return
	dec		WORD [bp+MENUVARS.wItemTop]
	jmp		.ScrollMenu
%endif

	; DOWN pressed
ALIGN JUMP_ALIGN
.KeyDown:
%ifdef USE_MENU_DIALOGS
	test	BYTE [bp+MENUVARS.bFlags], FLG_MNU_NOARRW	; Message dialog mode?
	jnz		.TextScrollDown					;  If so, go to text scrolling
%endif
	mov		ax, [bp+MENUVARS.wItemSel]		; Load selected index
	mov		dx, ax							; Copy selected index to DX
	inc		ax								; Increment menuitem index
	cmp		ax, [bp+MENUVARS.wItemCnt]		; Already at bottom?
	je		.KeyHome						;  If so, go to beginning
	mov		[bp+MENUVARS.wItemSel], ax		; Store new menuitem index
	eMOVZX	bx, BYTE [bp+MENUVARS.bVisCnt]	; Load number of visible items
	add		bx, [bp+MENUVARS.wItemTop]		; BX to one past last visible index
	cmp		ax, bx							; Need to scroll?
	jae		.ScrollDown
	jmp		.DrawSelection
ALIGN JUMP_ALIGN
.ScrollDown:
	inc		WORD [bp+MENUVARS.wItemTop]		; Scroll
	jmp		.ScrollMenu

%ifdef USE_MENU_DIALOGS
ALIGN JUMP_ALIGN
.TextScrollDown:
	eMOVZX	ax, BYTE [bp+MENUVARS.bVisCnt]	; Load visible items
	add		ax, [bp+MENUVARS.wItemTop]		; Add topmost menuitem index
	cmp		ax, [bp+MENUVARS.wItemCnt]		; Already at the bottom?
	jae		.Return							;  If so, return
	inc		WORD [bp+MENUVARS.wItemTop]
	jmp		.ScrollMenu
%endif

	; HOME pressed
ALIGN JUMP_ALIGN
.KeyHome:
	xor		ax, ax
	mov		[bp+MENUVARS.wItemSel], ax
	mov		[bp+MENUVARS.wItemTop], ax
	jmp		.ScrollMenu

	; END pressed
ALIGN JUMP_ALIGN
.KeyEnd:
	mov		ax, [bp+MENUVARS.wItemCnt]		; Load number if menuitems
	mov		bx, ax							; Copy menuitem count to BX
	dec		ax								; Decrement for last index
	mov		[bp+MENUVARS.wItemSel], ax		; Store new selection
	sub		bl, [bp+MENUVARS.bVisCnt]		; BX to first menuitem to draw
	sbb		bh, 0
	mov		[bp+MENUVARS.wItemTop], bx		; Store first menuitem to draw
	jnc		.ScrollMenu	
	mov		WORD [bp+MENUVARS.wItemTop], 0	; Overflow, start with 0
	jmp		.ScrollMenu

	; PGUP pressed
ALIGN JUMP_ALIGN
.KeyPgUp:
	mov		ax, [bp+MENUVARS.wItemSel]		; Load selected index
	div		BYTE [bp+MENUVARS.bVisCnt]		; AL=Current page index
	sub		al, 1							; Decrement page
	jc		.KeyHome						; Select first item if overflow
	mul		BYTE [bp+MENUVARS.bVisCnt]		; AX=Fist menuitem on page
	mov		[bp+MENUVARS.wItemSel], ax
	mov		[bp+MENUVARS.wItemTop], ax
	jmp		.ScrollMenu

	; PGDN pressed
ALIGN JUMP_ALIGN
.KeyPgDn:
	mov		ax, [bp+MENUVARS.wItemSel]		; Load selected index
	div		BYTE [bp+MENUVARS.bVisCnt]		; AL=Current page index
	inc		ax								; Increment page
	mul		BYTE [bp+MENUVARS.bVisCnt]		; AX=First menuitem on page
	eMOVZX	bx, BYTE [bp+MENUVARS.bVisCnt]	; Load number of visible items
	add		bx, ax							; BX now one past last visible
	cmp		bx, [bp+MENUVARS.wItemCnt]		; Went over last?
	jae		.KeyEnd							;  If so, select last menuitem
	mov		[bp+MENUVARS.wItemSel], ax
	mov		[bp+MENUVARS.wItemTop], ax
	; Fall to .ScrollMenu

	; Menuitem selection changed, redraw all items
ALIGN JUMP_ALIGN
.ScrollMenu:
	mov		bx, EVNT_MMU_SELCHG
	call	MenuLoop_SendEvent
	call	Menu_RestartTimeout
	xor		cx, cx							; Invalidate...
	dec		cx								; ...all menuitems
	mov		dl, MFL_UPD_ITEM
	call	Menu_Invalidate
	jmp		.Return

; Menuitem selection changed, only two items needs to be redrawn
ALIGN JUMP_ALIGN
.DrawSelection:
	MINMAX_U ax, dx							; First menuitem to AX, next to DX
	push	dx								; Store second to draw
	push	ax								; Store first to draw
	mov		bx, EVNT_MMU_SELCHG
	call	MenuLoop_SendEvent
	call	Menu_RestartTimeout
	pop		cx								; First to draw to CX
	call	MenuCrsr_PointNthItem			; Set cursor position
	call	MenuDraw_Item					; Draw first menuitem
	pop		cx								; Second to draw to CX
	call	MenuDraw_Item					; Draw second menuitem
	jmp		.Return

ALIGN WORD_ALIGN
.rgwMenuKeyJmp:
	dw		.KeyEnter	; KEY_ENTER
	dw		.KeyEsc		; KEY_ESC
	dw		.KeyUp		; KEY_UP
	dw		.KeyDown	; KEY_DOWN
	dw		.KeyPgUp	; KEY_PGUP
	dw		.KeyPgDn	; KEY_PGDN
	dw		.KeyHome	; KEY_HOME
	dw		.KeyEnd		; KEY_END
; Scan code to jump index translation table
.rgbKeyToIdx:	
	db	KEY_ENTER,	KEY_ESC,	KEY_UP,		KEY_DOWN,
	db	KEY_PGUP,	KEY_PGDN,	KEY_HOME,	KEY_END
