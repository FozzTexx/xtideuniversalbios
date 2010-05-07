; File name		:	RamVars.asm
; Project name	:	IDE BIOS
; Created date	:	14.3.2010
; Last update	:	2.5.2010
; Author		:	Tomi Tilli
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
;		Nothing
;	Corrupts registers:
;		AX, CX, DI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_Initialize:
	call	RamVars_StealBaseMemory	; Get RAMVARS segment to DS even if no stealing
	call	RamVars_ClearToZero
	jmp		DriveXlate_Reset


;--------------------------------------------------------------------
; Steals base memory to be used for RAMVARS.
;
; RamVars_StealBaseMemory
;	Parameters:
;		Nothing
;	Returns:
;		DS:		RAMVARS segment
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_StealBaseMemory:
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT RamVars_GetSegmentToDS	; No need to steal

	LOAD_BDA_SEGMENT_TO	ds, ax				; Zero AX
	mov		al, [cs:ROMVARS.bStealSize]
	sub		[BDA.wBaseMem], ax				; Steal one or more kilobytes
	mov		ax, [BDA.wBaseMem]				; Load base memory left
	eSHL_IM	ax, 6							; Shift for segment address
	mov		ds, ax							; Copy RAMVARS segment to DS
	ret


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
	jnz		SHORT RamVars_GetStolenSegmentToDS
	mov		di, SEGMENT_RAMVARS_TOP_OF_INTERRUPT_VECTORS
	mov		ds, di
	ret

ALIGN JUMP_ALIGN
RamVars_GetStolenSegmentToDS:
	LOAD_BDA_SEGMENT_TO	ds, di
	mov		di, [BDA.wBaseMem]		; Load available base memory size in kB
	eSHL_IM	di, 6					; Segment to first stolen kB
ALIGN JUMP_ALIGN
.LoopStolenKBs:
	mov		ds, di					; EBDA segment to DS
	add		di, BYTE 64				; DI to next stolen kB
	cmp		WORD [FULLRAMVARS.wSign], W_SIGN_FULLRAMVARS
	jne		SHORT .LoopStolenKBs	; Loop until sign found (always found eventually)
	ret


;--------------------------------------------------------------------
; Clears RAMVARS variables to zero.
; FULLRAMVARS sign will be saved if available.
;
; RamVars_ClearToZero
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX, DI, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_ClearToZero:
	call	FindDPT_PointToFirstDPT	; Get RAMVARS/FULLRAMVARS size to DI
	mov		cx, di					; Copy byte count to CX
	push	ds
	pop		es
	xor		di, di					; ES:DI now points to RAMVARS/FULLRAMVARS
	xor		ax, ax					; Store zeroes
	rep stosb
	mov		WORD [FULLRAMVARS.wSign], W_SIGN_FULLRAMVARS
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
	jnz		SHORT RamVars_IsDriveHandledByThisBIOS
	stc
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
	cmp		dl, ah								; Below first supported?
	jb		SHORT .DriveNotHandledByThisBIOS
	xchg	ax, di
	stc
	ret
ALIGN JUMP_ALIGN
.DriveNotHandledByThisBIOS:
	xchg	ax, di
	clc
	ret


;--------------------------------------------------------------------
; Increments hard disk count to RAMVARS.
;
; RamVars_IncrementHardDiskCount
;	Parameters:
;		DL:		Drive number for new drive
;		DS:		RAMVARS segment
;	Returns:
;		Nothing
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_IncrementHardDiskCount:
	inc		BYTE [RAMVARS.bDrvCnt]		; Increment drive count to RAMVARS
	cmp		BYTE [RAMVARS.bFirstDrv], 0	; First drive set?
	ja		SHORT .Return				;  If so, return
	mov		[RAMVARS.bFirstDrv], dl		; Store first drive number
ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; Return number of Hard Disks in system.
;
; RamVars_GetDriveCounts
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		AL:		Number of hard disks handled by our BIOS
;		CX:		Total number of hard disks in system
;	Corrupts registers:
;		AH
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_GetDriveCounts:
	push	es
	LOAD_BDA_SEGMENT_TO	es, cx			; Zero CX
	mov		cl, [es:BDA.bHDCount]		; Total hard drive count
	mov		al, [RAMVARS.bDrvCnt]		; Our drive count
	pop		es
	ret
