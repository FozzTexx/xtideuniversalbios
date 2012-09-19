; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h BIOS functions (Floppy and Hard disk).

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
; Int 13h software interrupt handler.
; This handler changes stack to top of stolen conventional memory
; and then calls the actual INT 13h handler (Int13h_DiskFunctionsHandler).
;
; Int13h_DiskFunctionsHandlerWithStackChange
;	Parameters:
;		AH:		Bios function
;		DL:		Drive number
;		Other:	Depends on function
;	Returns:
;		Depends on function
;--------------------------------------------------------------------
%ifdef RELOCATE_INT13H_STACK
ALIGN JUMP_ALIGN
Int13h_DiskFunctionsHandlerWithStackChange:
	push	ds
	push	di
	call	RamVars_GetSegmentToDS

	; Store entry registers to RAMVARS
	mov		[RAMVARS.fpInt13hEntryStack], sp
	mov		[RAMVARS.fpInt13hEntryStack+2], ss
	pop		WORD [RAMVARS.wStackChangeDI]
	pop		WORD [RAMVARS.wStackChangeDS]

	; Load new stack and restore DS and DI
	mov		di, ds		; We do not want to overwrite DS and DI in stack
	mov		ss, di
	mov		sp, [RAMVARS.wNewStackOffset]
	lds		di, [RAMVARS.dwStackChangeDSDI]

	; Call INT 13h
	pushf
	push	cs
	call	Int13h_DiskFunctionsHandler

	; Restore stack (we must not corrupt FLAGS!)
	cli
%ifdef USE_386
	lss		sp, [ss:RAMVARS.fpInt13hEntryStack]
%else
	mov		sp, [ss:RAMVARS.fpInt13hEntryStack]
	mov		ss, [ss:RAMVARS.fpInt13hEntryStack+2]
%endif
	pop		di			; DI before stack change
	pop		ds			; DS before stack change
	retf	2			; Skip FLAGS from stack
%endif ; RELOCATE_INT13H_STACK


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
	cld									; String instructions to increment pointers
	CREATE_FRAME_INTPACK_TO_SSBP	SIZE_OF_IDEPACK_WITHOUT_INTPACK
	call	RamVars_GetSegmentToDS

%ifdef MODULE_HOTKEYS
	call	DriveXlate_ToOrBack
	mov		[RAMVARS.xlateVars+XLATEVARS.bXlatedDrv], dl
%endif
	call	FindDPT_ForDriveNumberInDL	; DS:DI points to our DPT, or NULL if not our drive
	jc		SHORT .NotOurDrive			; DPT not found so this is not one of our drives

.OurFunction:
	; Jump to correct BIOS function
	eMOVZX	bx, ah
	eSHL_IM	bx, 1
	cmp		ah, 25h						; Possible EBIOS function?
%ifndef MODULE_EBIOS
	ja		SHORT UnsupportedFunction
	jmp		[cs:bx+g_rgw13hFuncJump]	; Jump to BIOS function

%else ; If using MODULE_EBIOS
	ja		SHORT .JumpToEbiosFunction
	jmp		[cs:bx+g_rgw13hFuncJump]	; Jump to BIOS function

ALIGN JUMP_ALIGN
.JumpToEbiosFunction:
	test	BYTE [di+DPT.bFlagsLow], FLGL_DPT_LBA_AND_EBIOS_SUPPORTED
	jz		SHORT UnsupportedFunction	; No eINT 13h for CHS drives
	sub		bl, 41h<<1					; BX = Offset to eINT 13h jump table
	jb		SHORT UnsupportedFunction
	cmp		ah, 48h
	ja		SHORT UnsupportedFunction
	jmp		[cs:bx+g_rgwEbiosFunctionJumpTable]
%endif	; MODULE_EBIOS


ALIGN JUMP_ALIGN
.NotOurDrive:
	test	ah, ah
	jz		SHORT .OurFunction			; We handle all function 0h requests (resets)

%ifndef MODULE_SERIAL_FLOPPY
; Without floppy support, we handle only hard disk traffic for function 08h.
	test	dl, dl
	jns		SHORT Int13h_DirectCallToAnotherBios
%endif
; With floppy support, we handle all traffic for function 08h, as we need to wrap both hard disk and floppy drive counts.
	cmp		ah, 8
	je		SHORT .OurFunction
	; Fall to Int13h_DirectCallToAnotherBios


