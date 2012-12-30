; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	Functions to detect ports and devices.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team.
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
; IdeAutodetect_DetectIdeDeviceFromPortDX
;	Parameters:
;		DX:		IDE Base Port
;		DS:DI:	Ptr to ROMVARS
;	Returns:
;		AL:		Device Type
;		CF:		Clear if IDE Device found
;				Set if IDE Device not found
;	Corrupts registers:
;		AH, BX, CX
;--------------------------------------------------------------------
IdeAutodetect_DetectIdeDeviceFromPortDX:
	cmp		dx, FIRST_MEMORY_SEGMENT_ADDRESS
	jb		SHORT .DetectPortMappedDevices

	; Try to detect JR-IDE/ISA (only if MODULE_8BIT_IDE_ADVANCED is present)
	test	WORD [di+ROMVARS.wFlags], FLG_ROMVARS_MODULE_8BIT_IDE_ADVANCED
	jz		SHORT .SkipRestOfDetection

	push	ds
	mov		ds, dx
	cli							; Disable Interrupts
	mov		ah, [JRIDE_COMMAND_BLOCK_REGISTER_WINDOW_OFFSET + STATUS_REGISTER_in]
	mov		al, [JRIDE_CONTROL_BLOCK_REGISTER_WINDOW_OFFSET + ALTERNATE_STATUS_REGISTER_in]
	sti							; Enable Interrupts
	pop		ds
	call	CompareIdeStatusRegistersFromALandAH
	mov		al, DEVICE_8BIT_JRIDE_ISA
	ret
.DetectPortMappedDevices:


	; Try to detect Standard 16- and 32-bit IDE Devices
	mov		bh, DEVICE_16BIT_ATA		; Assume 16-bit ISA slot for AT builds
	call	Buffers_IsXTbuildLoaded
	eCMOVE	bh, DEVICE_8BIT_ATA			; Assume 8-bit ISA slot for XT builds
	mov		bl, STATUS_REGISTER_in
	mov		cx, STANDARD_CONTROL_BLOCK_OFFSET + ALTERNATE_STATUS_REGISTER_in
	call	DetectIdeDeviceFromPortDXwithStatusRegOffsetsInBLandCX
	mov		al, bh
	jnc		SHORT .IdeDeviceFound


	; Detect 8-bit devices only if MODULE_8BIT_IDE is available
	test	BYTE [di+ROMVARS.wFlags], FLG_ROMVARS_MODULE_8BIT_IDE
	jz		SHORT .SkipRestOfDetection

	; Try to detect XT-CF
	mov		bl, STATUS_REGISTER_in << 1
	mov		cx, (XTIDE_CONTROL_BLOCK_OFFSET + ALTERNATE_STATUS_REGISTER_in) << 1
	call	DetectIdeDeviceFromPortDXwithStatusRegOffsetsInBLandCX
	mov		al, DEVICE_8BIT_XTCF_PIO8
	jnc		SHORT .IdeDeviceFound

	; Try to detect 8-bit XT-IDE rev 1
	shr		cx, 1
	call	DetectIdeDeviceFromPortDXwithStatusRegOffsetsInBLandCX
	mov		al, DEVICE_8BIT_XTIDE_REV1
	jnc		SHORT .IdeDeviceFound

	; Try to detect 8-bit XT-IDE rev 2 or modded rev 1
	; This doesn't actually work since Status Register and Alternative
	; Status Register swap place!!!
	mov		bl, 1110b	; STATUS_REGISTER_in with A0 and A3 swapped
	mov		cl, 0111b
	call	DetectIdeDeviceFromPortDXwithStatusRegOffsetsInBLandCX
	mov		al, DEVICE_8BIT_XTIDE_REV2
.IdeDeviceFound:
	ret
.SkipRestOfDetection:
	stc
	ret


