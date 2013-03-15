; Project name	:	Assembly Library
; Description	:	Strings used by dialogs.

;
; XTIDE Universal BIOS and Associated Tools
; Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; Visit http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
;

; Strings for Progress Dialog
g_szTimeElapsed:		db	"Time elapsed  :",NULL
g_szTimeLeft:			db	"Estimated left:",NULL
g_szTimeFormat:			db	" %2-u min %2-u sec",LF,CR,NULL

; Strings for Drive Dialog
g_szDriveFormat:		db	"%c:",NULL

; Strings for File Dialog
g_szChangeDrive:		db	"F2 Change Drive",LF,CR,NULL
g_szSelectDirectory:	db	"F3 Select Current Directory",LF,CR,NULL
g_szCreateNew:			db	"F4 Input new File or Directory",NULL

g_szSelectNewDrive:
	db		"Select new drive.",NULL
g_szLoadingPleaseWait:
	db		"Loading. Please wait...",NULL

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
