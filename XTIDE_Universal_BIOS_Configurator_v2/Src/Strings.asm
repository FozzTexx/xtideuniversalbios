; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	All strings.

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

; Section containing initialized data
SECTION .data

; Menu title
g_szProgramTitle:					db	"Configuration and Flashing program for XTIDE Universal BIOS v2.0.0.",LF,CR,NULL
g_szXtideUniversalBiosSignature:	db	"XTIDE205",NULL
g_szBiosIsNotLoaded:				db	"BIOS is not loaded!",NULL
g_szEEPROM:							db	"EEPROM",NULL
g_szSourceAndTypeSeparator:			db	" : ",NULL
g_szUnidentified:					db	"Unidentified",NULL
g_szUnsaved:						db	" ",SINGLE_LEFT_HORIZONTAL_TO_VERTICAL,"Unsaved",SINGLE_RIGHT_HORIZONTAL_TO_VERTICAL,NULL

; Item formatting
g_szFormatItemWithoutValue:			db	"%c%s",NULL
g_szFormatItemNameWithValue:		db	"%25s%-10S",NULL


g_szNo:								db	"No",NULL
g_szMultichoiceBooleanFlag:			db	"No",LF
g_szYes:							db	"Yes",NULL

; Exit messages
g_szDlgExitToDos:		db	"Exit to DOS?",NULL
g_szDlgSaveChanges:		db	"Do you want to save changes to XTIDE Universal BIOS image file?",NULL


; Generic dialog strings
g_szNotificationDialog:	db	"Notification.",NULL
g_szErrorDialog:		db	"Error!",NULL
g_szGenericDialogInfo:	db	"Press ENTER or ESC to close dialog.",NULL

; Flashing related strings
g_szFlashTitle:			db	"Flashing EEPROM, please wait.",NULL
g_szErrEepromTooSmall:	db	"Image is too large for selected EEPROM type!",NULL
g_szErrEepromPolling:	db	"Timeout when polling EEPROM.",LF
						db	"EEPROM was not flashed properly!",NULL
g_szErrEepromVerify:	db	"EEPROM did not return the same byte that was written.",LF
						db	"EEPROM was not flashed properly!",NULL
g_szPCFlashSuccessful:	db	"EEPROM was written successfully.",LF
						db	"Press any key to reboot.",NULL
g_szForeignFlash:		db	"EEPROM was written successfully.",NULL


; Strings for main menu
g_szItemMainExitToDOS:	db	"Exit to DOS",NULL
g_szItemMainLoadFile:	db	"Load BIOS from file",NULL
g_szItemMainLoadROM:	db	"Load BIOS from EEPROM",NULL
g_szItemMainLoadStngs:	db	"Load old settings from EEPROM",NULL
g_szItemMainConfigure:	db	"Configure XTIDE Universal BIOS",NULL
g_szItemMainFlash:		db	"Flash EEPROM",NULL
g_szItemMainSave:		db	"Save BIOS back to original file",NULL
g_szItemMainLicense:	db	"Copyright and License Information",NULL
g_szItemMainHomePage:	db	"Web Links",NULL

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
g_szNfoMainSave:		db	"Save BIOS changes back to original file from which it was loaded.",NULL
g_szNfoMainLicense:		db	"XTIDE Universal BIOS and XTIDECFG Copyright (C) 2009-2010 by Tomi Tilli, 2011-2013 by XTIDE Universal BIOS Team."
						db	" Released under GNU GPL v2, with ABSOLUTELY NO WARRANTY. Press ENTER for more details...",NULL
g_szNfoMainHomePage:	db	"Visit http://code.google.com/p/ xtideuniversalbios (home page) and http://vintage-computer.com/ vcforum (support)",NULL

g_szHelpMainLicense:	db	"XTIDE Universal BIOS and XTIDECFG Configuration program are Copyright 2009-2010 by Tomi Tilli,"
						db	" 2011-2013 by XTIDE Universal BIOS Team. Released under GNU GPL v2. This software comes with ABSOLUTELY NO WARRANTY."
						db	" This is free software, and you are welcome to redistribute it under certain conditions."
						db	" See the LICENSE.TXT file that was included with this distribution,"
						db	" visit http://www.gnu.org/licenses/ gpl-2.0.html, or visit http://code.coogle.com/p/ xtideuniversalbios.",NULL

