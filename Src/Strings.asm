; File name		:	Strings.asm
; Project name	:	XTIDE Univeral BIOS Configurator
; Created date	:	16.4.2010
; Last update	:	2.5.2010
; Author		:	Tomi Tilli
; Description	:	Strings used in this program.

; Section containing initialized data
SECTION .data

; General strings
g_szSignature:		db	"XTIDE110",STOP		; XTIDE Universal BIOS signature string
g_szCommonInfo:		db	"F1 displays item help. F2 toggles info. UP, DOWN, ENTER and ESC navigates. ENTER changes settings.",STOP
g_szPreviousMenu:	db	"Back to previous menu",STOP
g_szFileSearch:		db	"*.bin",STOP
g_szErrFileSize:	db	"File size is too large! Maximum supported size is 16384 bytes.",STOP
g_szDlgSaveChanges:	db	"Do you want to save changes to BIOS image file?",STOP


; Flashing strings
g_szFlashProgress:		db	"Writing EEPROM: %u / %u B.",STOP
g_szFlashTimeout:		db	"Timeout error when polling EEPROM!",STOP
g_szFlashVerifyErr:		db	"Data verification failed!",STOP
g_szFlashDoneReboot:	db	"EEPROM written succesfully. Press any key to reboot.",STOP
g_szFlashDoneContinue:	db	"EEPROM written succesfully.",STOP


; Strings for menu title
g_szTitleProgramName:	db	"Configuration and flashing program for XTIDE Universal BIOS v1.1.0",STOP
g_szNoBiosLoaded:		db	"No BIOS loaded.",STOP
g_szImageSource:		db	"Source image: ",STOP
g_szRomLoaded:			db	"ROM",STOP


; Strings for main menu
g_szItemMainExitToDOS:	db	"Exit to DOS",STOP
g_szItemMainLoadFile:	db	"Load BIOS from file",STOP
g_szItemMainLoadROM:	db	"Load BIOS from EEPROM",STOP
g_szItemMainLoadStngs:	db	"Load old settings from EEPROM",STOP
g_szItemMainFlash:		db	"Flash EEPROM",STOP
g_szItemMainConfigure:	db	"Configure XTIDE Universal BIOS",STOP

g_szDlgMainLoadROM:		db	"Successfully loaded XTIDE Universal BIOS from EEPROM.",STOP
g_szDlgMainLoadStngs:	db	"Successfully loaded settings from EEPROM.",STOP

g_szNfoMainExitToDOS:	db	"Quits XTIDE Univeral BIOS Configurator.",STOP
g_szNfoMainLoadFile:	db	"Load BIOS file to be configured or flashed.",STOP
g_szNfoMainLoadROM:		db	"Load BIOS from EEPROM to be reconfigured.",STOP
g_szNfoMainLoadStngs:	db	"Load old XTIDE Universal BIOS settings from EEPROM.",STOP
g_szNfoMainFlash:		db	"Flash loaded BIOS image to EEPROM.",STOP
g_szNfoMainConfigure:	db	"Configure XTIDE Universal BIOS settings.",STOP


; Strings for XTIDE Universal BIOS configuration menu
g_szItemCfgIde1:		db	"Primary IDE Controller",STOP
g_szItemCfgIde2:		db	"Secondary IDE Controller",STOP
g_szItemCfgIde3:		db	"Tertiary IDE Controller",STOP
g_szItemCfgIde4:		db	"Quaternary IDE Controller",STOP
g_szItemCfgIde5:		db	"Quinary IDE Controller",STOP
g_szItemCfgBootMenu:	db	"Boot menu settings",STOP
g_szItemCfgBootLoader:	db	"Boot loader type",STOP
g_szItemCfgLateInit:	db	"Late initialization",STOP
g_szItemCfgMaxSize:		db	"Maximize disk size",STOP
g_szItemCfgFullMode:	db	"Full operating mode",STOP
g_szItemCfgStealSize:	db	"kiB to steal from RAM",STOP
g_szItemCfgIdeCnt:		db	"Number of IDE controllers",STOP

