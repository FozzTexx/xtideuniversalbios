; /*
; Project name	:	XTIDE Universal BIOS
; Description	:	Version information.

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

; Flash signature revisions:
; XTIDE205	Added DEVICE_8BIT_XTCF_PIO16_WITH_BIU_OFFLOAD after other XT-CF
;			PIO modes (prevents empty indexes in PIO jump tables)
;

;--------------------------------------------------------------------------------
;
; Assembler Version
;

%ifndef VERSION_INC
%define VERSION_INC


%define TITLE_STRING_START	"-=XTIDE Universal BIOS "
%ifdef USE_AT
	%ifdef USE_386
		%define	TITLE_STRING_END	"(386)=-",NULL
	%else
		%define	TITLE_STRING_END	"(AT)=-",NULL
	%endif
%elifdef USE_186
	%define	TITLE_STRING_END	"(XT+)=-",NULL
%else
	%define	TITLE_STRING_END	"(XT)=-",NULL
%endif

%define	TITLE_STRING			TITLE_STRING_START, TITLE_STRING_END
%define	ROM_VERSION_STRING		"v2.0.0",BETA,"3+ (",__DATE__,")",NULL
%define	FLASH_SIGNATURE			"XTIDE205"	; Do not terminate with NULL


%endif ; VERSION_INC

%if 0			; equivalent of a NASM comment block
;*/

//--------------------------------------------------------------------------------
//
// C/C++ Version
//

#define BETA " Beta "

#define ROM_VERSION_STRING		"v2.0.0" BETA "3 (" __DATE__ ")"

/*
%endif
;*/