; Strings for XTIDE Universal BIOS configuration menu
g_szItemCfgBackToMain:	db	"Back to Main Menu",NULL
g_szItemCfgIde1:		db	"Primary IDE Controller",NULL
g_szItemCfgIde2:		db	"Secondary IDE Controller",NULL
g_szItemCfgIde3:		db	"Tertiary IDE Controller",NULL
g_szItemCfgIde4:		db	"Quaternary IDE Controller",NULL
g_szItemCfgBootMenu:	db	"Boot settings",NULL
g_szItemAutoConfigure:	db	"Auto Configure",NULL
g_szItemCfgFullMode:	db	"Full operating mode",NULL
g_szItemCfgStealSize:	db	"kiB to steal from RAM",NULL
g_szItemCfgIdeCnt:		db	"IDE controllers",NULL
g_szItemCfgIdleTimeout:	db	"Power Management",NULL

g_szDlgAutoConfigure:	db	"Found "
g_bControllersDetected:	db	'x'				; Value stored directly here
						db	" controllers.",NULL
g_szDlgCfgFullMode:		db	"Enable full operating mode?",NULL
g_szDlgCfgStealSize:	db	"How many kiB of base memory to steal for XTIDE Universal BIOS variables (1...255)?",NULL
g_szDlgCfgIdeCnt:		db	"How many IDE controllers to manage (1...4)?",NULL
g_szDlgCfgIdleTimeout:	db	"Select the amount of time before idling drives should enter standby mode.",NULL

g_szNfoCfgIde:			db	"IDE controller and drive configuration.",NULL
g_szNfoCfgBootMenu:		db	"Boot configuration.",NULL
g_szNfoAutoConfigure:	db	"Automatically Configure XTIDE Universal BIOS for this system.",NULL
g_szNfoCfgFullMode:		db	"Full mode supports multiple controllers and has more features.",NULL
g_szNfoCfgStealSize:	db	"How many kiB's to steal from Conventional memory for XTIDE Universal BIOS variables.",NULL
g_szNfoCfgIdeCnt:		db	"Number of IDE controllers to manage.",NULL
g_szNfoCfgIdleTimeout:	db	"Enable Power Management to set the harddrive(s) to spin down after idling a certain amount of time.",NULL

g_szSerialMoved:		db	"A Serial Controller has been moved to the end of the Controller list."
						db	" No further action is required. Serial Controllers must be placed at the end of the list.",NULL

g_szHelpCfgFullMode:	db	"Full mode supports up to 4 IDE controllers (8 drives). Full mode reserves a bit of RAM from the top of"
						db	" Conventional memory. This makes it possible to use ROM BASIC and other software that requires"
						db	" the interrupt vectors where XTIDE Universal BIOS parameters would be stored in Lite mode.",LF,LF
						db	"Lite mode supports only one IDE controller (2 drives) and stores parameters to the top of the interrupt vectors"
						db	" (30:0h) so no Conventional memory needs to be reserved. Lite mode cannot be used if some software requires"
						db	" the top of interrupt vectors. Usually this is not a problem since only IBM ROM BASIC uses them.",LF,LF
						db	"Tandy 1000 models with 640 kiB or less memory need to use Lite mode since the top of Conventional memory gets"
						db	" dynamically reserved by video hardware. This happens only with Tandy integrated video controller and not when"
						db	" using expansion graphics cards. It is possible to use Full mode if reserving RAM for video memory + what is"
						db	" required for XTIDE Universal BIOS. This would mean 65 kiB but most software should work with 33 kiB reserved.",NULL

g_szHelpCfgStealSize:	db	"Parameters for detected hard disks must be stored somewhere. In Full mode they are stored at the top of Conventional"
						db	" memory. 1 kiB is usually enough but you may have to reserve more if you want to use Full mode on a Tandy 1000.",NULL

g_szHelpCfgIdleTimeout:	db	"This option enables the standby timer for all harddrives handled by XTIDE Universal BIOS,"
						db	" allowing the drives to spin down after idling the selected amount of time."
						db	" Note that this does not work with old drives that lack the Power Management feature set."
						db	" Also note that timeouts less than 5 minutes may cause unnecessary wear on the drives and is not recommended"
						db	" (use for compatibility testing only).",NULL