g_szDlgCfgLateInit:		db	"Use late BIOS initialization?",STOP
g_szDlgCfgMaxSize:		db	"Maximize hard disk size by sacrificing compatibility with old BIOSes?",STOP
g_szDlgCfgFullMode:		db	"Enable full operating mode?",STOP
g_szDlgCfgStealSize:	db	"How many kiB of base memory to steal for XTIDE Universal BIOS variables (1...255)?",STOP
g_szDlgCfgIdeCnt:		db	"How many IDE controllers to manage (1...5)?",STOP

g_szNfoCfgBack:			db	"Back to main menu.",STOP
g_szNfoCfgIde:			db	"IDE controller and drive configuration.",STOP
g_szNfoCfgBootMenu:		db	"Boot menu configuration.",STOP
g_szNfoCfgBootLoader:	db	"Boot loader selection for INT 19h.",STOP
g_szNfoCfgLateInit:		db	"Detect hard disks on boot loader.",STOP
g_szNfoCfgMaxSize:		db	"Maximize hard disk size by not reserving diagnostic cylinder.",STOP
g_szNfoCfgFullMode:		db	"Full mode supports multiple controllers and has more features.",STOP
g_szNfoCfgStealSize:	db	"Number of kiB of base memory to steal for BIOS variables.",STOP
g_szNfoCfgIdeCnt:		db	"Number of IDE controllers to manage.",STOP

g_szHelpCfgLateInit:	db	"Normally expansion card BIOSes are initialized before POST completes. "
						db	"Some (older) systems initialize expansion card BIOSes before they have "
						db	"initialized themselves. This might cause problems since XTIDE Universal "
						db	"BIOS requires some main BIOS functions for drive detection.",MNU_NL
						db	"This problem can be fixed by using late initialization to "
						db	"detect drives on boot loader. "
						db	"Late initialization requires that XTIDE Universal BIOS is the last "
						db	"BIOS that installs INT 19h handler. Make sure that XTIDE ROM is "
						db	"configured to highest address if you have other storage device "
						db	"controllers present.",STOP
g_szHelpCfgMaxSize:		db	"Old BIOSes reserve diagnostic cylinder (landing zone cylinder for MFM drives) that "
						db	"is not used. Later BIOSes do not reserve it to allow more data to be stored.",MNU_NL
						db	"Do not maximize disk size if you need to move the drive between XTIDE Universal BIOS "
						db	"controlled systems and systems with cylinder reserving BIOSes.",STOP
g_szHelpCfgFullMode:	db	"Full mode supports up to 5 IDE controllers (10 drives). Full mode reserves a bit "
						db	"of RAM from top of base memory. This makes possible to use ROM Basic and software that "
						db	"requires top of interrupt vectors where XTIDE Universal BIOS parameters would be stored "
						db	"in lite mode.",MNU_NL
						db	"Lite mode supports only one IDE controller (2 drives) and stores parameters to top of "
						db	"interrupt vectors (30:0h) so no base RAM needs to be reserved. Lite mode cannot be used "
						db	"if some software requires top of interrupt vectors. Usually this is not a problem since "
						db	"only IBM ROM Basic uses them.",MNU_NL
						db	"Tandy 1000 models with 640 kiB or less memory need to use lite mode since top of base RAM "
						db	"gets dynamically reserved by video hardware. This happens only with Tandy integrated "
						db	"video controller, not with expansion graphics cards. It is possible to use full mode if "
						db	"reserving RAM for video memory + what is required for XTIDE Universal BIOS. This would mean "
						db	"129 kiB but most software should work with 65 kiB reserved.",STOP
g_szHelpCfgStealSize:	db	"Parameters for detected hard disks must be stored somewhere. In full mode they are stored "
						db	"to top of base RAM. At the moment 1 kiB is always enough but you might want to steal more if "
						db	"you want to use full mode with Tandy 1000 (see help for Full Mode).",STOP

g_szValueBootLdrMenu:	db	"Menu",STOP
g_szValueBootLdrSimple:	db	"Simple",STOP
g_szValueBootLdrNone:	db	"System",STOP

