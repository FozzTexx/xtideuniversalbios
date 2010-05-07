; File name		:	menudlg.asm
; Project name	:	Menu library
; Created date	:	17.11.2009
; Last update	:	4.12.2009
; Author		:	Tomi Tilli
; Description	:	ASM library to menu system.
;					Contains functions for displaying input dialogs.

;--------------- Equates -----------------------------

; Dialog init and return variables.
; This is an expanded MSGVARS struct.
struc DLGVARS
	.msgVars	resb	MSGVARS_size

	; Dialog parameters for different dialogs
	.wCXPrm:	
	.wPrmBase:				; Numeric base for DWORD dialog (10=dec, 16=hex...)
	.wBuffLen	resb	2	; Buffer length for string dialog (with STOP included)
	.dwBuffPtr	resb	4	; Far pointer to buffer to receive string

	; Return variables for different dialogs
	.dwReturn:
	.dwRetDW:				; DWORD inputted by user
	.wRetLen	resb	4	; Length of string inputted by user (chars without STOP)
	.fSuccess	resb	1	; Was data inputted successfully by user
				resb	1	; Alignment
endstruc


;-------------- Private global variables -------------
; Section containing initialized data
;SECTION .data

g_strYN:	db	"Y/N: ",STOP	; For asking Y/N input


;-------------- Public functions ---------------------
; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Displays dialog.
;
; MenuDlg_Show
;	Parameters:
;		BL:		Dialog width with borders included
;		CX:		Word parameter for dialog event handler
;		DX:		Offset to dialog event handler
;		SS:BP:	Ptr to MENUVARS
;		DS:SI	Pointer parameter for dialog event handler
;		ES:DI:	Ptr to STOP terminated string to display
;	Returns:
;		DX:AX:	User inputted data
;		CF:		Set if user data inputted successfully
;				Cleared is input cancelled
;	Corrupts registers:
;		BX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDlg_Show:
	; Create stack frame
	eENTER	DLGVARS_size, 0
	sub		bp, DLGVARS_size				; Point to DLGVARS

	; Initialize menu variables
	mov		[bp+MENUVARS.bWidth], bl		; Menu width
	mov		WORD [bp+MENUVARS.wTopDwnH], 0100h	; Title and Info size
	mov		[bp+MENUVARS.fnEvent], dx		; Store handler offset
	mov		[bp+MSGVARS.wStrOff], di		; Store far ptr...
	mov		[bp+MSGVARS.wStrSeg], es		; ...to string to display
	mov		[bp+DLGVARS.wCXPrm], cx			; Store word parameter
	mov		[bp+DLGVARS.dwBuffPtr], si		; Store far pointer...
	mov		[bp+DLGVARS.dwBuffPtr+2], ds	; ...parameter

	; Enter menu
	call	MenuMsg_GetLineCnt				; Get message line count to CX
	mov		ax, CNT_SCRN_ROW-4				; Load max line count without borders and info
	MIN_U	ax, cx							; String lines to display to AX
	add		al, 4							; Add borders for dlg height
	mov		[bp+MENUVARS.bHeight], al		; Store dialog height
	call	MenuCrsr_GetCenter				; Get X and Y coordinates to DX
	xor		ax, ax							; Selection timeout (disable)
	mov		bl, FLG_MNU_NOARRW				; Menu flags
	call	Menu_Init						; Returns only after dlg closed
	call	MenuCrsr_Hide					; Hide cursor again

	; Return
	mov		ax, [bp+DLGVARS.dwReturn]		; Load return loword
	mov		dx, [bp+DLGVARS.dwReturn+2]		; Load return hiword
	mov		bl, [bp+DLGVARS.fSuccess]		; Load success flag
	add		bp, DLGVARS_size				; Point to old BP
	eLEAVE									; Destroy stack frame
	rcr		bl, 1							; Move success flag to CF
	ret


;-------------- Private functions ---------------------