g_szMultichoiceIdleTimeout:	db	"Disabled",LF
							db	"1 m",LF
							db	"2 m",LF
							db	"3 m",LF
							db	"4 m",LF
							db	"5 m",LF
							db	"6 m",LF
							db	"7 m",LF
							db	"8 m",LF
							db	"9 m",LF
							db	"10 m",LF
							db	"11 m",LF
							db	"12 m",LF
							db	"13 m",LF
							db	"14 m",LF
							db	"15 m",LF
							db	"16 m",LF
							db	"17 m",LF
							db	"18 m",LF
							db	"19 m",LF
							db	"20 m",LF
							db	"30 m",LF
							db	"1 h",LF
							db	"1 h 30 m",LF
g_szIdleTimeoutChoice24:	db	"2 h",NULL
g_szIdleTimeoutChoice23:	db	"1 h 30 m",NULL
g_szIdleTimeoutChoice22:	db	"1 h",NULL
g_szIdleTimeoutChoice21:	db	"30 m",NULL
g_szIdleTimeoutChoice20:	db	"20 m",NULL
g_szIdleTimeoutChoice19:	db	"19 m",NULL
g_szIdleTimeoutChoice18:	db	"18 m",NULL
g_szIdleTimeoutChoice17:	db	"17 m",NULL
g_szIdleTimeoutChoice16:	db	"16 m",NULL
g_szIdleTimeoutChoice15:	db	"15 m",NULL
g_szIdleTimeoutChoice14:	db	"14 m",NULL
g_szIdleTimeoutChoice13:	db	"13 m",NULL
g_szIdleTimeoutChoice12:	db	"12 m",NULL
g_szIdleTimeoutChoice11:	db	"11 m",NULL
g_szIdleTimeoutChoice10:	db	"10 m",NULL
g_szIdleTimeoutChoice9:		db	"9 m",NULL
g_szIdleTimeoutChoice8:		db	"8 m",NULL
g_szIdleTimeoutChoice7:		db	"7 m",NULL
g_szIdleTimeoutChoice6:		db	"6 m",NULL
g_szIdleTimeoutChoice5:		db	"5 m",NULL
g_szIdleTimeoutChoice4:		db	"4 m",NULL
g_szIdleTimeoutChoice3:		db	"3 m",NULL
g_szIdleTimeoutChoice2:		db	"2 m",NULL
g_szIdleTimeoutChoice1:		db	"1 m",NULL
g_szIdleTimeoutChoice0:		db	"Disabled",NULL

; Strings for IDE Controller menu
g_szItemBackToCfgMenu:		db	"Back to Configuration Menu",NULL
g_szItemIdeMaster:			db	"Master Drive",NULL
g_szItemIdeSlave:			db	"Slave Drive",NULL
g_szItemIdeDevice:			db	"Device type",NULL
g_szItemIdeCmdPort:			db	"Base (cmd block) address",NULL
g_szItemIdeCtrlPort:		db	"Control block address",NULL
g_szItemIdeEnIRQ:			db	"Enable interrupt",NULL
g_szItemIdeIRQ:				db	"IRQ",NULL
g_szItemSerialCOM:			db	"COM Port",NULL
g_szItemSerialBaud:			db	"Baud Rate",NULL
g_szItemSerialPort:			db	"COM Port I/O address",NULL
g_szItemIdeSerialComPort:	db	"COM port",NULL
g_szItemIdeSerialBaudRate:	db	"Baud rate",NULL

g_szDlgDevice:				db	"Select controller type.",NULL
g_szDlgIdeCmdPort:			db	"Enter IDE command block (base port) address.",NULL
g_szDlgIdeCtrlPort:			db	"Enter IDE control block address (usually command block + 200h).",NULL
g_szDlgIdeEnIRQ:			db	"Enable interrupt?",NULL
g_szDlgIdeIRQ:				db	"Enter IRQ channel (2...7 for 8-bit controllers, 2...15 for any other controller).",NULL

