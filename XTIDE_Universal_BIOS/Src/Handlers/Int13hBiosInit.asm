; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h handler that is used to initialize
;					XTIDE Universal BIOS when our INT 19h was not called.

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

TEMPORARY_VECTOR_FOR_SYSTEM_INT13h		EQU		32h	; Unused by BIOS


;--------------------------------------------------------------------
; Int 13h software interrupt handler.
; This handler captures boot sector read from foreign drive when our
; INT 19h is not called. This way we can for XTIDE Universal BIOS
; initialization even without INT 19h being called.
;
; Int13hBiosInit_Handler
;	Parameters:
;		AH:		Bios function
;				READ_SECTORS_INTO_MEMORY will initialize XTIDE Universal BIOS
;--------------------------------------------------------------------
Int13hBiosInit_Handler:
	; Initialize XTIDE Universal BIOS only if Int13hBiosInit_Handler is still at
	; vector 13h. Otherwise some other BIOS has hooked us and our very late
	; initialization is not possible.
	push	ds
	push	ax
	LOAD_BDA_SEGMENT_TO	ds, ax
	pop		ax
	cmp		WORD [BIOS_DISK_INTERRUPT_13h*4], Int13hBiosInit_Handler
	pop		ds
	jne		SHORT .VeryLateInitFailed	; XTIDE Universal BIOS does not work

	; Ignore all but read command (assumed to read boot sector)
	cmp		ah, READ_SECTORS_INTO_MEMORY
	je		SHORT Int19h_BootLoaderHandler

	; Call system INT 13h since not trying to read boot sector
	int		TEMPORARY_VECTOR_FOR_SYSTEM_INT13h
	retf	2

.VeryLateInitFailed:
	mov		ah, RET_HD_INVALID
	stc
	retf	2
