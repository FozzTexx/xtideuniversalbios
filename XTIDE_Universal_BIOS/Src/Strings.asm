; Project name	:	XTIDE Universal BIOS
; Description	:	Strings and equates for BIOS messages.

; Section containing code
SECTION .text

; POST drive detection strings
g_szRomAt:		db	"%s @ %x",CR,LF,NULL
g_szMaster:		db	"Master",NULL
g_szSlave:		db	"Slave ",NULL
g_szDetect:		db	"IDE %s at %x: ",NULL			; IDE Master at 1F0h:
g_szNotFound:	db	"not found",CR,LF,NULL

; Boot loader strings
g_szFloppyDrv:	db	"Floppy Drive",NULL
g_szHardDrv:	db	" Hard Drive ",NULL
g_szTryToBoot:	db	"Booting from %s %x",175,"%x ... ",NULL
g_szBootSector:	db	"Boot Sector",NULL
g_szFound:		db	"found",NULL
g_szSectRead:	db	"%s %s!",CR,LF,NULL
g_szReadError:	db	"Error %x!",CR,LF,NULL
g_sz18hCallback:db	"Boot menu callback via INT 18h",NULL

; Boot menu bottom of screen strings
g_szFDD:		db	"FDD",NULL
g_szHDD:		db	"HDD",NULL
g_szBottomScrn:	db	"%c to %c boots from %s with %s mappings",CR,LF,NULL

; Boot Menu menuitem strings
g_szFDLetter:	db	"%s %c",NULL
g_szforeignHD:	db	"Foreign Hard Disk",NULL
g_szRomBoot:	db	"ROM Boot",NULL

; Boot Menu information strings
g_szCapacity:	db	"Capacity : ",NULL
g_szSizeSingle:	db	"%s%u.%u %ciB",NULL
g_szSizeDual:	db	"%s%u.%u %ciB / %u.%u %ciB",NULL
g_szCfgHeader:	db	"Addr.",SINGLE_VERTICAL,"Block",SINGLE_VERTICAL,"Bus",  SINGLE_VERTICAL,"IRQ",  SINGLE_VERTICAL,"Reset",NULL
g_szCfgFormat:	db	"%s"   ,SINGLE_VERTICAL,"%5u",  SINGLE_VERTICAL,"%c%2u",SINGLE_VERTICAL," %c%c",SINGLE_VERTICAL,"%5x",  NULL
g_szLCHS:		db	"L-CHS",NULL
g_szPCHS:		db	"P-CHS",NULL
g_szLBA28:		db	"LBA28",NULL
g_szLBA48:		db	"LBA48",NULL
g_szFddUnknown:	db	"%sUnknown",NULL
g_szFddSizeOr:	db	"%s5",172,22h," or 3",171,22h," DD",NULL
g_szFddSize:	db	"%s%c%c",22h,", %u kiB",NULL	; 3½", 1440 kiB
