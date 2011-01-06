; File name		:	menu.asm
; Project name	:	Menu library
; Created date	:	9.11.2009
; Last update	:	6.1.2011
; Author		:	Tomi Tilli,
;				:	Krister Nordvall (optimizations)
; Description	:	ASM library to menu system.
;
;					Menu.asm contains function to be called from
;					user code. Functions in other menu source files
;					are only to be called by menu library itself!

; Optional features.
%define USE_MENU_DIALOGS		; All dialogs
;%define USE_MENU_SETSEL		; Menu_SetSel
%define USE_MENU_TOGGLEINFO	; Menu_ToggleInfo
%define USE_MENU_INVITEMCNT		; Menu_InvItemCnt

; Include other menu source files.
%include "menudraw.asm"
%include "menucrsr.asm"
%include "menuloop.asm"
%ifdef USE_MENU_DIALOGS
	%include "menumsg.asm"
	%include "menudlg.asm"
	%include "menuprog.asm"
	%include "menufile.asm"
%endif

;--------------- Equates -----------------------------

; Menu Initialization Variables.
; Menu must always be initialized to stack.
struc MENUVARS
	; Menu size set by user
	.wSize:
	.bWidth		resb	1	; Menu full width in chars (borders included)
	.bHeight	resb	1	; Menu full height in chars (borders included)
	.wTopDwnH:
	.bTitleH	resb	1	; Title height in chars (borders not included, 0=disabled)
	.bInfoH		resb	1	; Info height in chars (borders not included, 0=disabled)
	
	; Menu callback system set by user
	.fnEvent	resb	2	; Offset to event callback function
	
	; Menu library internal variables.
	; Do not modify from outside menu library!
	.wTimeInit	resb	2	; System time ticks for autoselect (0=disabled)
	.wTimeout	resb	2	; System time ticks left for autoselect
	.wTimeLast	resb	2	; System time ticks when last read
	.wInitCrsr:				; Initial cursor coordinates
	.bInitX		resb	1
	.bInitY		resb	1

	; Item related variables
	.wItemCnt	resb	2	; Total number of items in menu
	.wItemSel	resb	2	; Index of currently selected (pointed) menuitem
	.wItemTop	resb	2	; Index of first visible menuitem
	.bVisCnt	resb	1	; Maximum number of visible menuitems
	.bFlags		resb	1	; Menu flags

	; User specific variables start here.
	; 4-byte user pointer is stored here if menu created with Menu_Enter.
	; Data is user specific if menu was created directly with Menu_Init.
	.user		resb	0
endstruc

; Screen row count (can be used to limit max menu height)
CNT_SCRN_ROW	EQU		25	; Number of rows on screen

; Menu flags
FLG_MNU_EXIT	EQU	(1<<0)	; Set when menu operation is to be stopped
FLG_MNU_NOARRW	EQU	(1<<1)	; Do not draw item selection arrow
FLG_MNU_HIDENFO	EQU	(1<<2)	; Hide menu information

; Menu update and invalidate flags
MFL_UPD_TITLE	EQU	(1<<0)	; Update title string(s)
MFL_UPD_NFO		EQU	(1<<1)	; Update info string(s)
MFL_UPD_ITEM	EQU	(1<<2)	; Update item string(s)
MFL_UPD_NOCLEAR	EQU	(1<<4)	; Do not clear old chars (prevents flickering)


;--------------------------------------------------------------------
; Event callback function prototype.
;
; MENUVARS.fnEvent
;	Parameters:
;		BX:			Callback event
;		CX:			Menuitem index (usually index of selected Menuitem)
;		DX:			Event parameter (event specific)
;		SS:BP:		Ptr to MENUVARS
;		Other regs:	Undefined
;	Returns:
;		AH:			Event specific or unused. Set to 0 if unused.
;		AL:			1=Event processed
;					0=Event not processed (default action if any)
;		Other regs:	Event specific or unused.
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
EVNT_MNU_EXIT		EQU	0		; Menu will quit
								;	Ret AH:	1 to cancel exit
								;			0 to allow menu exit
