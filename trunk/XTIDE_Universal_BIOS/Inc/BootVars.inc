; Project name	:	XTIDE Universal BIOS
; Description	:	Defines for BOOTVARS struct used by boot menu
;					and drive initialization.
%ifndef BOOTVARS_INC
%define BOOTVARS_INC


; Boot Menu Information Table. These are generated for all XTIDE Universal
; BIOS drives. Available only until boot is successfull.
LEN_BOOTNFO_DRV		EQU		26		; Bytes reserved for drive name
struc BOOTNFO
	.twSectCnt		resb	6		; Total user addressable sectors
	.szDrvName		resb	LEN_BOOTNFO_DRV+1	; Drive name
					resb	1		; Alignment
endstruc


; Pre-boot variables. These do not exist after successfull boot to OS.
; Segment is always 0000h, same as BDA segment
struc BOOTVARS
					resb	800h
	.dwSys18h		resb	4		;  800h, System INT 18h handler (Diskless boot, Boot failure)
	.dwPostStack	resb	4		;  804h, POST stack when entering INT 19h
					resb	4
	.rgBootNfo		resb	73F4h	;  80Ch, Array containing BOOTNFO structs
	.rgbMnuStack:					; 7C00h and below, Boot Menu stack
	.rgbAtaInfo:					; 7C00h, ATA Information for drive detection
	.rgbBootSect	resb 	512		; 7C00h, Boot sector
endstruc


%endif ; BOOTVARS_INC
