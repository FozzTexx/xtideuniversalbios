; Project name	:	XTIDE Universal BIOS
; Description	:	Int 19h BIOS functions for Boot Menu.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Boot Menu Loader.
;
; Int19hMenu_BootLoader
;	Parameters:
;		Nothing
;	Returns:
;		Jumps to Int19hMenu_Display, then never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19hMenu_BootLoader:
	; Store POST stack pointer
	LOAD_BDA_SEGMENT_TO	ds, ax
	STORE_POST_STACK_POINTER
	SWITCH_TO_BOOT_MENU_STACK
	call	RamVars_GetSegmentToDS
	; Fall to .InitializeDisplayForBootMenu

;--------------------------------------------------------------------
; .InitializeDisplayForBootMenu
;	Parameters:
;		Nothing
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, DI
;--------------------------------------------------------------------
.InitializeDisplayForBootMenu:
	; Change display mode if necessary
	mov		ax, [cs:ROMVARS.wDisplayMode]	; AH 00h = Set Video Mode
	cmp		al, DEFAULT_TEXT_MODE
	je		SHORT .InitializeDisplayLibrary
	int		BIOS_VIDEO_INTERRUPT_10h
.InitializeDisplayLibrary:	
	call	BootMenuPrint_InitializeDisplayContext
	; Fall to .ProcessMenuSelectionsUntilBootable

;--------------------------------------------------------------------
; .ProcessMenuSelectionsUntilBootable
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
.ProcessMenuSelectionsUntilBootable:
	call	BootMenu_DisplayAndReturnSelection
	call	DriveXlate_ToOrBack							; Translate drive number
	call	BootSector_TryToLoadFromDriveDL
	jnc		SHORT .ProcessMenuSelectionsUntilBootable	; Boot failure, show menu again
	; Fall to Int19hMenu_JumpToBootSector_or_RomBoot
	; (CF is set or we wouldn't be here, see "jnc" immediately above)

;--------------------------------------------------------------------
; Int19hMenu_JumpToBootSector_or_RomBoot
;
; Switches back to the POST stack, clears the DS and ES registers,
; and either jumps to the MBR (Master Boot Record) that was just read,
; or calls the ROM's boot routine on interrupt 18.
;
;	Parameters:
;		DL:		Drive to boot from (translated, 00h or 80h)
;       CF:     Set for Boot Sector Boot 
;               Clear for Rom Boot
;	   	ES:BX:	(if CF set) Ptr to boot sector
;
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19hMenu_JumpToBootSector_or_RomBoot:
		mov		cx,es		; preserve MBR segment
;
; inline of SWITCH_BACK_TO_POST_STACK macro, so that we can preserve CF
; and reuse zero value in ax for clearing segment registers
;
		mov		ax,0		; NOTE: can't use XOR as it impacts CF
%ifndef USE_386
		cli
		mov		ss,ax
		mov		sp,[ss:BOOTVARS.dwPostStack]
		mov		ss,[ss:BOOTVARS.dwPostStack+2]
		sti
%else
		mov		ss,ax
		lss		sp,[ss:BOOTVARS.dwPostStack]
%endif	
;
; end inline of SWITCH_BACK_TO_POST_STACK
;

; clear segment registers before boot sector or rom call
; (old ClearSegmentsForBoot routine)
;
		mov		ds,ax		
		mov		es,ax

		jnc		.romboot

; jump to boot sector
; (old JumpToBootSector routine)
;
		push	cx			; sgment address for MBR
		push	bx			; offset address for MBR
		retf				; NOTE:	DL is set to the drive number

; (old Int19hMenu_RomBoot routine)
;
.romboot:		
		int		BIOS_BOOT_FAILURE_INTERRUPT_18h	; Never returns		