EVNT_MMU_SELCHG		EQU	1		; Menuitem selection changed (with arrows)
EVNT_MNU_SELSET		EQU	2		; Menuitem selected (with Enter)
EVNT_MNU_KEY		EQU	3		; Keyboard key pressed
								;	DH: BIOS Scan Code
								;	DL: ASCII Char (if any)
EVNT_MNU_UPD		EQU	4		; Menu needs to be updated (use currect cursor position)
								;	DL:	MFL_UPD_TITLE set to update title string
								;		MFL_UPD_NFO set to update info string
								;		MFL_UPD_ITEM Set to update menuitem string
								;			CX: Index of Menuitem to update
EVNT_MNU_GETDEF		EQU	5		; Request menuitem to be selected by default
								;	Ret CX:	Index of menuitem to select
EVNT_MNU_INITDONE	EQU	6		; Menu has been initialized (created) but not yet drawn



;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data


;-------------- Public functions ---------------------
; Section containing code
SECTION .text


;--------------------------------------------------------------------
; Enters menu or submenu. Menu_Init does not have to be called
; if this function is used to enter menu or submenu.
; Menu_Init need to be called only when creating stack frame manually.
; Manual creation allows custom menu position and user defined variables.
;
; Menu_Enter
;	Parameters:
;		AL:		Menu width with borders included
;		AH:		Menu height with borders included
;		BL:		Title line count (0=disable title)
;		BH:		Info line count (0=disable info)
;		CL:		Number of menuitems in top menu
;		CH:		Menu flags
;		DX:		Selection timeout in milliseconds (0=timeout disabled)
;		DS:SI:	User specific far pointer (will be stored to MENUVARS.user)
;		CS:DI:	Pointer to menu event handler function
;	Returns:
;		CX:		Index of last pointed Menuitem (not necessary selected with ENTER)
;				FFFFh if cancelled with ESC
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_Enter:
	; Create stack frame
	eENTER	MENUVARS_size+4, 0
	sub		bp, MENUVARS_size+4	; Point to MENUVARS

	; Initialize menu variables
	mov		[bp+MENUVARS.wSize], ax
	mov		[bp+MENUVARS.wTopDwnH], bx
	mov		[bp+MENUVARS.fnEvent], di
	mov		[bp+MENUVARS.user], si
	mov		[bp+MENUVARS.user+2], ds

	; Prepare to call Menu_Init
	push	dx					; Store timeout
	call	MenuCrsr_GetCenter	; Get centered coordinates to DX
	pop		ax					; Restore timeout to AX
	xor		bx, bx				; Zero BX
	xchg	bl, ch				; Menu flags to BL, Item count to CX
	call	Menu_Init

	; Destroy stack frame
	add		bp, MENUVARS_size+4	; Point to old BP
	eLEAVE						; Destroy stack frame
	ret


;--------------------------------------------------------------------
; Initialize Menu.
; This function returns only after Menu_Exit has been called from
; event callback function (MENUVARS.fnEvent).
; Caller must clean MENUVARS from stack once this function returns!
;
; Multiple menus can be created to implement submenus.
;
; Menu_Init
;	Parameters:
;		AX:		Selection timeout (ms, 0=timeout disabled)
;		BL:		Menu flags
;		CX:		Number of menuitems in top menu
;		DX:		Top left coordinate for menu
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CX:		Index of last pointed Menuitem (not necessary selected with ENTER)
;				FFFFh if cancelled with ESC
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_Init:
	; Initialize internal variables
	call	Menu_StartTimeout
	xor		ax, ax						; Zero AX
	mov		[bp+MENUVARS.wInitCrsr], dx
	mov		[bp+MENUVARS.wItemCnt], cx
	mov		[bp+MENUVARS.wItemSel], ax
	mov		[bp+MENUVARS.wItemTop], ax
	mov		[bp+MENUVARS.bFlags], bl

	; Calculate number of visible menuitems
	eMOVZX	ax, [bp+MENUVARS.bHeight]	; Load menu total height
	times 2 dec	ax						; Decrement top and borders
	or		ah, [bp+MENUVARS.bTitleH]	; Load title height
	jz		.CheckInfo					;  If no title, check if info
	sub		al, ah						; Subtract title lines
	dec		ax							; Decrement item border
