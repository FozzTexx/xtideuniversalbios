; File name		:	Strings.asm
; Project name	:	XTIDE Universal BIOS Configurator v2
; Created date	:	5.10.2010
; Last update	:	2.11.2010
; Author		:	Tomi Tilli
; Description	:	All strings.


; Section containing initialized data
SECTION .data

; Menu title
g_szProgramTitle:
	db	"Configuration and Flashing program for XTIDE Universal BIOS v1.1.4.",LF,CR,NULL
g_szXtideUniversalBiosSignature:	db	"XTIDE110",NULL
g_szBiosIsNotLoaded:				db	"BIOS is not loaded!",NULL
g_szEEPROM:							db	"EEPROM",NULL
g_szSourceAndTypeSeparator:			db	" : ",NULL
g_szUnidentified:					db	"Unidentified",NULL
g_szUnsaved:						db	" ",SINGLE_LEFT_HORIZONTAL_TO_VERTICAL,
									db	"Unsaved",SINGLE_RIGHT_HORIZONTAL_TO_VERTICAL, NULL
									
; Item formatting
g_szFormatItemWithoutValue:			db	"%c%s",NULL
g_szFormatItemNameWithValue:		db	"%26s%-9S",NULL


g_szNo:								db	"No",NULL
g_szYes:							db	"Yes",NULL
g_szMultichoiseBooleanFlag:
									db	"No",LF
									db	"Yes",NULL


; Generic dialog strings
g_szNotificationDialog:	db	"Notification.",NULL
g_szErrorDialog:		db	"Error!",NULL
g_szGenericDialogInfo:	db	"Press ENTER or ESC to close dialog.",NULL


; Strings for main menu
g_szItemMainExitToDOS:	db	"Exit to DOS",NULL
g_szItemMainLoadFile:	db	"Load BIOS from file",NULL
g_szItemMainLoadROM:	db	"Load BIOS from EEPROM",NULL
g_szItemMainLoadStngs:	db	"Load old settings from EEPROM",NULL
g_szItemMainConfigure:	db	"Configure XTIDE Universal BIOS",NULL
g_szItemMainFlash:		db	"Flash EEPROM",NULL

g_szDlgMainLoadROM:		db	"Successfully loaded XTIDE Universal BIOS from EEPROM.",NULL
g_szDlgMainLoadStngs:	db	"Successfully loaded settings from EEPROM.",NULL
g_szDlgMainLoadFile:	db	"Successfully loaded file for flashing.",NULL
g_szDlgMainSaveFile:	db	"Successfully saved XTIDE Universal BIOS to file.",NULL
g_szDlgMainFileTooBig:	db	"Selected file is too big to be loaded for flashing!",NULL
g_szDlgMainLoadErr:		db	"Failed to load file!",NULL
g_szDlgMainSaveErr:		db	"Failed to save file!",NULL
g_szDlgFileTitle:		db	"Select file to be flashed.",NULL
g_szDlgFileFilter:		db	"*.*",NULL

g_szNfoMainExitToDOS:	db	"Quits XTIDE Universal BIOS Configurator.",NULL
g_szNfoMainLoadFile:	db	"Load BIOS file to be configured or flashed.",NULL
g_szNfoMainLoadROM:		db	"Load BIOS from EEPROM to be reconfigured.",NULL
g_szNfoMainLoadStngs:	db	"Load old XTIDE Universal BIOS settings from EEPROM.",NULL
g_szNfoMainConfigure:	db	"Configure XTIDE Universal BIOS settings.",NULL
g_szNfoMainFlash:		db	"Flash loaded BIOS image to EEPROM.",NULL


; Strings for XTIDE Universal BIOS configuration menu
g_szItemCfgBackToMain:	db	"Back to Main Menu",NULL
g_szItemCfgIde1:		db	"Primary IDE Controller",NULL
g_szItemCfgIde2:		db	"Secondary IDE Controller",NULL
g_szItemCfgIde3:		db	"Tertiary IDE Controller",NULL
g_szItemCfgIde4:		db	"Quaternary IDE Controller",NULL
g_szItemCfgIde5:		db	"Quinary IDE Controller",NULL
g_szItemCfgBootMenu:	db	"Boot menu settings",NULL
g_szItemCfgBootLoader:	db	"Boot loader type",NULL
g_szItemCfgFullMode:	db	"Full operating mode",NULL
g_szItemCfgStealSize:	db	"kiB to steal from RAM",NULL
g_szItemCfgIdeCnt:		db	"Number of IDE controllers",NULL

g_szDlgCfgFullMode:		db	"Enable full operating mode?",NULL
g_szDlgCfgStealSize:	db	"How many kiB of base memory to steal for XTIDE Universal BIOS variables (1...255)?",NULL
g_szDlgCfgIdeCnt:		db	"How many IDE controllers to manage (1...5)?",NULL