;--------------------------------------------------------------------
; UnsupportedFunction
; Int13h_DirectCallToAnotherBios
;	Parameters:
;		DL:		Translated drive number
;		DS:		RAMVARS segment
;		SS:BP:	Ptr to IDEPACK
;		BX, DI:	Corrupted on Int13h_DiskFunctionsHandler
;		Other:	Function specific INT 13h parameters
;	Returns:
;		Depends on function
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
UnsupportedFunction:
Int13h_DirectCallToAnotherBios:
	call	ExchangeCurrentInt13hHandlerWithOldInt13hHandler
	mov		bx, [bp+IDEPACK.intpack+INTPACK.bx]
	mov		di, [bp+IDEPACK.intpack+INTPACK.di]
	mov		ds, [bp+IDEPACK.intpack+INTPACK.ds]
	push	WORD [bp+IDEPACK.intpack+INTPACK.flags]
	popf
	push	bp
	mov		bp, [bp+IDEPACK.intpack+INTPACK.bp]
	int		BIOS_DISK_INTERRUPT_13h	; Can safely do as much recursion as it wants

	; Store returned values to INTPACK
	pop		bp	; Standard INT 13h functions never uses BP as return register
%ifdef USE_386
;	mov		[bp+IDEPACK.intpack+INTPACK.gs], gs
;	mov		[bp+IDEPACK.intpack+INTPACK.fs], fs
%endif
	mov		[bp+IDEPACK.intpack+INTPACK.es], es
	mov		[bp+IDEPACK.intpack+INTPACK.ds], ds
	mov		[bp+IDEPACK.intpack+INTPACK.di], di
	mov		[bp+IDEPACK.intpack+INTPACK.si], si
	mov		[bp+IDEPACK.intpack+INTPACK.bx], bx
%ifdef MODULE_HOTKEYS
	mov		[bp+IDEPACK.intpack+INTPACK.dh], dh
%else
	mov		[bp+IDEPACK.intpack+INTPACK.dx], dx
%endif
	mov		[bp+IDEPACK.intpack+INTPACK.cx], cx
	mov		[bp+IDEPACK.intpack+INTPACK.ax], ax
	pushf
	pop		WORD [bp+IDEPACK.intpack+INTPACK.flags]
	call	RamVars_GetSegmentToDS

%ifdef MODULE_HOTKEYS
	cmp		dl, [RAMVARS.xlateVars+XLATEVARS.bXlatedDrv]	; DL is still drive number?
	je		SHORT .ExchangeInt13hHandlers
	mov		[bp+IDEPACK.intpack+INTPACK.dl], dl	; Something is returned in DL
ALIGN JUMP_ALIGN
.ExchangeInt13hHandlers:
%endif

%ifdef USE_186
	push	Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
	jmp		SHORT ExchangeCurrentInt13hHandlerWithOldInt13hHandler
%else
	call	ExchangeCurrentInt13hHandlerWithOldInt13hHandler
	jmp		SHORT Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif


%ifdef MODULE_SERIAL_FLOPPY
;--------------------------------------------------------------------
; Int13h_ReturnSuccessForFloppy
;
; Some operations, such as format of a floppy disk track, should just
; return success, while for hard disks it should be treated as unsupported.
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_ReturnSuccessForFloppy:
	test	dl, dl
	js		SHORT UnsupportedFunction
	xor		ah, ah
	jmp		SHORT Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
%endif


;--------------------------------------------------------------------
; Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAHandTransferredSectorsFromCL
;	Parameters:
;		AH:		BIOS Error code
;		CL:		Number of sectors actually transferred
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		All registers are loaded from INTPACK
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAHandTransferredSectorsFromCL:
	mov		[bp+IDEPACK.intpack+INTPACK.al], cl
	; Fall to Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH


;--------------------------------------------------------------------
; Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH
; Int13h_ReturnFromHandlerWithoutStoringErrorCode
;	Parameters:
;		AH:		BIOS Error code
;		DS:		RAMVARS segment
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		All registers are loaded from INTPACK
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH:
%ifdef MODULE_SERIAL_FLOPPY
	mov		al, [bp+IDEPACK.intpack+INTPACK.dl]
Int13h_ReturnFromHandlerAfterStoringErrorCodeFromAH_ALHasDriveNumber:
	call	Int13h_SetErrorCodeToBdaAndToIntpackInSSBPfromAH_ALHasDriveNumber

%else
	call	Int13h_SetErrorCodeToBdaAndToIntpackInSSBPfromAH
%endif

Int13h_ReturnFromHandlerWithoutStoringErrorCode:
	; Always return with interrupts enabled since there are programs that rely
	; on INT 13h to enable interrupts.
	or		BYTE [bp+IDEPACK.intpack+INTPACK.flags+1], (FLG_FLAGS_IF>>8)
	mov		sp, bp	; This makes possible to exit anytime, no matter what is on stack
	RESTORE_FRAME_INTPACK_FROM_SSBP		SIZE_OF_IDEPACK_WITHOUT_INTPACK