g_szNfoIdeBackToCfgMenu:	db	"Back to XTIDE Universal BIOS Configuration Menu.",NULL
g_szNfoIdeMaster:			db	"Settings for Master Drive.",NULL
g_szNfoIdeSlave:			db	"Settings for Slave Drive.",NULL
g_szNfoIdeDevice:			db	"Select controller device type.",NULL
g_szNfoIdeCmdPort:			db	"IDE Controller Command Block (base port) address or segment address for JR-IDE/ISA and SVC ADP50L.",NULL
g_szNfoIdeCtrlPort:			db	"IDE Controller Control Block address. Usually Cmd Block + 8 for XTIDE, and Cmd Block + 200h for ATA.",NULL
g_szNfoIdeEnIRQ:			db	"Interrupt or polling mode.",NULL
g_szNfoIdeIRQ:				db	"IRQ channel to use.",NULL
g_szNfoIdeSerialCOM:		db	"Select a COM port by number.",NULL
g_szNfoIdeSerialBaud:		db	"Select the COM port's Baud Rate. The server must match this speed."
							db	" Note that UART clock multipliers may impact the actual speed.",NULL
g_szNfoIdeSerialPort:		db	"Select a COM port by custom I/O port address. Any address is valid up to 3F8h, but must be on an 8-byte boundary.",NULL

g_szHelpIdeCmdPort:			db	"IDE controller command block address is the usual address mentioned for IDE controllers."
							db	" By default the primary IDE controller uses port 1F0h and secondary controller uses port 170h."
							db	" XTIDE card uses port 300h by default."
							db	" JR-IDE/ISA and SVC ADP50L do not use ports but needs the ROM segment address set here instead.",NULL

g_szHelpIdeCtrlPort:		db	"IDE controller Control Block address is normally Command Block address + 200h."
							db	" For XTIDE card the Control Block registers are mapped right after Command Block"
							db	" registers so use Command Block address + 8h for XTIDE card.",NULL

g_szHelpIdeEnIRQ:			db	"IDE controller can use interrupts to signal when it is ready to transfer data."
							db	" This makes possible to do other tasks while waiting drive to be ready."
							db	" That is usually not useful in MS-DOS but using interrupts frees the bus for any DMA transfers."
							db	" Polling mode is used when interrupts are disabled."
							db	" Polling usually gives a little better access times since interrupt handling requires extra processing."
							db	" There can be some compatibility issues with some old drives when polling is used with Block Mode transfers.",NULL

g_szHelpIdeIRQ:				db	"IRQ channel to use. All controllers managed by XTIDE Universal BIOS can use the same IRQ when MS-DOS is used."
							db	" Other operating systems are likely to require different interrupts for each controller.",NULL

g_szHelpIdeSerialCOM:		db	"Select a serial port by COM port number. COM1 through COM4 have well established I/O port assignments,"
							db	' COM5 and onward are less well established. "COMA" represents COM10, "COMB" represents COM11, and "COMC"'
							db	' represents COM12. Selecting "COMx" enables the manual selection of an I/O port address.',NULL

g_szHelpIdeSerialPort:		db	"Select a serial port by I/O address. Any port address is supported up to 3F8h, but must be on an 8-byte boundary."
							db	" If the entered value corresponds to one of the established COM port numbers, then the selection will snap"
							db	' to that COM port and "COMx" must be selected again for custom I/O address entry.',NULL

g_szHelpIdeSerialBaud:		db	"Supported baud rates are 2400, 4800, 9600, 19.2K, 28.8K, 38.4K, 57.6K, and 115.2K. The server must also be set to"
							db	" this same speed. Older UARTs may only support up to 9600 baud, but sometimes can be pushed to 38.4K. 115.2K will"
							db	" likely only be possible with a newer UART that includes a FIFO. Some high speed serial ports include UART clock"
							db	" multipliers, allowing for speeds at 230.4K (2x multiplier) and 460.8K (4x multiplier) above 115.2K. These high"
							db	" speeds are supported by these BIOS, even on original 4.77MHz 8088 systems. Note that UART clock multipliers are"
							db	" not detectable by the software and 115.2K will still be used during configuration for high speeds; but if"
							db	" a multiplier is used, the actual speed (including the multiplier) will need to be used by the server.",NULL

