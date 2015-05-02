; Project name	:	XTIDE Universal BIOS
; Description	:	Promise PDC 20230-C and 20630 VLB IDE controller
;					specifications.
;
;					Specifications can be found at 

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

%ifndef PDC20x30_INC
%define PDC20x30_INC


; SECTOR_COUNT_REGISTER in programming mode
FLG_PDCSCR_UNKNOWN_BIT7		EQU		(1<<7)	; Set to 1 for speed setting 7 of device 0 or 1
FLG_PDCSCR_ID3				EQU		(1<<6)	; VLB bus speed: 0 > 33 MHz, 1 <= 33 MHz
POS_PDCSCR_DEV0SPEED		EQU		3
MASK_PDCSCR_DEV0SPEED		EQU		(7<<POS_PDCSCR_DEV0SPEED)	; 0 to 7
MASK_PDCSCR_DEV1SPEED		EQU		(7<<0)						; 0 to 7


; LOW_CYLINDER_REGISTER in programming mode
; This is only on PDC 20630!
FLG_PDCLCR_DEV0SPEED_BIT4	EQU		(1<<7)	; Possibly speed bit 4 (speed settings 8 to 15)?
FLG_PDCLCR_DEV1SPEED_BIT4	EQU		(1<<6)	; Same as above but for device 1
FLG_PDCLCR_DEV0IORDY		EQU		(1<<5)	; Not sure about this
FLG_PDCLCR_DEV1IORDY		EQU		(1<<4)	; Same as above but for device 15
FLG_PDCLCR_ENABLE_EXTRA_REGISTERS	EQU	(1<<3)


; PDC 20630 specific registers mapped after IDE registers
PDC20630_INDEX_REGISTER		EQU		8		; 1F8h
PDC20630_DATA_REGISTER		EQU		9		; 1F9h

; PDC 20630 registers to access through index and data register
PDCREG0_TIMING_OF_DEV0_LOW	EQU		0		; Low, high, what timings?
PDCREG1_TIMING_OF_DEV0_HIGH	EQU		1
PDCREG2_TIMING_OF_DEV1_LOW	EQU		2
PDCREG3_TIMING_OF_DEV1_HIGH	EQU		3
PDCREG7_STATUS				EQU		7

FLG_PDCSTATUS_DMA_ERROR				EQU	(1<<4)	; ?
FLG_PDCSTATUS_DMA_READ_COMPLETED	EQU	(1<<1)	; ?
FLG_PDCSTATUS_DMA_WRITE_COMPLETED	EQU	(1<<0)	; ?


%endif ; PDC20x30_INC
