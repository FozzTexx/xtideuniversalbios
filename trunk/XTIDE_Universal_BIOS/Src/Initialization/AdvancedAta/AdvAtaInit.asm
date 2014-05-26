; Project name	:	XTIDE Universal BIOS
; Description	:	Common functions for initializing different
;					VLB and PCI IDE Controllers.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;

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
; AdvAtaInit_GetControllerMaxPioModeToALandMinPioCycleTimeToBX
;	Parameters:
;		AX:		ID WORD specific for detected controller
;	Returns:
;		AL:		Max supported PIO mode
;		AH:		FLGH_DPT_IORDY if IORDY supported, zero otherwise
;		BX:		Min PIO cycle time (only if CF set)
;		CF:		Set if PIO limit necessary
;				Cleared if no need to limit timings
;	Corrupts registers:
;		(AX if CF cleared)
;--------------------------------------------------------------------
AdvAtaInit_GetControllerMaxPioModeToALandMinPioCycleTimeToBX	equ	Vision_GetMaxPioModeToALandMinCycleTimeToBX


;--------------------------------------------------------------------
; AdvAtaInit_InitializeControllerForDPTinDSDI
;	Parameters:
;		DS:DI:	Ptr to DPT for Single or Slave Drive
;	Returns:
;		AH:		Int 13h return status
;		CF:		Cleared if success or no controller to initialize
;				Set if error
;	Corrupts registers:
;		AL, BX, CX, DX
;--------------------------------------------------------------------
AdvAtaInit_InitializeControllerForDPTinDSDI:
	; Call Controller Specific initialization function
	mov		ax, [di+DPT_ADVANCED_ATA.wControllerID]
	test	ax, ax
	jz		SHORT .NoAdvancedController	; Return with CF cleared

	push	bp
	push	si

	; We only support Vision at the moment so no need to identify ID
	call	AdvAtaInit_LoadMasterDPTtoDSSIifSlaveInDSDI
	call	Vision_InitializeWithIDinAHandConfigInAL
	xor		ax, ax						; Success

	pop		si
	pop		bp

.NoAdvancedController:
	ret


;--------------------------------------------------------------------
; AdvAtaInit_LoadMasterDPTtoDSSIifSlaveInDSDI
;	Parameters:
;		DS:DI:	Ptr to DPT for Single or Slave Drive
;	Returns:
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
