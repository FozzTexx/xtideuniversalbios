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
	; Always steal memory when using Advanced ATA module since it
	; uses larger DPTs
%ifndef MODULE_ADVANCED_ATA
	mov		ax, LITE_MODE_RAMVARS_SEGMENT
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .InitializeRamvars	; No need to steal RAM
%endif

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

%ifndef MODULE_ADVANCED_ATA	; Always in Full Mode when using Advanced ATA Module
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
%endif ; MODULE_ADVANCED_ATA

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
	call	RamVars_GetCountOfKnownDrivesToAX
	push	ds
	LOAD_BDA_SEGMENT_TO	ds, cx
	mov		cl, [BDA.bHDCount]
	MAX_U	al, cl
	pop		ds
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
	and		ax, BYTE 7fh
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
	eMOVZX	cx, [cs:ROMVARS.bIdeCnt]
	ret

%ifdef MODULE_SERIAL_FLOPPY
;--------------------------------------------------------------------
; RamVars_UnpackFlopCntAndFirstToAL
;	Parameters:
;		Nothing
;	Returns:
;		AL:		First floppy drive number supported
;       CF:		Number of floppy drives supported (clear = 1, set = 2)
;		SF:		Emulating drives (clear = yes, set = no)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_UnpackFlopCntAndFirstToAL:
	mov		al, [RAMVARS.xlateVars+XLATEVARS.bFlopCntAndFirst]
	sar		al, 1
	ret
%endif
