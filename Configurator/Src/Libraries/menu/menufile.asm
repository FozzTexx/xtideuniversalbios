; Project name	:	Menu library
; Description	:	ASM library for menu system.
;					Contains functions for displaying file dialog.

;--------------- Equates -----------------------------

; Dialog init and return variables.
; This is an expanded MSGVARS struct.
struc FDLGVARS
	.msgVars	resb	MSGVARS_size

	; Dialog parameters
	.fpFileSrch	resb	4	; Far pointer to file search string
	.wFileCnt	resb	2	; Number of directories and files to display
	.wDrvCnt	resb	2	; Valid drive letter count

	; Return variables for different dialogs
	.fpDTA		resb	4	; Ptr to DTA for selected file
	.fSuccess	resb	1	; Was data inputted successfully by user
				resb	1	; Alignment
endstruc


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data

g_szDir:	db	"[%S]",STOP
g_szDrv:	db	"[%c:]",STOP


;-------------- Public functions ---------------------
; Section containing code
SECTION .text


;--------------------------------------------------------------------
; Displays file dialog.
;
; MenuFile_ShowDlg
;	Parameters:
;		BL:		Dialog width with borders included
;		SS:BP:	Ptr to MENUVARS
;		ES:DI:	Ptr to STOP terminated string to display
;		DS:SI:	Ptr to file search string (* and ? wildcards supported)
;	Returns:
;		DS:SI:	Ptr to selected file name string
;		CF:		Set if user data inputted successfully
;				Cleared is input cancelled
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuFile_ShowDlg:
	; Create stack frame
	eENTER	FDLGVARS_size, 0
	sub		bp, FDLGVARS_size				; Point to FDLGVARS

	; Initialize menu variables
	mov		bh, CNT_SCRN_ROW				; Menu height
	mov		[bp+MENUVARS.wSize], bx			; Menu size
	mov		[bp+MSGVARS.wStrOff], di		; Store far ptr...
	mov		[bp+MSGVARS.wStrSeg], es		; ...to info string to display
	mov		[bp+FDLGVARS.fpFileSrch], si	; Store far pointer...
	mov		[bp+FDLGVARS.fpFileSrch+2], ds	; ...to file search string
	;call	File_GetValidDrvCnt				; Get drive letter count to CX (drive support broken! Works on DOSBox, not on DOS 6.22)
	xor		cx, cx
	mov		[bp+FDLGVARS.wDrvCnt], cx
	mov		WORD [bp+MENUVARS.fnEvent], MenuFile_Event
	mov		[bp+FDLGVARS.fSuccess], cl		; For user cancel
	call	MenuMsg_GetLineCnt				; Get Info line count to CX
	xchg	cl, ch							; CH=Info lines, CL=Title lines
	mov		[bp+MENUVARS.wTopDwnH], cx

	; Enter menu
	mov		dx, si							; File search str ptr to DS:DX
	call	MenuFile_GetItemCnt				; Get menuitem count to CX
	call	MenuCrsr_GetCenter				; Get X and Y coordinates to DX
	xor		ax, ax							; Selection timeout (disable)
	xor		bx, bx							; Menu flags
	call	Menu_Init						; Returns only after dlg closed

	; Return
	mov		si, [bp+FDLGVARS.fpDTA]			; Load offset to return DTA
	mov		ds, [bp+FDLGVARS.fpDTA+2]		; Load segment to return DTA
	mov		bl, [bp+FDLGVARS.fSuccess]		; Load success flag
	add		bp, FDLGVARS_size				; Point to old BP
	eLEAVE									; Destroy stack frame
	rcr		bl, 1							; Move success flag to CF
	ret


;-------------- Private functions ---------------------

;--------------------------------------------------------------------
; File dialog event handler.
;
; MenuFile_Event
;	Parameters:
;		DS:DX:	Ptr to file search string (for example *.* or C:\temp\*.txt)
;		SS:BP:	Ptr to FDLGVARS
;	Returns:
;		CX:		Number of menuitems to display files and drives
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuFile_GetItemCnt:
	call	File_FindAndCount				; Get message line count to CX
	mov		[bp+FDLGVARS.wFileCnt], cx		; Store file and dir count
	add		cx, [bp+FDLGVARS.wDrvCnt]		; Add drive letter count to CX
	ret


;--------------------------------------------------------------------
; Directory, File and Drive rendering functions for menuitems.
; Cursor is assumed to be on correct position when this function is called.
;
; MenuFile_DrawItem
;	Parameters:
;		CX:		Index of menuitem to draw
;		SS:BP:	Ptr to FDLGVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuFile_DrawItem:
	push	ds
	mov		dx, [bp+FDLGVARS.fpFileSrch]	; Load ptr to file search str
	mov		ds, [bp+FDLGVARS.fpFileSrch+2]
	call	File_GetDTA						; Get DTA ptr to DS:BX
	jc		.DrawDrv						; No dir or file, draw drive
	test	BYTE [bx+DTA.bFileAttr], FLG_FATTR_DIR
	jnz		.DrawDir

;--------------------------------------------------------------------
; Directory, File and Drive rendering for menuitems.
; Cursor is assumed to be on correct position.
;
; .DrawFile		Draws file menuitem
; .DrawDir		Draws directory menuitem
; .DrawDrv		Draws drive menuitem
;	Parameters:
;		CX:		Index of menuitem to draw
;		DS:BX:	Ptr to DTA for menuitem (not for .DrawDrv)
;		SS:BP:	Ptr to FDLGVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
.DrawFile:
	lea		dx, [bx+DTA.szFile]	; DS:DX now points to filename string
	PRINT_STR
	pop		ds
	ret
