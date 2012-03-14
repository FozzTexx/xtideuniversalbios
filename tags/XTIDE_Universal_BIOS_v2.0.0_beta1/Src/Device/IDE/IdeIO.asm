; Project name	:	XTIDE Universal BIOS
; Description	:	IDE Register I/O functions.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; IdeIO_OutputALtoIdeControlBlockRegisterInDL
; IdeIO_OutputALtoIdeRegisterInDL
;	Parameters:
;		AL:		Byte to output
;		DL:		IDE Control Block Register	(IdeIO_OutputALtoIdeControlBlockRegisterInDL)
;				IDE Register				(IdeIO_OutputALtoIdeRegisterInDL)
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		Nothing
;	Corrupts registers:
;		BX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeIO_OutputALtoIdeControlBlockRegisterInDL:
	mov		bl, IDEVARS.wPortCtrl
	SKIP2B	f	; cmp ax, <next instruction>
	; Fall to IdeIO_OutputALtoIdeRegisterInDL

IdeIO_OutputALtoIdeRegisterInDL:
	mov		bl, IDEVARS.wPort
	call	GetPortToDXandTranslateA0andA3ifNecessary
	out		dx, al
	ret


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
ALIGN JUMP_ALIGN
IdeIO_InputToALfromIdeRegisterInDL:
	mov		bl, IDEVARS.wPort
	call	GetPortToDXandTranslateA0andA3ifNecessary
	in		al, dx
	ret


;--------------------------------------------------------------------
; GetPortToDXandTranslateA0andA3ifNecessary
;	Parameters:
;		BL:		Offset to port in IDEVARS (IDEVARS.wPort or IDEVARS.wPortCtrl)
;		DL:		IDE Register
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;	Returns:
;		DX:		Source/Destination Port
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
GetPortToDXandTranslateA0andA3ifNecessary:
	xor		bh, bh
	add		bl, [di+DPT.bIdevarsOffset]		; CS:BX now points port address
	xor		dh, dh							; DX now has IDE register offset
	add		dx, [cs:bx]
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_REVERSED_A0_AND_A3
	jz		SHORT .ReturnPortInDX

	; Exchange address lines A0 and A3 from DL
	mov		bl, dl
	mov		bh, MASK_A3_AND_A0_ADDRESS_LINES
	and		bh, bl							; BH = 0, 1, 8 or 9, we can ignore 0 and 9
	jz		SHORT .ReturnPortInDX			; Jump out since DH is 0
	xor		bh, MASK_A3_AND_A0_ADDRESS_LINES
	jz		SHORT .ReturnPortInDX			; Jump out since DH was 9
	and		dl, ~MASK_A3_AND_A0_ADDRESS_LINES
	or		dl, bh							; Address lines now reversed
.ReturnPortInDX:
	ret
