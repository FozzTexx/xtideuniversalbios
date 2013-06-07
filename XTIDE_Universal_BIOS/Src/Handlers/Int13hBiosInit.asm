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

TEMPORARY_VECTOR_FOR_SYSTEM_INT13h		EQU		21h	; MS-DOS


Int13hBiosInit_Handler:
	LOAD_BDA_SEGMENT_TO	ds, ax

	; Restore system INT 13h handler that we backuped
	les		ax, [TEMPORARY_VECTOR_FOR_SYSTEM_INT13h*4]
	mov		[BIOS_DISK_INTERRUPT_13h*4], ax
	mov		[BIOS_DISK_INTERRUPT_13h*4+2], es

	; Now install our handler and call 19h since non-standard motherboard BIOS did not
	; do that or our INT 19h hander was replaced by other BIOS.
	mov		WORD [BIOS_BOOT_LOADER_INTERRUPT_19h*4], Int19h_BootLoaderHandler
	mov		[BIOS_BOOT_LOADER_INTERRUPT_19h*4+2], cs
	int		BIOS_BOOT_LOADER_INTERRUPT_19h	; Does not return
