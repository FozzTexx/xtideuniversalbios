; Project name	:	BIOS Drive Information Tool
; Description	:	Strings used in this program.


; Section containing initialized data
SECTION .data

g_szProgramName:	db	"BIOS Drive Information Tool v1.0.1",LF,CR
					db	"(C) 2012 by XTIDE Universal BIOS Team",LF,CR
					db	"Released under GNU GPL v2",LF,CR
					db	"http://code.google.com/p/xtideuniversalbios/",LF,CR,NULL
					
g_szPressAnyKey:	db	LF,CR,"Press any key to display next drive.",LF,CR,NULL

g_szHeaderDrive:	db	LF,CR,"-= Drive %2x =-",LF,CR,NULL

g_szAtaInfoHeader:	db	"ATA-information from AH=25h...",LF,CR,NULL
g_szFormatDrvName:	db	" Name: %s",LF,CR,NULL
g_szFormatCHS:		db	" Cylinders    : %5-u, Heads: %3-u, Sectors: %2-u",LF,CR,NULL
g_szChsSectors:		db	" CHS   sectors: ",NULL
g_szLBA28:			db	" LBA28 sectors: ",NULL
g_szLBA48:			db	" LBA48 sectors: ",NULL

g_szXTUB:			db	"XTIDE Universal BIOS %s generates following L-CHS...",LF,CR,NULL
g_szXTUBversion:	db	ROM_VERSION_STRING	; This one is NULL terminated

g_szOldInfoHeader:	db	"Old INT 13h information from AH=08h and AH=15h...",LF,CR,NULL
					;	Cylinders
g_szSectors:		db	" Total sectors: ",NULL


g_szNewInfoHeader:	db	"EBIOS information from AH=48h...",LF,CR,NULL
g_szNewExtensions:	db	" Version      : %2-x, Interface bitmap: %2-x",LF,CR,NULL
					; Cylinders
					; Total sectors
g_szNewSectorSize:	db	" Sector size  : %u",LF,CR,NULL

g_szBiosError:		db	" BIOS returned error code %x",LF,CR,NULL
g_szDashForZero:	db	"- ",NULL		; Required by Assembly Library