; Strings for Boot Loader type menu
g_szItemBootMenu:		db	"Boot menu",STOP
g_szItemBootSimple:		db	"Simple boot loader",STOP
g_szItemBootNone:		db	"System boot loader",STOP

g_szNfoBootMenu:		db	"Boot menu for selecting drive to boot from.",STOP
g_szNfoBootSimple:		db	"Typical A, C, INT 18h boot order.",STOP
g_szNfoBootNone:		db	"Use boot loader provided by some other BIOS.",STOP


; Strings for IDE Controller menu
g_szItemIdeMaster:		db	"Master drive",STOP
g_szItemIdeSlave:		db	"Slave drive",STOP
g_szItemIdeCmdPort:		db	"Base (cmd block) address",STOP
g_szItemIdeCtrlPort:	db	"Control block address",STOP
g_szItemIdeBusType:		db	"Bus type",STOP
g_szItemIdeEnIRQ:		db	"Enable interrupt",STOP
g_szItemIdeIRQ:			db	"IRQ",STOP

g_szDlgIdeCmdPort:		db	"Enter IDE command block (base port) address.",STOP
g_szDlgIdeCtrlPort:		db	"Enter IDE control block address (usually command block + 200h).",STOP
g_szDlgIdeEnIRQ:		db	"Enable interrupt?",STOP
g_szDlgIdeIRQ:			db	"Enter IRQ channel (2...7 for 8-bit controllers, 2...15 for any other controller).",STOP

g_szNfoIdeBack:			db	"Back to XTIDE Universal BIOS configuration menu.",STOP
g_szNfoIdeMaster:		db	"Settings for master drive.",STOP
g_szNfoIdeSlave:		db	"Settings for slave drive.",STOP
g_szNfoIdeCmdPort:		db	"IDE Controller Command Block (base port) address.",STOP
g_szNfoIdeCtrlPort:		db	"IDE Controller Control Block address. Usually Cmd Block + 200h.",STOP
g_szNfoIdeBusType:		db	"Select controller bus type.",STOP
g_szNfoIdeEnIRQ:		db	"Interrupt or polling mode.",STOP
g_szNfoIdeIRQ:			db	"IRQ channel to use.",STOP

g_szHelpIdeCmdPort:		db	"IDE controller command block address is the usual address mentioned for IDE controllers.",MNU_NL
						db	"By default the primary IDE controller uses port 1F0h and secondary controller uses port 170h. "
						db	"XTIDE uses port 300h by default.",STOP
g_szHelpIdeCtrlPort:	db	"IDE controller control block address is normally command block address + 200h.",MNU_NL
						db	"For XTIDE the control block registers are mapped right "
						db	"after command block registers so use command block address + 8h for XTIDE.",STOP
g_szHelpIdeEnIRQ:		db	"IDE controller can use interrupts to signal when it is ready to transfer data. This makes possible "
						db	"to do other tasks while waiting drive to be ready. That is not useful in MS-DOS but using "
						db	"interrupts frees the bus for any DMA transfers.",MNU_NL
						db	"Polling mode is used when interrupts are disabled. Polling usually gives a little better access times "
						db	"since interrupt handling requires extra processing. There can be some compatibility issues with some old drives "
						db	"when polling is used with block mode transfers.",STOP
g_szHelpIdeIRQ:			db	"IRQ channel to use. All controllers managed by XTIDE Universal BIOS can use the same IRQ when MS-DOS is used. "
						db	"Other operating systems are likely to require different interrupts for each controller.",STOP

g_szValueDual8b:		db	"2x8-bit",STOP
g_szValue16b:			db	"16-bit",STOP
g_szValue32b:			db	"32-bit",STOP
g_szValueSingle8b:		db	"1x8-bit",STOP


; Strings for Bus Type menu
g_szItemBus8Dual:		db	"8-bit dual port (XTIDE)",STOP
g_szItemBus8Single:		db	"8-bit single port",STOP
g_szItemBus16:			db	"16-bit",STOP
g_szItemBus32Generic:	db	"32-bit generic",STOP

