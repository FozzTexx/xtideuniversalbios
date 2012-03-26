; Project name	:	XTIDE Universal BIOS
; Description	:	Common functions for initializing different
;					VLB and PCI IDE Controllers.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; AdvAtaInit_DetectControllerForIdeBaseInDX
;	Parameters:
;		DX:		IDE Controller base port
;	Returns:
;		AX:		ID WORD specific for detected controller
;				Zero if no controller detected
;		CX:		Controller base port (not IDE)
;		CF:		Set if controller detected
;				Cleared if no controller
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
AdvAtaInit_DetectControllerForIdeBaseInDX:
	call	Vision_DetectAndReturnIDinAXandPortInCXifControllerPresent
	jne		SHORT .NoAdvancedControllerForPortDX
	call	Vision_DoesIdePortInDXbelongToControllerWithIDinAX
	jne		SHORT .NoAdvancedControllerForPortDX

	stc		; Advanced Controller found for port DX
	ret

.NoAdvancedControllerForPortDX:
	xor		ax, ax
	ret


;--------------------------------------------------------------------
; AdvAtaInit_GetControllerMaxPioModeToAL
;	Parameters:
;		AX:		ID WORD specific for detected controller
;	Returns:
;		AL:		Max supported PIO mode (if CF set)
;		CF:		Set if PIO limit necessary
;				Cleared if no need to limit timings
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AdvAtaInit_GetControllerMaxPioModeToAL	equ	Vision_GetMaxPioModeToAL


;--------------------------------------------------------------------
; AdvAtaInit_InitializeControllerForDPTinDSDI
;	Parameters:
;		DS:DI:	Ptr to DPT for Single or Slave Drive
;	Returns:
;		CF:		Cleared if success or no controller to initialize
;				Set if error
;	Corrupts registers:
;		AX, BX, CX, DX
;--------------------------------------------------------------------
AdvAtaInit_InitializeControllerForDPTinDSDI:
	push	ds
	push	si
	push	di

	; PIO and Advanced Controller variables are stored to BOOTMENUINFO
	; to keep the DPTs as small as possible.
	call	GetMasterAndSlaveBootMenuInfosToSIandDI
	cmp		WORD [BOOTVARS.wMagicWord], BOOTVARS_MAGIC_WORD
	clc
	jne		SHORT .BootMenuInfosAreNoLongerAvailable

	; Call Controller Specific initialization function
	mov		ax, [si+BOOTMENUINFO.wControllerID]
	test	ax, ax
	jz		SHORT .NoAdvancedController
	call	Vision_InitializeWithIDinAHandConfigInAL	; The only we support at the moment

.BootMenuInfosAreNoLongerAvailable:
.NoAdvancedController:
	pop		di
	pop		si
	pop		ds
	ret


;--------------------------------------------------------------------
; AdvAtaInit_GetMasterAndSlaveBootMenuInfosToSIandDI
;	Parameters:
;		DS:DI:	Ptr to DPT for Single or Slave Drive
;	Returns:
;		DS:SI:	Ptr to Single or Master Drive BOOTMENUINFO
;		DI:		Offset to Slave Drive BOOTMENUINFO
;				Zero if Slave Drive not present
;	Corrupts registers:
;		BX, DX, (DS will change!)
;--------------------------------------------------------------------
GetMasterAndSlaveBootMenuInfosToSIandDI:
	call	BootMenuInfo_ConvertDPTtoBX
	LOAD_BDA_SEGMENT_TO	ds, di, !				; Zero DI to assume no Slave Drive present

	mov		dx, [bx+BOOTMENUINFO.wIdeBasePort]	; Load IDE Port from Single or Slave Drive
	lea		si, [bx+BOOTMENUINFO_size]			; SI points to Slave Drive if present
	cmp		dx, [si+BOOTMENUINFO.wIdeBasePort]
	jne		SHORT .BootMenuInfoForSingleDriveInDSBX

	mov		di, si								; Slave Drive detected, copy pointer to DS:DI
.BootMenuInfoForSingleDriveInDSBX:
	mov		si, bx
	ret


;--------------------------------------------------------------------
; AdvAtaInit_SelectSlowestTimingsToBXandCX
;	Parameters:
;		DS:SI:	Ptr to BOOTMENUINFO for Master or Single Drive
;		DI:		Offset to BOOTMENUINFO for Slave Drive
;				Zero if Slave Drive not present
;	Returns:
;		BX:		Min Active Time in nanosecs
;		CX:		Min Recovery Time in nanosecs
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AdvAtaInit_SelectSlowestTimingsToBXandCX:
	mov		bx, [si+BOOTMENUINFO.wMinPioActiveTimeNs]
	mov		cx, [si+BOOTMENUINFO.wMinPioRecoveryTimeNs]
	test	di, di
	jz		SHORT .ReturnSlowestTimingInBXandCX	; No Slave Drive

	; If Active Time is greater, then must be the Recovery Time as well
	cmp		bx, [di+BOOTMENUINFO.wMinPioActiveTimeNs]
	jbe		SHORT .ReturnSlowestTimingInBXandCX
	mov		bx, [di+BOOTMENUINFO.wMinPioActiveTimeNs]
	mov		cx, [di+BOOTMENUINFO.wMinPioRecoveryTimeNs]
.ReturnSlowestTimingInBXandCX:
	ret