;--------------------------------------------------------------------
; DWORD input dialog event handler.
;
; MenuDlg_DWEvent
;	Parameters:
;		BX:		Callback event
;		CX:		Selected menuitem index
;		DX:		Event parameter (event specific)
;		SS:BP:	Ptr to DLGVARS
;	Returns:
;		AH:		Event specific or unused
;		AL:		1=Event processed
;				0=Event not processed (default action if any)
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDlg_DWEvent:
	cmp		bx, EVNT_MNU_UPD			; Update strings?
	jne		MenuDlg_JmpToMsgEvnt		;  If not, use message handler
	test	dl, MFL_UPD_NFO				; Update info strings?
	jz		MenuDlg_JmpToMsgEvnt		;  If not, use message handler

	; Get user input instead of drawing info strings
	call	MenuCrsr_Show				; Show cursor during input
	mov		cx, [bp+DLGVARS.wPrmBase]	; Load numeric base to CX
	eMOVZX	dx, [bp+MENUVARS.bWidth]	; Load dialog width
	sub		dx, 4						; Subtract borders for max char count
	call	Keys_PrintGetUint			; Get DWORD
	mov		[bp+DLGVARS.dwRetDW], ax	; Store return loword
	mov		[bp+DLGVARS.dwRetDW+2], dx	; Store return hiword
	rcl		BYTE [bp+DLGVARS.fSuccess], 1	; Set or clear success flag

	; Exit menu
ALIGN JUMP_ALIGN
MenuDlg_ExitHandler:
	or		BYTE [bp+MENUVARS.bFlags], FLG_MNU_EXIT
	mov		ax, 1
	ret

ALIGN JUMP_ALIGN
MenuDlg_JmpToMsgEvnt:
	jmp		MenuMsg_MsgEvent


;--------------------------------------------------------------------
; Y/N dialog event handler.
;
; MenuDlg_YNEvent
;	Parameters:
;		BX:		Callback event
;		CX:		Selected menuitem index
;		DX:		Event parameter (event specific)
;		SS:BP:	Ptr to DLGVARS
;	Returns:
;		AH:		Event specific or unused
;		AL:		1=Event processed
;				0=Event not processed (default action if any)
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDlg_YNEvent:
	cmp		bx, EVNT_MNU_UPD			; Update strings?
	jne		MenuDlg_JmpToMsgEvnt		;  If not, use message handler
	test	dl, MFL_UPD_NFO				; Update info strings?
	jz		MenuDlg_JmpToMsgEvnt		;  If not, use message handler

	; Draw info string
	push	ds
	push	cs
	pop		ds
	mov		dx, g_strYN					; Y/N string in DS:DX
	PRINT_STR
	pop		ds

	; Wait for user input
	call	MenuCrsr_Show				; Show cursor during input
	call	Keys_PrintGetYN
	mov		[bp+DLGVARS.dwReturn], ax		; Store return char
	rcl		BYTE [bp+DLGVARS.fSuccess], 1	; Set or clear Y/N flag
	jmp		MenuDlg_ExitHandler


;--------------------------------------------------------------------
; String dialog event handler.
;
; MenuDlg_StrEvent
;	Parameters:
;		BX:		Callback event
;		CX:		Selected menuitem index
;		DX:		Event parameter (event specific)
;		SS:BP:	Ptr to DLGVARS
;	Returns:
;		AH:		Event specific or unused
;		AL:		1=Event processed
;				0=Event not processed (default action if any)
;	Corrupts registers:
;		BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
MenuDlg_StrEvent:
	cmp		bx, EVNT_MNU_UPD			; Update strings?
	jne		MenuDlg_JmpToMsgEvnt		;  If not, use message handler
	test	dl, MFL_UPD_NFO				; Update info strings?
	jz		MenuDlg_JmpToMsgEvnt		;  If not, use message handler

	; Get string from user
	push	es
	push	di
	call	MenuCrsr_Show				; Show cursor during input
	mov		bx, .VerifyChar				; Load offset to char verify function
	mov		dx, [bp+DLGVARS.wBuffLen]	; Load buffer length
	mov		di, [bp+DLGVARS.dwBuffPtr]	; Load buffer offset
	mov		es, [bp+DLGVARS.dwBuffPtr+2]; Load buffer segment
	call	Keys_GetStrToBuffer			; Get string from user
	mov		[bp+DLGVARS.wRetLen], ax	; Store string length
	rcl		BYTE [bp+DLGVARS.fSuccess], 1	; Set or clear success flag
	pop		di
	pop		es
	jmp		MenuDlg_ExitHandler
ALIGN JUMP_ALIGN
.VerifyChar:
	stc									; Set CF to allow all chars
	ret
