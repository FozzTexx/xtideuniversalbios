; Project name	:	BIOS Drive Information Tool
; Description	:	Strings used in this program.


; Section containing initialized data
SECTION .data

g_szProgramName:	db	"BIOS Drive Information Tool v1.0.1",CR,LF
					db	"(C) 2012 by XTIDE Universal BIOS Team",CR,LF
					db	"Released under GNU GPL v2",CR,LF
					db	"http://code.google.com/p/xtideuniversalbios/",CR,LF,NULL
					
g_szPressAnyKey:	db	CR,LF,"Press any key to display next drive.",CR,LF,NULL

g_szHeaderDrive:	db	CR,LF,"-= Drive %2x =-",CR,LF,NULL

g_szAtaInfoHeader:	db	"ATA-information from AH=25h...",CR,LF,NULL
g_szFormatDrvName:	db	" Name: %s",CR,LF,NULL
g_szFormatCHS:		db	" Cylinders    : %5-u, Heads: %3-u, Sectors: %2-u",CR,LF,NULL
g_szChsSectors:		db	" CHS   sectors: ",NULL
g_szLBA28:			db	" LBA28 sectors: ",NULL
g_szLBA48:			db	" LBA48 sectors: ",NULL

g_szXTUB:			db	"XTIDE Universal BIOS %s generates following L-CHS...",CR,LF,NULL
g_szXTUBversion:	db	ROM_VERSION_STRING	; This one is NULL terminated

g_szOldInfoHeader:	db	"Old INT 13h information from AH=08h and AH=15h...",CR,LF,NULL
					;	Cylinders
g_szSectors:		db	" Total sectors: ",NULL


g_szNewInfoHeader:	db	"EBIOS information from AH=48h...",CR,LF,NULL
g_szNewExtensions:	db	" Version      : %2-x, Interface bitmap: %2-x",CR,LF,NULL
					; Cylinders
					; Total sectors
g_szNewSectorSize:	db	" Sector size  : %u",CR,LF,NULL

g_szBiosError:		db	" BIOS returned error code %x",CR,LF,NULL
g_szDashForZero:	db	"- ",NULL		; Required by Assembly Library

g_szNewline:		db	CR,LF,NULL
