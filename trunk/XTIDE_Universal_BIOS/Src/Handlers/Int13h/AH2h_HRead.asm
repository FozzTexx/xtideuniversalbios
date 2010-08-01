; File name		:	AH2h_HRead.asm
; Project name	:	IDE BIOS
; Created date	:	27.9.2007
; Last update	:	1.8.2010
; Author		:	Tomi Tilli
; Description	:	Int 13h function AH=2h, Read Disk Sectors.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=2h, Read Disk Sectors.
;
; AH2h_HandlerForReadDiskSectors
;	Parameters:
;		AH:		Bios function 2h
;		AL:		Number of sectors to read (1...255)
;		CH:		Cylinder number, bits 7...0
;		CL:		Bits 7...6: Cylinder number bits 9 and 8
;				Bits 5...0:	Starting sector number (1...63)
;		DH:		Starting head number (0...255)
;		DL:		Drive number (8xh)
;		ES:BX:	Pointer to buffer recieving data
;	Parameters loaded by Int13h_Jump:
;		DS:		RAMVARS segment
;	Returns:
;		AH:		Int 13h/40h floppy return status
;		AL:		Burst error length if AH=11h, undefined otherwise
;		CF:		0 if successfull, 1 if error
;		IF:		1
;	Corrupts registers:
;		Flags
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH2h_HandlerForReadDiskSectors:
	test	al, al						; Invalid sector count?
	jz		SHORT AH2h_ZeroCntErr		;  If so, return with error

	; Save registers
	push	dx
	push	cx
	push	bx
	push	ax

	; Select sector or block mode command
	call	FindDPT_ForDriveNumber		; DS:DI now points to DPT
	mov		ah, HCMD_READ_SECT			; Load sector mode command
	cmp		BYTE [di+DPT.bSetBlock], 1	; Block mode enabled?
	jbe		SHORT .XferData				;  If not, jump to transfer
	mov		ah, HCMD_READ_MUL			; Load block mode command

	; Transfer data
ALIGN JUMP_ALIGN
.XferData:
	call	HCommand_OutputCountAndLCHSandCommand
	jc		SHORT .Return				; Return if error
	call	HPIO_ReadBlock				; Read data from IDE-controller
.Return:
	jmp		Int13h_PopXRegsAndReturn

; Invalid sector count (also for AH=3h and AH=4h)
AH2h_ZeroCntErr:
	mov		ah, RET_HD_INVALID			; Invalid value passed
	stc									; Set CF since error
	jmp		Int13h_StoreErrorCodeToBDAandPopDSDIandReturn