g_szMultichoiceCfgDevice:	db	"16-bit ISA/VLB/PCI IDE",LF
							db	"32-bit VLB/PCI IDE",LF
							db	"16-bit ISA IDE in 8-bit mode",LF
							db	"XTIDE rev 1",LF
							db	"XTIDE rev 2 or modded rev 1",LF
							db	"XT-CF (PIO)",LF
							db	"XT-CF (PIO8 w/BIU offload)",LF
							db	"XT-CF (PIO16 w/BIU offload)",LF
							db	"XT-CF DMA (v3 only)",LF
							db	"JR-IDE/ISA",LF
							db	"SVC ADP50L",LF
							db	"Serial port virtual device",NULL

g_szValueCfgDevice16b:						db	"16-bit",NULL
g_szValueCfgDevice32b:						db	"32-bit",NULL
g_szValueCfgDevice8b:						db	"8-bit",NULL
g_szValueCfgDeviceRev1:						db	"XTIDE r1",NULL
g_szValueCfgDeviceRev2:						db	"XTIDE r2",NULL
g_szValueCfgDeviceXTCFPio8:					db	"XTCF PIO",NULL
g_szValueCfgDeviceXTCFPio8WithBIUOffload:	db	"BIU 8",NULL
g_szValueCfgDeviceXTCFPio16WithBIUOffload:	db	"BIU 16",NULL
g_szValueCfgDeviceXTCFDMA:					db	"XTCF DMA",NULL
g_szValueCfgDeviceJrIdeIsa:					db	"JR-ISA",NULL
g_szValueCfgDeviceADP50L:					db	"ADP50L",NULL
g_szValueCfgDeviceSerial:					db	"Serial",NULL

g_szSerialCOMChoice:	db	"COM1 - address 3F8h",LF
						db	"COM2 - address 2F8h",LF
						db	"COM3 - address 3E8h",LF
						db	"COM4 - address 2E8h",LF
						db	"COM5 - address 2F0h",LF
						db	"COM6 - address 3E0h",LF
						db	"COM7 - address 2E0h",LF
						db	"COM8 - address 260h",LF
						db	"COM9 - address 368h",LF
						db	"COMA - address 268h",LF
						db	"COMB - address 360h",LF
						db	"COMC - address 270h",LF
						db	"COMx - Custom address",NULL

g_szValueCfgCOM1:		db	"COM1",NULL
g_szValueCfgCOM2:		db	"COM2",NULL
g_szValueCfgCOM3:		db	"COM3",NULL
g_szValueCfgCOM4:		db	"COM4",NULL
g_szValueCfgCOM5:		db	"COM5",NULL
g_szValueCfgCOM6:		db	"COM6",NULL
g_szValueCfgCOM7:		db	"COM7",NULL
g_szValueCfgCOM8:		db	"COM8",NULL
g_szValueCfgCOM9:		db	"COM9",NULL
g_szValueCfgCOMA:		db	"COMA",NULL
g_szValueCfgCOMB:		db	"COMB",NULL
g_szValueCfgCOMC:		db	"COMC",NULL
g_szValueCfgCOMx:		db	"Custom",NULL

g_szSerialBaudChoice:	db	"115.2K baud",LF
						db	"57.6K baud",LF
						db	"38.4K baud",LF
						db	"28.8K baud",LF
						db	"19.2K baud",LF
						db	"9600 baud",LF
						db	"4800 baud",LF
						db	"2400 baud",NULL

g_szValueCfgBaud115_2:	db	"115.2K",NULL
g_szValueCfgBaud57_6:	db	"57.6K",NULL
g_szValueCfgBaud38_4:	db	"38.4K",NULL
g_szValueCfgBaud28_8:	db	"28.8K",NULL
g_szValueCfgBaud19_2:	db	"19.2K",NULL
g_szValueCfgBaud9600:	db	"9600",NULL
g_szValueCfgBaud4800:	db	"4800",NULL
g_szValueCfgBaud2400:	db	"2400",NULL


