; Project name	:	Assembly Library
; Description	:	Functions for register operations.

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
; Registers_ExchangeDSSIwithESDI
;	Parameters
;		Nothing
;	Returns:
;		DS:SI and ES:DI are exchanged.
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Registers_ExchangeDSSIwithESDI:
	push	ds
	push	es
	pop		ds
	pop		es
	xchg	si, di
	ret


;--------------------------------------------------------------------
; Registers_CopySSBPtoESDI
; Registers_CopySSBPtoDSSI
; Registers_CopyDSSItoESDI
; Registers_CopyESDItoDSSI
;	Parameters
;		Nothing
;	Returns:
;		Copies farm pointer to different segment/pointer register pair
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%ifdef INCLUDE_MENU_LIBRARY
ALIGN JUMP_ALIGN
Registers_CopySSBPtoESDI:
	COPY_SSBP_TO_ESDI
	ret
%endif

%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS
ALIGN JUMP_ALIGN
Registers_CopySSBPtoDSSI:
	COPY_SSBP_TO_DSSI
	ret

ALIGN JUMP_ALIGN
Registers_CopyDSSItoESDI:
	COPY_DSSI_TO_ESDI
	ret

ALIGN JUMP_ALIGN
Registers_CopyESDItoDSSI:
	COPY_ESDI_to_DSSI
	ret
%endif


;--------------------------------------------------------------------
; Registers_NormalizeESSI
; Registers_NormalizeESDI
;	Parameters
;		DS:SI or ES:DI:	Ptr to normalize
;	Returns:
;		DS:SI or ES:DI:	Normalized pointer
;	Corrupts registers:
;		AX, CX
;
; Inline of NORMALIZE_FAR_POINTER so that we can share the last 2/3 of the
; routine with Registers_NormalizeFinish.
;
;--------------------------------------------------------------------
%ifndef EXCLUDE_FROM_XTIDE_UNIVERSAL_BIOS OR EXCLUDE_FROM_XTIDECFG
ALIGN JUMP_ALIGN
Registers_NormalizeESSI:
	mov			cx, si
	and			si, byte 0fh
	jmp			Registers_NormalizeFinish

ALIGN JUMP_ALIGN
Registers_NormalizeESDI:
	mov			cx, di
	and			di, byte 0fh
;;; fall-through

ALIGN JUMP_ALIGN
Registers_NormalizeFinish:
	eSHR_IM		cx, 4
	mov			ax, es
	add			ax, cx
	mov			es, ax
	ret
%endif


;--------------------------------------------------------------------
; Registers_SetZFifNullPointerInDSSI (commented to save bytes)
;	Parameters
;		DS:SI:	Far pointer
;	Returns:
;		ZF:		Set if NULL pointer in DS:SI
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
;Registers_SetZFifNullPointerInDSSI:
;	push	ax
;	mov		ax, ds
;	or		ax, si
;	pop		ax
;	ret
