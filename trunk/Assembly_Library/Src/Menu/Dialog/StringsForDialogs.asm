; File name		:	StringsForDialogs.asm
; Project name	:	Assembly Library
; Created date	:	14.9.2010
; Last update	:	1.10.2010
; Author		:	Tomi Tilli
; Description	:	Strings used by dialogs.

; Strings for Progress Dialog
g_szTimeElapsed:		db	"Time elapsed  :",NULL
g_szTimeLeft:			db	"Estimated left:",NULL
g_szTimeFormat:			db	" %2-u min %2-u sec",LF,CR,NULL

; Strings for File Dialog
g_szChangeDrive:		db	"F2 Change Drive",LF,CR,NULL
g_szSelectDirectory:	db	"F3 Select Current Directory",LF,CR,NULL
g_szCreateNew:			db	"F4 Input new File or Directory",NULL

g_szSelectNewDrive:
	db		"Select new drive.",NULL

g_szEnterNewFileOrDirectory:
	db		"Enter name for new file or directory.",NULL

FILE_STRING_LENGTH		EQU		(24+1)	; +1 = LF in directory contents string
g_szFileFormat:
	db		"%16S%4-u %c%cB",LF,NULL
g_szDirectoryFormat:
	db		"%16S%s-DIR",LF,NULL
g_szSub:
	db		ANGLE_QUOTE_RIGHT,"SUB",NULL
g_szUp:
	db		ANGLE_QUOTE_LEFT," UP",NULL

g_szSingleItem:			; Used by Dialog.asm for single item line
g_szUpdir:
	db		".."
g_szNull:
	db		NULL
