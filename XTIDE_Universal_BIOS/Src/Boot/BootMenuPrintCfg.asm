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
	mov		al,g_szAddressingModes_Displacement
	mul		bl
	add		ax,g_szAddressingModes
	push	ax
;
; Ensure that addressing modes are correctly spaced in memory
;
%if g_szLCHS <> g_szAddressingModes
%error "g_szAddressingModes Displacement Incorrect 1"
%endif
%if g_szPCHS <> g_szLCHS + g_szAddressingModes_Displacement
%error "g_szAddressingModes Displacement Incorrect 2"
%endif
%if g_szLBA28 <> g_szPCHS + g_szAddressingModes_Displacement		
%error "g_szAddressingModes Displacement Incorrect 3"
%endif
%if g_szLBA48 <> g_szLBA28 + g_szAddressingModes_Displacement		
%error "g_szAddressingModes Displacement Incorrect 4"
%endif				
		
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
	mov		al,g_szBusTypeValues_Displacement
	mul		BYTE [cs:si+IDEVARS.bDevice]
	shr		ax,1
	add		ax,g_szBusTypeValues
	push	ax	

;
; Ensure that bus type strings are correctly spaced in memory
;
%if g_szBusTypeValues_8Dual <> g_szBusTypeValues
%error "g_szBusTypeValues Displacement Incorrect 1"
%endif
%if g_szBusTypeValues_8Reversed <> g_szBusTypeValues + g_szBusTypeValues_Displacement
%error "g_szBusTypeValues Displacement Incorrect 2"		
%endif
%if g_szBusTypeValues_8Single <> g_szBusTypeValues_8Reversed + g_szBusTypeValues_Displacement
%error "g_szBusTypeValues Displacement Incorrect 3"				
%endif
%if g_szBusTypeValues_16 <> g_szBusTypeValues_8Single + g_szBusTypeValues_Displacement		
%error "g_szBusTypeValues Displacement Incorrect 4"				
%endif
%if g_szBusTypeValues_32 <> g_szBusTypeValues_16 + g_szBusTypeValues_Displacement
%error "g_szBusTypeValues Displacement Incorrect 5"				
%endif
%if g_szBusTypeValues_Serial <> g_szBusTypeValues_32 + g_szBusTypeValues_Displacement
%error "g_szBusTypeValues Displacement Incorrect 6"				
%endif				
				
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

