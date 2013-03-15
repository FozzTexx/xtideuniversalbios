; Project name	:	XTIDE Universal BIOS
; Description	:	Macros for normal I/O mapped ATA controllers.

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

%ifndef IDE_IO_INC
%define IDE_IO_INC

;--------------------------------------------------------------------
; OUTPUT_AL_TO_IDE_REGISTER
; OUTPUT_AL_TO_IDE_CONTROL_BLOCK_REGISTER
;	Parameters:
;		AL:		Byte to output
;		%1:		IDE Register				(OUTPUT_AL_TO_IDE_REGISTER)
;				IDE Control Block Register	(OUTPUT_AL_TO_IDE_CONTROL_BLOCK_REGISTER)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
%macro OUTPUT_AL_TO_IDE_REGISTER 1
%ifndef MODULE_8BIT_IDE	; Standard IDE controllers only

	%ifnidni %1, dx
		mov		dx, %1
	%endif
	add		dx, [di+DPT.wBasePort]
	out		dx, al

%else	; Register translations required

	%ifnidni %1, dl
		mov		dl, %1
	%endif
	call	IdeIO_OutputALtoIdeRegisterInDL

%endif
%endmacro


%macro OUTPUT_AL_TO_IDE_CONTROL_BLOCK_REGISTER 1
%ifndef MODULE_8BIT_IDE	; Standard IDE controllers only

	%ifnidni %1, dx
		mov		dx, %1
	%endif
	eMOVZX	bx, BYTE [di+DPT.bIdevarsOffset]
	add		dx, [cs:bx+IDEVARS.wControlBlockPort]
	out		dx, al

%else	; Register translations required

	%ifnidni %1, dl
		mov		dl, %1
	%endif
	call	IdeIO_OutputALtoIdeControlBlockRegisterInDL

%endif
%endmacro


;--------------------------------------------------------------------
; INPUT_TO_AL_FROM_IDE_REGISTER
;	Parameters:
;		%1:		IDE Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AL:		Inputted byte
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
%macro INPUT_TO_AL_FROM_IDE_REGISTER 1
%ifndef MODULE_8BIT_IDE	; Standard IDE controllers only

	%ifnidni %1, dx
		mov		dx, %1
	%endif
	add		dx, [di+DPT.wBasePort]
	in		al, dx

%else	; Register translations required

	%ifnidni %1, dl
		mov		dl, %1
	%endif
		call	IdeIO_InputToALfromIdeRegisterInDL

%endif
%endmacro


%endif ; IDE_IO_INC
