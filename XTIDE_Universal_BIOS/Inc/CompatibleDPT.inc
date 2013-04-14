; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for DPT structs to present drive geometry
;					to ill behaving applications that want
;					to read DPT from interrupt vectors 41h and 46h.

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

%ifndef COMPATIBLE_DPT
%define COMPATIBLE_DPT

; Standard DPT for small drives with 1024 or less cylinders
struc STANDARD_DPT
	.wPchsCylinders		resb	2	; 0-1, Physical number of cylinders
	.bPchsHeads			resb	1	; 2, Physical number of heads
	.bReserved3to4		resb	2	; 3-4, Reserved
	.wPrecompCylinder	resb	2	; 5-6, Write Precompensation Cylinder
	.bReserved7			resb	1	; 7, Reserved
	.bDrvControlByte	resb	1	; 8, Drive Control Byte
	.bReserved9to11		resb	3	; 9-11, Reserved
	.wLandingZone		resb	2	; 12-13, Landing Zone Cylinder
	.bPchsSectPerTrack	resb	1	; 14, Physical sectors per track
	.bReserved15		resb	1	; 15, Reserved
endstruc


; Translated DPT for drives with more than 1024 cylinders
struc TRANSLATED_DPT
	.wLchsCylinders		resb	2	; 0-1, Logical number of cylinders
	.bLchsHeads			resb	1	; 2, Logical number of heads
	.bSignature			resb	1	; 3, Axh signature to indicate Translated DPT
	.bPchsSectPerTrack	resb	1	; 4, Physical sectors per track
	.wPrecompCylinder	resb	2	; 5-6, Write Precompensation Cylinder
	.bReserved7			resb	1	; 7, Reserved
	.bDrvControlByte	resb	1	; 8, Drive Control Byte
	.wPchsCylinders		resb	2	; 9-10, Physical number of cylinders
	.bPchsHeads			resb	1	; 11, Physical number of heads
	.wLandingZone		resb	2	; 12-13, Landing Zone Cylinder
	.bLchsSectPerTrack	resb	1	; 14, Logical sectors per track
	.bChecksum			resb	1	; 15, Checksum: 2's complement of the 8-bit unsigned sum of bytes 0-14
endstruc

TRANSLATED_DPT_SIGNATURE	EQU		0A0h


; Device Parameter Table Extension (returned by AH=48h EBIOS function)
struc DPTE
	.wBasePort				resb	2	; 0, Command Block Base Port Address
	.wControlBlockPort		resb	2	; 2, Control Block Base Port Address
	.bDrvnhead				resb	1	; 4, Drive and Head Select Register upper nibble
	.bBiosVendor			resb	1	; 5, BIOS Vendor Specific
	.bIRQ					resb	1	; 6, IRQ for this device
	.bBlockSize				resb	1	; 7, Current block size in sectors
	.bDmaChannelAndType		resb	1	; 8, DMA information
	.bPioMode				resb	1	; 9, PIO mode
	.wFlags					resb	2	; 10, BIOS selected hardware specific option flags
	.wReserved				resb	2	; 12, Reserved. Must be zero.
	.bRevision				resb	1	; 14, Revision level of this table (11h)
	.bChecksum				resb	1	; 15, Checksum: 2's complement of the sum of bytes 0-14
endstruc

; Flags for DPTE.wFlags
FLG_FAST_PIO_ENABLED		EQU	(1<<0)	; Set if using PIO mode 1 or above (DPTE.bPioMode is valid when set)
FLG_DMA_ENABLED				EQU	(1<<1)	; Set if DMA enabled (DPTE.bDmaChannelAndType is valid when set)
FLG_BLOCK_MODE_ENABLED		EQU	(1<<2)	; Set if Block Mode transfers are enabled (DPTE.bBlockSize is valid when set)
FLG_CHS_TRANSLATION_ENABLED	EQU	(1<<3)	; Set for drives with more than 1024 cylinders
FLG_LBA_TRANSLATION_ENABLED	EQU	(1<<4)	; Set when LBA addresses from DAP are passed directly to the drive
FLG_REMOVABLE_MEDIA			EQU	(1<<5)
FLG_ATAPI_DEVICE			EQU	(1<<6)
FLG_32BIT_XFER_MODE			EQU	(1<<7)	; Set when using 32-bit data transfers
FLG_ATAPI_USES_IRQ			EQU	(1<<8)	; ATAPI Device uses IRQ for data transfers
; L-CHS translation type for old INT 13h (when FLG_CHS_TRANSLATION_ENABLED is set)
MASK_CHS_TRANSLATION_TYPE	EQU	(3<<TRANSLATION_TYPE_FIELD_POSITION)
	TRANSLATION_TYPE_FIELD_POSITION	EQU	9
	BIT_SHIFT_TRANSLATION			EQU	0	; LARGE
	LBA_ASSISTED_TRANSLATION		EQU	1	; Assisted LBA
											; 2 = reserved
	VENDOR_SPECIFIC_TRANSLATION		EQU	3


DPTE_REVISION				EQU		11h


%endif ; COMPATIBLE_DPT
