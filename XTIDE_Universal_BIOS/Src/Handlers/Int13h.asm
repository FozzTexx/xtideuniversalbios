; File name		:	Int13h_Jump.asm
; Project name	:	IDE BIOS
; Created date	:	21.9.2007
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h BIOS functions (Floppy and Hard disk).

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Macro that prints drive and function number.
; Used only for debugging.
;
; DEBUG_PRINT_DRIVE_AND_FUNCTION
;	Parameters:
;		AH:		INT 13h function number
;		DL:		Drive number
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
%macro DEBUG_PRINT_DRIVE_AND_FUNCTION 0
	push	dx
	push	ax
	mov		al, dl
	call	Print_IntHexW
	pop		ax
	pop		dx
%endmacro


;--------------------------------------------------------------------
; Int 13h software interrupt handler.
; Jumps to specific function defined in AH.
;
; Int13h_Jump
;	Parameters:
;		AH:		Bios function
;		DL:		Drive number
;	Returns:
;		Depends on function
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_DiskFunctions:
	; Save registers
	sti									; Enable interrupts
	push	ds							; Store DS
	push	di							; Store DI

	;DEBUG_PRINT_DRIVE_AND_FUNCTION
	call	RamVars_GetSegmentToDS
	call	DriveXlate_WhenEnteringInt13h
	call	RamVars_IsFunctionHandledByThisBIOS
	jnc		SHORT Int13h_DirectCallToAnotherBios

	; Jump to correct BIOS function
	cmp		ah, 25h						; Valid BIOS function?
	ja		SHORT Int13h_UnsupportedFunction
	mov		di, ax
	eSHR_IM	di, 7						; Shift function to DI...
	and		di, BYTE 7Eh				; ...and prepare for word lookup
	jmp		[cs:di+g_rgw13hFuncJump]	; Jump to BIOS function


;--------------------------------------------------------------------
; Directs call to another INT13h function whose pointer is
; stored to RAMVARS.
;
; Int13h_DirectCallToAnotherBios
;	Parameters:
;		AH:		Bios function
;		DL:		Drive number
;		DS:		RAMVARS segment
;		DI:		Corrupted
;		Stack from top to down:
;				Original DI
;				Original DS
;	Returns:
;		Depends on function
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_UnsupportedFunction:
Int13h_DirectCallToAnotherBios:
	; Temporarily store original DI and DS from stack to RAMVARS
	pop		WORD [RAMVARS.wI13hDI]
	pop		WORD [RAMVARS.wI13hDS]

	; Special return processing required if target function
	; returns something in DL
	mov		di, Int13h_ReturnFromAnotherBiosWithoutSwappingDrives
	call	DriveXlate_DoesFunctionReturnSomethingInDL
	jc		SHORT .PushIretAddress
	add		di, BYTE Int13h_ReturnFromAnotherBios - Int13h_ReturnFromAnotherBiosWithoutSwappingDrives
.PushIretAddress:
	pushf								; Push FLAGS to simulate INT
	push	cs							; Push return segment
	push	di							; Push return offset

	; "Return" to another INT 13h with original DI and DS
	push	WORD [RAMVARS.fpOldI13h+2]	; Segment
	push	WORD [RAMVARS.fpOldI13h]	; Offset
	lds		di, [RAMVARS.dwI13DIDS]
	cli									; Disable interrupts as INT would
	retf


;--------------------------------------------------------------------
; Return handlers from another INT 13h BIOS.
;
; Int13h_ReturnFromAnotherBiosWithoutSwappingDrives
; Int13h_ReturnFromAnotherBios
;	Parameters:
;		AH:		Error code
;		DL:		Drive number (only on Int13h_ReturnFromAnotherBios)
;		CF:		Error status
;	Returns:
;		Depends on function
;	Corrupts registers:
;		Nothing (not even FLAGS)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_ReturnFromAnotherBiosWithoutSwappingDrives:
	push	ds
	push	di
	pushf								; Store return flags
	call	RamVars_GetSegmentToDS
	dec		BYTE [RAMVARS.xlateVars+XLATEVARS.bRecurCnt]
	jmp		SHORT Int13h_Leave
ALIGN JUMP_ALIGN
Int13h_ReturnFromAnotherBios:
	push	ds
	push	di
	pushf								; Store return flags
	call	RamVars_GetSegmentToDS
	call	DriveXlate_WhenLeavingInt13h
	jmp		SHORT Int13h_Leave


