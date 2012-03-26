; Project name	:	XTIDE Universal BIOS
; Description	:	Functions for initializing QDI Vision
;					QD6500 and QD6580 VLB IDE Controllers.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Vision_DetectAndReturnIDinAXandPortInCXifControllerPresent
;	Parameters:
;		Nothing
;	Returns:
;		AX:		ID WORD specific for QDI Vision Controllers
;				(AL = QD65xx Config Register contents)
;				(AH = QDI Vision Controller ID (bits 4...7))
;		CX:		Controller port (not IDE port)
;		ZF:		Set if controller found
;				Cleared if supported controller not found (AX,DX = undefined)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
Vision_DetectAndReturnIDinAXandPortInCXifControllerPresent:
	; Check QD65xx base port
	mov		cx, QD65XX_BASE_PORT
	in		al, QD65XX_BASE_PORT + QD65XX_CONFIG_REGISTER_in
	call	IsConfigRegisterWithIDinAL
	je		SHORT VisionControllerDetected

	; Check QD65xx alternative base port
	or		cl, QD65XX_ALTERNATIVE_BASE_PORT
	in		al, QD65XX_ALTERNATIVE_BASE_PORT + QD65XX_CONFIG_REGISTER_in
	; Fall to IsConfigRegisterWithIDinAL

;--------------------------------------------------------------------
; IsConfigRegisterWithIDinAL
;	Parameters:
;		AL:		Possible QD65xx Config Register contents
;	Returns:
;		AH		QDI Vision Controller ID or undefined
;		ZF:		Set if controller found
;				Cleared if supported controller not found (AH = undefined)
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
IsConfigRegisterWithIDinAL:
	mov		ah, al
	and		ah, MASK_QDCONFIG_CONTROLLER_ID
	cmp		ah, ID_QD6500 << 4
	je		SHORT VisionControllerDetected
	cmp		ah, ID_QD6580 << 4
	je		SHORT VisionControllerDetected
	cmp		ah, ID_QD6580_ALTERNATE << 4
VisionControllerDetected:
	ret


;--------------------------------------------------------------------
; Vision_DoesIdePortInDXbelongToControllerWithIDinAX
;	Parameters:
;		AX:		ID WORD specific for QDI Vision Controllers
;				(AL = QD65xx Config Register contents)
;				(AH = QDI Vision Controller ID (bits 4...7))
;		CX:		Vision Controller port
;		DX:		IDE base port to check
;	Returns:
;		ZF:		Set if port belongs to controller
;				Cleared if port belongs to another controller
;	Corrupts registers:
;		BX
;--------------------------------------------------------------------
Vision_DoesIdePortInDXbelongToControllerWithIDinAX:
	cmp		ah, ID_QD6500 << 4
	je		SHORT .DoesIdePortInDXbelongToQD6500

	; QD6580 always have Primary IDE at 1F0h
	; Secondary IDE at 170h can be enabled or disabled
	cmp		dx, DEVICE_ATA_DEFAULT_PORT
	je		SHORT .ReturnResultInZF

	; Check if Secondary IDE channel is enabled
	xchg	bx, ax		; Backup AX
	xchg	dx, cx		; Swap ports

	add		dx, BYTE QD6580_CONTROL_REGISTER
	in		al, dx
	sub		dx, BYTE QD6580_CONTROL_REGISTER

	xchg	cx, dx
	xchg	ax, bx		; Restore AX, Control Register to BL
	test	bl, FLG_QDCONTROL_SECONDARY_DISABLED_in
	jz		SHORT .CompareDXtoSecondaryIDE
	ret

	; QD6500 has only one IDE channel that can be at 1F0h or 170h
.DoesIdePortInDXbelongToQD6500:
	test	al, FLG_QDCONFIG_PRIMARY_IDE
	jz		SHORT .CompareDXtoSecondaryIDE
	cmp		dx, DEVICE_ATA_DEFAULT_PORT
	ret

.CompareDXtoSecondaryIDE:
	cmp		dx, DEVICE_ATA_DEFAULT_SECONDARY_PORT
.ReturnResultInZF:
	ret


;--------------------------------------------------------------------
; Vision_GetMaxPioModeToAL
;	Parameters:
;		AX:		ID WORD specific for QDI Vision Controllers
;				(AH = QDI Vision Controller ID (bits 4...7))
;	Returns:
;		AL:		Max supported PIO mode (if CF set)
;		CF:		Set if PIO limit necessary
;				Cleared if no need to limit timings
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
Vision_GetMaxPioModeToAL:
	cmp		ah, ID_QD6500 << 4
	clc
	jne		SHORT .NoNeedToLimitForQD6580

	mov		al, 2	; Limit to PIO 2 because QD6500 supports PIO 3 but without IORDY
	stc
.NoNeedToLimitForQD6580:
	ret