;--------------------------------------------------------------------
; Int13h_CallPreviousInt13hHandler
;	Parameters:
;		AH:		INT 13h function to call
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		Depends on function
;       NOTE: ES:DI needs to be returned from the previous interrupt
;		      handler, for floppy DPT in function 08h
;	Corrupts registers:
;		None
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int13h_CallPreviousInt13hHandler:
	call	ExchangeCurrentInt13hHandlerWithOldInt13hHandler
	int		BIOS_DISK_INTERRUPT_13h
;;;  fall-through to ExchangeCurrentInt13hHandlerWithOldInt13hHandler

;--------------------------------------------------------------------
; ExchangeCurrentInt13hHandlerWithOldInt13hHandler
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;       Nothing
;       Note: Flags are preserved
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ExchangeCurrentInt13hHandlerWithOldInt13hHandler:
	push	es
	push	si
	LOAD_BDA_SEGMENT_PRESERVE_FLAGS_TO	es, si
	mov		si, [RAMVARS.fpOldI13h]
	cli
	xchg	si, [es:BIOS_DISK_INTERRUPT_13h*4]
	mov		[RAMVARS.fpOldI13h], si
	mov		si, [RAMVARS.fpOldI13h+2]
	xchg	si, [es:BIOS_DISK_INTERRUPT_13h*4+2]
	sti
	mov		[RAMVARS.fpOldI13h+2], si
	pop		si
	pop		es
	ret


;--------------------------------------------------------------------
; Int13h_SetErrorCodeToBdaAndToIntpackInSSBPfromAH
; Int13h_SetErrorCodeToIntpackInSSBPfromAH
;	Parameters:
;		AH:		BIOS error code (00h = no error)
;		SS:BP:	Ptr to IDEPACK
;	Returns:
;		SS:BP:	Ptr to IDEPACK with error condition set
;	Corrupts registers:
;		DS, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
%ifdef MODULE_SERIAL_FLOPPY
Int13h_SetErrorCodeToBdaAndToIntpackInSSBPfromAH_ALHasDriveNumber:
	; Store error code to BDA
	mov		bx, BDA.bHDLastSt
	test	al, al
	js		SHORT .HardDisk
	mov		bl, BDA.bFDRetST & 0xff
.HardDisk:
	LOAD_BDA_SEGMENT_TO	ds, di
	mov		[bx], ah
	; Fall to Int13h_SetErrorCodeToIntpackInSSBPfromAH

%else
Int13h_SetErrorCodeToBdaAndToIntpackInSSBPfromAH:
	; Store error code to BDA
	LOAD_BDA_SEGMENT_TO	ds, di
	mov		[BDA.bHDLastSt], ah
	; Fall to Int13h_SetErrorCodeToIntpackInSSBPfromAH
%endif

	; Store error code to INTPACK
Int13h_SetErrorCodeToIntpackInSSBPfromAH:
	mov		[bp+IDEPACK.intpack+INTPACK.ah], ah
	test	ah, ah
	jnz		SHORT .SetCFtoIntpack
	and		BYTE [bp+IDEPACK.intpack+INTPACK.flags], ~FLG_FLAGS_CF
	ret
.SetCFtoIntpack:
	or		BYTE [bp+IDEPACK.intpack+INTPACK.flags], FLG_FLAGS_CF
	ret


; Jump table for correct BIOS function
ALIGN WORD_ALIGN
g_rgw13hFuncJump:
	dw	AH0h_HandlerForDiskControllerReset			; 00h, Disk Controller Reset (All)
	dw	AH1h_HandlerForReadDiskStatus				; 01h, Read Disk Status (All)
	dw	AH2h_HandlerForReadDiskSectors				; 02h, Read Disk Sectors (All)
	dw	AH3h_HandlerForWriteDiskSectors				; 03h, Write Disk Sectors (All)
	dw	AH4h_HandlerForVerifyDiskSectors			; 04h, Verify Disk Sectors (All)
%ifdef MODULE_SERIAL_FLOPPY
	dw	Int13h_ReturnSuccessForFloppy				; 05h, Format Disk Track (XT, AT, EISA)
%else
	dw	UnsupportedFunction							; 05h, Format Disk Track (XT, AT, EISA)
