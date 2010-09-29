; File name		:	Dialog.inc
; Project name	:	Assembly Library
; Created date	:	15.9.2010
; Last update	:	28.9.2010
; Author		:	Tomi Tilli
; Description	:	Defines for Menu library dialogs.
%ifndef DIALOG_INC
%define DIALOG_INC

; Struct and defines for all dialogs
struc DIALOG
	.menu					resb	MENU_size
	.fpDialogIO				resb	4	; Ptr to DIALOG_INPUT + dialog specific data
	.pParentMenu			resb	2
endstruc

DIALOG_DELTA_WIDTH_FROM_PARENT		EQU		5
DIALOG_MAX_WIDTH					EQU		60
DIALOG_MAX_HEIGHT					EQU		25


; Dialog parameter and return value structs
struc DIALOG_INPUT
	.fszTitle			resb	4
	.fszItems			resb	4
	.fszInfo			resb	4
endstruc

struc WORD_DIALOG_IO
	.dialogInput		resb	DIALOG_INPUT_size
	.bUserCancellation	resb	1
	.bNumericBase		resb	1
	.wMin				resb	2
	.wMax				resb	2
	.wReturnWord		resb	2
endstruc

struc STRING_DIALOG_IO
	.dialogInput		resb	DIALOG_INPUT_size
	.bUserCancellation	resb	1
						resb	1
	.fnCharFilter		resb	2	; Optional, can be NULL to accept all
	.wBufferSize:
	.wReturnLength		resb	2	; String length without NULL
	.fpReturnBuffer		resb	4
endstruc

struc PROGRESS_DIALOG_IO
	.dialogInput					resb	DIALOG_INPUT_size
									resb	2
	.wCurrentProgressValue			resb	2
	.wMaxProgressValue				resb	2
	.wMinProgressValue				resb	2
	.fnTaskWithParamInDSSI			resb	2

	; Progress Dialog internal values
	.wProgressPerCharacter			resb	2
	.wStartTimeTicks				resb	2
endstruc

struc FILE_DIALOG_IO
	; DIALOG_INPUT adjusted for File Dialog
	.fszTitle			resb	4
	.fszItemBuffer		resb	4	; For generating file strings
						resb	4

	.bUserCancellation	resb	1
						resb	1
	.bDialogFlags		resb	1
	.bFileAttributes	resb	1
						resb	2
	.fpFileFilterString:			; Ptr to NULL terminated search string (may include path and wildcards)
	.szFile				resb	FILENAME_BUFFER_SIZE
endstruc


; Progress bar dialog
PROGRESS_COMPLETE_CHARACTER			EQU		BLOCK_FULL_FOREGROUND
PROGRESS_INCOMPLETE_CHARACTER		EQU		BLOCK_MOSTLY_BACKGROUND

; File dialog
FILENAME_BUFFER_SIZE				EQU		14	; 8+1+3+NULL+alignment
MAX_FILE_DIALOG_INFO_LINES			EQU		3
FLG_FILEDIALOG_DRIVES				EQU		(1<<0)	; Allow changing drive
FLG_FILEDIALOG_DIRECTORY			EQU		(1<<1)	; Select directory instead of file
FLG_FILEDIALOG_NEW					EQU		(1<<2)	; Allow creating new file or directory

KEY_FILEDIALOG_CHANGE_DRIVE			EQU		3Ch		; F2
KEY_FILEDIALOG_SELECT_DIRECTORY		EQU		3Dh		; F3
KEY_FILEDIALOG_NEW_FILE_OR_DIR		EQU		3Eh		; F4


%endif ; DIALOG_INC