;--------------------------------------------------------------------
; DetectIdeDeviceFromPortDXwithStatusRegOffsetsInBLandCX
;	Parameters:
;		BL:		Offset to IDE Status Register
;		CX:		Offset to Alternative Status Register
;		DX:		IDE Base Port
;	Returns:
;		CF:		Clear if IDE Device found
;				Set if IDE Device not found
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
DetectIdeDeviceFromPortDXwithStatusRegOffsetsInBLandCX:
	; Read Status and Alternative Status Registers
	push	cx
	push	dx

	add		cx, dx				; CX = Address to Alternative Status Register
	add		dl, bl				; DX = Address to Status Register
	cli							; Disable Interrupts
	in		al, dx				; Read Status Register
	mov		ah, al
	mov		dx, cx
	in		al, dx				; Read Alternative Status Register
	sti							; Enable Interrupts

	pop		dx
	pop		cx
	; Fall to CompareIdeStatusRegistersFromALandAH


;--------------------------------------------------------------------
; CompareIdeStatusRegistersFromALandAH
;	Parameters:
;		AL:		Possible IDE Status Register contents
;		AH:		Possible IDE Alternative Status Register contents
;	Returns:
;		CF:		Clear if valid Status Register Contents
;				Set if not possible IDE Status Registers
;	Corrupts registers:
;		Nothing
;--------------------------------------------------------------------
CompareIdeStatusRegistersFromALandAH:
	; Status Register now in AH and Alternative Status Register in AL.
	; They must be the same if base port was in use by IDE device.
	cmp		al, ah
	jne		SHORT .InvalidStatusRegister

	; Bytes were the same but it is possible they were both FFh, for 
	; example. We must make sure bit are what is expected from valid
	; IDE Status Register.
	test	al, FLG_STATUS_BSY | FLG_STATUS_DF | FLG_STATUS_DRQ | FLG_STATUS_ERR
	jnz		SHORT .InvalidStatusRegister	; Busy or Errors cannot be set
	test	al, FLG_STATUS_DRDY
	jz		SHORT .InvalidStatusRegister	; Device needs to be ready
	ret										; Return with CF cleared

.InvalidStatusRegister:
AllPortsAlreadyDetected:
	stc
	ret


;--------------------------------------------------------------------
; IdeAutodetect_IncrementDXtoNextIdeBasePort
;	Parameters:
;		DX:		Previous IDE Base Port
;	Returns:
;		DX:		Next IDE Base Port
;		ZF:		Set if no more Base Ports (DX was last base port on entry)
;				Clear if new base port returned in DX
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
IdeAutodetect_IncrementDXtoNextIdeBasePort:
	cmp		dx, [cs:.wLastIdePort]
	je		SHORT .AllPortsAlreadyDetected

	push	si
	mov		si, .rgwIdeBasePorts
.CompareNextIdeBasePort:
	cmp		[cs:si], dx
	lea		si, [si+2]	; Increment SI and preserve FLAGS
	jne		SHORT .CompareNextIdeBasePort

	mov		dx, [cs:si]			; Get next port
	test	dx, dx				; Clear ZF
	pop		si
.AllPortsAlreadyDetected:
	ret


	; All ports used in autodetection. Ports can be in any order.
ALIGN WORD_ALIGN
.rgwIdeBasePorts:
	dw		IDE_PORT_TO_START_DETECTION		; Must be first
	; JR-IDE/ISA (Memory Segment Addresses)
	dw		0C000h
	dw		0C400h
	dw		0C800h
	dw		0CC00h
	dw		0D000h
	dw		0D400h
	dw		0D800h
	dw		0DC00h
	; 8-bit Devices
	dw		200h
	dw		220h
	dw		240h
	dw		260h
	dw		280h
	dw		2A0h
	dw		2C0h
	dw		2E0h
	dw		300h
	dw		320h
	dw		340h
	dw		360h
	dw		380h
	dw		3A0h
	dw		3C0h
	dw		3E0h
	; Standard IDE
	dw		DEVICE_ATA_PRIMARY_PORT
	dw		DEVICE_ATA_SECONDARY_PORT
	dw		DEVICE_ATA_TERTIARY_PORT
.wLastIdePort:
	dw		DEVICE_ATA_QUATERNARY_PORT
