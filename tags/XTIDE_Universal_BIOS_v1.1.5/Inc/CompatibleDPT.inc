; File name		:	CompatibleDPT.inc
; Project name	:	IDE BIOS
; Created date	:	6.4.2010
; Last update	:	6.4.2010
; Author		:	Tomi Tilli
; Description	:	Structs for standard DPTs used for software
;					compatibility.
%ifndef COMPATIBLEDPT_INC
%define COMPATIBLEDPT_INC

; Fixed Disk Parameter table used for drives with capacity up to 504 MiB
struc COMPATIBLE_FDPT
	.wCyls			resb	2	; 0, Maximum number of cylinders
	.bHeads			resb	1	; 2, Maximum number of heads
	.wRedWrCyl		resb	2	; 3, Starting cylinder for reduced write current (MFM)
	.wWrPreCmpCyl	resb	2	; 5, Starting write precompensation cylinder (MFM)
	.bMaxECCLen		resb	1	; 7, Maximum ECC data burst length (MFM)
	.bDrvCtrl		resb	1	; 8, Control Byte
	.bNormTimeout	resb	1	; 9, Normal timeout value
	.bFormatTimeout	resb	1	; 10, Timeout value for format disk drive
	.bCheckTimeout	resb	1	; 11, Timeout value for check disk drive
	.wLZoneCyl		resb	2	; 12, Landing zone cylinder
	.bSectPerTrack	resb	1	; 14, Number of sectors per track
					resb	1	; 15, unused
endstruc


; Fixed Disk Parameter table used for drives with P-CHS or LBA addressing
struc COMPATIBLE_EDPT
	.wLCyls			resb	2	; 0, L-CHS cylinders (1...1024)
	.bLHeads		resb	1	; 2, L-CHS heads (1...255)
	.bSignature		resb	1	; 3, EDPT signature (A0h)
	.bPSect			resb	1	; 4, P-CHS sectors per track (1...63)
					resb	3	; 5...7, unused
	.bDrvCtrl		resb	1	; 8, Control Byte
	.wPCyls			resb	2	; 9, P-CHS cylinders (1...16383)
	.bPHeads		resb	1	; 11, P-CHS heads (1...16)
					resb	2	; 12...13, unused
	.bLSect			resb	1	; 14, L-CHS sectors per track (1...63)
	.bChecksum		resb	1	; 15, Checksum of bytes 0 to 14		
endstruc

COMPATIBLE_EDPT_SIGNATURE	EQU		0A0h


%endif ; COMPATIBLEDPT_INC
