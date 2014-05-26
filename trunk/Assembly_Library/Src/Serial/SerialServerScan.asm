; Project name	:	Assembly Library
; Description	:	Serial Server Support, Scan for Server
;
; This functionality is broken out from SerialServer as it may only be needed during
; initialization to find a server, and then could be discarded, (for example the case
; of a TSR).

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


%include "SerialServer.inc"

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; SerialServerScan_ScanForServer:
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Select Register
;				0xAx: Scan for drive, low nibble indicates drive
;				0x0:  Scan for Server, independent of drives
;		DX:		Port and Baud to Scan for
;				0: Scan a known set of ports and bauds
;		ES:SI:	Ptr to buffer for return
;	Returns:
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX, CX, DX, DI
;--------------------------------------------------------------------
SerialServerScan_ScanForServer:
		mov		cx, 1			; one sector, not scanning (default)

		test	dx, dx
		jnz		short SerialServerScan_CheckForServer_PortAndBaudInDX

		mov		di,.scanPortAddresses-1
		mov		ch,1			;  tell server that we are scanning

.nextPort:
		inc		di				; load next port address
		xor		dh, dh
		mov		dl,[cs:di]
		eSHL_IM	dx, 2			; shift from one byte to two
		stc						; setup error code for exit
		jz		.error

;
; Test for COM port presence, write to and read from registers
;
		push	dx
		add		dl,Serial_UART_lineControl
		mov		al, 09ah
		out		dx, al
		in		al, dx
		pop		dx
		cmp		al, 09ah
		jnz		.nextPort

		mov		al, 0ch
		out		dx, al
		in		al, dx
		cmp		al, 0ch
		jnz		.nextPort

;
; Begin baud rate scan on this port...
;
; On a scan, we support 6 baud rates, starting here and going higher by a factor of two each step, with a
; small jump between 9600 and 38800.  These 6 were selected since we wanted to support 9600 baud and 115200,
; *on the server side* if the client side had a 4x clock multiplier, a 2x clock multiplier, or no clock multiplier.
;
; Starting with 30h, that means 30h (2400 baud), 18h (4800 baud), 0ch (9600 baud), and
;					            04h (28800 baud), 02h (57600 baud), 01h (115200 baud)
;
; Note: hardware baud multipliers (2x, 4x) will impact the final baud rate and are not known at this level
;
		mov		dh,030h * 2		; multiply by 2 since we are about to divide by 2
		mov		dl,[cs:di]		; restore single byte port address for scan

.nextBaud:
		shr		dh,1
		jz		.nextPort
		cmp		dh,6			; skip from 6 to 4, to move from the top of the 9600 baud range
		jnz		.testBaud		; to the bottom of the 115200 baud range
		mov		dh,4

.testBaud:
		call	SerialServerScan_CheckForServer_PortAndBaudInDX
		jc		.nextBaud

.error:
		ret

.scanPortAddresses: db	SERIAL_COM7_IOADDRESS >> 2
					db	SERIAL_COM6_IOADDRESS >> 2
					db	SERIAL_COM5_IOADDRESS >> 2
					db	SERIAL_COM4_IOADDRESS >> 2
					db	SERIAL_COM3_IOADDRESS >> 2
					db	SERIAL_COM2_IOADDRESS >> 2
					db	SERIAL_COM1_IOADDRESS >> 2
					db	0


;--------------------------------------------------------------------
; SerialServer_CheckForServer_PortAndBaudInDX:
;	Parameters:
;		BH:		Drive Select byte for Drive and Head Select Register
;				0xAx: Scan for drive, low nibble indicates drive
;				0x0:  Scan for Server, independent of drives
;		DX:		Baud and Port
;		CH:		1: We are doing a scan for the serial server
;				0: We are working off a specific port given by the user
;		CL:		1, for one sector to read
;		ES:SI:	Ptr to buffer for return
;	Returns:
;		AH:		INT 13h Error Code
;		CF:		Cleared if success, Set if error
;	Corrupts registers:
;		AL, BX
;--------------------------------------------------------------------
SerialServerScan_CheckForServer_PortAndBaudInDX:
		push	bp				; setup fake SerialServer_Command

		push	dx				; send port baud and rate, returned in inquire packet
								; (and possibly returned in the drive identification string)

		push	cx				; send number of sectors, and if it is on a scan or not

		mov		bl,SerialServer_Command_Inquire			; protocol command onto stack with bh
		push	bx

		mov		bp,sp

		call	SerialServer_SendReceive

		pop		bx
		pop		cx
		pop		dx
		pop		bp

		ret