;--------------------------------------------------------------------
; Returns from any BIOS function implemented by this BIOS.
;
; Int13h_ReturnWithoutSwappingDrives
; Int13h_PopXRegsAndReturn
; Int13h_PopDiDsAndReturn
;	Parameters:
;		DL:		Drive number (not Int13h_ReturnWithoutSwappingDrives)
;		DS:		RAMVARS segment
;	Returns:
;		Depends on function
;	Corrupts registers:
;		Nothing (not even FLAGS)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_ReturnWithoutSwappingDrives:
	pushf
	dec		BYTE [RAMVARS.xlateVars+XLATEVARS.bRecurCnt]
	jmp		SHORT Int13h_StoreErrorCodeAndLeave
ALIGN JUMP_ALIGN
Int13h_PopXRegsAndReturn:
	pop		bx							; Pop old AX to BX
	mov		al, bl						; Restore AL
	pop		bx
	pop		cx
	pop		dx
ALIGN JUMP_ALIGN
Int13h_PopDiDsAndReturn:
	pushf
	call	DriveXlate_WhenLeavingInt13h
Int13h_StoreErrorCodeAndLeave:
	LOAD_BDA_SEGMENT_TO	ds, di
	mov		[BDA.bHDLastSt], ah			; Store error code
Int13h_Leave:
	popf
	pop		di
	pop		ds
	retf	2


; Jump table for correct BIOS function
ALIGN WORD_ALIGN
g_rgw13hFuncJump:
	dw	AH0h_HandlerForDiskControllerReset				; 00h, Disk Controller Reset (All)
	dw	AH1h_HandlerForReadDiskStatus					; 01h, Read Disk Status (All)
	dw	AH2h_HandlerForReadDiskSectors					; 02h, Read Disk Sectors (All)
	dw	AH3h_HandlerForWriteDiskSectors					; 03h, Write Disk Sectors (All)
	dw	AH4h_HandlerForVerifyDiskSectors				; 04h, Verify Disk Sectors (All)
	dw	AH5h_HandlerForFormatDiskTrack					; 05h, Format Disk Track (XT, AT, EISA)
	dw	Int13h_UnsupportedFunction						; 06h, Format Disk Track with Bad Sectors (XT)
	dw	Int13h_UnsupportedFunction						; 07h, Format Multiple Cylinders (XT)
	dw	AH8h_HandlerForReadDiskDriveParameters			; 08h, Read Disk Drive Parameters (All)
	dw	AH9h_HandlerForInitializeDriveParameters		; 09h, Initialize Drive Parameters (All)
	dw	Int13h_UnsupportedFunction						; 0Ah, Read Disk Sectors with ECC (XT, AT, EISA)
	dw	Int13h_UnsupportedFunction						; 0Bh, Write Disk Sectors with ECC (XT, AT, EISA)
	dw	AHCh_HandlerForSeek								; 0Ch, Seek (All)
	dw	AHDh_HandlerForResetHardDisk					; 0Dh, Alternate Disk Reset (All)
	dw	Int13h_UnsupportedFunction						; 0Eh, Read Sector Buffer (XT, PS/1), ESDI Undocumented Diagnostic (PS/2)
	dw	Int13h_UnsupportedFunction						; 0Fh, Write Sector Buffer (XT, PS/1), ESDI Undocumented Diagnostic (PS/2)
	dw	AH10h_HandlerForCheckDriveReady					; 10h, Check Drive Ready (All)
	dw	AH11h_HandlerForRecalibrate						; 11h, Recalibrate (All)
	dw	Int13h_UnsupportedFunction						; 12h, Controller RAM Diagnostic (XT)
	dw	Int13h_UnsupportedFunction						; 13h, Drive Diagnostic (XT)
	dw	AH14h_HandlerForControllerInternalDiagnostic	; 14h, Controller Internal Diagnostic (All)
	dw	AH15h_HandlerForReadDiskDriveSize				; 15h, Read Disk Drive Size (AT+)
	dw	Int13h_UnsupportedFunction						; 16h, 
	dw	Int13h_UnsupportedFunction						; 17h, 
	dw	Int13h_UnsupportedFunction						; 18h, 
	dw	Int13h_UnsupportedFunction						; 19h, Park Heads (PS/2)
	dw	Int13h_UnsupportedFunction						; 1Ah, Format ESDI Drive (PS/2)
	dw	Int13h_UnsupportedFunction						; 1Bh, Get ESDI Manufacturing Header (PS/2)
	dw	Int13h_UnsupportedFunction						; 1Ch, ESDI Special Functions (PS/2)
	dw	Int13h_UnsupportedFunction						; 1Dh, 
	dw	Int13h_UnsupportedFunction						; 1Eh, 
	dw	Int13h_UnsupportedFunction						; 1Fh, 
	dw	Int13h_UnsupportedFunction						; 20h, 
	dw	Int13h_UnsupportedFunction						; 21h, Read Disk Sectors, Multiple Blocks (PS/1)
	dw	Int13h_UnsupportedFunction						; 22h, Write Disk Sectors, Multiple Blocks (PS/1)
	dw	AH23h_HandlerForSetControllerFeatures			; 23h, Set Controller Features Register (PS/1)
	dw	AH24h_HandlerForSetMultipleBlocks				; 24h, Set Multiple Blocks (PS/1)
	dw	AH25h_HandlerForGetDriveInformation				; 25h, Get Drive Information (PS/1)
