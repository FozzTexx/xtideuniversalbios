; Project name	:	Menu library
; Description	:	ASM library for menu system.
;					Contains functions for displaying progress bar dialog.

;--------------- Equates -----------------------------

; Dialog init and return variables.
; This is an expanded MSGVARS struct.
struc PDLGVARS
	.msgVars	resb	MSGVARS_size

	; Dialog parameters
	.fpUser		resb	4	; Far pointer to user specific data
	.ffnTask	resb	4	; Far pointer to task function

	; Return variables for different dialogs
	.wRetUser	resb	2	; User specific return variable
endstruc

;--------------------------------------------------------------------
; Function prototype for Progress Task function (PDLGVARS.fnTask).
; Cursor will be set to Title string location so user may modify the
; title string if needed.
; Remember to return with RETF instead of RET!
;	Parameters:
;		DS:SI:	User specified far pointer
;	Returns:
;		AX:		User specified return code if CF set
;				Task completion percentage (0...100) if CF cleared
;		CF:		Set if task was completed or cancelled
;				Cleared if task must be continued
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data


;-------------- Public functions ---------------------
; Section containing code
SECTION .text


;--------------------------------------------------------------------
; Displays progress bar dialog.
;
; MenuProg_Show
;	Parameters:
;		BL:		Dialog width with borders included
;		BH:		Dialog height with borders included
;		SS:BP:	Ptr to MENUVARS
;		ES:DI:	Far ptr to user specified task function
;		DS:SI:	User specified far pointer
;	Returns:
;		AX:		User specified return code
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuProg_Show:
	; Create stack frame
	eENTER	PDLGVARS_size, 0
	sub		bp, PDLGVARS_size				; Point to PDLGVARS

	; Initialize menu variables
	mov		[bp+MENUVARS.wSize], bx			; Menu size
	mov		[bp+PDLGVARS.fpUser], si		; Store user defined...
	mov		[bp+PDLGVARS.fpUser+2], ds		; ...far pointer
	mov		[bp+PDLGVARS.ffnTask], di		; Store far ptr to...
	mov		[bp+PDLGVARS.ffnTask+2], es		; ...task function
	mov		WORD [bp+MENUVARS.wTopDwnH], 0101h	; 1 title line, 1 info line
	mov		WORD [bp+MENUVARS.fnEvent], MenuProg_Event

	; Enter menu
	call	MenuCrsr_GetCenter				; Get X and Y coordinates to DX
	xor		cx, cx							; No menuitems
	xor		bx, bx							; Menu flags
	xor		ax, ax							; Selection timeout (disable)
	call	Menu_Init						; Returns only after dlg closed

	; Return
	mov		ax, [bp+PDLGVARS.wRetUser]		; Load user return variable
	add		bp, PDLGVARS_size				; Point to old BP
	eLEAVE									; Destroy stack frame
	ret


;-------------- Private functions ---------------------

;--------------------------------------------------------------------
; Draws progress bar.
;
; MenuProg_DrawBar
;	Parameters:
;		AX:		Completion percentage (0...100)
;		SS:BP:	Ptr to PDLGVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuProg_DrawBar:
	; Calculate number of chars to draw
	eMOVZX	cx, [bp+MENUVARS.bWidth]		; Dialog width to CX
	sub		cl, 4							; Sub borders, CX=bar width
	mul		cl								; AX=bar with * percentage
	mov		bx, 100							; Prepare to div by 100
	div		bl								; AL=Full char cnt
	sub		cl, al							; CX=Empty char cnt
	mov		bl, al							; BX=full char cnt

	; Draw full chars
	mov		dl, FULL_BLCK					; Load full block char
	xchg	bx, cx							; CX=full chars, BX=empty chars
	call	Print_Repeat					; Repeat chars
	mov		dl, MIN_BLCK					; Load min block char
	mov		cx, bx							; CX=empty chars
	call	Print_Repeat					; Repeat chars
	ret


;--------------------------------------------------------------------
; File dialog event handler.
;
; MenuProg_Event
;	Parameters:
;		BX:		Callback event
;		CX:		Selected menuitem index
;		DX:		Event parameter (event specific)
;		SS:BP:	Ptr to PDLGVARS
;	Returns:
;		AH:		Event specific or unused
;		AL:		1=Event processed
;				0=Event not processed (default action if any)
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuProg_Event:
	cmp		bx, EVNT_MNU_UPD		; Update menu string?
	je		.EventUpd				;  If so, jump to update
	xor		ax, ax					; Event not processed
	ret

ALIGN JUMP_ALIGN
.EventHandled:	; Return point from all handled events
	mov		ax, 1
	ret

;--------------------------------------------------------------------
; EVNT_MNU_UPD event handler.
;
; .EventUpd
;	Parameters:
;		CX:		Index of menuitem to update (MFL_UPD_ITEM only)
;		DL:		Update flag:
;					MFL_UPD_TITLE	Set to update title string
;					MFL_UPD_NFO		Set to update info string
;					MFL_UPD_ITEM	Set to update menuitem string
;		SS:BP:	Ptr to PDLGVARS
;	Returns:
;		AX:		1 (Event processed)
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EventUpd:
	test	dl, MFL_UPD_NFO		; Update info?
	jz		.EventHandled		;  If not, do nothing and return

	; Start task
	push	ds
	push	si
	lds		si, [bp+PDLGVARS.fpUser]	; Load user defined ptr
	xor		ax, ax						; Zero percent
ALIGN JUMP_ALIGN
.TaskLoop:
	push	ax
	call	MenuCrsr_PointInfo			; Point cursor to info string
	pop		ax
	call	MenuProg_DrawBar			; Draw progress bar
	call	MenuCrsr_PointTitle			; Point cursor to title string
	call	far [bp+PDLGVARS.ffnTask]	; Call task function
	jnc		.TaskLoop					; Loop until task complete

	; Task complete
	mov		[bp+PDLGVARS.wRetUser], ax	; Store user return value
	pop		si
	pop		ds
	jmp		MenuDlg_ExitHandler			; Close progress bar
