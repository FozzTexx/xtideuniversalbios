; Project name	:	Assembly Library
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
	pushf
	push	di
	push	bx
	push	ax

	mov		ax, %1
	mov		bx, %2
	CALL_DISPLAY_LIBRARY PrintWordFromAXwithBaseInBX
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	call	Keyboard_RemoveAllKeystrokesFromBuffer
%endif
	call	Keyboard_GetKeystrokeToAXandWaitIfNecessary

	pop		ax
	pop		bx
	pop		di
	popf
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
	pushf
	push	di
	push	ax

	mov		al, %1
	CALL_DISPLAY_LIBRARY PrintCharacterFromAL
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	call	Keyboard_RemoveAllKeystrokesFromBuffer
%endif
	call	Keyboard_GetKeystrokeToAXandWaitIfNecessary

	pop		ax
	pop		di
	popf
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
	pushf
	push	di
	push	ax
	mov		al, %1
	CALL_DISPLAY_LIBRARY PrintCharacterFromAL
	pop		ax
	pop		di
	popf
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
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	call	Keyboard_RemoveAllKeystrokesFromBuffer
%endif
	call	Keyboard_GetKeystrokeToAXandWaitIfNecessary
	pop		ax
%endmacro


%endif ; DEBUG_INC