;	dw	Int13h_UnsupportedFunction						; 26h, 
;	dw	Int13h_UnsupportedFunction						; 27h, 
;	dw	Int13h_UnsupportedFunction						; 28h, 
;	dw	Int13h_UnsupportedFunction						; 29h, 
;	dw	Int13h_UnsupportedFunction						; 2Ah, 
;	dw	Int13h_UnsupportedFunction						; 2Bh, 
;	dw	Int13h_UnsupportedFunction						; 2Ch, 
;	dw	Int13h_UnsupportedFunction						; 2Dh, 
;	dw	Int13h_UnsupportedFunction						; 2Eh, 
;	dw	Int13h_UnsupportedFunction						; 2Fh, 
;	dw	Int13h_UnsupportedFunction						; 30h, 
;	dw	Int13h_UnsupportedFunction						; 31h, 
;	dw	Int13h_UnsupportedFunction						; 32h, 
;	dw	Int13h_UnsupportedFunction						; 33h, 
;	dw	Int13h_UnsupportedFunction						; 34h, 
;	dw	Int13h_UnsupportedFunction						; 35h, 
;	dw	Int13h_UnsupportedFunction						; 36h, 
;	dw	Int13h_UnsupportedFunction						; 37h, 
;	dw	Int13h_UnsupportedFunction						; 38h, 
;	dw	Int13h_UnsupportedFunction						; 39h, 
;	dw	Int13h_UnsupportedFunction						; 3Ah, 
;	dw	Int13h_UnsupportedFunction						; 3Bh, 
;	dw	Int13h_UnsupportedFunction						; 3Ch, 
;	dw	Int13h_UnsupportedFunction						; 3Dh, 
;	dw	Int13h_UnsupportedFunction						; 3Eh, 
;	dw	Int13h_UnsupportedFunction						; 3Fh, 
;	dw	Int13h_UnsupportedFunction						; 40h, 
;	dw	Int13h_UnsupportedFunction						; 41h, Check if Extensions Present (EBIOS)
;	dw	Int13h_UnsupportedFunction						; 42h, Extended Read Sectors (EBIOS)
;	dw	Int13h_UnsupportedFunction						; 43h, Extended Write Sectors (EBIOS)
;	dw	Int13h_UnsupportedFunction						; 44h, Extended Verify Sectors (EBIOS)
;	dw	Int13h_UnsupportedFunction						; 45h, Lock and Unlock Drive (EBIOS)
;	dw	Int13h_UnsupportedFunction						; 46h, Eject Media Request (EBIOS)
;	dw	Int13h_UnsupportedFunction						; 47h, Extended Seek (EBIOS)
;	dw	Int13h_UnsupportedFunction						; 48h, Get Extended Drive Parameters (EBIOS)
;	dw	Int13h_UnsupportedFunction						; 49h, Get Extended Disk Change Status (EBIOS)
;	dw	Int13h_UnsupportedFunction						; 4Ah, Initiate Disk Emulation (Bootable CD-ROM)
;	dw	Int13h_UnsupportedFunction						; 4Bh, Terminate Disk Emulation (Bootable CD-ROM)
;	dw	Int13h_UnsupportedFunction						; 4Ch, Initiate Disk Emulation and Boot (Bootable CD-ROM)
;	dw	Int13h_UnsupportedFunction						; 4Dh, Return Boot Catalog (Bootable CD-ROM)
;	dw	Int13h_UnsupportedFunction						; 4Eh, Set Hardware Configuration (EBIOS)
