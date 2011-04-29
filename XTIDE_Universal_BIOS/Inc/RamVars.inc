; Project name	:	XTIDE Universal BIOS
; Description	:	RAMVARS struct containing BIOS variables stored in RAM.
%ifndef RAMVARS_INC
%define RAMVARS_INC

; Segment when RAMVARS is stored to top of interrupt vectors.
LITE_MODE_RAMVARS_SEGMENT	EQU		30h


; Variables for translating drive numbers.
struc XLATEVARS
	.bFDSwap		resb	1	; Floppy Drive to swap to 00h and vice versa
	.bHDSwap		resb	1	; Hard Drive to swap to 80h and vice versa
	.bXlatedDrv		resb	1	; Drive number after translation
					resb	1	; For WORD alignment
endstruc

; RAM Variables.
; Variables should be kept to minimum since they might be located
; at the top of interrupt vectors.
struc RAMVARS
	.fpOldI13h			resb	4	; Far pointer to old INT 13h handler
	.wTimeoutCounter	resb	2
	.pInServiceDPT		resb	2	; Ptr to DPT for drive waiting for interrupt
	.wSignature			resb	2	; Sign for finding stolen 1 kiB

	.wDrvCntAndFirst:
	.bDrvCnt			resb	1	; Number of drives handled by this BIOS
	.bFirstDrv			resb	1	; Number of first drive for this BIOS

	; Variables for drive number translation
	.xlateVars		resb	XLATEVARS_size
endstruc

RAMVARS_SIGNATURE		EQU	"Xu"	; RAMVARS signature for .wSignature


struc IDEPACK
	.bDrvAndHead			resb	1	; LBA28 27...24
	.bFeatures				resb	1

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

	; Parameters for 48-bit LBA
	.wSectorCountHighAndLbaLowExt:
	.bSectorCountHighExt	resb	1	; LBA48 Sector Count 15...8
	.bLbaLowExt				resb	1	; LBA48 31...24

	.wLbaMiddleAndHighExt:
	.bLbaMiddleExt			resb	1	; LBA48 39...32
	.bLbaHighExt			resb	1	; LBA48 47...40

	.intpack				resb	INTPACK_size
endstruc

EXTRA_WORDS_TO_RESERVE_FOR_INTPACK	EQU	((IDEPACK_size - INTPACK_size) / 2)


%endif ; RAMVARS_INC
