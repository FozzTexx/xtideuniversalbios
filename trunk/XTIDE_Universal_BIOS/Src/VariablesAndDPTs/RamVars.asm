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
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .InitializeRamvars	; No need to steal RAM

	LOAD_BDA_SEGMENT_TO	ds, ax, !		; Zero AX
	mov		al, [cs:ROMVARS.bStealSize]
	sub		[BDA.wBaseMem], ax
	mov		ax, [BDA.wBaseMem]
	eSHL_IM	ax, 6						; Segment to first stolen kB (*=40h)
	mov		ds, ax
	mov		WORD [FULLRAMVARS.wSign], W_SIGN_FULLRAMVARS
	; Fall to .InitializeRamvarsFromDS

;--------------------------------------------------------------------
; .InitializeRamvars
;	Parameters:
;		Nothing
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		AX, CX, DI, ES
;--------------------------------------------------------------------
.InitializeRamvars:
	call	RamVars_GetSegmentToDS
	mov		cx, RAMVARS_size
	xor		di, di
	push	ds
	pop		es
	call	Memory_ZeroESDIwithSizeInCX
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
	mov		di, SEGMENT_RAMVARS_TOP_OF_INTERRUPT_VECTORS
	mov		ds, di
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
	cmp		WORD [FULLRAMVARS.wSign], W_SIGN_FULLRAMVARS
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
;		CF:		Set if function is handled by this BIOS
;				Cleared if function belongs to some other BIOS
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_IsFunctionHandledByThisBIOS:
	test	ah, ah			; Reset for all floppy and hard disk drives?
	jz		SHORT .FunctionIsHandledByOurBIOS
	cmp		ah, 08h			; Read Disk Drive Parameters?
	jne		SHORT RamVars_IsDriveHandledByThisBIOS
	test	dl, dl			; We do not handle floppy drives
	jns		SHORT .FunctionIsNotHandledByOurBIOS
ALIGN JUMP_ALIGN
.FunctionIsHandledByOurBIOS:
	stc
.FunctionIsNotHandledByOurBIOS:
	ret

;--------------------------------------------------------------------
; Checks if drive is handled by this BIOS.
;
; RamVars_IsDriveHandledByThisBIOS
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		CF:		Set if drive is handled by this BIOS
;				Cleared if drive belongs to some other BIOS
;	Corrupts registers:
;		DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_IsDriveHandledByThisBIOS:
	xchg	di, ax								; Backup AX
	mov		ax, [RAMVARS.wDrvCntAndFirst]		; Drive count to AL, First number to AH
	add		al, ah								; One past last drive to AL
	cmp		dl, al								; Above last supported?
	jae		SHORT .DriveNotHandledByThisBIOS
	cmp		ah, dl								; Below first supported?
	ja		SHORT .DriveNotHandledByThisBIOS
	stc
ALIGN JUMP_ALIGN
.DriveNotHandledByThisBIOS:
	xchg	ax, di
	ret


;--------------------------------------------------------------------
; RamVars_IncrementHardDiskCount
;	Parameters:
;		DL:		Drive number for new drive
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
RamVars_IncrementHardDiskCount:
	inc		BYTE [RAMVARS.bDrvCnt]		; Increment drive count to RAMVARS
	cmp		BYTE [RAMVARS.bFirstDrv], 0	; First drive set?
	ja		SHORT .Return				;  If so, return
	mov		[RAMVARS.bFirstDrv], dl		; Store first drive number
.Return:
	ret


;--------------------------------------------------------------------
; RamVars_GetHardDiskCountFromBDAtoCX
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		CX:		Total hard disk count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_GetHardDiskCountFromBDAtoCX:
	push	es
	push	dx

	LOAD_BDA_SEGMENT_TO	es, cx, !		; Zero CX
	call	RamVars_GetCountOfKnownDrivesToDL
	MAX_U	dl, [es:BDA.bHDCount]
	mov		cl, dl

	pop		dx
	pop		es
	ret

;--------------------------------------------------------------------
; RamVars_GetCountOfKnownDrivesToDL
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Total hard disk count
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_GetCountOfKnownDrivesToDL:
	mov		dl, [RAMVARS.bFirstDrv]		; Number for our first drive
	add		dl, [RAMVARS.bDrvCnt]		; Our drives
	and		dl, 7Fh						; Clear HD bit for drive count
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
RamVars_GetIdeControllerCountToCX:
	eMOVZX	cx, BYTE [cs:ROMVARS.bIdeCnt]
	ret
