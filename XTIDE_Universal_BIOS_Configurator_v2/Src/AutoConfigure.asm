; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	Functions to automatically configure XTIDE
;					Universal BIOS for current system.

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
; AutoConfigure_ForThisSystem
; MENUITEM activation function (.fnActivate)
;	Parameters:
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		All, except segments
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AutoConfigure_ForThisSystem:
	push	es
	push	ds

	call	Buffers_GetFileBufferToESDI		; ROMVARS now in ES:DI
	push	es
	pop		ds								; ROMVARS now in DS:DI
	call	ResetIdevarsToDefaultValues
	call	DetectIdePortsAndDevices
	call	EnableInterruptsForPrimaryAndSecondaryControllers
	call	StoreAndDisplayNumberOfControllers

	pop		ds
	pop		es
	ret


;--------------------------------------------------------------------
; ResetIdevarsToDefaultValues
;	Parameters:
;		DS:DI:	Ptr to ROMVARS
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, CX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
ResetIdevarsToDefaultValues:
	push	di
	add		di, BYTE ROMVARS.ideVarsBegin
	mov		cx, ROMVARS.ideVarsEnd - ROMVARS.ideVarsBegin
	call	Memory_ZeroESDIwithSizeInCX	; Never clears ROMVARS.ideVarsSerialAuto
	pop		di

	; Set default values (other than zero)
	mov		ax, DISABLE_WRITE_CACHE | (TRANSLATEMODE_AUTO<<TRANSLATEMODE_FIELD_POSITION) | FLG_DRVPARAMS_BLOCKMODE
	mov		[di+ROMVARS.ideVars0+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags], ax
	mov		[di+ROMVARS.ideVars0+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags], ax

	mov		[di+ROMVARS.ideVars1+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags], ax
	mov		[di+ROMVARS.ideVars1+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags], ax

	mov		[di+ROMVARS.ideVars2+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags], ax
	mov		[di+ROMVARS.ideVars2+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags], ax

	mov		[di+ROMVARS.ideVars3+IDEVARS.drvParamsMaster+DRVPARAMS.wFlags], ax
	mov		[di+ROMVARS.ideVars3+IDEVARS.drvParamsSlave+DRVPARAMS.wFlags], ax
	ret


;--------------------------------------------------------------------
; DetectIdePortsAndDevices
;	Parameters:
;		DS:DI:	Ptr to ROMVARS
;	Returns:
;		CX:		Number of controllers detected
;	Corrupts registers:
;		AX, BX, DX, SI
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
DetectIdePortsAndDevices:
	xor		cx, cx							; Number of devices found
	xor		dx, dx							; IDE_PORT_TO_START_DETECTION
	lea		si, [di+ROMVARS.ideVarsBegin]	; DS:SI points to first IDEVARS

.DetectFromNextPort:
	call	IdeAutodetect_IncrementDXtoNextIdeBasePort
	jz		SHORT .AllPortsAlreadyDetected
	push	si
	call	IdeAutodetect_DetectIdeDeviceFromPortDXAndReturnControlBlockInSI
	mov		bx, si
	pop		si
	jc		SHORT .DetectFromNextPort

	; Device found from port DX, Device Type returned in AL
	inc		cx	; Increment number of controllers found
	mov		[si+IDEVARS.wBasePort], dx
	mov		[si+IDEVARS.wControlBlockPort], bx
	mov		[si+IDEVARS.bDevice], al

	; Point to next IDEVARS
	add		si, IDEVARS_size
	cmp		si, ROMVARS.ideVars3
	jbe		SHORT .DetectFromNextPort
.AllPortsAlreadyDetected:
	ret


;--------------------------------------------------------------------
; EnableInterruptsForPrimaryAndSecondaryControllers
;	Parameters:
;		DS:DI:	Ptr to ROMVARS
;		CX:		Number of controllers detected
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
EnableInterruptsForPrimaryAndSecondaryControllers:
	jcxz	.NoControllersDetected
	call	Buffers_IsXTbuildLoaded
	je		SHORT .DoNotEnableIRQforXTbuilds
	push	di
	push	cx

	add		di, BYTE ROMVARS.ideVars0	; DS:DI now points first IDEVARS
.CheckNextController:
	mov		al, 14
	cmp		WORD [di+IDEVARS.wBasePort], DEVICE_ATA_PRIMARY_PORT
	je		SHORT .EnableIrqAL

	inc		ax	; 15
	cmp		WORD [di+IDEVARS.wBasePort], DEVICE_ATA_SECONDARY_PORT
	jne		SHORT .DoNotEnableIRQ

.EnableIrqAL:
	mov		[di+IDEVARS.bIRQ], al
.DoNotEnableIRQ:
	loop	.CheckNextController
	pop		cx
	pop		di
.DoNotEnableIRQforXTbuilds:
.NoControllersDetected:
	ret


;--------------------------------------------------------------------
; StoreAndDisplayNumberOfControllers
;	Parameters:
;		CX:		Number of controllers detected
;		DS:DI:	Ptr to ROMVARS
;		SS:BP:	Ptr to MENU
;	Returns:
;		Nothing
;	Corrupts registers:
;		AX, BX, DX, DI, SI, DS, ES
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
StoreAndDisplayNumberOfControllers:
	xor		ax, ax
	or		al, cl
	jnz		SHORT .AtLeastOneController
	inc		ax							; Cannot store zero
.AtLeastOneController:
	test	BYTE [di+ROMVARS.wFlags], FLG_ROMVARS_FULLMODE
	jnz		SHORT .FullModeSoNoNeedToLimit
	MIN_U	al, MAX_LITE_MODE_CONTROLLERS
.FullModeSoNoNeedToLimit:

	; Store number of IDE Controllers. This will also modify
	; menu and set unsaved changes flag.
	push	cs
	pop		ds
	mov		si, g_MenuitemConfigurationIdeControllers
	call	Menuitem_StoreValueFromAXtoMenuitemInDSSI

	; Display results (should be changed to proper string formatting)
	add		cl, '0'
	mov		[cs:g_bControllersDetected], cl
	mov		dx, g_szDlgAutoConfigure
	jmp		Dialogs_DisplayNotificationFromCSDX
