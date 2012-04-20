; Project name	:	XTIDE Universal BIOS
; Description	:	RAMVARS struct containing BIOS variables stored in RAM.

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

%ifndef RAMVARS_INC
%define RAMVARS_INC

; Segment when RAMVARS is stored to top of interrupt vectors.
%ifndef USE_AT
LITE_MODE_RAMVARS_SEGMENT	EQU		30h
%endif


; Variables for translating drive numbers.
struc XLATEVARS
%ifdef MODULE_SERIAL_FLOPPY
	.bFlopCreateCnt:
	.bFlopCntAndFirst	resb	1	; Normally, packed starting floppy drive number (high order 7 bits)
									; and number of drives (low order bit, max 2 drives supported).
									; During initialization, until the end of DetectDrives_FromAllIDEControllers,
									; this byte contains the raw number of floppy drives seen (using .bFlopCreateCnt)
%else
						resb	1	; alignment
%endif
	.bXlatedDrv			resb	1	; Drive number after translation
	.wFDandHDswap:
	.bFDSwap			resb	1	; Floppy Drive to swap to 00h and vice versa
	.bHDSwap			resb	1	; Hard Drive to swap to 80h and vice versa
endstruc

; RAM Variables.
; Variables should be kept to minimum since they might be located
; at the top of interrupt vectors.
struc RAMVARS
	.fpOldI13h			resb	4	; Far pointer to old INT 13h handler
	.wSignature			resb	2	; Sign for finding stolen 1 kiB
	.bTimeoutTicksLeft	resb	1
	.bLastTimeoutUpdate	resb	1

	.wDrvCntAndFirst:
	.bFirstDrv			resb	1	; Number of first drive for this BIOS
	.wDrvCntAndFlopCnt:				; Both the hard disk and floppy counts in one word
									; (yes, misaligned, but it is only used this way during initialization)
	.bDrvCnt			resb	1	; Number of drives handled by this BIOS

	; Variables for drive number translation
	.xlateVars		resb	XLATEVARS_size
endstruc

%ifdef MODULE_SERIAL_FLOPPY
  %ifndef CHECK_FOR_UNUSED_ENTRYPOINTS
	%if RAMVARS.xlateVars != RAMVARS.bDrvCnt+1 || XLATEVARS.bFlopCreateCnt != 0
		%error "bFlopCreateCnt needs to be the first thing in XLATEVARS, and .xlateVars needs to come immediately after .bDrvCnt.  In at least one place, we read .wDrvCntAndFlopCnt to get both counts in one fetch"
	%endif
  %endif
%endif

RAMVARS_SIGNATURE		EQU	"Xu"	; RAMVARS signature for .wSignature

;
; IDEPACK NOTE: The first six bytes of this structure are directly put on the 
; wire for MODULE_SERIAL, please do not change the order or insert other members.
;
struc IDEPACK
	.bFeatures				resb	1
	.bDrvAndHead			resb	1	; LBA28 27...24

	.wSectorCountAndLbaLow:
	.bSectorCount			resb	1
	.bSectorNumber:
	.bLbaLow				resb	1	; LBA 7...0

	.wCylinder:
	.wLbaMiddleAndHigh:
	.bLbaMiddle				resb	1	; LBA 15...8
	.bLbaHigh				resb	1	; LBA 23...16

	.bCommand				resb	1
	.bDeviceControl			resb	1	; Offset 7 shared with PIOVARS
							resb	1

	; Parameters for 48-bit LBA
	.bLbaLowExt				resb	1	; LBA48 31...24
	.wLbaMiddleAndHighExt:
	.bLbaMiddleExt			resb	1	; LBA48 39...32
	.bLbaHighExt			resb	1	; LBA48 47...40

	.intpack				resb	INTPACK_size
endstruc

EXTRA_BYTES_FOR_INTPACK		EQU	(IDEPACK_size - INTPACK_size)


%endif ; RAMVARS_INC