g_szNfoBus8Dual:		db	"8-bit ISA controllers with two data ports.",STOP
g_szNfoBus8Single:		db	"8-bit ISA controllers with one data port.",STOP
g_szNfoBus16:			db	"16-bit I/O for ISA (16-bit), VLB and PCI controllers.",STOP
g_szNfoBus32Generic:	db	"Generic 32-bit I/O for VLB and PCI controllers.",STOP


; Strings for DRVPARAMS menu
g_szItemDrvBlockMode:	db	"Block mode transfers",STOP
g_szItemDrvUserCHS:		db	"User specified CHS",STOP
g_szItemDrvCyls:		db	"Cylinders",STOP
g_szItemDrvHeads:		db	"Heads",STOP
g_szItemDrvSect:		db	"Sectors per track",STOP

g_szDlgDrvBlockMode:	db	"Enable block mode transfers?",STOP
g_szDlgDrvUserCHS:		db	"Specify (P-)CHS parameters manually?",STOP
g_szDlgDrvCyls:			db	"Enter number of P-CHS cylinders (1...16383).",STOP
g_szDlgDrvHeads:		db	"Enter number of P-CHS heads (1...16).",STOP
g_szDlgDrvSect:			db	"Enter number of sectors per track (1...63).",STOP

g_szNfoDrvBack:			db	"Back to IDE controller menu.",STOP
g_szNfoDrvBlockMode:	db	"Transfer multiple sectors per data request.",STOP
g_szNfoDrvUserCHS:		db	"Specify (P-)CHS manually instead of autodetect.",STOP
g_szNfoDrvCyls:			db	"Number of user specified P-CHS cylinders.",STOP
g_szNfoDrvHeads:		db	"Number of user specified P-CHS heads.",STOP
g_szNfoDrvSect:			db	"Number of user specified P-CHS sectors per track.",STOP

g_szHelpDrvBlockMode:	db	"Block mode will speed up transfers since multiple sectors can be transferred "
						db	"before waiting next data request. Normally block mode should always be kept enabled "
						db	"but there is at least one drive with buggy block mode implementation. See readme for "
						db	"more information.",STOP
g_szHelpDrvUserCHS:		db	"Specify (P-)CHS parameters manually instead of autodetect.",MNU_NL
						db	"This can be used to limit drive size for old operating systems "
						db	"that do not support large hard disks.",MNU_NL
						db	"Limiting cylinders will work for all drives but drives may not accept all "
						db	"values for heads and sectors per track.",STOP


; Strings for boot menu settings menu
g_szItemBootHeight:		db	"Maximum height",STOP
g_szItemBootTimeout:	db	"Selection timeout",STOP
g_szItemBootDrive:		db	"Default boot drive",STOP
g_szItemBootMinFDD:		db	"Min floppy drive count",STOP
g_szItemBootSwap:		db	"Swap boot drive numbers",STOP
g_szItemBootRomBoot:	db	"Display ROM boot",STOP
g_szItemBootInfo:		db	"Display drive info",STOP

g_szDlgBootHeight:		db	"Enter boot menu maximum height in characters (8...25).",STOP
g_szDlgBootTimeout:		db	"Enter Boot Menu selection timeout in seconds (1...60, 0 disables timeout).",STOP
g_szDlgBootDrive:		db	"Enter default drive number (0xh for Floppy Drives, 8xh for Hard Disks, FFh for ROM boot).",STOP
g_szDlgBootMinFDD:		db	"Enter minimum number of floppy drives.",STOP
g_szDlgBootSwap:		db	"Enable drive number translation?",STOP
g_szDlgBootRomBoot:		db	"Show ROM Boot option on boot menu?",STOP
g_szDlgBootInfo:		db	"Show drive information on boot menu?",STOP

g_szNfoBootHeight:		db	"Boot Menu maximum height in characters.",STOP
g_szNfoBootTimeout:		db	"Menu item selection timeout in seconds.",STOP
g_szNfoBootDrive:		db	"Default drive on boot menu.",STOP
g_szNfoBootMinFDD:		db	"Minimum number of floppy drives to display.",STOP
g_szNfoBootSwap:		db	"Drive Number Translation (swap first drive with selected).",STOP
g_szNfoBootRomBoot:		db	"Show ROM Basic or ROM DOS boot option.",STOP
g_szNfoBootInfo:		db	"Show detailed drive information on boot menu.",STOP