; Strings for DRVPARAMS menu
g_szItemDrvBackToIde:	db	"Back to IDE Controller Menu",NULL
g_szItemDrvBlockMode:	db	"Block Mode Transfers",NULL
g_szItemDrvXlateMode:	db	"CHS translation method",NULL
g_szItemDrvWriteCache:	db	"Internal Write Cache",NULL
g_szItemDrvUserCHS:		db	"User specified CHS",NULL
g_szItemDrvCyls:		db	"Cylinders",NULL
g_szItemDrvHeads:		db	"Heads",NULL
g_szItemDrvSect:		db	"Sectors per track",NULL
g_szItemDrvUserLBA:		db	"User specified LBA",NULL
g_szItemDrvLbaSectors:	db	"Millions of sectors",NULL

g_szDlgDrvBlockMode:	db	"Enable Block Mode Transfers?",NULL
g_szDlgDrvXlateMode:	db	"Select P-CHS to L-CHS translation method.",NULL
g_szDlgDrvWriteCache:	db	"Select hard drive internal write cache settings.",NULL
g_szDlgDrvUserCHS:		db	"Specify (P-)CHS parameters manually?",NULL
g_szDlgDrvCyls:			db	"Enter number of P-CHS cylinders (1...16383).",NULL
g_szDlgDrvHeads:		db	"Enter number of P-CHS heads (1...16).",NULL
g_szDlgDrvSect:			db	"Enter number of sectors per track (1...63).",NULL
g_szDlgDrvUserLBA:		db	"Limit drive capacity?",NULL
g_szDlgDrvLbaSectors:	db	"Enter maximum capacity in millions of sectors (16...256).",NULL

g_szNfoDrvBlockMode:	db	"Transfer multiple sectors per data request.",NULL
g_szNfoDrvXlateMode:	db	"P-CHS to L-CHS translation method.",NULL
g_szNfoDrvWriteCache:	db	"Hard Drive Internal Write Cache settings (WARNING!).",NULL
g_szNfoDrvUserCHS:		db	"Specify (P-)CHS parameters manually instead of autodetecting them.",NULL
g_szNfoDrvCyls:			db	"Number of user specified P-CHS cylinders.",NULL
g_szNfoDrvHeads:		db	"Number of user specified P-CHS heads.",NULL
g_szNfoDrvSect:			db	"Number of user specified P-CHS sectors per track.",NULL
g_szNfoDrvUserLBA:		db	"Limit drive capacity to fix compatibility problems with Windows 9x.",NULL
g_szNfoDrvLbaSectors:	db	"Millions of sectors (1024*1024). 1M sectors = 512 MiB. Recommended limits are 64 for Windows 95, 128 for Windows 98 and 256 for Windows ME (and 98 with updated fdisk).",NULL

g_szHelpDrvBlockMode:	db	"Block Mode will speed up transfers since multiple sectors can be transferred before waiting next data request."
						db	" Normally Block Mode should always be kept enabled but there is at"
						db	" least one drive with buggy Block Mode implementation.",NULL

g_szHelpDrvWriteCache:	db	"Modern Hard Drives have a large amount of internal write cache."
						db	" The cache will speed up writes since the drive can free the bus right after data has been written to cache."
						db	" The drive then starts to write the data from cache to disk by itself."
						db	" This can be dangerous since all unwritten data in cache is lost if power is turned off or the system is reset."
						db	" Modern operating systems will flush the cache when user shuts down the system."
						db	" DOS does not have that sort of protection so it is up to the user to make sure cache is flushed."
						db	" WARNING!!! Write cache should be left disabled.",NULL

g_szHelpDrvUserCHS:		db	"Specify (P-)CHS parameters manually instead of autodetecting them."
						db	" This can be used to limit drive size for old operating systems that do not support large hard disks."
						db	" Some early IDE drives have buggy autodetection so they require CHS to be specified manually."
						db	" Limiting Cylinders will work for all drives but drives may not accept all values for Heads and Sectors per Track.",NULL

g_szHelpDrvUserLBA:		db	"Limit drive size to X million sectors for EBIOS functions. This option is useful to"
						db	" prevent large drive compatibility problems with MS-DOS 7.x (Windows 95 and 98).",NULL

g_szMultichoiseXlateMode:
						db	"NORMAL",LF
						db	"LARGE",LF
						db	"Assisted LBA",LF
						db	"Autodetect",NULL

