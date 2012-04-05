; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for printing boot related strings.

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
; BootPrint_FailedToLoadFirstSector
;	Parameters:
;		AH:		INT 13h error code
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, SI, DI
;--------------------------------------------------------------------
BootPrint_FailedToLoadFirstSector:
	push	bp
	mov		bp, sp
	eMOVZX	cx, ah
	push	cx					; Push INT 13h error code
	mov		si, g_szReadError
		
	jmp		short BootMenuPrint_FormatCSSIfromParamsInSSBP_Relay
		

;--------------------------------------------------------------------
; BootPrint_TryToBootFromDL
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
BootPrint_TryToBootFromDL:
	push	bp
	mov		bp, sp

	mov		ax, g_szHDD
	test	dl, dl
	js		SHORT .NotFDD
	mov		ax, g_szFDD
.NotFDD:
	push	ax

	call	DriveXlate_ToOrBack
	push	dx					; Push untranslated drive number
	call	DriveXlate_ToOrBack
	push	dx					; Push translated drive number

	mov		si, g_szTryToBoot
	jmp		short BootMenuPrint_FormatCSSIfromParamsInSSBP_Relay		



