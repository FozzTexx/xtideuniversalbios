; Project name	:	XTIDE Universal BIOS
; Description	:	Common functions for initializing different
;					VLB and PCI IDE Controllers.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; AdvAtaInit_DetectControllerForIdeBaseInBX
;	Parameters:
;		BX:		IDE Controller base port
;	Returns:
;		AX:		ID WORD specific for detected controller
;				Zero if no controller detected
;		DX:		Controller base port (not IDE)
;		CF:		Set if controller detected
;				Cleared if no controller
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
AdvAtaInit_DetectControllerForIdeBaseInBX:
	call	Vision_DetectAndReturnIDinAXandPortInDXifControllerPresent
	jne		SHORT .NoAdvancedControllerForPortBX
	call	Vision_DoesIdePortInBXbelongToControllerWithIDinAX
	jne		SHORT .NoAdvancedControllerForPortBX

	stc		; Advanced Controller found for port BX
	ret

.NoAdvancedControllerForPortBX:
	xor		ax, ax
	ret


;--------------------------------------------------------------------
; AdvAtaInit_GetControllerMaxPioModeToAL
;	Parameters:
;		AX:		ID WORD specific for detected controller
;	Returns:
;		AL:		Max supported PIO mode
;		AH:		FLGH_DPT_IORDY if IORDY supported, zero otherwise
;		CF:		Set if PIO limit necessary
;				Cleared if no need to limit timings
;	Corrupts registers:
;		(AX if CF cleared)
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
	push	bp
	push	si

	; Call Controller Specific initialization function
	mov		ax, [di+DPT_ADVANCED_ATA.wControllerID]
	test	ax, ax
	jz		SHORT .NoAdvancedController	; Return with CF cleared

	; We only support Vision at the moment so no need to identify ID
	call	AdvAtaInit_LoadMasterDPTtoDSSIifSlaveInDSDI
	call	Vision_InitializeWithIDinAHandConfigInAL

.NoAdvancedController:
	pop		si
	pop		bp
	ret


;--------------------------------------------------------------------
; AdvAtaInit_LoadMasterDPTtoDSSIifSlaveInDSDI
;	Parameters:
;		DS:DI:	Ptr to DPT for Single or Slave Drive
;	Returns:
;		DS:DI:	Ptr to DPT for Single or Slave Drive
;		SI:		Offset to Master DPT if Slave Drive present
;				Zero if Slave Drive not present
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
AdvAtaInit_LoadMasterDPTtoDSSIifSlaveInDSDI:
	; Must be Slave Drive if previous DPT has same IDEVARS offset
	lea		si, [di-LARGEST_DPT_SIZE]	; DS:SI points to previous DPT
	mov		al, [di+DPT.bIdevarsOffset]
	cmp		al, [si+DPT.bIdevarsOffset]
	je		SHORT .MasterAndSlaveDrivePresent

	; We only have single drive so zero SI
	xor		si, si
.MasterAndSlaveDrivePresent:
	ret


;--------------------------------------------------------------------
; AdvAtaInit_SelectSlowestCommonPioTimingsToBXandCXfromDSSIandDSDI
;	Parameters:
;		DS:DI:	Ptr to DPT for Single or Slave Drive
;		SI:		Offset to Master DPT if Slave Drive present
;				Zero if Slave Drive not present
;	Returns:
;		BX:		Best common PIO mode
;		CX:		Slowest common PIO Cycle Time in nanosecs
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
AdvAtaInit_SelectSlowestCommonPioTimingsToBXandCXfromDSSIandDSDI:
	eMOVZX	bx, [di+DPT_ADVANCED_ATA.bPioMode]
	mov		cx, [di+DPT_ADVANCED_ATA.wMinPioCycleTime]
	test	si, si
	jz		SHORT .PioTimingsLoadedToAXandCX
	MIN_U	bl, [si+DPT_ADVANCED_ATA.bPioMode]
	MAX_U	cx, [si+DPT_ADVANCED_ATA.wMinPioCycleTime]
.PioTimingsLoadedToAXandCX:
	ret
