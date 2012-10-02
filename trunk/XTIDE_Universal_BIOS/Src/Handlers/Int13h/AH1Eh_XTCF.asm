; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=1Eh, Lo-tech XT-CF features.

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
; Int 13h function AH=1Eh, Lo-tech XT-CF features.
; This function is supported only by XTIDE Universal BIOS.
;
; AH1Eh_HandlerForXTCFfeatures
;	Parameters:
;		AL, CX:	Same as in INTPACK
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Parameters on INTPACK:
;		AL:		XT-CF subcommand (see XTCF.inc for more info)
;	Returns with INTPACK:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;--------------------------------------------------------------------
AH1Eh_HandlerForXTCFfeatures:
	xor		ah, ah		; Subcommand now in AX
%ifndef USE_186
	call	AH1Eh_ProcessXTCFsubcommandFromAX
	jmp		Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%else
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	; Fall to AH1Eh_ProcessXTCFsubcommandFromAX
%endif


;--------------------------------------------------------------------
; AH1Eh_ProcessXTCFsubcommandFromAX
;	Parameters:
;		AX:		XT-CF subcommand (see XTCF.inc for more info)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		AH:		Int 13h return status
;		CF:		0 if successful, 1 if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
AH1Eh_ProcessXTCFsubcommandFromAX:
	; IS_THIS_DRIVE_XTCF. We check this for all commands.
	dec		ax		; Subcommand
	mov		dx, [di+DPT.wXTCFport]
	test	dx, dx	; Never zero for XT-CF, Always zero for other devices
	jz		SHORT XTCFnotFound

	; READ_XTCF_CONTROL_REGISTER_TO_DH
	add		dl, XTCF_CONTROL_REGISTER	; DX to Control Register
	dec		ax		; Subcommand
	jnz		SHORT .SkipReadXtcfControlRegisterToDH
	in		al, dx
	mov		[bp+IDEPACK.intpack+INTPACK.dh], al
	jmp		SHORT .ReturnWithSuccess
.SkipReadXtcfControlRegisterToDH:

	; WRITE_DH_TO_XTCF_CONTROL_REGISTER
	dec		ax		; Subcommand
	jnz		SHORT XTCFnotFound			; Invalid subcommand
	mov		al, [bp+IDEPACK.intpack+INTPACK.dh]
	out		dx, al
.ReturnWithSuccess:
	xor		ah, ah
	ret


;--------------------------------------------------------------------
; AH1Eh_DetectXTCFwithBasePortInDX
;	Parameters:
;		DX:		Base I/O port address to check
;	Returns:
;		AH:		RET_HD_SUCCESS if XT-CF is found from port
;				RET_HD_INVALID if XT-CF is not found
;		CF:		Cleared if XT-CF found
;				Set if XT-CF not found
;	Corrupts registers:
;		AL, DX
;--------------------------------------------------------------------
AH1Eh_DetectXTCFwithBasePortInDX:
	add		dl, XTCT_CONTROL_REGISTER_INVERTED_in	; set DX to XT-CF config register (inverted)
	in		al, dx		; get value
	mov		ah, al		; save in ah
	inc		dx			; set DX to XT-CF config register (non-inverted)
	in		al, dx		; get value
	not		al			; invert it
	sub		ah, al		; do they match? (clear AH if they do)
	jz		SHORT XTCFfound

XTCFnotFound:
	stc					; set carry flag since XT-CF not found
	mov		ah, RET_HD_INVALID
XTCFfound:
	ret					; and return