g_szValueDrvXlateNormal:db	"NORMAL",NULL
g_szValueDrvXlateLarge:	db	"LARGE",NULL
g_szValueDrvXlateLBA:	db	"LBA",NULL
g_szValueDrvXlateAuto:	db	"Auto",NULL

g_szMultichoiseWrCache:	db	"Drive Default",LF
						db	"Disable Write Cache",LF
						db	"Enable Write Cache",NULL

g_szValueDrvWrCaDis:	db	"Disabled",NULL
g_szValueDrvWrCaEn:		db	"Enabled",NULL


; Strings for boot settings menu
g_szItemBootTimeout:	db	"Selection timeout",NULL
g_szItemBootDrive:		db	"Default boot drive",NULL
g_szItemBootDispMode:	db	"Display Mode",NULL
g_szItemBootFloppyDrvs:	db	"Number of Floppy Drives",NULL
g_szItemSerialDetect:	db	"Scan for Serial Drives",NULL

g_szDlgBootTimeout:		db	"Enter Boot Menu selection timeout in BIOS timer ticks (2...1092).",NULL
g_szDlgBootDrive:		db	"Enter default drive number (0xh for Floppy Drives, 8xh for Hard Disks).",NULL
g_szDlgBootDispMode:	db	"Select display mode.",NULL
g_szDlgBootFloppyDrvs:	db	"Select number of Floppy Drives in system.",NULL
g_szDlgSerialDetect:	db	"Scan for serial drives?",NULL

g_szNfoBootTimeout:		db	"Menu item selection timeout in BIOS timer ticks. 1 tick = 54.9 ms.",NULL
g_szNfoBootDrive:		db	"Default boot drive.",NULL
g_szNfoDispMode:		db	"Display mode to set when booting.",NULL
g_szNfoBootFloppyDrvs:	db	"Number of Floppy Drives in system.",NULL
g_szNfoSerialDetect:	db	"Scans all standard COM ports for serial drives."
						db	" This can also be invoked by holding down ALT at the end of normal drive detection.",NULL

g_szHelpBootTimeout:	db	"Boot Menu selection timeout in BIOS timer ticks (1 second = 18.2 ticks)."
						db	" When timer goes to zero, currently selected drive will be booted automatically."
						db	" Timeout can be disabled by setting this to 0.",NULL

g_szHelpBootDrive:		db	"Drive to be set selected by default when Boot Menu is displayed.",NULL

g_szHelpBootFloppyDrvs:	db	"Detecting the correct number of floppy drives might fail when using a floppy controller with its own BIOS."
						db	" A minimum number of floppy drives can be specified to force non-detected drives to appear on boot menu.",NULL

g_szHelpSerialDetect:	db	"Set to Yes, at the end of normal drive detection, COM ports 1-7 (in reverse order) will be scanned for a connection"
						db	" to a serial drive server. This option provides flexibility with the COM port and baud rate to be used,"
						db	" it need not be configured ahead of time, but at the expense of a slower boot process."
						db	" Even when this option is set to No, this functionality can still be invoked by holding down the ALT key at the end"
						db	" of normal drive detection. Note that if any serial drives are detected during the normal drive detection,"
						db	" no scan will take place (to avoid finding the same drive twice).",NULL

g_szMultichoiceBootDispMode:	db	"Default",LF
								db	"40x25 Black & White",LF
								db	"40x25 Color",LF
								db	"80x25 Black & White",LF
								db	"80x25 Color",LF
								db	"80x25 Monochrome",NULL

g_szValueBootDispModeDefault:	db	"Default",NULL
g_szValueBootDispModeBW40:		db	"BW40",NULL
g_szValueBootDispModeCO40:		db	"CO40",NULL
g_szValueBootDispModeBW80:		db	"BW80",NULL
g_szValueBootDispModeCO80:		db	"CO80",NULL
g_szValueBootDispModeMono:		db	"Mono",NULL

g_szMultichoiceBootFloppyDrvs:	db	"Autodetect",LF
								db	"1",LF
								db	"2",LF
								db	"3",LF
g_szValueBootFloppyDrvs4:		db	"4",NULL
g_szValueBootFloppyDrvs3:		db	"3",NULL
g_szValueBootFloppyDrvs2:		db	"2",NULL
g_szValueBootFloppyDrvs1:		db	"1",NULL
g_szValueBootFloppyDrvsAuto:	db	"Auto",NULL