%endif
	dw	UnsupportedFunction							; 06h, Format Disk Track with Bad Sectors (XT)
	dw	UnsupportedFunction							; 07h, Format Multiple Cylinders (XT)
	dw	AH8h_HandlerForReadDiskDriveParameters		; 08h, Read Disk Drive Parameters (All)
	dw	AH9h_HandlerForInitializeDriveParameters	; 09h, Initialize Drive Parameters (All)
	dw	UnsupportedFunction							; 0Ah, Read Disk Sectors with ECC (XT, AT, EISA)
	dw	UnsupportedFunction							; 0Bh, Write Disk Sectors with ECC (XT, AT, EISA)
	dw	AHCh_HandlerForSeek							; 0Ch, Seek (All)
	dw	AHDh_HandlerForResetHardDisk				; 0Dh, Alternate Disk Reset (All)
	dw	UnsupportedFunction							; 0Eh, Read Sector Buffer (XT, PS/1), ESDI Undocumented Diagnostic (PS/2)
	dw	UnsupportedFunction							; 0Fh, Write Sector Buffer (XT, PS/1), ESDI Undocumented Diagnostic (PS/2)
	dw	AH10h_HandlerForCheckDriveReady				; 10h, Check Drive Ready (All)
	dw	AH11h_HandlerForRecalibrate					; 11h, Recalibrate (All)
	dw	UnsupportedFunction							; 12h, Controller RAM Diagnostic (XT)
	dw	UnsupportedFunction							; 13h, Drive Diagnostic (XT)
	dw	UnsupportedFunction							; 14h, Controller Internal Diagnostic (All)
	dw	AH15h_HandlerForReadDiskDriveSize			; 15h, Read Disk Drive Size (AT+)
	dw	UnsupportedFunction							; 16h,
	dw	UnsupportedFunction							; 17h,
	dw	UnsupportedFunction							; 18h,
	dw	UnsupportedFunction							; 19h, Park Heads (PS/2)
	dw	UnsupportedFunction							; 1Ah, Format ESDI Drive (PS/2)
	dw	UnsupportedFunction							; 1Bh, Get ESDI Manufacturing Header (PS/2)
	dw	UnsupportedFunction							; 1Ch, ESDI Special Functions (PS/2)
	dw	UnsupportedFunction							; 1Dh,
	dw	UnsupportedFunction							; 1Eh,
	dw	UnsupportedFunction							; 1Fh,
	dw	UnsupportedFunction							; 20h,
	dw	UnsupportedFunction							; 21h, Read Disk Sectors, Multiple Blocks (PS/1)
	dw	UnsupportedFunction							; 22h, Write Disk Sectors, Multiple Blocks (PS/1)
	dw	AH23h_HandlerForSetControllerFeatures		; 23h, Set Controller Features Register (PS/1)
	dw	AH24h_HandlerForSetMultipleBlocks			; 24h, Set Multiple Blocks (PS/1)
	dw	AH25h_HandlerForGetDriveInformation			; 25h, Get Drive Information (PS/1)

%ifdef MODULE_EBIOS
g_rgwEbiosFunctionJumpTable:
	dw	AH41h_HandlerForCheckIfExtensionsPresent	; 41h, Check if Extensions Present (EBIOS)*
	dw	AH42h_HandlerForExtendedReadSectors			; 42h, Extended Read Sectors (EBIOS)*
	dw	AH43h_HandlerForExtendedWriteSectors		; 43h, Extended Write Sectors (EBIOS)*
	dw	AH44h_HandlerForExtendedVerifySectors		; 44h, Extended Verify Sectors (EBIOS)*
	dw	UnsupportedFunction							; 45h, Lock and Unlock Drive (EBIOS)***
	dw	UnsupportedFunction							; 46h, Eject Media Request (EBIOS)***
	dw	AH47h_HandlerForExtendedSeek				; 47h, Extended Seek (EBIOS)*
	dw	AH48h_HandlerForGetExtendedDriveParameters	; 48h, Get Extended Drive Parameters (EBIOS)*
;	dw	UnsupportedFunction							; 49h, Get Extended Disk Change Status (EBIOS)***
;	dw	UnsupportedFunction							; 4Ah, Initiate Disk Emulation (Bootable CD-ROM)
;	dw	UnsupportedFunction							; 4Bh, Terminate Disk Emulation (Bootable CD-ROM)
;	dw	UnsupportedFunction							; 4Ch, Initiate Disk Emulation and Boot (Bootable CD-ROM)
;	dw	UnsupportedFunction							; 4Dh, Return Boot Catalog (Bootable CD-ROM)
;	dw	UnsupportedFunction							; 4Eh, Set Hardware Configuration (EBIOS)**
;
;   * = Enhanced Drive Access Support (minimum required EBIOS functions)
;  ** = Enhanced Disk Drive (EDD) Support
; *** = Drive Locking and Ejecting Support
%endif
