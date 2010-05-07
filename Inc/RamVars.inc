; File name		:	RamVars.inc
; Project name	:	IDE BIOS
; Created date	:	23.3.2010
; Last update	:	8.4.2010
; Author		:	Tomi Tilli
; Description	:	RAMVARS struct containing BIOS variables stored in RAM.
%ifndef RAMVARS_INC
%define RAMVARS_INC

; Segment when RAMVARS is stored to top of interrupt vectors.
SEGMENT_RAMVARS_TOP_OF_INTERRUPT_VECTORS		EQU		30h


; Variables for translating drive numbers.
struc XLATEVARS
	.bFDSwap		resb	1	; Floppy Drive to swap to 00h and vice versa
	.bHDSwap		resb	1	; Hard Drive to swap to 80h and vice versa
	.bRecurCnt		resb	1	; INT 13h recursion counter for drive translation
					resb	1	; For WORD alignment
endstruc

; RAM Variables.
; Variables should be kept to minimum since they might be located
; at the top of interrupt vectors.
struc RAMVARS
	.fpOldI13h		resb	4	; Far pointer to old INT 13h handler

	.dwI13DIDS:					; Temporary DI and DS storages when calling...
	.wI13hDI:					; ...previous INT 13h handler
	.wIdeBase		resb	2	; Base port address for currently handled controller

	.wI13hDS:
	.bEndTime		resb	1	; Timeout ending time
					resb	1	; Alignment

	.wDrvCntAndFirst:
	.bDrvCnt		resb	1	; Number of drives handled by this BIOS
	.bFirstDrv		resb	1	; Number of first drive for this BIOS

	; Variables for drive number translation
	.xlateVars		resb	XLATEVARS_size
endstruc

; Full mode RAM variables.
struc FULLRAMVARS
	.ramVars		resb	RAMVARS_size
	.wSign			resb	2			; FULLRAMVARS signature for finding segment
	.drv80hCompDPT	resb	COMPATIBLE_FDPT_size
	.drv81hCompDPT	resb	COMPATIBLE_FDPT_size
endstruc

W_SIGN_FULLRAMVARS		EQU	"fR"		; FULLRAMVARS signature


%endif ; RAMVARS_INC