; Strings for Flash menu
g_szItemFlashStart:		db	"Start flashing",NULL
g_szItemFlashEepromType:db	"EEPROM type",NULL
g_szItemFlashSDP:		db	"SDP command",NULL
g_szItemFlashAddr:		db	"EEPROM address",NULL
g_szItemFlashPageSize:	db	"Page size",NULL
g_szItemFlashChecksum:	db	"Generate checksum byte",NULL

g_szDlgFlashEepromType:	db	"Select EEPROM type.",NULL
g_szDlgFlashSDP:		db	"Select Software Data Protection command.",NULL
g_szDlgFlashAddr:		db	"Enter segment address where EEPROM is located.",NULL
g_szDlgFlashPageSize:	db	"Select write page size.",NULL
g_szDlgFlashChecksum:	db	"Generate checksum byte to the end of BIOS image?",NULL

g_szNfoFlashEepromType:	db	"EEPROM type.",NULL
g_szNfoFlashStart:		db	"Writes BIOS to EEPROM.",NULL
g_szNfoFlashSDP:		db	"Software Data Protection command.",NULL
g_szNfoFlashAddr:		db	"Address (segment) where EEPROM is located.",NULL
g_szNfoFlashPageSize:	db	"Number of bytes to write before delay.",NULL
g_szNfoFlashChecksum:	db	"Generate checksum byte to the end of BIOS image.",NULL

g_szHelpFlashSDP:		db	"Software Data Protection Command:",LF
						db	"None    = Do not use Software Data Protection. Meant for EEPROMs that do not support SDP.",LF,LF
						db	"Enable  = Write protects the EEPROM after flashing."
						db	" Software Data Protection should always be enabled if EEPROM supports it.",LF,LF
						db	"Disable = Disables Software Data Protection after flashing.",NULL

g_szHelpFlashPageSize:	db	"Larger page size will improve write performance but not all EEPROMs support large pages or page writing at all."
						db	" Byte writing mode will be used when page size is set to 1. Byte writing mode is supported by all EEPROMs."
						db	" Large pages cannot be flashed with slow CPUs.",NULL

g_szHelpFlashChecksum:	db	"PC BIOSes require a checksum byte at the end of expansion card BIOS ROMs."
						db	" You might not want to generate checksum byte when flashing some other images than XTIDE Universal BIOS.",NULL

g_szMultichoiceEepromType:
						db	"2816 (2 kiB)",LF
						db	"2864 (8 kiB)",LF
						db	"2864 mod (8 kiB)",LF
						db	"28256 (32 kiB)",LF
						db	"28512 (64 kiB)",NULL
g_szValueFlash2816:		db	"2816",NULL
g_szValueFlash2864:		db	"2864",NULL
g_szValueFlash2864Mod:	db	"2864mod",NULL
g_szValueFlash28256:	db	"28256",NULL
g_szValueFlash28512:	db	"28512",NULL

g_szMultichoiceSdpCommand:
						db	"None",LF
						db	"Enable",LF
g_szValueFlashDisable:	db	"Disable",NULL
g_szValueFlashEnable:	db	"Enable",NULL
g_szValueFlashNone:		db	"None",NULL

g_szMultichoicePageSize:
						db	"1 byte",LF
						db	"2 bytes",LF
						db	"4 bytes",LF
						db	"8 bytes",LF
						db	"16 bytes",LF
						db	"32 bytes",LF
g_szValueFlash64bytes:	db	"64 bytes",NULL
g_szValueFlash32bytes:	db	"32 bytes",NULL
g_szValueFlash16bytes:	db	"16 bytes",NULL
g_szValueFlash8bytes:	db	"8 bytes",NULL
g_szValueFlash4bytes:	db	"4 bytes",NULL
g_szValueFlash2bytes:	db	"2 bytes",NULL
g_szValueFlash1byte:	db	"1 byte",NULL

g_szSelectionTimeout:	db	DOUBLE_BOTTOM_LEFT_CORNER,DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL,"%ASelection in %2u s",NULL
g_szDashForZero:		db	"- ",NULL
g_szValueUnknownError:	db	"Error!",NULL

