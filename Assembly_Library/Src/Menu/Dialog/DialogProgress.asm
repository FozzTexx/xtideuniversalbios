; Project name	:	Assembly Library
; Description	:	Displays progress bar dialog and starts progress task.

;
; XTIDE Universal BIOS and Associated Tools 
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.		
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;
		

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; DialogProgress_GetStringWithIoInDSSI
;	Parameters:
;		DS:SI:	Ptr to PROGRESS_DIALOG_IO
;		SS:BP:	Ptr to parent MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DialogProgress_StartProgressTaskWithIoInDSSIandParamInDXAX:
	mov		bx, ProgressEventHandler
	jmp		Dialog_DisplayWithDialogInputInDSSIandHandlerInBX


;--------------------------------------------------------------------
; DialogProgress_SetProgressValueFromAX
;	Parameters
;		AX:		Progress bar value to set
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DialogProgress_SetProgressValueFromAX:
	push	ds

	lds		si, [bp+DIALOG.fpDialogIO]
	mov		bx, [si+PROGRESS_DIALOG_IO.wMaxProgressValue]
	cmp		ax, bx
	jb		SHORT .AXlessThanBX
	mov		ax, bx
	jmp		SHORT .UpdateProgressBar
ALIGN JUMP_ALIGN
.AXlessThanBX:
	mov		bx, ax
	sub		bx, [si+PROGRESS_DIALOG_IO.wCurrentProgressValue]
	cmp		bx, [si+PROGRESS_DIALOG_IO.wProgressPerCharacter]
	jb		SHORT .ReturnWithoutUpdate
.UpdateProgressBar:
	mov		[si+PROGRESS_DIALOG_IO.wCurrentProgressValue], ax
	xor		ax, ax
	call	MenuText_RefreshItemFromAX
	call	MenuText_RefreshInformation
ALIGN JUMP_ALIGN
.ReturnWithoutUpdate:
	pop		ds
	ret


;--------------------------------------------------------------------
; ProgressEventHandler
;	Common parameters for all events:
;		BX:			Menu event (anything from MENUEVENT struct)
;		SS:BP:		Ptr to DIALOG
;	Common return values for all events:
;		CF:			Set if event processed
;					Cleared if event not processed
;	Corrupts registers:
;		All
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ProgressEventHandler:
	jmp		[cs:bx+.rgfnEventHandlers]


ALIGN JUMP_ALIGN
.InitializeMenuinitFromDSSI:
	mov		ax, NO_ITEM_HIGHLIGHTED
	call	Dialog_EventInitializeMenuinitFromDSSIforSingleItemWithHighlightedItemInAX
	lds		si, [bp+DIALOG.fpDialogIO]
	call	TimerTicks_ReadFromBdaToAX
	mov		[si+PROGRESS_DIALOG_IO.wStartTimeTicks], ax

	; 0 = 65536 but it needs to be adjusted to 65535 prevent division by zero
	cmp		WORD [si+PROGRESS_DIALOG_IO.wMaxProgressValue], BYTE 0
	jne		SHORT CalculateProgressNeededBeforeUpdatingCharacter
	dec		WORD [si+PROGRESS_DIALOG_IO.wMaxProgressValue]
	jmp		SHORT CalculateProgressNeededBeforeUpdatingCharacter


ALIGN JUMP_ALIGN
.IdleProcessing:
	call	MenuInit_GetUserDataToDSSI
	les		di, [bp+DIALOG.fpDialogIO]
	push	bp
	call	[es:di+PROGRESS_DIALOG_IO.fnTaskWithParamInDSSI]
	pop		bp
	call	MenuInit_CloseMenuWindow
	stc
	ret


ALIGN JUMP_ALIGN
.RefreshItemFromCX:
	lds		si, [bp+DIALOG.fpDialogIO]
	call	DrawProgressBarFromDialogIoInDSSI
	stc
	ret


ALIGN JUMP_ALIGN
.RefreshInformation:
	lds		si, [bp+DIALOG.fpDialogIO]
	call	TimerTicks_ReadFromBdaToAX
	sub		ax, [si+PROGRESS_DIALOG_IO.wStartTimeTicks]
	xchg	dx, ax
	call	DrawTimeElapsedFromDX
	call	DrawTimeLeftFromProgressDialogIoInDSSIwithTimeElapsedInDX
	stc
	ret


ALIGN WORD_ALIGN
.rgfnEventHandlers:
istruc MENUEVENT
	at	MENUEVENT.InitializeMenuinitFromDSSI,	dw	.InitializeMenuinitFromDSSI
	at	MENUEVENT.ExitMenu,						dw	Dialog_EventExitMenu
	at	MENUEVENT.IdleProcessing,				dw	.IdleProcessing
	at	MENUEVENT.ItemHighlightedFromCX,		dw	Dialog_EventNotHandled
	at	MENUEVENT.ItemSelectedFromCX,			dw	Dialog_EventNotHandled
	at	MENUEVENT.KeyStrokeInAX,				dw	Dialog_EventNotHandled
	at	MENUEVENT.RefreshTitle,					dw	Dialog_EventRefreshTitle
	at	MENUEVENT.RefreshInformation,			dw	.RefreshInformation
	at	MENUEVENT.RefreshItemFromCX,			dw	.RefreshItemFromCX
