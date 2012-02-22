; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for accessings RAMVARS.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Initializes RAMVARS.
; Drive detection can be started after this function returns.
;
; RamVars_Initialize
;	Parameters:
;		Nothing
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		AX, CX, DI
;--------------------------------------------------------------------
RamVars_Initialize:
	push	es
	; Fall to .StealMemoryForRAMVARS

;--------------------------------------------------------------------
; .StealMemoryForRAMVARS
;	Parameters:
;		Nothing
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.StealMemoryForRAMVARS:
	mov		ax, LITE_MODE_RAMVARS_SEGMENT
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .InitializeRamvars	; No need to steal RAM

	LOAD_BDA_SEGMENT_TO	ds, ax, !		; Zero AX
	mov		al, [cs:ROMVARS.bStealSize]
	sub		[BDA.wBaseMem], ax
	mov		ax, [BDA.wBaseMem]
	eSHL_IM	ax, 6						; Segment to first stolen kB (*=40h)
	; Fall to .InitializeRamvars

;--------------------------------------------------------------------
; .InitializeRamvars
;	Parameters:
;		AX:		RAMVARS segment
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		AX, CX, DI, ES
;--------------------------------------------------------------------
.InitializeRamvars:
	mov		ds, ax
	mov		es, ax
	mov		cx, RAMVARS_size
	xor		di, di
	call	Memory_ZeroESDIwithSizeInCX
	mov		WORD [RAMVARS.wSignature], RAMVARS_SIGNATURE
	; Fall to .InitializeDriveTranslationAndReturn

;--------------------------------------------------------------------
; .InitializeDriveTranslationAndReturn
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
.InitializeDriveTranslationAndReturn:
	pop		es
	jmp		DriveXlate_Reset


;--------------------------------------------------------------------
; Returns segment to RAMVARS.
; RAMVARS might be located at the top of interrupt vectors (0030:0000h)
; or at the top of system base RAM.
;
; RamVars_GetSegmentToDS
;	Parameters:
;		Nothing
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_GetSegmentToDS:
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jnz		SHORT .GetStolenSegmentToDS
%ifndef USE_186
	mov		di, LITE_MODE_RAMVARS_SEGMENT
	mov		ds, di
%else
	push	LITE_MODE_RAMVARS_SEGMENT
	pop		ds
%endif
	ret

ALIGN JUMP_ALIGN
.GetStolenSegmentToDS:
	LOAD_BDA_SEGMENT_TO	ds, di
	mov		di, [BDA.wBaseMem]		; Load available base memory size in kB
	eSHL_IM	di, 6					; Segment to first stolen kB (*=40h)
ALIGN JUMP_ALIGN
.LoopStolenKBs:
	mov		ds, di					; EBDA segment to DS
	add		di, BYTE 64				; DI to next stolen kB
	cmp		WORD [RAMVARS.wSignature], RAMVARS_SIGNATURE
	jne		SHORT .LoopStolenKBs	; Loop until sign found (always found eventually)
	ret


;--------------------------------------------------------------------
; Checks if INT 13h function is handled by this BIOS.
;
; RamVars_IsFunctionHandledByThisBIOS
;	Parameters:
;		AH:		INT 13h function number
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Cleared if function is handled by this BIOS
;				Set if function belongs to some other BIOS
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_IsFunctionHandledByThisBIOS:
	test	ah, ah			; Reset for all floppy and hard disk drives?
	jz		SHORT RamVars_IsDriveHandledByThisBIOS.CFAlreadyClear_IsHandledByOurBIOS
	cmp		ah, 08h
%ifdef MODULE_SERIAL_FLOPPY
; we handle all traffic for function 08h, as we need to wrap both hard disk and floppy drive counts
	je		SHORT RamVars_IsDriveHandledByThisBIOS.CFAlreadyClear_IsHandledByOurBIOS
%else
; we handle all *hard disk* traffic for function 08h, as we need to wrap the hard disk drive count
	je		SHORT RamVars_IsDriveHandledByThisBIOS.IsDriveAHardDisk