ALIGN JUMP_ALIGN
.CheckInfo:
	xor		ah, ah						; Zero AH
	or		ah, [bp+MENUVARS.bInfoH]	; Load info height
	jz		.StoreVisible				;  If no info, jump to store
	sub		al, ah						; Subtract info lines
	dec		ax							; Decrement item border
ALIGN JUMP_ALIGN
.StoreVisible:
	mov		[bp+MENUVARS.bVisCnt], al	; Store max visible menuitems

	; Get default menuitem
	mov		bx, EVNT_MNU_GETDEF
	call	MenuLoop_SendEvent
	test	al, al						; Default menuitem returned?
	jz		.InitDone					;  If not, continue
	mov		[bp+MENUVARS.wItemSel], cx	; Store default
	eMOVZX	ax, [bp+MENUVARS.bVisCnt]	; Load one past last to be displayed
	cmp		cx, ax						; Visible selection?
	jb		.InitDone					;  If so, continue
	mov		[bp+MENUVARS.wItemTop], cx	; Set selected to topmost

	; Send EVNT_MNU_INITDONE event
ALIGN JUMP_ALIGN
.InitDone:
	mov		bx, EVNT_MNU_INITDONE
	call	MenuLoop_SendEvent

	; Draw menu
	call	MenuCrsr_Hide				; Hide cursor
	mov		cx, -1						; Invalidate all menuitems
	mov		dl, MFL_UPD_TITLE | MFL_UPD_ITEM | MFL_UPD_NFO
	call	Menu_Invalidate

	; Enter menu loop until Menu_Exit is called
	call	MenuLoop_Enter
	call	MenuCrsr_Show				; Show cursor again
	mov		cx, [bp+MENUVARS.wItemSel]	; Load return value
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Below functions are called only from event callback function ;
; (MENUVARS.fnEvent)                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;--------------------------------------------------------------------
; Sets wanted menuitem selected and draws changes.
;
; Menu_SetSel
;	Parameters:
;		CX:		Index of menuitem to set selected
;		SS:BP:	Ptr to MENUVARS for menu to refresh
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
%ifdef USE_MENU_SETSEL
ALIGN JUMP_ALIGN
Menu_SetSel:
	cmp		cx, [bp+MENUVARS.wItemCnt]	; Valid menuitem index?
	jae		.Return						;  If not, return
	mov		[bp+MENUVARS.wItemSel], cx	; Store new selected index

	; Scroll if necessary
	mov		ax, [bp+MENUVARS.wItemTop]	; Load index of topmost visible
	MIN_U	ax, cx						; AX = new topmost visible
	mov		[bp+MENUVARS.wItemTop], ax	; Store new topmost
	add		al, [bp+MENUVARS.bVisCnt]	; AX to one past...
	adc		ah, 0						; ...last visible
	cmp		cx, ax						; After last visible?
	jb		.SendSelChg					;  If not, continue
	mov		[bp+MENUVARS.wItemTop], cx	; New selection to topmost

	; Send EVNT_MMU_SELCHG message
ALIGN JUMP_ALIGN
.SendSelChg:
	mov		bx, EVNT_MMU_SELCHG
	call	MenuLoop_SendEvent

	; Redraw changes
	mov		cx, -1						; Invalidate all menuitems
	mov		dl, MFL_UPD_ITEM
	call	Menu_Invalidate
.Return:
	ret
%endif