ALIGN JUMP_ALIGN
.DrawDir:
	push	si
	lea		ax, [bx+DTA.szFile]	; Dir string offset to AX
	push	ds					; Push dir string segment
	push	ax					; Push dir string offset
	push	cs					; Copy CS...
	pop		ds					; ...to DS for format string
	mov		si, g_szDir			; Format string now in DS:SI
	call	Print_Format
	add		sp, 4				; Clean stack variables
	pop		si
	pop		ds
	ret
ALIGN JUMP_ALIGN
.DrawDrv:
	push	si
	sub		cx, [bp+FDLGVARS.wFileCnt]	; Menuitem to valid drive index
	call	File_GetNthValidDrv			; Get letter to AX
	push	ax							; Push drive letter
	push	cs							; Copy CS...
	pop		ds							; ...to DS for format string
	mov		si, g_szDrv					; Format string now in DS:SI
	call	Print_Format
	add		sp, 2						; Clean stack variables
	pop		si
	pop		ds
	ret


;--------------------------------------------------------------------
; File dialog event handler.
;
; MenuFile_Event
;	Parameters:
;		BX:		Callback event
;		CX:		Selected menuitem index
;		DX:		Event parameter (event specific)
;		SS:BP:	Ptr to FDLGVARS
;	Returns:
;		AH:		Event specific or unused
;		AL:		1=Event processed
;				0=Event not processed (default action if any)
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuFile_Event:
	cmp		bx, EVNT_MNU_UPD		; Above last supported?
	ja		.EventNotHandled		;  If so, return
	shl		bx, 1					; Shift for word lookup
	jmp		[cs:bx+.rgwEventJump]	; Jumpt to handle event
ALIGN WORD_ALIGN
.rgwEventJump:
	dw		.EventExit				; 0, EVNT_MNU_EXIT
	dw		.EventSelChg			; 1, EVNT_MMU_SELCHG
	dw		.EventSelSet			; 2, EVNT_MNU_SELSET
	dw		.EventKey				; 3, EVNT_MNU_KEY
	dw		.EventUpd				; 4, EVNT_MNU_UPD

; Events that do not require any handling
ALIGN JUMP_ALIGN
.EventSelChg:
.EventKey:
.EventNotHandled:
	xor		ax, ax					; Event not processed
	ret
ALIGN JUMP_ALIGN
.EventExit:
.EventHandled:	; Return point from all handled events
	mov		ax, 1
	ret


;--------------------------------------------------------------------
; EVNT_MNU_SELSET event handler.
;
; .EventSelSet
;	Parameters:
;		CX:		Index of menuitem that user selected
;		SS:BP:	Ptr to FDLGVARS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EventSelSet:
	push	ds
	cmp		cx, [bp+FDLGVARS.wFileCnt]		; Selecting file or dir?
	jae		.ChgDrv							;  If not, must be drive
	mov		dx, [bp+FDLGVARS.fpFileSrch]	; Load ptr to file search str
	mov		ds, [bp+FDLGVARS.fpFileSrch+2]
	call	File_GetDTA						; Get DTA ptr to DS:BX
	rcl		al, 1							; CF to AL
	test	BYTE [bx+DTA.bFileAttr], FLG_FATTR_DIR
	jnz		.ChgDir							; If directory, go change

	; File selected, close dialog
	not		al								; Invert CF
	mov		[bp+FDLGVARS.fSuccess], al		; Store success flag
	mov		[bp+FDLGVARS.fpDTA], bx			; Store offset to DTA
	mov		[bp+FDLGVARS.fpDTA+2], ds		; Store segment to DTA
	pop		ds
	jmp		MenuDlg_ExitHandler				; Close dialog

ALIGN JUMP_ALIGN
.ChgDrv:
	sub		cx, [bp+FDLGVARS.wFileCnt]		; Menuitem to drive index
	call	File_GetNthValidDrv				; Drv device num to DX
	call	File_SetDrive					; Change drive
	jmp		.ChangeDone						; Update menu
ALIGN JUMP_ALIGN
.ChgDir:
	lea		dx, [bx+DTA.szFile]				; Offset to new path
	call	File_ChangeDir					; Change directory
ALIGN JUMP_ALIGN
.ChangeDone:
	lds		dx, [bp+FDLGVARS.fpFileSrch]	; Load ptr to file search str
	call	MenuFile_GetItemCnt				; Get file count from new dir
	pop		ds
	xor		dx, dx							; Redraw only necessary
	call	Menu_InvItemCnt					; Redraw with new items
	jmp		.EventHandled

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
;		SS:BP:	Ptr to FDLGVARS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.EventUpd:
	test	dl, MFL_UPD_TITLE	; Update title?
	jnz		.EventNotHandled	;  If so, return without handling event
	test	dl, MFL_UPD_NFO		; Update info?
	jnz		.DrawInfo			;  If so, jump to update

	; Update Menuitem
	call	MenuFile_DrawItem	; Draw menuitem
	jmp		.EventHandled

	; Update Info string
ALIGN JUMP_ALIGN
.DrawInfo:
	push	es
	push	di
	mov		di, [bp+MSGVARS.wStrOff]		; Load string offset
	mov		es, [bp+MSGVARS.wStrSeg]		; Load string segment
	eMOVZX	cx, [bp+MENUVARS.bInfoH]		; Load info line count to CX
	call	MenuDraw_MultilineStr			; Draw multiline str
	pop		di
	pop		es
	jmp		.EventHandled
