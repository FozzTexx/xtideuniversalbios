; File name		:	CompatibleDPT.asm
; Project name	:	IDE BIOS
; Created date	:	6.4.2010
; Last update	:	6.4.2010
; Author		:	Tomi Tilli
; Description	:	Functions for creating Disk Parameter Tables for
;					software compatibility only. These DPTs are not used
;					by our BIOS.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Creates compatible for drives 80h and 81h. There will be stored
; to interrupt vectors 41h and 46h.
;
; CompatibleDPT_CreateForDrives80hAnd81h
;	Parameters:
;		DS:		RAMVARS segment
;		ES:		BDA segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		All except DS and ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CompatibleDPT_CreateForDrives80hAnd81h:
	; Only create compatible DPTs in full mode
	test	BYTE [cs:ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jz		SHORT CompatibleDPT_StoreCustomDPTs

	mov		dl, 80h
	call	FindDPT_ForDriveNumber	; DPT to DS:DI
	jnc		SHORT .CreateForDrive81h
	call	CompatibleDPT_CreateForDrive80h
ALIGN JUMP_ALIGN
.CreateForDrive81h:
	mov		dl, 81h
	call	FindDPT_ForDriveNumber
	jnc		SHORT .Return
	call	CompatibleDPT_CreateForDrive81h
ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; Stores pointers to our custom DPTs for drives 80h and 81h.
;
; CompatibleDPT_StoreCustomDPTs
;	Parameters:
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		DX, DI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CompatibleDPT_StoreCustomDPTs:
	mov		dl, 80h
	call	FindDPT_ForDriveNumber	; DPT to DS:DI
	jnc		SHORT .FindForDrive81h
	mov		[es:INTV_HD0DPT*4], di
	mov		[es:INTV_HD0DPT*4+2], ds
ALIGN JUMP_ALIGN
.FindForDrive81h:
	inc		dx
	call	FindDPT_ForDriveNumber
	jnc		SHORT .Return
	mov		[es:INTV_HD1DPT*4], di
	mov		[es:INTV_HD1DPT*4+2], ds
ALIGN JUMP_ALIGN
.Return:
	ret


;--------------------------------------------------------------------
; Copies parameters from our custom DPT struct to a
; standard COMPATIBLE_FDPT or COMPATIBLE_EDPT struct.
;
; CompatibleDPT_CreateForDrive80h
; CompatibleDPT_CreateForDrive81h
;	Parameters:
;		DS:DI:	Ptr to DPT
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CompatibleDPT_CreateForDrive80h:
	mov		si, FULLRAMVARS.drv80hCompDPT	; DS:SI now points compatible DPT
	call	CompatibleDPT_CopyFromCustom
	mov		[es:INTV_HD0DPT*4], si
	mov		[es:INTV_HD0DPT*4+2], ds
	ret
ALIGN JUMP_ALIGN
CompatibleDPT_CreateForDrive81h:
	mov		si, FULLRAMVARS.drv81hCompDPT	; DS:SI now points compatible DPT
	call	CompatibleDPT_CopyFromCustom
	mov		[es:INTV_HD1DPT*4], si
	mov		[es:INTV_HD1DPT*4+2], ds
	ret


;--------------------------------------------------------------------
; Copies parameters from our custom DPT struct to a
; standard COMPATIBLE_FDPT or COMPATIBLE_EDPT struct.
;
; CompatibleDPT_CopyFromCustom
;	Parameters:
;		DS:SI:	Ptr to COMPATIBLE_FDPT or COMPATIBLE_EDPT
;		DS:DI:	Ptr to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CompatibleDPT_CopyFromCustom:
	call	AccessDPT_GetLCHSfromPCHS			; AX=Lsects, BX=Lcyls, DX=Lheads
	test	BYTE [di+DPT.bFlags], FLG_DPT_EBIOS	; Drive larger than 504 MiB?
	jnz		SHORT CompatibleDPT_CopyFromCustomToEDPT
	; Fall to CompatibleDPT_CopyFromCustomToFDPT

;--------------------------------------------------------------------
; Copies parameters from our custom DPT struct to a
; standard COMPATIBLE_FDPT struct for drives up to 504 MiB.
;
; CompatibleDPT_CopyFromCustomToFDPT
;	Parameters:
;		AX:		L-CHS sectors per track
;		BX:		L-CHS cylinders
;		DX:		L-CHS heads
;		DS:SI:	Ptr to COMPATIBLE_FDPT
;		DS:DI:	Ptr to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
CompatibleDPT_CopyFromCustomToFDPT:
	mov		[si+COMPATIBLE_FDPT.wCyls], bx
	mov		[si+COMPATIBLE_FDPT.bHeads], dl
	mov		[si+COMPATIBLE_FDPT.bSectPerTrack], al
	mov		WORD [si+COMPATIBLE_FDPT.wWrPreCmpCyl], -1
	mov		al, [di+DPT.bDrvCtrl]
	mov		[si+COMPATIBLE_FDPT.bDrvCtrl], al
	mov		BYTE [si+COMPATIBLE_FDPT.bNormTimeout], B_TIMEOUT_BSY
	mov		BYTE [si+COMPATIBLE_FDPT.bFormatTimeout], B_TIMEOUT_DRQ
	mov		BYTE [si+COMPATIBLE_FDPT.bCheckTimeout], B_TIMEOUT_DRQ
	dec		bx
	mov		[si+COMPATIBLE_FDPT.wLZoneCyl], bx
	ret


;--------------------------------------------------------------------
; Copies parameters from our custom DPT struct to a
; standard COMPATIBLE_EDPT struct.
;
; CompatibleDPT_CopyFromCustomToEDPT
;	Parameters:
;		AX:		L-CHS sectors per track
;		BX:		L-CHS cylinders
;		DX:		L-CHS heads
;		DS:SI:	Ptr to COMPATIBLE_EDPT
;		DS:DI:	Ptr to DPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
CompatibleDPT_CopyFromCustomToEDPT:
	mov		[si+COMPATIBLE_EDPT.wLCyls], bx
	mov		[si+COMPATIBLE_EDPT.bLHeads], dl
	mov		BYTE [si+COMPATIBLE_EDPT.bSignature], COMPATIBLE_EDPT_SIGNATURE
	mov		[si+COMPATIBLE_EDPT.bPSect], al
	mov		[si+COMPATIBLE_EDPT.bLSect], al
	mov		al, [di+DPT.bDrvCtrl]
	mov		[si+COMPATIBLE_EDPT.bDrvCtrl], al
	mov		ax, [di+DPT.wPCyls]
	mov		[si+COMPATIBLE_EDPT.wPCyls], ax
	mov		al, [di+DPT.bPHeads]
	mov		[si+COMPATIBLE_EDPT.bPHeads], al
	; Fall to CompatibleDPT_StoreChecksum

;--------------------------------------------------------------------
; Stores checksum byte to the end of COMPATIBLE_EDPT struct.
;
; CompatibleDPT_StoreChecksum
;	Parameters:
;		DS:SI:	Ptr to COMPATIBLE_EDPT
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, CX
;--------------------------------------------------------------------
;ALIGN JUMP_ALIGN
CompatibleDPT_StoreChecksum:
	xor		ax, ax
	xor		bx, bx
	mov		cx, COMPATIBLE_EDPT_size-1
ALIGN JUMP_ALIGN
.SumLoop:
	add		al, [bx+si]
	inc		bx
	loop	.SumLoop
	neg		al
	mov		[si+COMPATIBLE_EDPT.bChecksum], al
	ret