;--------------------------------------------------------------------
; Shows or hides menu information at the bottom of menu.
;
; Menu_ShowInfo		Enables menu information
; Menu_HideInfo		Disables menu information
; Menu_ToggleInfo	Enables or disables menu information
;	Parameters:
;		SS:BP:	Ptr to MENUVARS for menu
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
%ifdef USE_MENU_TOGGLEINFO
ALIGN JUMP_ALIGN
Menu_ShowInfo:
	test	BYTE [bp+MENUVARS.bFlags], FLG_MNU_HIDENFO
	jnz		Menu_ToggleInfo
	ret
ALIGN JUMP_ALIGN
Menu_HideInfo:
	test	BYTE [bp+MENUVARS.bFlags], FLG_MNU_HIDENFO
	jz		Menu_ToggleInfo
	ret
ALIGN JUMP_ALIGN
Menu_ToggleInfo:
	xor		BYTE [bp+MENUVARS.bFlags], FLG_MNU_HIDENFO
	; Fall to Menu_RefreshMenu
%endif


;--------------------------------------------------------------------
; Refreshes menu. This function must be called when
; call to submenu Menu_Enter (or Menu_Init) returns.
;
; Menu_RefreshMenu
;	Parameters:
;		SS:BP:	Ptr to MENUVARS for menu to refresh
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_RefreshMenu:
	push	cx
	call	MenuCrsr_Hide				; Hide cursor
	call	Menu_RestartTimeout			; Restart selection timeout
	call	Menu_GetTime				; Get system time ticks to CX:DX
	mov		[bp+MENUVARS.wTimeLast], dx	; Store last time updated
	call	Keys_ClrBuffer				; Clear keyboard buffer
	call	MenuDraw_ClrScr				; Clear screen
	mov		cx, -1						; Invalidate all menuitems
	mov		dl, MFL_UPD_TITLE | MFL_UPD_NFO | MFL_UPD_ITEM
	call	Menu_Invalidate				; Redraw everything
	pop		cx
	ret


;--------------------------------------------------------------------
; Destroy menu by causing Menu_Init to return.
;
; Menu_Exit
;	Parameters:
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if user cancelled exit
;				Cleared if user allowed exit
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_Exit:
	mov		bx, EVNT_MNU_EXIT
	call	MenuLoop_SendEvent
	rcr		ah, 1					; AH bit 0 to CF
	jc		.Return					; Do not exit if AH non-zero
	or		BYTE [bp+MENUVARS.bFlags], FLG_MNU_EXIT	; (Clear CF)
ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; Invalidate any menu string.
; Menu then sends EVNT_MNU_UPD events when necessary.
;
; Menu_InvItemCnt	Changes total item count and invalidates
;	Parameters: (in addition to Menu_Invalidate)
;		CX:		New Total item count
; Menu_Invalidate
;	Parameters:
;		DL:		Invalidate flags (any combination is valid):
;					MFL_UPD_NOCLEAR	Set to prevent clearing old chars
;					MFL_UPD_TITLE	Invalidate menu title string
;					MFL_UPD_NFO		Invalidate menu info string
;					MFL_UPD_ITEM	Invalidate menuitem strings
;						CX: Index of Menuitem to update
;							-1 to update all menuitems
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
%ifdef USE_MENU_INVITEMCNT
ALIGN JUMP_ALIGN
Menu_InvItemCnt:
	xor		ax, ax
	mov		[bp+MENUVARS.wItemCnt], cx
	mov		[bp+MENUVARS.wItemSel], ax
	mov		[bp+MENUVARS.wItemTop], ax
	xchg	cx, ax					; CX = 0
	dec		cx						; CX = -1 (Invalidate all items)
	or		dl, MFL_UPD_ITEM
%endif
ALIGN JUMP_ALIGN
Menu_Invalidate:
	push	di
	mov		di, dx
	test	di, MFL_UPD_ITEM		; Invalidate Menuitems?
	jz		.InvTitle				;  If not, jump to invalidate Title
	cmp		cx, -1					; Redraw all menuitems?
	je		.InvAllItems			;  If so, jump to draw
	call	MenuCrsr_PointNthItem	; Set cursor position
	call	MenuDraw_Item			; Draw single menuitem
	jmp		.InvTitle				; Jump to invalidate Title
