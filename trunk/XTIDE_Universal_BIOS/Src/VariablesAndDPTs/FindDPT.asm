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
;		DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ForNewDriveToDSDI:
	mov		ax, [RAMVARS.wDrvCntAndFirst]
	add		al, ah
%ifdef MODULE_SERIAL_FLOPPY
	add		al, [RAMVARS.xlateVars+XLATEVARS.bFlopCreateCnt]
%endif
	xchg	ax, dx
	; fall-through to FindDPT_ForDriveNumber

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

%ifdef MODULE_SERIAL_FLOPPY
	mov		ax, [RAMVARS.wDrvCntAndFirst]
		
	test	dl, dl
	js		.harddisk

	call	RamVars_UnpackFlopCntAndFirstToAL
	add		dl, ah						; add in end of hard disk DPT list, floppies start immediately after
.harddisk:
	sub		dl, al						; subtract off beginning of either hard disk or floppy list (as appropriate)
%else
	sub		dl, [RAMVARS.bFirstDrv]		; subtract off beginning of hard disk list
%endif
		
	mov		al, LARGEST_DPT_SIZE
		
	mul		dl
	add		ax, BYTE RAMVARS_size

	xchg	di, ax						; Restore AX and put result in DI
	pop		dx
		
	ret

;--------------------------------------------------------------------
; Consolidator for checking the result from RamVars_IsDriveHandledByThisBIOS
; and then if it is our drive, getting the DPT with FindDPT_ForDriveNumber
;
; RamVars_IsDriveHandledByThisBIOS_And_FindDPT_ForDriveNumber
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;	Returns:
;		DS:DI:	Ptr to DPT, if it is our drive
;       CF:     Set if not our drive, clear if it is our drive
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
RamVars_IsDriveHandledByThisBIOS_And_FindDPT_ForDriveNumber:
	call	RamVars_IsDriveHandledByThisBIOS
	jnc		FindDPT_ForDriveNumber
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
;
; Converted to macros since there is only once call site for each of these
;
;--------------------------------------------------------------------
	
%macro FindDPT_ToDSDIForIdeMasterAtPortDX 0
	mov		si, IterateToMasterAtPortCallback
	call	IterateAllDPTs
%endmacro

%macro FindDPT_ToDSDIForIdeSlaveAtPortDX 0
	mov		si, IterateToSlaveAtPortCallback
	call	IterateAllDPTs
%endmacro

		
;--------------------------------------------------------------------
; Iteration callback for finding DPT using
; IDE base port for Master or Slave drive.
;
; IterateToSlaveAtPortCallback
; IterateToMasterAtPortCallback
;	Parameters:
;		DX:		IDE Base Port address
;		DS:DI:	Ptr to DPT to examine
;	Returns:
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

ReturnRightDPT:
	stc											; Set CF since wanted DPT
	ret


;--------------------------------------------------------------------
; IterateToDptWithFlagsHighInBL
;	Parameters:
;		DS:DI:	Ptr to DPT to examine
;       BL:		Bit(s) to test in DPT.bFlagsHigh 
;	Returns:
;		CF:		Set if wanted DPT found
;				Cleared if wrong DPT
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IterateToDptWithFlagsHighInBL:		
	test	BYTE [di+DPT.bFlagsHigh], bl		; Clears CF (but we need the clc
												; below anyway for callers above)
	jnz		SHORT ReturnRightDPT

ReturnWrongDPT:
	clc										; Clear CF since wrong DPT
	ret

;--------------------------------------------------------------------
; FindDPT_ToDSDIforSerialDevice
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
FindDPT_ToDSDIforSerialDevice:			
	mov		bl, FLGH_DPT_SERIAL_DEVICE
; fall-through
				
;--------------------------------------------------------------------
; FindDPT_ToDSDIforFlagsHigh
;	Parameters:
;		DS:		RAMVARS segment
;       BL:		Bit(s) to test in DPT.bFlagsHigh
;	Returns:
;		DS:DI:	Ptr to DPT
;		CF:		Set if wanted DPT found
;				Cleared if DPT not found
;	Corrupts registers:
;		SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
FindDPT_ToDSDIforFlagsHighInBL:		
	mov		si, IterateToDptWithFlagsHighInBL
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
;					If not found, points to first empty DPT
;		CF:			Set if wanted DPT found
;					Cleared if DPT not found, or no DPTs present
;	Corrupts registers:
;		Nothing unless corrupted by callback function
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IterateAllDPTs:
	push	cx

	mov		di, RAMVARS_size			; Point DS:DI to first DPT
		
	mov		cl, [RAMVARS.bDrvCnt]
	xor		ch, ch						; Clears CF  
		
	jcxz	.AllDptsIterated			; Return if no drives, CF will be clear from xor above
		
ALIGN JUMP_ALIGN
.LoopWhileDPTsLeft:
	call	si							; Is wanted DPT?
	jc		SHORT .AllDptsIterated		;  If so, return
	add		di, BYTE LARGEST_DPT_SIZE	; Point to next DPT, clears CF
	loop	.LoopWhileDPTsLeft
	
	; fall-through: DPT was not found, CF is already clear from ADD di inside the loop
		
ALIGN JUMP_ALIGN
.AllDptsIterated:
	pop		cx
	ret