g_szNfoCfgIde:			db	"IDE controller and drive configuration.",NULL
g_szNfoCfgBootMenu:		db	"Boot menu configuration.",NULL
g_szNfoCfgBootLoader:	db	"Boot loader selection for INT 19h.",NULL
g_szNfoCfgFullMode:		db	"Full mode supports multiple controllers and has more features.",NULL
g_szNfoCfgStealSize:	db	"Number of kiB of base memory to steal for BIOS variables.",NULL
g_szNfoCfgIdeCnt:		db	"Number of IDE controllers to manage.",NULL

g_szHelpCfgFullMode:	db	"incbin goes here.",NULL
g_szHelpCfgStealSize:	db	"incbin goes here.",NULL

g_szMultichoiseCfgBootLoader:
						db	"Boot menu",LF
						db	"Drive A then C",LF
						db	"System boot loader",NULL

g_szValueCfgBootLoaderMenu:		db	"Menu",NULL
g_szValueCfgBootLoaderAthenC:	db	"A, C",NULL
g_szValueCfgBootLoaderSystem:	db	"System",NULL


; Strings for IDE Controller menu
g_szItemBackToCfgMenu:	db	"Back to Configuration Menu",NULL
g_szItemIdeMaster:		db	"Master Drive",NULL
g_szItemIdeSlave:		db	"Slave Drive",NULL
g_szItemIdeBusType:		db	"Bus type",NULL
g_szItemIdeCmdPort:		db	"Base (cmd block) address",NULL
g_szItemIdeCtrlPort:	db	"Control block address",NULL
g_szItemIdeEnIRQ:		db	"Enable interrupt",NULL
g_szItemIdeIRQ:			db	"IRQ",NULL

g_szDlgBusType:			db	"Select type of bus where Ide Controller is connected.",NULL
g_szDlgIdeCmdPort:		db	"Enter IDE command block (base port) address.",NULL
g_szDlgIdeCtrlPort:		db	"Enter IDE control block address (usually command block + 200h).",NULL
g_szDlgIdeEnIRQ:		db	"Enable interrupt?",NULL
g_szDlgIdeIRQ:			db	"Enter IRQ channel (2...7 for 8-bit controllers, 2...15 for any other controller).",NULL

g_szNfoIdeBackToCfgMenu:db	"Back to XTIDE Universal BIOS Configuration Menu.",NULL
g_szNfoIdeMaster:		db	"Settings for Master Drive.",NULL
g_szNfoIdeSlave:		db	"Settings for Slave Drive.",NULL
g_szNfoIdeBusType:		db	"Select controller bus type.",NULL
g_szNfoIdeCmdPort:		db	"IDE Controller Command Block (base port) address.",NULL
g_szNfoIdeCtrlPort:		db	"IDE Controller Control Block address. Usually Cmd Block + 200h.",NULL
g_szNfoIdeEnIRQ:		db	"Interrupt or polling mode.",NULL
g_szNfoIdeIRQ:			db	"IRQ channel to use.",NULL

g_szHelpIdeCmdPort:		db	"incbin goes here.",NULL
g_szHelpIdeCtrlPort:	db	"incbin goes here.",NULL
g_szHelpIdeEnIRQ:		db	"incbin goes here.",NULL
g_szHelpIdeIRQ:			db	"incbin goes here.",NULL

g_szMultichoiseCfgBusType:
						db	"8-bit dual port (XTIDE)",LF
						db	"8-bit single port",LF
						db	"16-bit",LF
						db	"32-bit generic",NULL

g_szValueCfgBusTypeDual8b:		db	"2x8-bit",NULL
g_szValueCfgBusTypeSingle8b:	db	"1x8-bit",NULL
g_szValueCfgBusType16b:			db	"16-bit",NULL
g_szValueCfgBusType32b:			db	"32-bit",NULL


; Strings for DRVPARAMS menu
g_szItemDrvBackToIde:	db	"Back to IDE Controller Menu",NULL
g_szItemDrvBlockMode:	db	"Block Mode Transfers",NULL
g_szItemDrvUserCHS:		db	"User specified CHS",NULL
g_szItemDrvCyls:		db	"Cylinders",NULL
g_szItemDrvHeads:		db	"Heads",NULL
g_szItemDrvSect:		db	"Sectors per track",NULL

g_szDlgDrvBlockMode:	db	"Enable Block Mode Transfers?",NULL
g_szDlgDrvUserCHS:		db	"Specify (P-)CHS parameters manually?",NULL
g_szDlgDrvCyls:			db	"Enter number of P-CHS cylinders (1...16383).",NULL
g_szDlgDrvHeads:		db	"Enter number of P-CHS heads (1...16).",NULL
g_szDlgDrvSect:			db	"Enter number of sectors per track (1...63).",NULL

