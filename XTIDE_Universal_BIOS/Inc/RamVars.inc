; Project name	:	XTIDE Universal BIOS
; Description	:	RAMVARS struct containing BIOS variables stored in RAM.
%ifndef RAMVARS_INC
%define RAMVARS_INC

; Segment when RAMVARS is stored to top of interrupt vectors.
SEGMENT_RAMVARS_TOP_OF_INTERRUPT_VECTORS		EQU		30h


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
	.wIdeBase			resb	2	; Base port address for currently handled controller
	.wTimeoutCounter	resb	2

	.wDrvCntAndFirst:
	.bDrvCnt			resb	1	; Number of drives handled by this BIOS
	.bFirstDrv			resb	1	; Number of first drive for this BIOS

	; Variables for drive number translation
	.xlateVars		resb	XLATEVARS_size
endstruc

; Full mode RAM variables.
struc FULLRAMVARS
	.ramVars			resb	RAMVARS_size
	.wSign				resb	2		; FULLRAMVARS signature for finding segment
endstruc

W_SIGN_FULLRAMVARS		EQU	"fR"		; FULLRAMVARS signature


%endif ; RAMVARS_INC