;--------------------------------------------------------------------
; Vision_InitializeWithIDinAHandConfigInAL
;	Parameters:
;		AX:		ID WORD specific for QDI Vision Controllers
;				(AL = QD65xx Config Register contents)
;				(AH = QDI Vision Controller ID (bits 4...7))
;		DS:SI:	Ptr to BOOTMENUINFO for Single or Master Drive
;		DS:DI:	Ptr to BOOTMENUINFO for Slave Drive
;				Zero if Slave not present
;	Returns:
;		CF:		Cleared if success
;				Set if error
;	Corrupts registers:
;		AX, BX, CX, DX, SI, DI
;--------------------------------------------------------------------
Vision_InitializeWithIDinAHandConfigInAL:
	; QD6580 has a Control Register that needs to be programmed
	mov		dx, [si+BOOTMENUINFO.wControllerBasePort]
	cmp		ah, ID_QD6500 << 4
	je		SHORT .GetPioTimingsInNanosecs

	; Program QD6580 Control Register (not available on QD6500) to
	; Enable or Disable Read-Ahead and Post-Write Buffer to match
	; jumper setting on the multi I/O card.
.ProgramControlRegisterForQD6580:
	xchg	bx, ax									; Backup AX
	add		dx, BYTE QD6580_CONTROL_REGISTER
	in		al, dx									; Read to get ATAPI jumper status
	test	al, FLG_QDCONTROL_HDONLY_in
	mov		al, MASK_QDCONTROL_FLAGS_TO_SET
	jz		SHORT .SkipHdonlyBitSinceAtapiPossible
	or		al, FLG_QDCONTROL_NONATAPI
.SkipHdonlyBitSinceAtapiPossible:
	out		dx, al
	sub		dx, BYTE QD6580_CONTROL_REGISTER		; Back to base port
	xchg	ax, bx									; Restore AX

	; If we have Master and Slave drive in the system, we must select
	; timings from the slower drive (this is why it is a bad idea to use
	; fast and slow drive on the same IDE channel)
.GetPioTimingsInNanosecs:
	call	AdvAtaInit_SelectSlowestTimingsToBXandCX

	; Now we need to determine is the drive connected to the Primary or Secondary channel.
	; QD6500 has only one channel that can be Primary at 1F0h or Secondary at 170h.
	; QD6580 always has Primary channel at 1F0h. Secondary channel at 170h can be Enabled or Disabled.
	cmp		ah, ID_QD6500 << 4
	je		SHORT .CalculateTimingTicksForQD6500
	cmp		WORD [si+BOOTMENUINFO.wIdeBasePort], DEVICE_ATA_DEFAULT_PORT
	je		SHORT .CalculateTimingTicksForQD6580
	times 2 inc dx									; Secondary Channel IDE Timing Register

	; Now we must translate the PIO timing nanosecs in CX and DX to VLB ticks
	; suitable for QD65xx IDE Timing Register.
	; Both of the controllers require slightly different calculations.
.CalculateTimingTicksForQD6580:
	mov		si, QD6580_MIN_ACTIVE_TIME_CLOCKS
	mov		di, QD6580_MAX_ACTIVE_TIME_CLOCKS
	jmp		SHORT .CalculateTimingForQD65xx

.CalculateTimingTicksForQD6500:
	mov		si, QD6500_MIN_ACTIVE_TIME_CLOCKS
	mov		di, QD6500_MAX_ACTIVE_TIME_CLOCKS

.CalculateTimingForQD65xx:
	test	al, FLG_QDCONFIG_ID3		; Set ZF if 40 MHz VLB bus
	mov		al, VLB_33MHZ_CYCLE_TIME	; Assume 33 MHz or slower VLB bus
	xchg	ax, bx						; Active Time to AX
	eCMOVZ	bl, VLB_40MHZ_CYCLE_TIME

	div		bl
	inc		ax							; Round up
	xor		ah, ah
	xchg	cx, ax						; CX = Active Time in VLB ticks
	MAX_U	cx, si						; Limit ticks to valid values...
	MIN_U	cx, di						; ...for QD65xx

	div		bl
	inc		ax							; Round up
	xchg	bx, ax						; BL = Recovery Time in VLB ticks
	mov		al, QD65xx_MAX_RECOVERY_TIME_CLOCKS
	MAX_U	bl, QD65xx_MIN_RECOVERY_TIME_CLOCKS
	MIN_U	bl, al

	; Not done yet, we need to invert the ticks since 0 is the slowest
	; value on the timing register
	sub		di, cx						; DI = Active Time value to program
	sub		al, bl						; AL = Recovery Time value to program

	; Finally we can shift the values in places and program the Timing Register
	eSHIFT_IM	al, POSITON_QD65XXIDE_RECOVERY_TIME, shl
	or		ax, di
	out		dx, al
	ret									; Return with CF cleared
