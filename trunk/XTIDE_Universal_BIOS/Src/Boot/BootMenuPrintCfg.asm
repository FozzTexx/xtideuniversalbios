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
;		DS:DI:		Pointer to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrintCfg_ForOurDrive:
	eMOVZX	ax, BYTE [di+DPT.bIdevarsOffset]
	xchg	si, ax						; CS:SI now points to IDEVARS
	; Fall to .PushAndFormatCfgString

;--------------------------------------------------------------------
; PushAddressingMode
;	Parameters:
;		DS:DI:	Ptr to DPT
;		CS:SI:	Ptr to IDEVARS
;	Returns:
;		Nothing (jumps to next push below)
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
.PushAddressingMode:
	AccessDPT_GetUnshiftedAddressModeToALZF
	;; 
	;; This multiply both shifts the addressing mode bits down to low order bits, and 
	;; at the same time multiplies by the size of the string displacement.  The result is in AH,
	;; with AL clear, and so we exchange AL and AH after the multiply for the final result.
	;; 
	mov		bl,(1<<(8-ADDRESSING_MODE_FIELD_POSITION)) * g_szAddressingModes_Displacement
	mul		bl
	xchg	al,ah
	add		ax,g_szAddressingModes
	push	ax
		
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
.PushBlockMode:
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
.PushBusType:
	mov		al,g_szBusTypeValues_Displacement
	mul		BYTE [cs:si+IDEVARS.bDevice]
		
	shr		ax,1			; divide by 2 since IDEVARS.bDevice is multiplied by 2
		
	add		ax,g_szBusTypeValues
	push	ax	
				
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
.PushIRQ:
	mov		al, BYTE [cs:si+IDEVARS.bIRQ]
	cbw
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
.PushResetStatus:
	mov		al, [di+DPT.bFlagsHigh]
	and		al, MASKH_DPT_RESET			;  ah already zero from last push
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
.PrintValuesFromStack:
	jmp		BootMenuPrint_HardDiskRefreshInformation.output

