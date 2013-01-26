; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Register I/O functions when supporting 8-bit
;					devices that need address translations.

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
; IdeIO_InputStatusRegisterToAL
;	Parameters:
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AL:		IDE Status Register contents
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeIO_InputStatusRegisterToAL:
%ifndef MODULE_8BIT_IDE
	INPUT_TO_AL_FROM_IDE_REGISTER STATUS_REGISTER_in
	ret

%else
	mov		dl, STATUS_REGISTER_in
	; Fall to IdeIO_InputToALfromIdeRegisterInDL

;--------------------------------------------------------------------
; IdeIO_InputToALfromIdeRegisterInDL
;	Parameters:
;		DL:		IDE Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		AL:		Inputted byte
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
IdeIO_InputToALfromIdeRegisterInDL:
	xor		dh, dh	; IDE Register index now in DX
	mov		bx, dx	; and BX
	mov		al, [di+DPT_ATA.bDevice]
	cmp		al, DEVICE_8BIT_XTIDE_REV2
	je		SHORT .ReverseA0andA3fromRegisterIndexInDX
	jb		SHORT .InputToALfromRegisterInDX	; Standard IDE controllers and XTIDE rev 1
		
%ifdef MODULE_8BIT_IDE_ADVANCED
	cmp		al, DEVICE_8BIT_JRIDE_ISA
	jne		SHORT .ShlRegisterIndexInDX			; All XT-CF modes
	; Fall to .InputToALfromMemoryMappedRegisterInDX

.InputToALfromMemoryMappedRegisterInDX:
	push	ds
	mov		ds, [di+DPT.wBasePort]	; Segment for JR-IDE/ISA
	mov		al, [bx+JRIDE_COMMAND_BLOCK_REGISTER_WINDOW_OFFSET]
	pop		ds
	ret
%endif
		
.ReverseA0andA3fromRegisterIndexInDX:
	mov		dl, [cs:bx+g_rgbSwapA0andA3fromIdeRegisterIndex]
	SKIP2B	bx	; Skip shl dx, 1

.ShlRegisterIndexInDX:
	shl		dx, 1
	; Fall to .InputToALfromRegisterInDX

.InputToALfromRegisterInDX:
	add		dx, [di+DPT.wBasePort]
	in		al, dx
	ret


;--------------------------------------------------------------------
; IdeIO_OutputALtoIdeControlBlockRegisterInDL
;	Parameters:
;		AL:		Byte to output
;		DL:		IDE Control Block Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
IdeIO_OutputALtoIdeControlBlockRegisterInDL:
	xor		dh, dh	; IDE Register index now in DX

	mov		bl, [di+DPT_ATA.bDevice]
	cmp		bl, DEVICE_8BIT_XTIDE_REV2
	je		SHORT .ReverseA0andA3fromRegisterIndexInDX
	jb		SHORT .OutputALtoControlBlockRegisterInDX	; Standard IDE controllers and XTIDE rev 1

%ifdef MODULE_8BIT_IDE_ADVANCED
	cmp		bl, DEVICE_8BIT_JRIDE_ISA
	jne		SHORT .ShlRegisterIndexInDX		; All XT-CF modes
	; Fall to .OutputALtoMemoryMappedRegisterInDX

.OutputALtoMemoryMappedRegisterInDX:
	mov		bx, JRIDE_CONTROL_BLOCK_REGISTER_WINDOW_OFFSET
	jmp 	SHORT IdeIO_OutputALtoIdeRegisterInDL.OutputALtoMemoryMappedRegisterInDXwithWindowOffsetInBX
%endif

.ReverseA0andA3fromRegisterIndexInDX:
	; We cannot use lookup table since A3 will be always set because
	; Control Block Registers start from Command Block + 8h. We can do
	; a small trick since we only access Device Control Register at
	; offset 6h: Always clear A3 and set A0.
	add		dx, [cs:bx+IDEVARS.wControlBlockPort]
	xor		dl, 1001b						; Clear A3, Set A0
	jmp		SHORT OutputALtoPortInDX

.ShlRegisterIndexInDX:
	add		dl, XTCF_CONTROL_BLOCK_OFFSET
	shl		dx, 1
	jmp		SHORT OutputALtoRegisterInDX

.OutputALtoControlBlockRegisterInDX:
	call	AccessDPT_GetIdevarsToCSBX
	add		dx, [cs:bx+IDEVARS.wControlBlockPort]
	jmp		SHORT OutputALtoPortInDX


;--------------------------------------------------------------------
; IdeIO_OutputALtoIdeRegisterInDL
;	Parameters:
;		AL:		Byte to output
;		DL:		IDE Command Block Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeIO_OutputALtoIdeRegisterInDL:
	xor		dh, dh	; IDE Register index now in DX

	mov		bl, [di+DPT_ATA.bDevice]
	cmp		bl, DEVICE_8BIT_XTIDE_REV2
	je		SHORT .ReverseA0andA3fromRegisterIndexInDX
	jb		SHORT OutputALtoRegisterInDX	; Standard IDE controllers and XTIDE rev 1

%ifdef MODULE_8BIT_IDE_ADVANCED
	cmp		bl, DEVICE_8BIT_JRIDE_ISA
	jne		SHORT .ShlRegisterIndexInDX		; All XT-CF modes
	; Fall to .OutputALtoMemoryMappedRegisterInDX

.OutputALtoMemoryMappedRegisterInDX:
	mov		bx, JRIDE_COMMAND_BLOCK_REGISTER_WINDOW_OFFSET
.OutputALtoMemoryMappedRegisterInDXwithWindowOffsetInBX:
	add		bx, dx
	push	ds
	mov		ds, [di+DPT.wBasePort]	; Segment for JR-IDE/ISA
	mov		[bx], al
	pop		ds
	ret
%endif

.ReverseA0andA3fromRegisterIndexInDX:
	mov		bx, dx
	mov		dl, [cs:bx+g_rgbSwapA0andA3fromIdeRegisterIndex]
	SKIP2B	bx	; Skip shl dx, 1

.ShlRegisterIndexInDX:
	shl		dx, 1
	; Fall to OutputALtoRegisterInDX

ALIGN JUMP_ALIGN
OutputALtoRegisterInDX:
	add		dx, [di+DPT.wBasePort]
OutputALtoPortInDX:
	out		dx, al
	ret



; A0 <-> A3 lookup table
g_rgbSwapA0andA3fromIdeRegisterIndex:
	db	0000b	; <-> 0000b, 0
	db	1000b	; <-> 0001b, 1
	db	0010b	; <-> 0010b, 2
	db	1010b	; <-> 0011b, 3
	db	0100b	; <-> 0100b, 4
	db	1100b	; <-> 0101b, 5
	db	0110b	; <-> 0110b, 6
	db	1110b	; <-> 0111b, 7

%endif ; MODULE_8BIT_IDE
