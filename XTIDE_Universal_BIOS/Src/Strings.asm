; Project name	:	XTIDE Universal BIOS
; Description	:	Strings and equates for BIOS messages.

; Section containing code
SECTION .text

; POST drive detection strings
g_szRomAt:		db	"%s @ %x",LF,CR,NULL
g_szMaster:		db	"Master",NULL
g_szSlave:		db	"Slave ",NULL
g_szDetect:		db	"IDE %s at %x: ",NULL			; IDE Master at 1F0h:
g_szNotFound:	db	"not found",LF,CR,NULL

; Boot loader strings
g_szTryToBoot:	db	"Booting from %s %x",ANGLE_QUOTE_RIGHT,"%x",LF,CR,NULL
g_szBootSector:	db	"Boot sector",NULL
g_szFound:		db	"found",NULL
g_szSectRead:	db	"%s %s!",LF,CR,NULL
g_szReadError:	db	"Error %x!",LF,CR,NULL

; Boot menu bottom of screen strings
g_szFDD:		db	"FDD",NULL
g_szHDD:		db	"HDD",NULL
g_szRomBoot:	db	"ROM Boot",NULL
g_szHotkey:		db	"%A%c%c%A%8s%A ",NULL


; Boot Menu menuitem strings
g_szFDLetter:	db	"%s %c",NULL
g_szFloppyDrv:	db	"Floppy Drive",NULL
g_szforeignHD:	db	"Foreign Hard Disk",NULL

; Boot Menu information strings
g_szCapacity:	db	"Capacity : ",NULL
g_szSizeSingle:	db	"%s%u.%u %ciB",NULL
g_szSizeDual:	db	"%s%u.%u %ciB / %u.%u %ciB",LF,CR,NULL
g_szCfgHeader:	db	"Addr.",SINGLE_VERTICAL,"Block",SINGLE_VERTICAL,"Bus",  SINGLE_VERTICAL,"IRQ",  SINGLE_VERTICAL,"Reset",LF,CR,NULL
g_szCfgFormat:	db	"%s"   ,SINGLE_VERTICAL,"%5u",  SINGLE_VERTICAL,"%c%2u",SINGLE_VERTICAL," %c%c",SINGLE_VERTICAL,"%5x",  NULL
g_szLCHS:		db	"L-CHS",NULL
g_szPCHS:		db	"P-CHS",NULL
g_szLBA28:		db	"LBA28",NULL
g_szLBA48:		db	"LBA48",NULL
g_szFddUnknown:	db	"%sUnknown",NULL
g_szFddSizeOr:	db	"%s5",ONE_QUARTER,QUOTATION_MARK," or 3",ONE_HALF,QUOTATION_MARK," DD",NULL
g_szFddSize:	db	"%s%c%c",QUOTATION_MARK,", %u kiB",NULL	; 3½", 1440 kiB
