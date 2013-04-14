; Project name	:	XTIDE Universal BIOS
; Description	:	Equates used in Enhanced INT 13h functions (EBIOS).

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

%ifndef EBIOS_INC
%define EBIOS_INC

; EBIOS specification returned by INT 13h, AH=41h

EDD_V1_1							EQU	21h		; 21h = EDD version 1.1
EBIOS_VERSION						EQU	EDD_V1_1

; Support bits returned by INT 13h, AH=41h
ENHANCED_DRIVE_ACCESS_SUPPORT		EQU	(1<<0)	; 41h, 42h, 43h 44h, 47h and 48h are available
DRIVE_LOCKING_AND_EJECTING_SUPPORT	EQU	(1<<1)	; 41h, 45h, 46h, 48h, 49h are available and INT 15h, AH=52h
ENHANCED_DISK_DRIVE_SUPPORT			EQU	(1<<2)	; 41h, 48h, 4Eh are available (EDD)


; Extended Drive Information returned by AH=48h
struc EDRIVE_INFO
	.wSize					resb	2	; 0, Size of this buffer, at least 26
	.wFlags					resb	2	; 2, Information flags
	.dwCylinders			resb	4	; 4, Total number of addressable cylinders
	.dwHeads				resb	4	; 8, Total number of addressable heads
	.dwSectorsPerTrack		resb	4	; 12, Number of sectors per track
	.qwTotalSectors			resb	8	; 16, Total number of addressable sectors
	.wSectorSize			resb	2	; 24, Number of bytes per sector
	.fpDPTE					resb	4	; 26, Optional pointer to Device Parameter Table Extension
endstruc

MINIMUM_EDRIVEINFO_SIZE		EQU		26	; 26 bytes does not include EDD pointer
EDRIVEINFO_SIZE_WITH_DPTE	EQU		EDRIVE_INFO_size

; Flags for EDRIVE_INFO.wFlags
FLG_DMA_BOUNDARY_ERRORS_HANDLED_BY_BIOS				EQU	(1<<0)
FLG_CHS_INFORMATION_IS_VALID						EQU	(1<<1)
FLG_REMOVABLE_DRIVE									EQU	(1<<2)
FLG_WRITE_WITH_VERIFY_SUPPORTED						EQU	(1<<3)
FLG_CHANGE_LINE_SUPPORT								EQU	(1<<4)	; Removable media only
FLG_LOCKABLE										EQU	(1<<5)	; Removable media only
FLG_NO_MEDIA_PRESENT_AND_CHS_SET_TO_MAX				EQU	(1<<6)	; Removable media only


; Disk Address Packet for read, write and verify functions
struc DAP
	.bSize					resb	1	; 0, Size of this packet in bytes
	.bReservedAt1			resb	1	; 1, Currently unused, must be zero
	.wSectorCount			resb	2	; 2, Number of sectors to process (0...127)
	.dwMemoryAddress:
	.wOffset				resb	2	; 4, Memory offset for transfer
	.wSegment				resb	2	; 6, Memory segment for transfer
	.qwLBA					resb	8	; 8, Starting sector for transfer
endstruc

MINIMUM_DAP_SIZE			EQU		16


%endif ; EBIOS_INC