g_szNfoDrvBlockMode:	db	"Transfer multiple sectors per data request.",NULL
g_szNfoDrvUserCHS:		db	"Specify (P-)CHS manually instead of autodetect.",NULL
g_szNfoDrvCyls:			db	"Number of user specified P-CHS cylinders.",NULL
g_szNfoDrvHeads:		db	"Number of user specified P-CHS heads.",NULL
g_szNfoDrvSect:			db	"Number of user specified P-CHS sectors per track.",NULL

g_szHelpDrvBlockMode:	db	"incbin goes here.",NULL
g_szHelpDrvUserCHS:		db	"incbin goes here.",NULL


; Strings for boot menu settings menu
g_szItemBootHeight:		db	"Maximum height",NULL
g_szItemBootTimeout:	db	"Selection timeout",NULL
g_szItemBootDrive:		db	"Default boot drive",NULL
g_szItemBootMinFDD:		db	"Min floppy drive count",NULL
g_szItemBootSwap:		db	"Swap boot drive numbers",NULL
g_szItemBootRomBoot:	db	"Display ROM boot",NULL
g_szItemBootInfo:		db	"Display drive info",NULL

g_szDlgBootHeight:		db	"Enter boot menu maximum height in characters (8...25).",NULL
g_szDlgBootTimeout:		db	"Enter Boot Menu selection timeout in seconds (1...60, 0 disables timeout).",NULL
g_szDlgBootDrive:		db	"Enter default drive number (0xh for Floppy Drives, 8xh for Hard Disks, FFh for ROM boot).",NULL
g_szDlgBootMinFDD:		db	"Enter minimum number of floppy drives.",NULL
g_szDlgBootSwap:		db	"Enable drive number translation?",NULL
g_szDlgBootRomBoot:		db	"Show ROM Boot option on boot menu?",NULL
g_szDlgBootInfo:		db	"Show drive information on boot menu?",NULL

g_szNfoBootHeight:		db	"Boot Menu maximum height in characters.",NULL
g_szNfoBootTimeout:		db	"Menu item selection timeout in seconds.",NULL
g_szNfoBootDrive:		db	"Default drive on boot menu.",NULL
g_szNfoBootMinFDD:		db	"Minimum number of floppy drives to display.",NULL
g_szNfoBootSwap:		db	"Drive Number Translation (swap first drive with selected).",NULL
g_szNfoBootRomBoot:		db	"Show ROM Basic or ROM DOS boot option.",NULL
g_szNfoBootInfo:		db	"Show detailed drive information on boot menu.",NULL

g_szHelpBootTimeout:	db	"incbin goes here.",NULL
g_szHelpBootDrive:		db	"incbin goes here.",NULL
g_szHelpBootMinFDD:		db	"incbin goes here.",NULL
g_szHelpBootSwap:		db	"incbin goes here.",NULL
g_szHelpBootRomBoot:	db	"incbin goes here.",NULL
g_szHelpBootInfo:		db	"incbin goes here.",NULL


; Strings for Flash menu
g_szItemFlashStart:		db	"Start flashing",NULL
g_szItemFlashSDP:		db	"SDP command",NULL
g_szItemFlashAddr:		db	"EEPROM address",NULL
g_szItemFlashPageSize:	db	"Page size",NULL
g_szItemFlashChecksum:	db	"Generate checksum byte",NULL

g_szDlgFlashAddr:		db	"Enter segment address where EEPROM is located.",NULL
g_szDlgFlashPageSize:	db	"Enter write page size (1, 2, 4, 8, 16, 32 or 64 bytes).",NULL
g_szDlgFlashChecksum:	db	"Generate checksum byte to the end of BIOS image?",NULL

g_szNfoFlashStart:		db	"Writes BIOS to EEPROM.",NULL
g_szNfoFlashSDP:		db	"Software Data Protection command.",NULL
g_szNfoFlashAddr:		db	"Address (segment) where EEPROM is located.",NULL
g_szNfoFlashPageSize:	db	"Number of bytes to write before delay.",NULL
g_szNfoFlashChecksum:	db	"Generate checksum byte to the end of BIOS image.",NULL

g_szHelpFlashSDP:		db	"incbin goes here.",NULL
g_szHelpFlashPageSize:	db	"incbin goes here.",NULL
g_szHelpFlashChecksum:	db	"incbin goes here.",NULL


; Strings for SDP command menu
g_szValueSdpNone:
g_szItemSdpNone:		db	"None",NULL
g_szValueSdpEnable:
g_szItemSdpEnable:		db	"Enable",NULL
g_szValueSdpDisable:
g_szItemSdpDisable:		db	"Disable",NULL

g_szNfoSdpNone:			db	"Do not use Software Data Protection.",NULL
g_szNfoSdpEnable:		db	"Enable Software Data Protection after flashing.",NULL
g_szNfoSdpDisable:		db	"Disable Software Data Protection after flashing.",NULL
