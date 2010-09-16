; File name		:	Debug.inc
; Project name	:	Assembly Library
; Created date	:	8.8.2010
; Last update	:	8.8.2010
; Author		:	Tomi Tilli
; Description	:	Debugging macros.
%ifndef DEBUG_INC
%define DEBUG_INC


;--------------------------------------------------------------------
; DISPLAY_DEBUG_WORD_AND_WAIT_ANY_KEY
;	Parameters:
;		%1:		Debug word
;		%2:		Numeric base (2, 10, 16)
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro DISPLAY_DEBUG_WORD_AND_WAIT_ANY_KEY 2
	push	di
	push	bx
	push	ax

	mov		ax, %1
	mov		bx, %2
	CALL_DISPLAY_LIBRARY PrintWordFromAXwithBaseInBX
	call	Keyboard_RemoveAllKeystrokesFromBuffer
	call	Keyboard_GetKeystrokeToAXandWaitIfNecessary

	pop		ax
	pop		bx
	pop		di
%endmacro


;--------------------------------------------------------------------
; DISPLAY_DEBUG_CHARACTER_AND_WAIT_ANY_KEY
;	Parameters:
;		%1:		Character to print
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro DISPLAY_DEBUG_CHARACTER_AND_WAIT_ANY_KEY 1
	push	di
	push	ax

	mov		al, %1
	CALL_DISPLAY_LIBRARY PrintCharacterFromAL
	call	Keyboard_RemoveAllKeystrokesFromBuffer
	call	Keyboard_GetKeystrokeToAXandWaitIfNecessary

	pop		ax
	pop		di
%endmacro


;--------------------------------------------------------------------
; DISPLAY_DEBUG_CHARACTER
;	Parameters:
;		%1:		Character to print
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro DISPLAY_DEBUG_CHARACTER 1
	push	di
	push	ax
	mov		al, %1
	CALL_DISPLAY_LIBRARY PrintCharacterFromAL
	pop		ax
	pop		di
%endmacro


;--------------------------------------------------------------------
; WAIT_ANY_KEY_TO_CONTINUE
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro WAIT_ANY_KEY_TO_CONTINUE 0
	push	ax
	call	Keyboard_RemoveAllKeystrokesFromBuffer
	call	Keyboard_GetKeystrokeToAXandWaitIfNecessary
	pop		ax
%endmacro



%endif ; DEBUG_INC
