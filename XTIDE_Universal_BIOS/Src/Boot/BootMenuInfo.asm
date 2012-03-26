; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for generating and accessing drive
;					information to be displayed on boot menu.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Creates new BOOTMENUINFO struct for detected hard disk.
;
; BootMenuInfo_CreateForHardDisk
;	Parameters:
;		DL:		Drive number
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		ES:BX:	Ptr to BOOTMENUINFO (if successful)
;	Corrupts registers:
;		AX, CX, DX, DI
;--------------------------------------------------------------------
BootMenuInfo_CreateForHardDisk:
	call	BootMenuInfo_ConvertDPTtoBX			; ES:BX now points to new BOOTMENUINFO
	push	ds									; Preserve RAMVARS...
	push	si									; ...and SI

	push	es									; ES to be copied to DS

%ifdef MODULE_ADVANCED_ATA
	; Copy DPT_ADVANCED_ATA to BOOTMENUINFO to keep DPTs small.
	; DPT_ADVANCED_ATA has variables that are only needed during initialization.
	mov		ax, [di+DPT_ADVANCED_ATA.wIdeBasePort]
	mov		[es:bx+BOOTMENUINFO.wIdeBasePort], ax
	mov		dx, [di+DPT_ADVANCED_ATA.wMinPioActiveTimeNs]
	mov		[es:bx+BOOTMENUINFO.wMinPioActiveTimeNs], dx

	mov		ax, [di+DPT_ADVANCED_ATA.wMinPioRecoveryTimeNs]
	mov		cx, [di+DPT_ADVANCED_ATA.wControllerID]
	mov		dx, [di+DPT_ADVANCED_ATA.wControllerBasePort]
	pop		ds									; ES copied to DS
	mov		[bx+BOOTMENUINFO.wMinPioRecoveryTimeNs], ax
	mov		[bx+BOOTMENUINFO.wControllerID], cx
	mov		[bx+BOOTMENUINFO.wControllerBasePort], dx

%else
	pop		ds									; ES copied to DS
%endif

	; Store Drive Name
	add		si, BYTE ATA1.strModel				; DS:SI now points drive name
	lea		di, [bx+BOOTMENUINFO.szDrvName]		; ES:DI now points to name destination
	mov		cx, MAX_HARD_DISK_NAME_LENGTH / 2	; Max number of WORDs allowed
.CopyNextWord:
	lodsw
	xchg	al, ah								; Change endianness
	stosw
	loop	.CopyNextWord
	xor		ax, ax								; Zero AX and clear CF
	stosw										; Terminate with NULL

	pop		si
	pop		ds
	ret


;--------------------------------------------------------------------
; BootMenuInfo_GetTotalSectorCount
;	Parameters:
;		DS:DI:		DPT Pointer
;	Returns:
;		BX:DX:AX:	48-bit sector count
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
BootMenuInfo_GetTotalSectorCount:
	test	BYTE [di+DPT.bFlagsLow], FLG_DRVNHEAD_LBA
	jnz		SHORT .ReturnFullCapacity
	jmp		AH15h_GetSectorCountToBXDXAX
.ReturnFullCapacity:
	jmp		AccessDPT_GetLbaSectorCountToBXDXAX


;--------------------------------------------------------------------
; BootMenuInfo_IsAvailable
;	Parameters:
;		Nothing
;	Returns:
;		ES:		Segment to BOOTVARS with BOOTMENUINFOs
;		ZF:		Set if BOOTVARS with BOOTMENUINFOs is available
;				Cleared if not available (no longer initializing)
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
BootMenuInfo_IsAvailable:
	LOAD_BDA_SEGMENT_TO	es, bx
	cmp		WORD [es:BOOTVARS.wMagicWord], BOOTVARS_MAGIC_WORD
	ret


;--------------------------------------------------------------------
; Returns offset to BOOTMENUINFO based on DPT pointer.
;
; BootMenuInfo_ConvertDPTtoBX
;	Parameters:
;		DS:DI:	DPT Pointer
;	Returns:
;		BX:		Offset to BOOTMENUINFO struct
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
BootMenuInfo_ConvertDPTtoBX:
	push	ax
	mov		ax, di
	sub		ax, BYTE RAMVARS_size					; subtract off base of DPTs
	mov		bl, DPT_BOOTMENUINFO_SIZE_MULTIPLIER	; BOOTMENUINFO's are a whole number multiple of DPT size
	mul		bl								
	add		ax, BOOTVARS.rgBootNfo					; add base of BOOTMENUINFO
	xchg	ax, bx
	pop		ax
	ret			