ALIGN JUMP_ALIGN
.InvAllItems:
	test	di, MFL_UPD_NOCLEAR		; Keep background?
	jnz		.DrawAllItems			;  If not, jump to draw
	call	MenuDraw_ItemBorders	; Draw item borders
ALIGN JUMP_ALIGN
.DrawAllItems:
	call	MenuDraw_AllItemsNoBord	; Draw items without borders

ALIGN JUMP_ALIGN
.InvTitle:
	test	di, MFL_UPD_TITLE		; Invalidate Title?
	jz		.InvInfo				;  If not, jump to invalidate Info
	test	di, MFL_UPD_NOCLEAR		; Keep background?
	jnz		.DrawTitle				;  If not, jump to draw
	call	MenuDraw_TitleBorders	; Draw borders
ALIGN JUMP_ALIGN
.DrawTitle:
	call	MenuDraw_TitleNoBord	; Draw title without borders

ALIGN JUMP_ALIGN
.InvInfo:
	test	di, MFL_UPD_NFO			; Invalidate Info?
	jz		.Return					;  If not, return
	test	di, MFL_UPD_NOCLEAR		; Keep background?
	jnz		.DrawInfo				;  If not, jump to draw
	call	MenuDraw_InfoBorders	; Draw borders
ALIGN JUMP_ALIGN
.DrawInfo:
	call	MenuDraw_InfoNoBord		; Draw info without borders
ALIGN JUMP_ALIGN
.Return:
	pop		di
	ret


;--------------------------------------------------------------------
; Starts or stops menu selection timeout.
;
; Menu_StopTimeout		; Stops timeout
; Menu_StartTimeout		; Starts timeout with new value
; Menu_RestartTimeout	; Restarts timeout with previous value
;	Parameters:
;		AX:		New timeout value in ms (for Menu_StartTimeout only)
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_StopTimeout:
	xor		ax, ax
ALIGN JUMP_ALIGN
Menu_StartTimeout:
	push	dx
	push	bx
	xor		dx, dx
	mov		bx, 55						; 1 timer tick = 54.945ms
	div		bx							; DX:AX / 55
	mov		[bp+MENUVARS.wTimeInit], ax	; Store timer tick count
	mov		[bp+MENUVARS.wTimeout], ax
	pop		bx
	pop		dx
	ret
ALIGN JUMP_ALIGN
Menu_RestartTimeout:
	mov		ax, [bp+MENUVARS.wTimeInit]
	mov		[bp+MENUVARS.wTimeout], ax
	ret


;--------------------------------------------------------------------
; Returns system time in clock ticks. One tick is 54.95ms.
;
; Menu_GetTime
;	Parameters:
;		Nothing
;	Returns:
;		AL:		Midnight flag, set if midnight passed since last read
;		CX:DX:	Number of clock ticks since midnight
;	Corrupts registers:
;		AH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_GetTime:
	xor		ah, ah				; Get System Time
	int		1Ah
	ret


;--------------------------------------------------------------------
; Checks if Menuitem is currently visible.
;
; Menu_IsItemVisible
;	Parameters:
;		AX:		Menuitem index
;		SS:BP:	Ptr to MENUVARS
;	Returns:
;		CF:		Set if Menuitem is visible
;				Cleared if Menuitem is not visible
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_IsItemVisible:
	push	dx
	mov		dx, [bp+MENUVARS.wItemTop]		; Load index of first visible
	cmp		ax, dx							; First visible menuitem?
	jb		.RetFalse						;  If below, return false
	add		dl, [bp+MENUVARS.bVisCnt]		; Inc to one past...
	adc		dh, 0							; ...last visible menuitem
	cmp		ax, dx							; Over last visible or not?
	cmc										; Either way, fall through
