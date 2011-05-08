; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for finding Disk Parameter Table.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Finds pointer to first unused Disk Parameter Table.
;
; FindDPT_ForNewDriveToDSDI
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to first unused DPT
;	Corrupts registers:
;		DL
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ForNewDriveToDSDI:
	mov		dl, [RAMVARS.bFirstDrv]
	add		dl, [RAMVARS.bDrvCnt]
	; Fall to FindDPT_ForDriveNumber


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
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ForDriveNumber:
	push	dx
	xchg	di, ax	; Save the contents of AX in DI

	mov		al, LARGEST_DPT_SIZE
	sub		dl, [RAMVARS.bFirstDrv]
	mul		dl
	add		ax, BYTE RAMVARS_size

	xchg	di, ax	; Restore AX and put result in DI
	pop		dx
	ret


;--------------------------------------------------------------------
; Finds Disk Parameter Table for
; Master or Slave drive at wanted port.
;
; FindDPT_ToDSDIForIdeMasterAtPortDX
; FindDPT_ToDSDIForIdeSlaveAtPortDX
;	Parameters:
;		DX:		IDE Base Port address
;		DS:		RAMVARS segment
;	Returns:
;		DL:		Drive number (if DPT found)
;		DS:DI:	Ptr to DPT
;		CF:		Set if wanted DPT found
;				Cleared if DPT not found
;	Corrupts registers:
;		SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ToDSDIForIdeMasterAtPortDX:
	mov		si, IterateToMasterAtPortCallback
	jmp		SHORT IterateAllDPTs

ALIGN JUMP_ALIGN
FindDPT_ToDSDIForIdeSlaveAtPortDX:
	mov		si, IterateToSlaveAtPortCallback
	jmp		SHORT IterateAllDPTs

;--------------------------------------------------------------------
; Iteration callback for finding DPT using
; IDE base port for Master or Slave drive.
;
; IterateToSlaveAtPortCallback
; IterateToMasterAtPortCallback
;	Parameters:
;		CH:		Drive number
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
IterateToSlaveAtPortCallback:
	test	BYTE [di+DPT.bFlagsLow], FLGL_DPT_SLAVE	; Clears CF
	jnz		SHORT CompareBasePortAddress
	ret		; Wrong DPT

ALIGN JUMP_ALIGN
IterateToMasterAtPortCallback:
	test	BYTE [di+DPT.bFlagsLow], FLGL_DPT_SLAVE
	jnz		SHORT ReturnWrongDPT				; Return if slave drive

CompareBasePortAddress:
	push	bx
	eMOVZX	bx, BYTE [di+DPT.bIdevarsOffset]	; CS:BX now points to IDEVARS
	cmp		dx, [cs:bx+IDEVARS.wPort]			; Wanted port?
	pop		bx
	jne		SHORT ReturnWrongDPT
	mov		dl, ch								; Return drive number in DL
	stc											; Set CF since wanted DPT
	ret


;--------------------------------------------------------------------
; IterateToDptWithInterruptInServiceFlagSet
;	Parameters:
;		DS:DI:	Ptr to DPT to examine
;	Returns:
;		CF:		Set if wanted DPT found
;				Cleared if wrong DPT
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IterateToDptWithInterruptInServiceFlagSet:
	test	BYTE [di+DPT.bFlagsHigh], FLGH_DPT_INTERRUPT_IN_SERVICE
	jz		SHORT ReturnWrongDPT
	stc										; Set CF since wanted DPT
	ret
ReturnWrongDPT:
	clc										; Clear CF since wrong DPT
	ret


;--------------------------------------------------------------------
; FindDPT_ToDSDIforInterruptInService
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to DPT
;		CF:		Set if wanted DPT found
;				Cleared if DPT not found
;	Corrupts registers:
;		SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ToDSDIforInterruptInService:
	mov		si, IterateToDptWithInterruptInServiceFlagSet
	; Fall to IterateAllDPTs


;--------------------------------------------------------------------
; Iterates all Disk Parameter Tables.
;
; IterateAllDPTs
;	Parameters:
;		AX,BX,DX:	Parameters to callback function
;		CS:SI:		Ptr to callback function
;		DS:			RAMVARS segment
;	Returns:
;		DS:DI:		Ptr to wanted DPT (if found)
;		CF:			Set if wanted DPT found
;					Cleared if DPT not found
;	Corrupts registers:
;		Nothing unless corrupted by callback function
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IterateAllDPTs:
	push	cx
	mov		cx, [RAMVARS.wDrvCntAndFirst]
	jcxz	.AllDptsIterated			; Return if no drives
	mov		di, RAMVARS_size			; Point DS:DI to first DPT
ALIGN JUMP_ALIGN
.LoopWhileDPTsLeft:
	call	si							; Is wanted DPT?
	jc		SHORT .AllDptsIterated		;  If so, return
	inc		ch							; Increment drive number
	add		di, BYTE LARGEST_DPT_SIZE	; Point to next DPT
	dec		cl							; Decrement drives left
	jnz		SHORT .LoopWhileDPTsLeft
	clc									; Clear CF since DPT not found
ALIGN JUMP_ALIGN
.AllDptsIterated:
	pop		cx
	ret
