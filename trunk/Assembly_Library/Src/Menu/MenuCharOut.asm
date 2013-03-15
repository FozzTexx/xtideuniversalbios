; Project name	:	Assembly Library
; Description	:	Character out function for printing within menu window.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
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
; MenuCharOut_MenuTeletypeOutputWithAutomaticLineChange
; MenuCharOut_MenuTeletypeOutput
;	Parameters:
;		AL:		Character to output
;		AH:		Attribute to output
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to video memory where to output
;		[DISPLAY_CONTEXT.wCharOutParam]:
;				Low byte  = First column offset (after CR)
;				High byte = Last column offset (when using automatic line change)
;	Returns:
;		DI:		Incremented for next character
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuCharOut_MenuTeletypeOutputWithAutomaticLineChange:
	call	CharOutLineSplitter_IsCursorAtTheEndOfTextLine
	jnc		SHORT MenuCharOut_MenuTeletypeOutput
	cmp		al, ' '
	jb		SHORT ReturnSinceNoNeedToStartLineWithControlCharacter
	call	CharOutLineSplitter_MovePartialWordToNewTextLine
	; Fall to MenuCharOut_MenuTextTeletypeOutputWithAttribute

ALIGN MENU_JUMP_ALIGN
MenuCharOut_MenuTeletypeOutput:
	cmp		al, CR
	je		SHORT PrintCRandAdjustOffsetForStartOfLine
	jmp		DisplayCharOut_TeletypeOutputWithAttribute


;--------------------------------------------------------------------
; MenuCharOut_PrintLFCRandAdjustOffsetForStartOfLine
; PrintCRandAdjustOffsetForStartOfLine
;	Parameters:
;		DS:		BDA segment (zero)
;		ES:DI:	Ptr to cursor location
;		[DISPLAY_CONTEXT.wCharOutParam]:
;				Low byte  = First column offset (after CR)
;				High byte = Last column offset (when using automatic line change)
;	Returns:
;		ES:DI:	Ptr to beginning of new line
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
ALIGN MENU_JUMP_ALIGN
MenuCharOut_PrintLFCRandAdjustOffsetForStartOfLine:
	mov		al, LF
	call	DisplayCharOut_BiosTeletypeOutput
	; Fall to PrintCRandAdjustOffsetForStartOfLine

ALIGN MENU_JUMP_ALIGN
PrintCRandAdjustOffsetForStartOfLine:
	mov		al, CR
	call	DisplayCharOut_BiosTeletypeOutput
	eMOVZX	ax, [VIDEO_BDA.displayContext+DISPLAY_CONTEXT.wCharOutParam]
	add		di, ax
ReturnSinceNoNeedToStartLineWithControlCharacter:
	ret
