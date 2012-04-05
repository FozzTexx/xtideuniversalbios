; Project name	:	Assembly Library
; Description	:	Functions for rebooting computer.

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
; Reboot_ComputerWithBootFlagInAX
;	Parameters:
; 		AX:		Boot Flag
;	Returns:
;		Nothing, function never returns
;--------------------------------------------------------------------
Reboot_ComputerWithBootFlagInAX:
	LOAD_BDA_SEGMENT_TO	ds, bx
	mov		[BDA.wBoot], ax			; Store boot flag
	; Fall to Reboot_AT


;--------------------------------------------------------------------
; Reboot_AT
;	Parameters:
; 		Nothing
;	Returns:
;		Nothing, function never returns
;--------------------------------------------------------------------
Reboot_AT:
	mov		al, 0FEh				; System reset (AT+ keyboard controller)
	out		64h, al					; Reset computer (AT+)
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
	%ifdef INCLUDE_TIME_LIBRARY
		mov		ax, 10
		call	Delay_MicrosecondsFromAX
	%else
		JMP_DELAY
	%endif
%else
	JMP_DELAY
%endif
	; Fall to Reboot_XT


;--------------------------------------------------------------------
; Reboot_XT
;	Parameters:
; 		Nothing
;	Returns:
;		Nothing, function never returns
;--------------------------------------------------------------------
Reboot_XT:
	xor		ax, ax
	push	ax
	popf							; Clear FLAGS (disables interrupt)
	mov		ds, ax
	mov		es, ax
	mov		ss, ax
	jmp		0FFFFh:0				; XT reset
