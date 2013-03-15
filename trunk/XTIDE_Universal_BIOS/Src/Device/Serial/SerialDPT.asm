; Project name	:	XTIDE Universal BIOS
; Description	:	Sets Serial Device specific parameters to DPT.

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
; SerialDPT_Finalize
;	Parameters:
;		DS:DI:	Ptr to Disk Parameter Table
;		ES:SI:	Ptr to 512-byte ATA information read from the drive
;	Returns:
;		CF:		Set, indicates that this is a floppy disk
;               Clear, indicates that this is a hard disk
;	Corrupts registers:
;		AX
;--------------------------------------------------------------------
SerialDPT_Finalize:
		mov		ax, [es:si+SerialServer_ATA_wPortAndBaud]
		mov		[di+DPT_SERIAL.wSerialPortAndBaud], ax

;
; Note that this section is not under %ifdef MODULE_SERIAL_FLOPPY.  It is important to
; distinguish floppy disks presented by the server and not treat them as hard disks, even
; if the floppy support is disabled.
;
		mov		al, [es:si+SerialServer_ATA_wDriveFlags]
		eSHL_IM	al, 1
		mov		byte [di+DPT.bFlagsHigh], al

		ret

%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if FLGH_DPT_SERIAL_DEVICE != 0x4 || FLGH_DPT_SERIAL_FLOPPY != 0x10 || FLGH_DPT_SERIAL_FLOPPY_TYPE_MASK != 0xe0 || FLGH_DPT_SERIAL_FLOPPY_TYPE_FIELD_POSITION != 5
		%error "The serial server passes FLGH values into SerialDPT_Finalize directly.  If the flag positions are changed, corresponding changes will need to be made in the serial server, and likely a version check put in to deal with servers talking to incompatible clients"
	%endif
%endif
