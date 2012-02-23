; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for printing boot menu strings.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; BootMenuPrint_RefreshItem
; 
;	Parameters:
;		DL:		Untranslated Floppy Drive number
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_RefreshItem:
	call	BootMenu_GetDriveToDXforMenuitemInCX_And_RamVars_GetSegmentToDS
	jnc		BootMenuEvent_EventCompleted			; if no menu item selected, out we go
		
	push	bp
	mov		bp, sp

	call	RamVars_IsDriveHandledByThisBIOS_And_FindDPT_ForDriveNumber
	jc		.notOurs

	call	BootMenuInfo_ConvertDPTtoBX
	mov		si, g_szDriveNumBOOTNFO					; special g_szDriveNum that prints from BDA
	jmp		.go
		
.notOurs:
	mov		si,g_szDriveNum									
	mov		bx,g_szForeignHD						; assume a hard disk for the moment
		
	test	dl,80h											
	js		.go
	mov		bl,((g_szFloppyDrv)-$$ & 0xff)			; and revisit the earlier assumption...
		
.go:
	mov		ax, dx									; preserve DL for the floppy drive letter addition
	call	DriveXlate_ToOrBack
	push	dx										; translated drive number
	push	bx										; sub string
	add		al, 'A'									; floppy drive letter (we always push this although
	push	ax										; the hard disks don't ever use it, but it does no harm)
		
	jmp		short BootMenuPrint_RefreshInformation.FormatRelay

;--------------------------------------------------------------------
; Prints Boot Menu title strings.
;
; BootMenuPrint_TitleStrings
;	Parameters:
;		Nothing
;	Returns:
;		CF:		Set since menu event handled
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_TitleStrings:
	mov		si, ROMVARS.szTitle
	call	BootMenuPrint_NullTerminatedStringFromCSSIandSetCF
	CALL_DISPLAY_LIBRARY PrintNewlineCharacters
	mov		si, ROMVARS.szVersion
	; Fall to BootMenuPrint_NullTerminatedStringFromCSSIandSetCF

;--------------------------------------------------------------------
; BootMenuPrint_NullTerminatedStringFromCSSIandSetCF
;	Parameters:
;		CS:SI:	Ptr to NULL terminated string to print
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_NullTerminatedStringFromCSSIandSetCF:
;
; We send all CSSI strings through the Format routine for the case of
; compressed strings, but this doesn't hurt in the non-compressed case either
; (perhaps a little slower, but shouldn't be noticeable to the user)
; and results in smaller code size.
;
	push	bp
	mov		bp,sp
	jmp		short BootMenuPrint_RefreshInformation.FormatRelay

		
;--------------------------------------------------------------------
; BootMenuPrint_FloppyMenuitemInformation
;	Parameters:
;		DL:		Untranslated Floppy Drive number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_RefreshInformation:
	CALL_MENU_LIBRARY ClearInformationArea		
		
	call	BootMenu_GetDriveToDXforMenuitemInCX_And_RamVars_GetSegmentToDS
	jnc		BootMenuEvent_EventCompleted				; if no menu selection, abort

	push	bp
	mov		bp, sp

	mov		si, g_szCapacity							; Setup print string now, carries through to print call

	xor		di, di										; Zero DI for checks for our drive later on
	call	RamVars_IsDriveHandledByThisBIOS_And_FindDPT_ForDriveNumber

	test	dl, dl										; are we a hard disk?
	js		BootMenuPrint_HardDiskRefreshInformation	

	test	di, di
	jnz		.ours										; Based on CF from RamVars_IsDriveHandledByThisBIOS above
	call	FloppyDrive_GetType							; Get Floppy Drive type to BX
	jmp		.around
.ours:
	call	AH8h_GetDriveParameters
.around:				

	mov		ax, g_szFddSizeOr	        				; .PrintXTFloppyType
	test	bl, bl										; Two possibilities? (FLOPPY_TYPE_525_OR_35_DD)		
	jz		SHORT .PushAXAndOutput

	mov		al, (g_szFddUnknown - $$) & 0xff	        ; .PrintUnknownFloppyType
	cmp		bl, FLOPPY_TYPE_35_ED
	ja		SHORT .PushAXAndOutput
		
	; Fall to .PrintKnownFloppyType

;--------------------------------------------------------------------
; .PrintKnownFloppyType
;	Parameters:
;		BX:		Floppy drive type
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		AX, BX, SI, DI
; 
; Floppy Drive Types:
;
;   0  Handled above 
;   1  FLOPPY_TYPE_525_DD          5 1/4   360K
;   2  FLOPPY_TYPE_525_HD          5 1/4   1.2M
;   3  FLOPPY_TYPE_35_DD           3 1/2   720K
;   4  FLOPPY_TYPE_35_HD           3 1/2   1.44M
;   5  3.5" ED on some BIOSes      3 1/2   2.88M
;   6  FLOPPY_TYPE_35_ED		   3 1/2   2.88M
;   >6 Unknwon, handled above
; 
;--------------------------------------------------------------------
.PrintKnownFloppyType:
	mov		al, (g_szFddSize - $$) & 0xff
	push	ax
		
	mov		al, (g_szFddThreeHalf - $$) & 0xff
	cmp		bl, FLOPPY_TYPE_525_HD
	ja		.ThreeHalf
	mov		al, (g_szFddFiveQuarter - $$) & 0xff
.ThreeHalf:		
	push	ax											; "5 1/4" or "3 1/2"

	mov		al,FloppyTypes.rgbCapacityMultiplier
	mov		bh, 0
	mul		byte [cs:bx+FloppyTypes.rgbCapacity - 1]    ; -1 since 0 is handled above and not in the table

.PushAXAndOutput:					
	push	ax

.FormatRelay:
	jmp		short BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; Prints Hard Disk Menuitem information strings.
;
; BootMenuPrint_HardDiskMenuitemInformation
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set since menu event was handled successfully
;	Corrupts registers:
;		BX, CX, DX, SI, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_HardDiskRefreshInformation:		
	test	di, di
	jz		.HardDiskMenuitemInfoForForeignDrive		

.HardDiskMenuitemInfoForOurDrive:
	ePUSH_T ax, g_szInformation						; Add substring for our hard disk information
	call	BootMenuInfo_GetTotalSectorCount		; Get Total LBA Size
	jmp		.ConvertSectorCountInBXDXAXtoSizeAndPushForFormat
		
.HardDiskMenuitemInfoForForeignDrive:
	call	DriveXlate_ToOrBack
	call	AH15h_GetSectorCountFromForeignDriveToDXAX

.ConvertSectorCountInBXDXAXtoSizeAndPushForFormat:
	ePUSH_T	cx, g_szCapacityNum		; Push format substring
	call	Size_ConvertSectorCountInBXDXAXtoKiB
	mov		cx, BYTE_MULTIPLES.kiB
	call	Size_GetSizeToAXAndCharToDLfromBXDXAXwithMagnitudeInCX
	push	ax						; Size in magnitude
	push	cx						; Tenths
	push	dx						; Magnitude character		
				
	test	di,di
	jz		short BootMenuPrint_FormatCSSIfromParamsInSSBP

%include "BootMenuPrintCfg.asm"			; inline of code to fill out remainder of information string

;;; fall-through to BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; BootMenuPrint_FormatCSSIfromParamsInSSBP
;	Parameters:
;		CS:SI:	Ptr to string to format
;		BP:		SP before pushing parameters
;	Returns:
;		BP:		Popped from stack
;		CF:		Set since menu event was handled successfully		
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_FormatCSSIfromParamsInSSBP:
	CALL_DISPLAY_LIBRARY FormatNullTerminatedStringFromCSSI
	stc				; Successfull return from menu event
	pop		bp
	ret
		
		
;--------------------------------------------------------------------
; BootMenuPrint_ClearScreen
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_ClearScreen:
	call	BootMenuPrint_InitializeDisplayContext
	xor		ax, ax
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	mov		ax, ' ' | (MONO_NORMAL<<8)
	CALL_DISPLAY_LIBRARY ClearScreenWithCharInALandAttrInAH
	ret


;--------------------------------------------------------------------
; BootMenuPrint_TheBottomOfScreen
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_TheBottomOfScreen:
	call	FloppyDrive_GetCountToAX
	xchg	bx, ax					; Floppy Drive count to BL
	call	RamVars_GetHardDiskCountFromBDAtoAX
	mov		bh, al					; Hard Disk count to BH
	; Fall to .MoveCursorToHotkeyStrings

;--------------------------------------------------------------------
; .MoveCursorToHotkeyStrings
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
.MoveCursorToHotkeyStrings:
	CALL_DISPLAY_LIBRARY GetColumnsToALandRowsToAH
	xor		al, al
	dec		ah
	CALL_DISPLAY_LIBRARY SetCursorCoordinatesFromAX
	; Fall to .PrintHotkeyString

;--------------------------------------------------------------------
; .PrintHotkeyString
;	Parameters:
;		BL:		Floppy Drives
;		BH:		Hard Drives
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DX, SI, DI
;--------------------------------------------------------------------
.PrintHotkeyString:
	; Display Library should not be called like this
	mov		si, ATTRIBUTE_CHARS.cHighlightedItem
	call	MenuAttribute_GetToAXfromTypeInSI
	xchg	dx, ax
	mov		cx, MONO_BRIGHT

	test	bl, bl		; Any Floppy Drives?
	jz		SHORT .SkipFloppyDriveHotkeys
	mov		ax, 'A' | (ANGLE_QUOTE_RIGHT<<8)
	mov		si, g_szFDD
	call	PushHotkeyParamsAndFormat

.SkipFloppyDriveHotkeys:
	test	bh, bh		; Any Hard Drives?
	jz		SHORT .SkipHardDriveHotkeys
	call	BootMenu_GetLetterForFirstHardDiskToAL
	mov		ah, ANGLE_QUOTE_RIGHT
	mov		si, g_szHDD
	call	PushHotkeyParamsAndFormat

.SkipHardDriveHotkeys:
	; Fall to .PrintRomBootHotkey

;--------------------------------------------------------------------
; .PrintRomBootHotkey
;	Parameters:
;		CX:		Key Attribute
;		DX:		Description Attribute
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
.PrintRomBootHotkey:
	mov		ax, 'F' | ('8'<<8)		; F8
	mov		si, g_szRomBoot
	; Fall to PushHotkeyParamsAndFormat

;--------------------------------------------------------------------
; PushHotkeyParamsAndFormat
;	Parameters:
;		AL:		First character
;		AH:		Second character
;		CX:		Key Attribute
;		DX:		Description Attribute
;		CS:SI:	Description string
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, SI, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
PushHotkeyParamsAndFormat:
	push	bp
	mov		bp, sp

	push	cx			; Key attribute
	push	ax			; First character
	xchg	al, ah
	push	ax			; Second character
	push	dx			; Description attribute
	push	si			; Description string
	push	cx			; Key attribute for last space
	mov		si, g_szHotkey
		
BootMenuPrint_FormatCSSIfromParamsInSSBP_Relay:	
	jmp		SHORT BootMenuPrint_FormatCSSIfromParamsInSSBP


;--------------------------------------------------------------------
; BootMenuPrint_InitializeDisplayContext
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
BootMenuPrint_InitializeDisplayContext:
	CALL_DISPLAY_LIBRARY InitializeDisplayContext
	ret


FloppyTypes:
.rgbCapacityMultiplier equ 20	        ; Multiplier to reduce word sized values to byte size
.rgbCapacity:
	db		360   / FloppyTypes.rgbCapacityMultiplier    ;  type 1
	db		1200  / FloppyTypes.rgbCapacityMultiplier    ;  type 2
	db		720   / FloppyTypes.rgbCapacityMultiplier    ;  type 3
	db		1440  / FloppyTypes.rgbCapacityMultiplier    ;  type 4
	db		2880  / FloppyTypes.rgbCapacityMultiplier    ;  type 5
	db		2880  / FloppyTypes.rgbCapacityMultiplier    ;  type 6
