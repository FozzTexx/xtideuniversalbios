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
; IdeAutodetect_DetectIdeDeviceFromPortDXAndReturnControlBlockInCX
;	Parameters:
;		DX:		IDE Base Port
;		DS:DI:	Ptr to ROMVARS
;	Returns:
;		AL:		Device Type
;		CX:		Control Block Base port (detected since there is no
;				standard address for Tetriary and Quaternary IDE controllers)
;		CF:		Clear if IDE Device found
;				Set if IDE Device not found
;	Corrupts registers:
;		AH, BX
;--------------------------------------------------------------------
IdeAutodetect_DetectIdeDeviceFromPortDXAndReturnControlBlockInCX:
	cmp		dx, FIRST_MEMORY_SEGMENT_ADDRESS
	jb		SHORT .DetectPortMappedDevices

	; *** Try to detect JR-IDE/ISA (only if MODULE_8BIT_IDE_ADVANCED is present) ***
	test	WORD [di+ROMVARS.wFlags], FLG_ROMVARS_MODULE_8BIT_IDE_ADVANCED
	jz		SHORT .SkipRestOfDetection

	push	ds
	mov		ds, dx
	cli									; Disable Interrupts
	mov		ah, [JRIDE_COMMAND_BLOCK_REGISTER_WINDOW_OFFSET + STATUS_REGISTER_in]
	mov		al, [JRIDE_CONTROL_BLOCK_REGISTER_WINDOW_OFFSET + ALTERNATE_STATUS_REGISTER_in]
	sti									; Enable Interrupts
	pop		ds
	call	CompareIdeStatusRegistersFromALandAH
	mov		al, DEVICE_8BIT_JRIDE_ISA	; Assume CF was cleared
	ret									; No need to return Control Block Port
.DetectPortMappedDevices:


	; *** Try to detect Standard 16- and 32-bit IDE Devices ***
	mov		bh, DEVICE_16BIT_ATA		; Assume 16-bit ISA slot for AT builds
	call	Buffers_IsXTbuildLoaded
	eCMOVE	bh, DEVICE_8BIT_ATA			; Assume 8-bit ISA slot for XT builds

	mov		bl, STATUS_REGISTER_in
	mov		cx, STANDARD_CONTROL_BLOCK_OFFSET + ALTERNATE_STATUS_REGISTER_in
.RedetectTertiaryOrQuaternaryWithDifferentAlternativeStatusRegisterPort:
	call	DetectIdeDeviceFromPortDXwithStatusRegOffsetsInBLandCX
	mov		al, bh
	jnc		SHORT .IdeDeviceFound

	; 16- or 32-bit IDE Device was not found but we may have used wrong Control Block port if we were trying
	; to detect Tertiary or Quaternary IDE controllers. Control Block port location is not standardized. For
	; example Promise FloppyMAX has Control Block at STANDARD_CONTROL_BLOCK_OFFSET but Sound Blaster 16 (CT2290)
	; use DEVICE_ATA_SECONDARY_PORTCTRL for Tertiary and Quaternary even though only Secondary should use that.
	cmp		cx, STANDARD_CONTROL_BLOCK_OFFSET + ALTERNATE_STATUS_REGISTER_in
	jne		SHORT .AlreadyTriedAlternativeControlBlock
	mov		cx, DEVICE_ATA_SECONDARY_PORTCTRL + ALTERNATE_STATUS_REGISTER_in
	sub		cx, dx						; Offset to add to DX
	cmp		dx, DEVICE_ATA_TERTIARY_PORT
	je		SHORT .RedetectTertiaryOrQuaternaryWithDifferentAlternativeStatusRegisterPort
	cmp		dx, DEVICE_ATA_QUATERNARY_PORT
	je		SHORT .RedetectTertiaryOrQuaternaryWithDifferentAlternativeStatusRegisterPort
.AlreadyTriedAlternativeControlBlock:


	; Detect 8-bit devices only if MODULE_8BIT_IDE is available
	test	BYTE [di+ROMVARS.wFlags], FLG_ROMVARS_MODULE_8BIT_IDE
	jz		SHORT .SkipRestOfDetection

	; *** Try to detect XT-CF ***
	mov		bl, STATUS_REGISTER_in << 1
	mov		cx, (XTIDE_CONTROL_BLOCK_OFFSET + ALTERNATE_STATUS_REGISTER_in) << 1
	call	DetectIdeDeviceFromPortDXwithStatusRegOffsetsInBLandCX
	rcl		ax, 1						; Store CF
	shr		cx, 1						; XTIDE_CONTROL_BLOCK_OFFSET + ALTERNATE_STATUS_REGISTER_in
	rcr		ax, 1						; Restore CF
	mov		al, DEVICE_8BIT_XTCF_PIO8
	jnc		SHORT .IdeDeviceFound


	; *** Try to detect 8-bit XT-IDE rev 1 or rev 2 ***
	; Note that A0<->A3 address swaps Status Register and Alternative
	; Status Register addresses. That is why we need another step
	; to check is this XT-IDE rev 1 or rev 2.
	call	DetectIdeDeviceFromPortDXwithStatusRegOffsetsInBLandCX
	jc		SHORT .SkipRestOfDetection	; No XT-IDE rev 1 or rev 2 found

	; Now we can be sure that we have XT-IDE rev 1 or rev 2.
	; Rev 2 swaps address lines A0 and A3 thus LBA Low Register
	; moves from offset 3h to offset Ah. There is no Register at
	; offset Ah so if we can write to it and read back, then we
	; must have XT-IDE rev 2 or modded rev 1.
	push	dx
	add		dx, BYTE 0Ah				; LBA Low Register for XT-IDE rev 2
	mov		al, DEVICE_8BIT_XTIDE_REV2	; Our test byte
	out		dx, al						; Output our test byte
	JMP_DELAY
	in		al, dx						; Read back
	pop		dx
	cmp		al, DEVICE_8BIT_XTIDE_REV2
	je		SHORT .IdeDeviceFound
	mov		al, DEVICE_8BIT_XTIDE_REV1	; We must have rev 1
.IdeDeviceFound:
	sub		cl, ALTERNATE_STATUS_REGISTER_in	; Clear CF
	add		cx, dx								; CX = Control Block address
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
	; example. We must make sure bits are what is expected from valid
	; IDE Status Register. So far all drives I've tested return 50h
	; (FLG_STATUS_DRDY and FLG_STATUS_DSC set) but I don't want to assume
	; just yet that all drives report 50h.
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
	; Standard IDE
	dw		DEVICE_ATA_PRIMARY_PORT
	dw		DEVICE_ATA_SECONDARY_PORT
	dw		DEVICE_ATA_TERTIARY_PORT
	dw		DEVICE_ATA_QUATERNARY_PORT
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
	; JR-IDE/ISA (Memory Segment Addresses)
	dw		0C000h
	dw		0C400h
	dw		0C800h
	dw		0CC00h
	dw		0D000h
	dw		0D400h
	dw		0D800h
.wLastIdePort:
	dw		0DC00h
