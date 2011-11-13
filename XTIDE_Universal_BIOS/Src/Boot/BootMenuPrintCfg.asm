; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for printing drive configuration
;					information on Boot Menu.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Prints Hard Disk configuration for drive handled by our BIOS.
; Cursor is set to configuration header string position.
;
; BootMenuPrintCfg_ForOurDrive
;	Parameters:
;		DS:		Segment to DPT
;		Stack:	Offset to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrintCfg_ForOurDrive:
	pop		di
	mov		si, g_szCfgHeader
	call	BootMenuPrint_NullTerminatedStringFromCSSIandSetCF
	eMOVZX	ax, BYTE [di+DPT.bIdevarsOffset]
	xchg	si, ax						; CS:SI now points to IDEVARS
	; Fall to PushAndFormatCfgString

;--------------------------------------------------------------------
; PushAndFormatCfgString
;	Parameters:
;		DS:DI:	Ptr to DPT
;		CS:SI:	Ptr to IDEVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DX, SI, DI
;--------------------------------------------------------------------
PushAndFormatCfgString:
	push	bp
	mov		bp, sp
	; Fall to first push below

;--------------------------------------------------------------------
; PushAddressingMode
;	Parameters:
;		DS:DI:	Ptr to DPT
;		CS:SI:	Ptr to IDEVARS
;	Returns:
;		Nothing (jumps to next push below)
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
PushAddressingMode:
	call	AccessDPT_GetAddressingModeForWordLookToBX
	push	WORD [cs:bx+rgszAddressingModeString]

;--------------------------------------------------------------------
; PushBlockMode
;	Parameters:
;		DS:DI:	Ptr to DPT
;		CS:SI:	Ptr to IDEVARS
;	Returns:
;		Nothing (falls to next push below)
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
PushBlockMode:
	mov		ax, 1
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_BLOCK_MODE_SUPPORTED
	jz		SHORT .PushBlockSizeFromAX
	mov		al, [di+DPT_ATA.bSetBlock]
.PushBlockSizeFromAX:
	push	ax

;--------------------------------------------------------------------
; PushBusType
;	Parameters:
;		DS:DI:	Ptr to DPT
;		CS:SI:	Ptr to IDEVARS
;	Returns:
;		Nothing (jumps to next push below)
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
;PushBusType:
	cwd					; Clear DX using sign extension
	xchg	ax, bx		; Store BX to AX
	eMOVZX	bx, BYTE [cs:si+IDEVARS.bDevice]
	mov		bx, [cs:bx+rgwBusTypeValues]	; Char to BL, Int to BH
	mov		dl, bh
	push	bx			; Push character
	push	dx			; Push 1, 8, 16 or 32
	xchg	bx, ax		; Restore BX

;--------------------------------------------------------------------
; PushIRQ
;	Parameters:
;		DS:DI:	Ptr to DPT
;		CS:SI:	Ptr to IDEVARS
;	Returns:
;		Nothing (falls to next push below)
;	Corrupts registers:
;		AX, DX
;--------------------------------------------------------------------
PushIRQ:
	mov		dl, ' '						; Load space to DL
	mov		al, [cs:si+IDEVARS.bIRQ]
	test	al, al						; Interrupts disabled?
	jz		SHORT .PushIrqDisabled
	add		al, '0'						; Digit to ASCII
	cmp		al, '9'						; Only one digit needed?
	jbe		SHORT .PushCharacters

	; Two digits needed
	sub		al, 10						; Limit to single digit ASCII
	mov		dl, '1'						; Load '1 to DX
	jmp		SHORT .PushCharacters
ALIGN JUMP_ALIGN
.PushIrqDisabled:
	mov		al, '-'						; Load line to AL
	xchg	ax, dx						; Space to AL, line to DL
ALIGN JUMP_ALIGN
.PushCharacters:
	push	dx
	push	ax

;--------------------------------------------------------------------
; PushResetStatus
;	Parameters:
;		DS:DI:	Ptr to DPT
;		CS:SI:	Ptr to IDEVARS
;	Returns:
;		Nothing (falls to next push below)
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
PushResetStatus:
	mov		al, [di+DPT.bFlagsHigh]
	and		ax, MASKH_DPT_RESET
	push	ax

;--------------------------------------------------------------------
; PrintValuesFromStack
;	Parameters:
;		Stack:	All formatting parameters
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
PrintValuesFromStack:
	mov		si, g_szCfgFormat
	jmp		BootMenuPrint_FormatCSSIfromParamsInSSBP


ALIGN WORD_ALIGN
rgszAddressingModeString:
	dw		g_szLCHS
	dw		g_szPCHS
	dw		g_szLBA28
	dw		g_szLBA48

rgwBusTypeValues:
	db		'D', 8		; DEVICE_8BIT_DUAL_PORT_XTIDE
	db		'X', 8		; DEVICE_XTIDE_WITH_REVERSED_A3_AND_A0
	db		'S', 8		; DEVICE_8BIT_SINGLE_PORT
	db		' ', 16		; DEVICE_16BIT_ATA
	db		' ', 32		; DEVICE_32BIT_ATA
	db		' ', 1		; DEVICE_SERIAL_PORT
