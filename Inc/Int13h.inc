; File name		:	Int13h.inc
; Project name	:	IDE BIOS
; Created date	:	23.3.2010
; Last update	:	23.3.2010
; Author		:	Tomi Tilli
; Description	:	Equates used in INT 13h functions.
%ifndef INT13H_INC
%define INT13H_INC

; Hard Disk function (INT 13h) return status codes in AH
RET_HD_SUCCESS			EQU		0h		; Operation succesfull, no error occurred
RET_HD_INVALID			EQU		1h		; Invalid value passed or unsupported func
RET_HD_ADDRMARK			EQU		2h		; Missing address mark
RET_HD_WRITEPROT		EQU		3h		; Removable media is write protected
RET_HD_NOT_FOUND		EQU		4h		; Requested sector not found
RET_HD_RESETFAIL		EQU		5h		; Reset failed
RET_HD_CHANGED			EQU		6h		; Media changed
RET_HD_PARAMACT			EQU		7h		; Drive parameter activity failed
RET_HD_OVERRUN			EQU		8h		; DMA overrun
RET_HD_BOUNDARY			EQU		9h		; Data boundary error
RET_HD_BADSECTOR		EQU		0Ah		; Bad sector detected
RET_HD_BADTRACK			EQU		0Bh		; Bad track detected
RET_HD_UNCORRECC		EQU		10h		; Uncorrectable ECC error
RET_HD_ECC				EQU		11h		; Corrected ECC error
RET_HD_CONTROLLER		EQU		20h		; Hard disk controller or drive problem
RET_HD_NOMEDIA			EQU		31h		; No media in removable media drive
RET_HD_SEEK_FAIL		EQU		40h		; Seek operation failed
RET_HD_TIMEOUT			EQU		80h		; Drive failed to respond
RET_HD_NOTREADY			EQU		0AAh	; Drive is not ready or is not selected
RET_HD_NOTLOCKED		EQU		0B0h	; Volume not locked in drive
RET_HD_LOCKED			EQU		0B1h	; Volume locked in drive
RET_HD_NOTREMOVABLE		EQU		0B2h	; Volume not removable
RET_HD_INUSE			EQU		0B3h	; Volume in use
RET_HD_LOCKEXCEEDED		EQU		0B4h	; Lock count exceeded
RET_HD_EJECTFAIL		EQU		0B5h	; Valid eject request failed
RET_HD_UNDEFINED		EQU		0BBh	; Undefined error occurred
RET_HD_WRFAULT			EQU		0CCh	; Write fault on selected drive
RET_HD_STATUSERR		EQU		0E0h	; Status error without error
RET_HD_SENSEFAIL		EQU		0FFh	; Sense operation failed


; Timeout values for IDE controller timeout
; 255 is the maximum value. Zero means immediate timeout.
B_TIMEOUT_BSY			EQU		(1000/55)	; 1000 ms
B_TIMEOUT_RDY			EQU		(1000/55)	; 1000 ms
B_TIMEOUT_DRQ			EQU		(5000/55)	; 5000 ms
B_TIMEOUT_DRVINFO		EQU		(500/55)	;  500 ms
B_TIMEOUT_RESET			EQU		255			;   14 s


; Floppy Drive types returned by INT 13h, AH=08h
FLOPPY_TYPE_525_OR_35_DD	EQU	0
FLOPPY_TYPE_525_DD			EQU	1
FLOPPY_TYPE_525_HD			EQU	2
FLOPPY_TYPE_35_DD			EQU	3
FLOPPY_TYPE_35_HD			EQU	4
FLOPPY_TYPE_35_ED			EQU	6


%endif ; INT13H_INC
