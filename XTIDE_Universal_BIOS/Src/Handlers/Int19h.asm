; Project name	:	XTIDE Universal BIOS
; Description	:	Int 19h Handler (Boot Loader).

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int19h_BootLoaderHandler
;	Parameters:
;		Nothing
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
Int19h_BootLoaderHandler:
	LOAD_BDA_SEGMENT_TO	es, ax
	call	Initialize_AndDetectDrives		; Installs new boot menu loader
	; Fall to .PrepareStackAndSelectDriveFromBootMenu

;--------------------------------------------------------------------
; .PrepareStackAndSelectDriveFromBootMenu
;	Parameters:
;		ES:		BDA and interrupt vector segment (zero)
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
.PrepareStackAndSelectDriveFromBootMenu:
	STORE_POST_STACK_POINTER
	SWITCH_TO_BOOT_MENU_STACK
	; Fall to .InitializeDisplay

;--------------------------------------------------------------------
; .InitializeDisplay
;	Parameters:
;		Nothing
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
.InitializeDisplay:
	; Change display mode if necessary
	mov		ax, [cs:ROMVARS.wDisplayMode]	; AH 00h = Set Video Mode
	cmp		al, DEFAULT_TEXT_MODE
	je		SHORT .InitializeDisplayLibrary
	int		BIOS_VIDEO_INTERRUPT_10h
.InitializeDisplayLibrary:
	call	BootMenuPrint_InitializeDisplayContext
	; Fall to .SelectDriveToBootFrom

;--------------------------------------------------------------------
; .SelectDriveToBootFrom
;	Parameters:
;		Nothing
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
.SelectDriveToBootFrom:
	call	RamVars_GetSegmentToDS
	cmp		WORD [cs:ROMVARS.wfDisplayBootMenu], BYTE 0
	jne		SHORT ProcessBootMenuSelectionsUntilBootableDriveSelected	; Display boot menu
	; Fall to BootFromDriveAthenTryDriveC

;--------------------------------------------------------------------
; BootFromDriveAthenTryDriveC
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Never returns (loads operating system)
;--------------------------------------------------------------------
BootFromDriveAthenTryDriveC:
	xor		dx, dx				; DL = 00h = Floppy Drive A
	call	BootSector_TryToLoadFromDriveDL
	jc		SHORT Int19hMenu_JumpToBootSector_or_RomBoot
	mov		dl, 80h				; DL = 80h = First Hard Drive (usually C)
	call	BootSector_TryToLoadFromDriveDL
	jmp		SHORT Int19hMenu_JumpToBootSector_or_RomBoot	; ROM Boot if error


;--------------------------------------------------------------------
; ProcessBootMenuSelectionsUntilBootableDriveSelected
;	Parameters:
;		DS:		RAMVARS segment
;	Returns:
;		Never returns
;--------------------------------------------------------------------
ProcessBootMenuSelectionsUntilBootableDriveSelected:
	call	BootMenu_DisplayAndReturnSelectionInDX
	call	DriveXlate_ToOrBack											; Translate drive number
	call	BootSector_TryToLoadFromDriveDL
	jnc		SHORT ProcessBootMenuSelectionsUntilBootableDriveSelected	; Boot failure, show menu again
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
	mov		cx, es		; Preserve MBR segment (can't push because of stack change)
	mov		ax, 0		; NOTE: can't use XOR (LOAD_BDA_SEGMENT_TO) as it impacts CF
	SWITCH_BACK_TO_POST_STACK

; clear segment registers before boot sector or rom call
	mov		ds, ax		
	mov		es, ax
%ifdef USE_386
	mov		fs, ax
	mov		gs, ax
%endif
	jnc		SHORT .romboot

; jump to boot sector
	push	cx			; sgment address for MBR
	push	bx			; offset address for MBR
	retf				; NOTE:	DL is set to the drive number

; Boot by calling INT 18h (ROM Basic of ROM DOS)
.romboot:
	int		BIOS_BOOT_FAILURE_INTERRUPT_18h	; Never returns		