iend


;--------------------------------------------------------------------
; CalculateProgressNeededBeforeUpdatingCharacter
;	Parameters:
;		DS:SI:	Ptr to PROGRESS_DIALOG_IO
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		CF:		Set since event handled
;	Corrupts:
;		AX, BX, DX, SI, DS
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CalculateProgressNeededBeforeUpdatingCharacter:
	call	MenuLocation_GetMaxTextLineLengthToAX
	call	GetProgressLengthToBXfromProgressDialogIoInDSSI
	xchg	ax, bx
	xor		dx, dx
	div		bx
	mov		[si+PROGRESS_DIALOG_IO.wProgressPerCharacter], ax
	stc
	ret


;--------------------------------------------------------------------
; DrawProgressBarFromDialogIoInDSSI
;	Parameters:
;		DS:SI:	Ptr to PROGRESS_DIALOG_IO
;		SS:BP:	Ptr to DIALOG
;	Returns:
;		Nothing
;	Corrupts:
;		AX, BX, CX, DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrawProgressBarFromDialogIoInDSSI:
	; Get full chars to CX and empty chars to DX
	call	MenuLocation_GetMaxTextLineLengthToAX
	mov		cx, ax
	mul		WORD [si+PROGRESS_DIALOG_IO.wCurrentProgressValue]
	call	GetProgressLengthToBXfromProgressDialogIoInDSSI
	div		bx
	xchg	cx, ax		; AX = Text line length, CX = Number of full chars
	sub		ax, cx
	xchg	dx, ax		; DX = Number of empty chars

	mov		al, PROGRESS_COMPLETE_CHARACTER
	call	.RepeatProgressCharacterCXtimesFromAL

	mov		cx, dx
	mov		al, PROGRESS_INCOMPLETE_CHARACTER
	; Fall to .RepeatProgressCharacterCXtimesFromAL

;--------------------------------------------------------------------
; .RepeatProgressCharacterCXtimesFromAL
;	Parameters:
;		AL:		Progress bar character to repeat
;		CX:		Number of times to repeat the progress character
;	Returns:
;		Nothing
;	Corrupts:
;		AX, CX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.RepeatProgressCharacterCXtimesFromAL:
	jcxz	.NothingToRepeat
	CALL_DISPLAY_LIBRARY PrintRepeatedCharacterFromALwithCountInCX
ALIGN JUMP_ALIGN, ret
.NothingToRepeat:
	ret


;--------------------------------------------------------------------
; GetProgressLengthToBXfromProgressDialogIoInDSSI
;	Parameters:
;		DS:SI:	Ptr to PROGRESS_DIALOG_IO
;	Returns:
;		BX:		Progress length
;	Corrupts:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetProgressLengthToBXfromProgressDialogIoInDSSI:
	mov		bx, [si+PROGRESS_DIALOG_IO.wMaxProgressValue]
	sub		bx, [si+PROGRESS_DIALOG_IO.wMinProgressValue]
	ret


;--------------------------------------------------------------------
; DrawTimeElapsedFromDX
;	Parameters:
;		DX:		Ticks elapsed
;	Returns:
;		Nothing
;	Corrupts:
;		AX, BX, CX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrawTimeElapsedFromDX:
	push	si
	push	dx

	mov		si, g_szTimeElapsed
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromCSSI
	call	FormatTicksFromDX

	pop		dx
	pop		si
	ret


;--------------------------------------------------------------------
; DrawTimeLeftFromProgressDialogIoInDSSIwithTimeElapsedInDX
;	Parameters:
;		DX:		Ticks elapsed
;		DS:SI:	Ptr to PROGRESS_DIALOG_IO
;	Returns:
;		Nothing
;	Corrupts:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DrawTimeLeftFromProgressDialogIoInDSSIwithTimeElapsedInDX:
	push	si
	mov		si, g_szTimeLeft
	CALL_DISPLAY_LIBRARY PrintNullTerminatedStringFromCSSI
	pop		si

	mov		cx, [si+PROGRESS_DIALOG_IO.wCurrentProgressValue]
	mov		ax, [si+PROGRESS_DIALOG_IO.wMaxProgressValue]
	sub		ax, cx
	mul		dx			; Progress left * elapsed time

	sub		cx, [si+PROGRESS_DIALOG_IO.wMinProgressValue]
	jz		SHORT .PreventDivisionByZero
	div		cx			; AX = Estimated ticks left
	xchg	dx, ax
	SKIP2B	f	; cmp ax, <next instruction>
.PreventDivisionByZero:
	xor		dx, dx
	; Fall to FormatTicksFromDX


;--------------------------------------------------------------------
; FormatTicksFromDX
;	Parameters:
;		DX:		Ticks to format
;	Returns:
;		Nothing
;	Corrupts:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FormatTicksFromDX:
	push	bp

	mov		bp, sp
	mov		si, g_szTimeFormat
	call	TimerTicks_GetMinutesToAXfromTicksInDX
	push	ax
	call	TimerTicks_GetSecondsToAXfromTicksInDX
	push	ax
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI

	pop		bp
	ret
