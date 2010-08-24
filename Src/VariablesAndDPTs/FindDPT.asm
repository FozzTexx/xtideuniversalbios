; File name		:	FindDPT.asm
; Project name	:	IDE BIOS
; Created date	:	14.3.2010
; Last update	:	12.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions for finding Disk Parameter Table.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Finds pointer to first unused Disk Parameter Table.
;
; FindDPT_ForNewDrive
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to first unused DPT
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ForNewDrive:
	push	si
	mov		si, FindDPT_ReturnWrongDPT
	jmp		SHORT FindDPT_StartIterationAndReturnAfterDone


;--------------------------------------------------------------------
; Finds Disk Parameter Table for
; Master or Slave drive at wanted port.
;
; FindDPT_ForIdeSlaveAtPort
; FindDPT_ForIdeMasterAtPort
;	Parameters:
;		DX:		IDE Base Port address
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Drive number (if DPT found)
;		DS:DI:	Ptr to DPT
;		CF:		Set if wanted DPT found
;				Cleared if DPT not found
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ForIdeSlaveAtPort:
	push	si
	mov		si, FindDPT_IterateToSlaveAtPortCallback
	jmp		SHORT FindDPT_StartIterationAndReturnAfterDone

ALIGN JUMP_ALIGN
FindDPT_ForIdeMasterAtPort:
	push	si
	mov		si, FindDPT_IterateToMasterAtPortCallback
	jmp		SHORT FindDPT_StartIterationAndReturnAfterDone

;--------------------------------------------------------------------
; Iteration callback for finding DPT using
; IDE base port for Master or Slave drive.
;
; FindDPT_IterateToSlaveAtPortCallback
; FindDPT_IterateToMasterAtPortCallback
;	Parameters:
;		DX:		IDE Base Port address
;		DS:DI:	Ptr to DPT to examine
;	Returns:
;		DL:		Drive number if correct DPT
;		CF:		Set if wanted DPT found
;				Cleared if wrong DPT
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_IterateToSlaveAtPortCallback:
	test	BYTE [di+DPT.bDrvSel], FLG_IDE_DRVHD_DRV
	jnz		SHORT FindDPT_IterateToMasterOrSlaveAtPortCallback
	jmp		SHORT FindDPT_ReturnWrongDPT	; Return if master drive

ALIGN JUMP_ALIGN
FindDPT_IterateToMasterAtPortCallback:
	test	BYTE [di+DPT.bDrvSel], FLG_IDE_DRVHD_DRV
	jnz		SHORT FindDPT_ReturnWrongDPT	; Return if slave drive

	; If BIOS partitioned, ignore all but first partition
ALIGN JUMP_ALIGN
FindDPT_IterateToMasterOrSlaveAtPortCallback:
	test	BYTE [di+DPT.bFlags], FLG_DPT_PARTITION
	jz		SHORT .CompareBasePortAddress
	test	BYTE [di+DPT.bFlags], FLG_DPT_FIRSTPART
	jz		SHORT FindDPT_ReturnWrongDPT
ALIGN JUMP_ALIGN
.CompareBasePortAddress:
	push	bx
	eMOVZX	bx, BYTE [di+DPT.bIdeOff]		; CS:BX now points to IDEVARS
	cmp		dx, [cs:bx+IDEVARS.wPort]		; Wanted port?
	pop		bx
	jne		SHORT FindDPT_ReturnWrongDPT
	mov		dl, [di+DPT.bDrvNum]			; Load drive number
	stc										; Set CF since wanted DPT
	ret


;--------------------------------------------------------------------
; Finds Disk Parameter Table for drive number.
; IDE Base Port address will be stored to RAMVARS if correct DPT is found.
;
; FindDPT_ForDriveNumber
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to DPT
;		CF:		Set if wanted DPT found
;				Cleared if DPT not found
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ForDriveNumber:
	push	si
	mov		si, FindDPT_IterateToDriveNumberCallback
FindDPT_StartIterationAndReturnAfterDone:
	call	FindDPT_IterateAllDPTs
	pop		si
	ret

;--------------------------------------------------------------------
; Iteration callback for finding DPT for drive number.
;
; FindDPT_IterateToDriveNumberCallback
;	Parameters:
;		DL:		Drive number to search for
;		DS:DI:	Ptr to DPT to examine
;	Returns:
;		CF:		Set if wanted DPT found
;				Cleared if wrong DPT
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_IterateToDriveNumberCallback:
	cmp		dl, [di+DPT.bDrvNum]			; Wanted DPT found?
	je		SHORT FindDPT_RightDriveNumber	;  If so, return
FindDPT_ReturnWrongDPT:
	clc										; Clear CF since wrong DPT
	ret
ALIGN JUMP_ALIGN
FindDPT_RightDriveNumber:
	push	bx
	eMOVZX	bx, BYTE [di+DPT.bIdeOff]		; CS:BX now points to IDEVARS
	mov		bx, [cs:bx+IDEVARS.wPort]		; Load IDE Base Port address...
	mov		[RAMVARS.wIdeBase], bx			; ...and store it to RAMVARS
	pop		bx
	stc
	ret


;--------------------------------------------------------------------
; Iterates all Disk Parameter Tables.
;
; FindDPT_IterateAllDPTs
;	Parameters:
;		BX,DX:	Parameters to callback function
;		CS:SI:	Ptr to callback function
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to wanted DPT (if found)
;		CF:		Set if wanted DPT found
;				Cleared if DPT not found
;	Corrupts registers:
;		Nothing, unless corrupted by callback function
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_IterateAllDPTs:
	push	ax
	push	cx
	call	FindDPT_PointToFirstDPT		; Point DS:DI to first DPT
	eMOVZX	cx, BYTE [RAMVARS.bDrvCnt]	; Load number of drives
	xor		ax, ax						; Zero AX for DPT size and clear CF
	jcxz	.Return						; Return if no drives
ALIGN JUMP_ALIGN
.LoopWhileDPTsLeft:
	call	si							; Is wanted DPT?
	jc		SHORT .Return				;  If so, return
	mov		al, [di+DPT.bSize]			; Load DPT size to AX
	add		di, ax						; Point to next DPT
	loop	.LoopWhileDPTsLeft			; Check next DPT
	clc									; Clear CF since DPT not found
ALIGN JUMP_ALIGN
.Return:
	pop		cx
	pop		ax
	ret


;--------------------------------------------------------------------
; Sets DI to point to first Disk Parameter Table.
;
; FindDPT_PointToFirstDPT
;	Parameters:
;		Nothing
;	Returns:
;		DI:		Offset to first DPT (even if unused)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_PointToFirstDPT:
	mov		di, RAMVARS_size
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT .Return							; RAMVARS used (top of interrupt vectors)
	add		di, BYTE FULLRAMVARS_size-RAMVARS_size	; FULLRAMVARS used (top of base memory)
ALIGN JUMP_ALIGN
.Return:
	ret
