; Project name	:	XTIDE Universal BIOS
; Description	:	Int 19h Handler (Boot Loader).

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
; INT 19h handler that properly reboots the computer when
; INT 19h is called.
;
; Int19hReset_Handler
;	Parameters:
;		Nothing
;	Returns:
;		Never returns (reboots computer)
;--------------------------------------------------------------------
Int19hReset_Handler:
	mov		ax, BOOT_FLAG_WARM				; Skip memory tests
	jmp		Reboot_ComputerWithBootFlagInAX