%endif
;;; fall-through			
		
;--------------------------------------------------------------------
; Checks if drive is handled by this BIOS.
;
; RamVars_IsDriveHandledByThisBIOS
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Cleared if drive is handled by this BIOS
;				Set if drive belongs to some other BIOS
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_IsDriveHandledByThisBIOS:
	push	ax

	mov		ax, [RAMVARS.wDrvCntAndFirst]		; Drive count to AH, First number to AL
	add		ah, al								; One past last drive to AH
	cmp		dl, ah								; Above last supported?
	jae		SHORT .HardDiskIsNotHandledByThisBIOS
.TestLowLimit:
	cmp		dl, al								; Below first supported?
	jae		SHORT .CFAlreadyClear_IsHandledByOurBIOS_PopAX	; note that CF is clear if the branch is taken

.HardDiskIsNotHandledByThisBIOS:
%ifdef MODULE_SERIAL_FLOPPY
	call	RamVars_UnpackFlopCntAndFirstToAL
	cbw											; normally 0h, could be ffh if no drives present
	adc		ah, al								; if no drives present, still ffh (ffh + ffh + 1 = ffh)
	js		SHORT .DiskIsNotHandledByThisBIOS
	cmp		ah, dl
	jz		SHORT .CFAlreadyClear_IsHandledByOurBIOS_PopAX
	cmp		al, dl
	jz		SHORT .CFAlreadyClear_IsHandledByOurBIOS_PopAX
.DiskIsNotHandledByThisBIOS:			
%endif

	stc											; Is not supported by our BIOS
		
.CFAlreadyClear_IsHandledByOurBIOS_PopAX:				
	pop		ax
.CFAlreadyClear_IsHandledByOurBIOS:	
	ret

%ifndef MODULE_SERIAL_FLOPPY		
;
; Note that we could have just checked for the high order bit in dl, but with the needed STC and jumps, 
; leveraging the code above resulted in space savings.
;
.IsDriveAHardDisk:		
	push	ax									; match stack at the top of routine
	mov		al, 80h								; to catch all hard disks, lower limit is 80h vs. bFirstDrv
	jmp		.TestLowLimit						; and there is no need to test a high limit
%endif

;--------------------------------------------------------------------
; RamVars_GetHardDiskCountFromBDAtoAX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AX:		Total hard disk count
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_GetHardDiskCountFromBDAtoAX:
	push	es

	LOAD_BDA_SEGMENT_TO	es, ax
	call	RamVars_GetCountOfKnownDrivesToAX
	mov		cl, [es:BDA.bHDCount]
	MAX_U	al, cl
		
	pop		es
	ret

;--------------------------------------------------------------------
; RamVars_GetCountOfKnownDrivesToAX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AX:		Total hard disk count
;	Corrupts registers:
;		None
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_GetCountOfKnownDrivesToAX:
	mov		ax, [RAMVARS.wDrvCntAndFirst]
	add		al, ah
	and		al, 7fh
	cbw
	ret
	
;--------------------------------------------------------------------
; RamVars_GetIdeControllerCountToCX
;	Parameters:
;		Nothing
;	Returns:
;		CX:		Number of IDE controllers to handle
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_GetIdeControllerCountToCX:
	eMOVZX	cx, BYTE [cs:ROMVARS.bIdeCnt]
	ret

%ifdef MODULE_SERIAL_FLOPPY
;--------------------------------------------------------------------
; RamVars_UnpackFlopCntAndFirstToAL
;	Parameters:
;		Nothing
;	Returns:
;		AL:		First floppy drive number supported
;       CF:		Number of floppy drives supported (clear = 1, set = 2)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------		
ALIGN JUMP_ALIGN
RamVars_UnpackFlopCntAndFirstToAL:
	mov		al, [RAMVARS.xlateVars+XLATEVARS.bFlopCntAndFirst]
	sar		al, 1		
	ret
%endif
