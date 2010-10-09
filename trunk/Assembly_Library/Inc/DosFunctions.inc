; File name		:	DosFunctions.inc
; Project name	:	AssemblyLibrary
; Created date	:	1.9.2010
; Last update	:	8.10.2010
; Author		:	Tomi Tilli
; Description	:	Defines for MS-DOS functions.
%ifndef DOS_FUNCTIONS_INC
%define DOS_FUNCTIONS_INC

; DOS interrupts
DOS_INTERRUPT_21h									EQU		21h
DOS_CRITICAL_ERROR_HANDLER_24h						EQU		24h

; DOS file functions
SELECT_DEFAULT_DRIVE								EQU		0Eh
GET_CURRENT_DEFAULT_DRIVE							EQU		19h
SET_INTERRUPT_VECTOR								EQU		25h
GET_DISK_TRANSFER_AREA_ADDRESS						EQU		2Fh
GET_DOS_DRIVE_PARAMETER_BLOCK_FOR_SPECIFIC_DRIVE	EQU		32h
SET_CURRENT_DIRECTORY								EQU		3Bh
OPEN_EXISTING_FILE									EQU		3Dh
CLOSE_FILE											EQU		3Eh
READ_FROM_FILE_OR_DEVICE							EQU		3Fh
WRITE_TO_FILE_OR_DEVICE								EQU		40h
SET_CURRENT_FILE_POSITION							EQU		42h
GET_CURRENT_DIRECTORY								EQU		47h
FIND_FIRST_MATCHING_FILE							EQU		4Eh
FIND_NEXT_MATCHING_FILE								EQU		4Fh

; DOS errors
ERR_DOS_DRIVE_NOT_READY								EQU		15h



; DOS Program Segment Prefix (PSP, first 256 (100h) bytes on top of program)
struc PSP
	.int20hInstruction				resb	2
	.wSizeOfMemoryInParagraphs		resb	2
	.reservedAt4h					resb	1
	.callToDosFunctionDispatcher	resb	5
	.fpInt22hTerminate				resb	4
	.fpInt23hCtrlC					resb	4
	.fpInt24hCriticalError			resb	4
	.reservedAt16h					resb	22
	.wEnvironmentSegment			resb	2
	.reservedAt2Eh					resb	34
	.int21hAndRetfInstructions		resb	3
	.reservedAt53h					resb	9
	.FCB1							resb	16
	.FCB2							resb	20
	.DiskTransferArea:
	.bCommandLineLength				resb	1
	.szCommandLine					resb	127
endstruc


; DOS DTA (Disk Transfer Area)
struc DTA
	; Undocumented fields
	.reservedAt0h		resb	21
	; Documented fields
	.bFileAttributes	resb	1	; 15h, Attribute of matching file
	.wFileTime			resb	2	; 16h, File time
	.wFileDate			resb	2	; 18h, File date
	.dwFileSize			resb	4	; 1Ah, File size in bytes
	.szFile				resb	13	; 1Eh, ASCIZ filename + extension
endstruc


%endif ; DOS_FUNCTIONS_INC