g_szHelpBootTimeout:	db	"Boot Menu selection timeout in seconds. When time goes to zero, "
						db	"currently selected drive will be booted automatically.",MNU_NL
						db	"Timeout can be disabled by setting this to 0.",STOP
g_szHelpBootDrive:		db	"Default drive will be set selected by default when Boot Menu is displayed.",STOP
g_szHelpBootMinFDD:		db	"Detecting correct number of floppy drives might fail when using floppy controller with it's own BIOS. "
						db	"Minimum number of floppy drives can be specified to force non-detected drives to appear on boot menu.",STOP
g_szHelpBootSwap:		db	"Some old operating systems (DOS) can only boot from "
						db	"Floppy Drive A (00h) or first Hard Disk (80h, usually drive C). "
						db	"Drive Translation can be used to modify drive numbers so that "
						db	"selected drive will be mapped to 00h or 80h so that it can be booted.",STOP
g_szHelpBootRomBoot:	db	"Some old systems have Basic or DOS in ROM. Since most systems don't have either, "
						db	"ROM Boot setting is disabled by default. Enable it if you have use for it.",STOP
g_szHelpBootInfo:		db	"Boot Menu can display some details about the drives in system. Reading this data "
						db	"is slow on XTs so you might want to hide drive information.",STOP


; Strings for Flash menu
g_szItemFlashStart:		db	"Start flashing",STOP
g_szItemFlashSDP:		db	"SDP command",STOP
g_szItemFlashAddr:		db	"EEPROM address",STOP
g_szItemFlashPageSize:	db	"Page size",STOP
g_szItemFlashChecksum:	db	"Generate checksum byte",STOP

g_szDlgFlashAddr:		db	"Enter segment address where EEPROM is located.",STOP
g_szDlgFlashPageSize:	db	"Enter write page size (1, 2, 4, 8, 16, 32 or 64 bytes).",STOP
g_szDlgFlashChecksum:	db	"Generate checksum byte to the end of BIOS image?",STOP

g_szNfoFlashStart:		db	"Writes BIOS to EEPROM.",STOP
g_szNfoFlashSDP:		db	"Software Data Protection command.",STOP
g_szNfoFlashAddr:		db	"Address (segment) where EEPROM is located.",STOP
g_szNfoFlashPageSize:	db	"Number of bytes to write before delay.",STOP
g_szNfoFlashChecksum:	db	"Generate checksum byte to the end of BIOS image.",STOP

g_szHelpFlashSDP:		db	"Software Data Protection protects the EEPROM from unwanted writes.",MNU_NL
						db	"ENABLE command write protects the EEPROM after flashing. DISABLE command leaves the "
						db	"EEPROM unprotected. NONE is meant for EEPROMs that do not support Software Data Protection.",MNU_NL
						db	"Software Data Protection should always be left enabled if EEPROM supports it.",STOP
g_szHelpFlashPageSize:	db	"Larger page size will improve write performance but not all "
						db	"EEPROMs support large pages or page writing at all.",MNU_NL
						db	"Byte writing mode will be used when page size is set "
						db	"to 1. Byte writing mode is supported by every EEPROM. "
						db	"Large pages cannot be used with slow CPUs.",STOP
g_szHelpFlashChecksum:	db	"PC BIOSes require checksum byte to the end of expansion card BIOS ROMs. "
						db	"Checksum generation can be disabled so any type of binaries can be flashed.",STOP


; Strings for SDP command menu
g_szValueSdpNone:
g_szItemSdpNone:		db	"None",STOP
g_szValueSdpEnable:
g_szItemSdpEnable:		db	"Enable",STOP
g_szValueSdpDisable:
g_szItemSdpDisable:		db	"Disable",STOP

g_szNfoSdpNone:			db	"Do not use Software Data Protection.",STOP
g_szNfoSdpEnable:		db	"Enable Software Data Protection after flashing.",STOP
g_szNfoSdpDisable:		db	"Disable Software Data Protection after flashing.",STOP
