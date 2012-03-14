; File name		:	File.inc
; Project name	:	Assembly Library
; Created date	:	8.10.2010
; Last update	:	6.12.2010
; Author		:	Tomi Tilli
; Description	:	File library defines.
%ifndef FILE_INC
%define FILE_INC

; File access and sharing modes
struc FILE_ACCESS
	.ReadOnly		resb	1
	.WriteOnly		resb	1
	.ReadAndWrite	resb	1
endstruc

; Origin of file seek
struc SEEK_FROM
	.startOfFile			resb	1	; 00h
	.currentFilePosition	resb	1	; 01h
	.endOfFile				resb	1	; 02h
endstruc

; File attribute flags
FLG_FILEATTR_READ_ONLY			EQU		(1<<0)
FLG_FILEATTR_HIDDEN				EQU		(1<<1)
FLG_FILEATTR_SYSTEM				EQU		(1<<2)
FLG_FILEATTR_VOLUME_LABEL		EQU		(1<<3)
FLG_FILEATTR_DIRECTORY			EQU		(1<<4)
FLG_FILEATTR_ARCHIVE			EQU		(1<<5)


; Max number of bytes to read/write per DOS call when transferring DX:CX bytes
SPLIT_SIZE_FOR_LARGE_TRANSFERS	EQU		(32<<10)


%endif ; FILE_INC
