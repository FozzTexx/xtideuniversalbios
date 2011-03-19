; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h BIOS functions (Floppy and Hard disk).

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h software interrupt handler.
; Jumps to specific function defined in AH.
;
; Note to developers: Do not make recursive INT 13h calls!
;
; Int13h_DiskFunctionsHandler
;	Parameters:
;		AH:		Bios function
;		DL:		Drive number
;		Other:	Depends on function
;	Returns:
;		Depends on function
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_DiskFunctionsHandler:
	sti									; Enable interrupts
	SAVE_AND_GET_INTPACK_TO_SSBP

	call	RamVars_GetSegmentToDS
	call	DriveXlate_ToOrBack
	mov		[RAMVARS.xlateVars+XLATEVARS.bXlatedDrv], dl
	call	RamVars_IsFunctionHandledByThisBIOS
	jnc		SHORT Int13h_DirectCallToAnotherBios
	call	FindDPT_ForDriveNumber		; DS:DI now points to DPT

	; Jump to correct BIOS function
JumpToBiosFunctionInAH:
	cmp		ah, 25h						; Valid BIOS function?
	ja		SHORT Int13h_UnsupportedFunction
	eMOVZX	bx, ah
	shl		bx, 1
	jmp		[cs:bx+g_rgw13hFuncJump]	; Jump to BIOS function


;--------------------------------------------------------------------
; Int13h_UnsupportedFunction
; Int13h_DirectCallToAnotherBios
;	Parameters:
;		DL:		Translated drive number
;		DS:		RAMVARS segment
;		SS:BP:	Ptr to INTPACK
;		BX, DI:	Corrupted on Int13h_DiskFunctionsHandler
;		Other:	Function specific INT 13h parameters 
;	Returns:
;		Depends on function
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_UnsupportedFunction:
Int13h_DirectCallToAnotherBios:
	call	ExchangeCurrentInt13hHandlerWithOldInt13hHandler
	mov		bx, [bp+INTPACK.bx]
	mov		di, [bp+INTPACK.di]
	mov		ds, [bp+INTPACK.ds]
	push	WORD [bp+INTPACK.flags]
	popf
	push	bp
	mov		bp, [bp+INTPACK.bp]
	int		BIOS_DISK_INTERRUPT_13h	; Can safely do as much recursion as it wants

	; Store returned values to INTPACK
	pop		bp	; Standard INT 13h functions never uses BP as return register
%ifdef USE_386
	mov		[bp+INTPACK.gs], gs
	mov		[bp+INTPACK.fs], fs
%endif
	mov		[bp+INTPACK.es], es
	mov		[bp+INTPACK.ds], ds
	mov		[bp+INTPACK.di], di
	mov		[bp+INTPACK.si], si
	mov		[bp+INTPACK.bx], bx
	mov		[bp+INTPACK.dh], dh
	mov		[bp+INTPACK.cx], cx
	mov		[bp+INTPACK.ax], ax
	pushf
	pop		WORD [bp+INTPACK.flags]
	call	RamVars_GetSegmentToDS
	cmp		dl, [RAMVARS.xlateVars+XLATEVARS.bXlatedDrv]
	je		SHORT .ExchangeInt13hHandlers
	mov		[bp+INTPACK.dl], dl		; Something is returned in DL
ALIGN JUMP_ALIGN
.ExchangeInt13hHandlers:
	call	ExchangeCurrentInt13hHandlerWithOldInt13hHandler
	; Fall to Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH


;--------------------------------------------------------------------
; Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
; Int13h_ReturnFromHandlerWithoutStoringErrorCode
;	Parameters:
;		AH:		BIOS Error code
;		SS:BP:	Ptr to INTPACK
;	Returns:
;		All registers are loaded from INTPACK
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH:
	call	HError_SetErrorCodeToBdaAndToIntpackInSSBPfromAH
Int13h_ReturnFromHandlerWithoutStoringErrorCode:
	or		WORD [bp+INTPACK.flags], FLG_FLAGS_IF	; Return with interrupts enabled
	mov		sp, bp									; Now we can exit anytime
	RESTORE_INTPACK_FROM_SSBP


;--------------------------------------------------------------------
; Int13h_CallPreviousInt13hHandler
;	Parameters:
;		AH:		INT 13h function to call
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		Depends on function
;	Corrupts registers:
;		BX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_CallPreviousInt13hHandler:
	push	di
	call	ExchangeCurrentInt13hHandlerWithOldInt13hHandler
	int		BIOS_DISK_INTERRUPT_13h
	call	ExchangeCurrentInt13hHandlerWithOldInt13hHandler
	pop		di
	ret


;--------------------------------------------------------------------
; ExchangeCurrentInt13hHandlerWithOldInt13hHandler
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ExchangeCurrentInt13hHandlerWithOldInt13hHandler:
	push	es
	LOAD_BDA_SEGMENT_TO	es, di
	mov		di, [RAMVARS.fpOldI13h]
	xchg	di, [es:BIOS_DISK_INTERRUPT_13h*4]
	mov		[RAMVARS.fpOldI13h], di
	mov		di, [RAMVARS.fpOldI13h+2]
	xchg	di, [es:BIOS_DISK_INTERRUPT_13h*4+2]
	mov		[RAMVARS.fpOldI13h+2], di
	pop		es
	ret



; Jump table for correct BIOS function
ALIGN WORD_ALIGN
g_rgw13hFuncJump:
	dw	AH0h_HandlerForDiskControllerReset				; 00h, Disk Controller Reset (All)
	dw	AH1h_HandlerForReadDiskStatus					; 01h, Read Disk Status (All)
	dw	AH2h_HandlerForReadDiskSectors					; 02h, Read Disk Sectors (All)
	dw	AH3h_HandlerForWriteDiskSectors					; 03h, Write Disk Sectors (All)
	dw	AH4h_HandlerForVerifyDiskSectors				; 04h, Verify Disk Sectors (All)
	dw	Int13h_UnsupportedFunction						; 05h, Format Disk Track (XT, AT, EISA)
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
	dw	Int13h_UnsupportedFunction						; 14h, Controller Internal Diagnostic (All)
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