ALIGN JUMP_ALIGN							; CF will reflect TRUE/FALSE
.RetFalse:
	cmc
	pop		dx
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Optional Dialog functions start here ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%ifdef USE_MENU_DIALOGS

;--------------------------------------------------------------------
; Shows message dialog to display string.
; String can be multiple lines but line feeds will be determined
; by menu system.
;
; Menu_ShowMsgDlg
;	Parameters:
;		BL:		Dialog width with borders included
;		SS:BP:	Ptr to MENUVARS
;		ES:DI:	Ptr to STOP terminated string to display
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_ShowMsgDlg:
	call	MenuMsg_ShowMessage
	jmp		Menu_RefreshMenu


;--------------------------------------------------------------------
; Shows dialog that asks unsigned DWORD from user.
;
; Menu_ShowDWDlg
;	Parameters:
;		BL:		Dialog width with borders included
;		CX:		Numeric base (10=dec, 16=hex...)
;		SS:BP:	Ptr to MENUVARS
;		ES:DI:	Ptr to STOP terminated string to display
;	Returns:
;		DX:AX:	User inputted data
;		CF:		Set if user data inputted successfully
;				Cleared is input cancelled
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_ShowDWDlg:
	mov		dx, MenuDlg_DWEvent	; Offset to event handler
	call	MenuDlg_Show
	push	ax
	push	dx
	pushf
	call	Menu_RefreshMenu
	popf
	pop		dx
	pop		ax
	ret


;--------------------------------------------------------------------
; Shows dialog that asks Y/N input from user.
;
; Menu_ShowYNDlg
;	Parameters:
;		BL:		Dialog width with borders included
;		SS:BP:	Ptr to MENUVARS
;		ES:DI:	Ptr to STOP terminated string to display
;	Returns:
;		AX:		'Y' if Y pressed
;				'N' if N pressed
;				Zero if ESC pressed
;		CF:		Set if Y pressed
;				Cleared if N or ESC pressed
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_ShowYNDlg:
	mov		dx, MenuDlg_YNEvent	; Offset to event handler
	jmp		ContinueMenuShowDlg


;--------------------------------------------------------------------
; Shows dialog that asks any string from user.
;
; Menu_ShowStrDlg
;	Parameters:
;		BL:		Dialog width with borders included
;		CX:		Buffer length with STOP included
;		SS:BP:	Ptr to MENUVARS
;		ES:DI:	Ptr to STOP terminated string to display
;		DS:SI:	Prt to buffer to receive string
;	Returns:
;		AX:		String length in characters without STOP
;		CF:		Set if string inputted successfully
;				Cleared if user cancellation
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_ShowStrDlg:
	mov		dx, MenuDlg_StrEvent	; Offset to event handler
ContinueMenuShowDlg:
	call	MenuDlg_Show
	push	ax
	pushf
	call	Menu_RefreshMenu
	popf
	pop		ax
	ret


;--------------------------------------------------------------------
; Shows progress bar dialog.
;
; Menu_ShowProgDlg
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
Menu_ShowProgDlg:
	call	MenuProg_Show
	push	ax
	call	Menu_RefreshMenu
	pop		ax
	ret


;--------------------------------------------------------------------
; Shows dialog that user can use to select file.
;
; Menu_ShowFileDlg
;	Parameters:
;		BL:		Dialog width with borders included
;		SS:BP:	Ptr to MENUVARS
;		ES:DI:	Ptr to STOP terminated info string
;		DS:SI:	Ptr to file search string (* and ? wildcards supported)
;	Returns:
;		DS:SI:	Ptr to DTA for selected file
;		CF:		Set if file selected successfully
;				Cleared if user cancellation
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Menu_ShowFileDlg:
	call	MenuFile_ShowDlg
	pushf
	call	Menu_RefreshMenu
	popf
	ret


%endif ; USE_MENU_DIALOGS
