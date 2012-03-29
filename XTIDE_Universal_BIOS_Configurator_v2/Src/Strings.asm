; Project name	:	XTIDE Universal BIOS Configurator v2
; Description	:	All strings.

; Section containing initialized data
SECTION .data

; Menu title
g_szProgramTitle:
	db	"Configuration and Flashing program for XTIDE Universal BIOS v2.0.0.",LF,CR,NULL
g_szXtideUniversalBiosSignature:	db	"XTIDE200",NULL
g_szBiosIsNotLoaded:				db	"BIOS is not loaded!",NULL
g_szEEPROM:							db	"EEPROM",NULL
g_szSourceAndTypeSeparator:			db	" : ",NULL
g_szUnidentified:					db	"Unidentified",NULL
g_szUnsaved:						db	" ",SINGLE_LEFT_HORIZONTAL_TO_VERTICAL,
									db	"Unsaved",SINGLE_RIGHT_HORIZONTAL_TO_VERTICAL,NULL

; Item formatting
g_szFormatItemWithoutValue:			db	"%c%s",NULL
g_szFormatItemNameWithValue:		db	"%25s%-10S",NULL


g_szNo:								db	"No",NULL
g_szMultichoiceBooleanFlag:
									db	"No",LF
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
g_szItemMainLicense:	db  "Copyright and License Information",NULL
g_szItemMainHomePage:	db  "Web Links",NULL

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
g_szNfoMainLicense:		db	"XTIDE Universal BIOS and XTIDECFG Copyright (C) 2009-2010 by Tomi Tilli, 2011-2012 by XTIDE Universal BIOS Team. Released under GNU GPL v2, with ABSOLUTELY NO WARRANTY. Press ENTER for more details...",NULL
g_szNfoMainHomePage:	db	"Visit http://code.google.com/p/ xtideuniversalbios (home page) and http://vintage-computer.com/ vcforum (support)",NULL

g_szHelpMainLicense:	incbin	"Main_License.txt" 
						db	NULL		

; Strings for XTIDE Universal BIOS configuration menu
g_szItemCfgBackToMain:	db	"Back to Main Menu",NULL
g_szItemCfgIde1:		db	"Primary IDE Controller",NULL
g_szItemCfgIde2:		db	"Secondary IDE Controller",NULL
g_szItemCfgIde3:		db	"Tertiary IDE Controller",NULL
g_szItemCfgIde4:		db	"Quaternary IDE Controller",NULL
g_szItemCfgBootMenu:	db	"Boot settings",NULL
g_szItemCfgFullMode:	db	"Full operating mode",NULL
g_szItemCfgStealSize:	db	"kiB to steal from RAM",NULL
g_szItemCfgIdeCnt:		db	"IDE controllers",NULL

g_szDlgCfgFullMode:		db	"Enable full operating mode?",NULL
g_szDlgCfgStealSize:	db	"How many kiB of base memory to steal for XTIDE Universal BIOS variables (1...255)?",NULL
g_szDlgCfgIdeCnt:		db	"How many IDE controllers to manage (1...4)?",NULL

g_szNfoCfgIde:			db	"IDE controller and drive configuration.",NULL
g_szNfoCfgBootMenu:		db	"Boot configuration.",NULL
g_szNfoCfgFullMode:		db	"Full mode supports multiple controllers and has more features.",NULL
g_szNfoCfgStealSize:	db	"How many kiB's to steal from Conventional memory for XTIDE Universal BIOS variables.",NULL
g_szNfoCfgIdeCnt:		db	"Number of IDE controllers to manage.",NULL

g_szSerialMoved:		db  "A Serial Controller has been moved to the end of the Controller list. No further action is required. Serial Controllers must be placed at the end of the list.",NULL

g_szHelpCfgFullMode:	incbin	"Configuration_FullMode.txt"
						db	NULL
g_szHelpCfgStealSize:	incbin	"Configuration_StealSize.txt"
						db	NULL

; Strings for IDE Controller menu
g_szItemBackToCfgMenu:	db	"Back to Configuration Menu",NULL
g_szItemIdeMaster:		db	"Master Drive",NULL
g_szItemIdeSlave:		db	"Slave Drive",NULL
g_szItemIdeDevice:		db	"Device type",NULL
g_szItemIdeCmdPort:		db	"Base (cmd block) address",NULL
g_szItemIdeCtrlPort:	db	"Control block address",NULL
g_szItemIdeEnIRQ:		db	"Enable interrupt",NULL
g_szItemIdeIRQ:			db	"IRQ",NULL
g_szItemSerialCOM:		db	"COM Port",NULL
g_szItemSerialBaud:		db	"Baud Rate",NULL
g_szItemSerialPort:		db	"COM Port I/O address",NULL

g_szItemIdeSerialComPort:		db		"COM port",NULL
g_szItemIdeSerialBaudRate:		db		"Baud rate",NULL

g_szDlgDevice:			db	"Select controller type.",NULL
g_szDlgIdeCmdPort:		db	"Enter IDE command block (base port) address.",NULL
g_szDlgIdeCtrlPort:		db	"Enter IDE control block address (usually command block + 200h).",NULL
g_szDlgIdeEnIRQ:		db	"Enable interrupt?",NULL
g_szDlgIdeIRQ:			db	"Enter IRQ channel (2...7 for 8-bit controllers, 2...15 for any other controller).",NULL

g_szNfoIdeBackToCfgMenu:db	"Back to XTIDE Universal BIOS Configuration Menu.",NULL
g_szNfoIdeMaster:		db	"Settings for Master Drive.",NULL
g_szNfoIdeSlave:		db	"Settings for Slave Drive.",NULL
g_szNfoIdeDevice:		db	"Select controller device type.",NULL
g_szNfoIdeCmdPort:		db	"IDE Controller Command Block (base port) address.",NULL
g_szNfoIdeCtrlPort:		db	"IDE Controller Control Block address. Usually Cmd Block + 8 for XTIDE, and Cmd Block + 200h for ATA.",NULL
g_szNfoIdeEnIRQ:		db	"Interrupt or polling mode.",NULL
g_szNfoIdeIRQ:			db	"IRQ channel to use.",NULL
g_szNfoIdeSerialCOM:	db	"Select a COM port by number.",NULL
g_szNfoIdeSerialBaud:	db	"Select the COM port's Baud Rate. The server must match this speed. Note that UART clock multipliers may impact the actual speed.",NULL
g_szNfoIdeSerialPort:	db	"Select a COM port by custom I/O port address. Any address is valid up to 3f8h, but must be on an 8-byte boundary.",NULL

g_szHelpIdeCmdPort:		incbin	"IDE_CommandPort.txt"
						db	NULL
g_szHelpIdeCtrlPort:	incbin	"IDE_ControlPort.txt"
						db	NULL
g_szHelpIdeEnIRQ:		incbin	"IDE_EnableInterrupt.txt"
						db	NULL
g_szHelpIdeIRQ:			incbin	"IDE_IRQ.txt"
						db	NULL
g_szHelpIdeSerialCOM:	incbin  "IDE_SerialCOM.txt"
						db	NULL
g_szHelpIdeSerialPort:	incbin  "IDE_SerialPort.txt"
						db  NULL
g_szHelpIdeSerialBaud:	incbin  "IDE_SerialBaud.txt"
						db  NULL

g_szMultichoiceCfgDevice:
						db	"XTIDE rev 1",LF
						db	"XTIDE rev 2 or modded rev 1",LF
						db	"Fast XTIDE (CPLD v2 project)",LF
						db	"16-bit ISA/VLB/PCI IDE",LF
						db	"32-bit VLB/PCI IDE",LF
						db	"Serial port virtual device",LF
						db	"JR-IDE/ISA",NULL

g_szSerialCOMChoice:
						db  "COM1 - address 3f8h",LF
						db	"COM2 - address 2f8h",LF
						db  "COM3 - address 3e8h",LF
						db  "COM4 - address 2e8h",LF
						db  "COM5 - address 2f0h",LF
						db  "COM6 - address 3e0h",LF
						db	"COM7 - address 2e0h",LF
						db	"COM8 - address 260h",LF
						db	"COM9 - address 368h",LF
						db	"COMA - address 268h",LF
						db	"COMB - address 360h",LF
						db	"COMC - address 270h",LF
						db  "COMx - Custom address",NULL

g_szValueCfgCOM1:		db		"COM1",NULL
g_szValueCfgCOM2:		db		"COM2",NULL
g_szValueCfgCOM3:		db		"COM3",NULL
g_szValueCfgCOM4:		db		"COM4",NULL
g_szValueCfgCOM5:		db		"COM5",NULL
g_szValueCfgCOM6:		db		"COM6",NULL
g_szValueCfgCOM7:		db		"COM7",NULL
g_szValueCfgCOM8:		db		"COM8",NULL
g_szValueCfgCOM9:		db		"COM9",NULL
g_szValueCfgCOMA:		db		"COMA",NULL
g_szValueCfgCOMB:		db		"COMB",NULL
g_szValueCfgCOMC:		db		"COMC",NULL
g_szValueCfgCOMx:		db		"Custom",NULL

g_szSerialBaudChoice:
						db  "115.2K baud",LF
						db  "57.6K baud",LF
						db	"38.4K baud",LF
						db  "28.8K baud",LF
						db  "19.2K baud",LF
						db	"9600 baud",LF
						db  "4800 baud",LF
						db  "2400 baud",NULL

g_szValueCfgBaud115_2:	db		"115.2K",NULL
g_szValueCfgBaud57_6:	db		"57.6K",NULL
g_szValueCfgBaud38_4:	db		"38.4K",NULL
g_szValueCfgBaud28_8:	db		"28.8K",NULL
g_szValueCfgBaud19_2:	db		"19.2K",NULL
g_szValueCfgBaud9600:	db		"9600",NULL
g_szValueCfgBaud4800:	db		"4800",NULL
g_szValueCfgBaud2400:	db		"2400",NULL


g_szValueCfgDeviceRev1:		db	"XTIDE r1",NULL
g_szValueCfgDeviceRev2:		db	"XTIDE r2",NULL
g_szValueCfgDeviceFast:		db	"Fast XT",NULL
g_szValueCfgDevice16b:		db	"16-bit",NULL
g_szValueCfgDevice32b:		db	"32-bit",NULL
g_szValueCfgDeviceSerial:	db	"Serial",NULL
g_szValueCfgDeviceJrIdeIsa:	db	"JR-ISA",NULL


; Strings for DRVPARAMS menu
g_szItemDrvBackToIde:	db	"Back to IDE Controller Menu",NULL
g_szItemDrvBlockMode:	db	"Block Mode Transfers",NULL
g_szItemDrvWriteCache:	db	"Internal Write Cache",NULL
g_szItemDrvUserCHS:		db	"User specified CHS",NULL
g_szItemDrvCyls:		db	"Cylinders",NULL
g_szItemDrvHeads:		db	"Heads",NULL
g_szItemDrvSect:		db	"Sectors per track",NULL
g_szItemDrvUserLBA:		db	"User specified LBA",NULL
g_szItemDrvLbaSectors:	db	"Millions of sectors",NULL

g_szDlgDrvBlockMode:	db	"Enable Block Mode Transfers?",NULL
g_szDlgDrvWriteCache:	db	"Select hard drive internal write cache settings.",NULL
g_szDlgDrvUserCHS:		db	"Specify (P-)CHS parameters manually?",NULL
g_szDlgDrvCyls:			db	"Enter number of P-CHS cylinders (1...16383).",NULL
g_szDlgDrvHeads:		db	"Enter number of P-CHS heads (1...16).",NULL
g_szDlgDrvSect:			db	"Enter number of sectors per track (1...63).",NULL
g_szDlgDrvUserLBA:		db	"Limit drive capacity?",NULL
g_szDlgDrvLbaSectors:	db	"Enter maximum capacity in millions of sectors (1...256).",NULL

g_szNfoDrvBlockMode:	db	"Transfer multiple sectors per data request.",NULL
g_szNfoDrvWriteCache:	db	"Hard Drive Internal Write Cache settings (WARNING!).",NULL
g_szNfoDrvUserCHS:		db	"Specify (P-)CHS parameters manually instead of autodetecting them.",NULL
g_szNfoDrvCyls:			db	"Number of user specified P-CHS cylinders.",NULL
g_szNfoDrvHeads:		db	"Number of user specified P-CHS heads.",NULL
g_szNfoDrvSect:			db	"Number of user specified P-CHS sectors per track.",NULL
g_szNfoDrvUserLBA:		db	"Limit drive capacity to X million sectors.",NULL
g_szNfoDrvLbaSectors:	db	"Millions of sectors (1024*1024). 1M sectors = 512 MiB.",NULL

g_szHelpDrvBlockMode:	incbin	"Drive_BlockMode.txt"
						db	NULL
g_szHelpDrvWriteCache:	incbin	"Drive_WriteCache.txt"
						db	NULL
g_szHelpDrvUserCHS:		incbin	"Drive_UserCHS.txt"
						db	NULL
g_szHelpDrvUserLBA:		incbin	"Drive_UserLBA.txt"
						db	NULL
						
g_szMultichoiseWrCache:	db	"Drive Default",LF
						db	"Disable Write Cache",LF
						db	"Enable Write Cache",NULL

g_szValueDrvWrCaDis:	db	"Disabled",NULL
g_szValueDrvWrCaEn:		db	"Enabled",NULL


; Strings for boot settings menu
g_szItemBootEnableMenu:	db	"Boot Menu",NULL
g_szItemBootTimeout:	db	"Selection timeout",NULL
g_szItemBootDrive:		db	"Default boot drive",NULL
g_szItemBootDispMode:	db	"Display Mode",NULL
g_szItemBootFloppyDrvs:	db	"Number of Floppy Drives",NULL
g_szItemBootSwap:		db	"Swap boot drive numbers",NULL
g_szItemSerialDetect:	db	"Scan for Serial Drives",NULL

g_szDlgBootEnableMenu:	db	"Enable Boot Menu?",NULL
g_szDlgBootTimeout:		db	"Enter Boot Menu selection timeout in BIOS timer ticks (2...1092).",NULL
g_szDlgBootDrive:		db	"Enter default drive number (0xh for Floppy Drives, 8xh for Hard Disks, FFh for ROM boot).",NULL
g_szDlgBootDispMode:	db	"Select display mode for Boot Menu.",NULL
g_szDlgBootFloppyDrvs:	db	"Select number of Floppy Drives to display on boot menu.",NULL
g_szDlgBootSwap:		db	"Enable drive number translation?",NULL
g_szDlgSerialDetect:	db	"Scan for serial drives?",NULL

g_szNfoBootEnableMenu:	db	"Enable to display boot drive selection menu.",NULL
g_szNfoBootTimeout:		db	"Menu item selection timeout in BIOS timer ticks. 1 tick = 54.9 ms.",NULL
g_szNfoBootDrive:		db	"Default drive on boot menu.",NULL
g_szNfoDispMode:		db	"Display Mode for Boot Menu.",NULL
g_szNfoBootFloppyDrvs:	db	"Number of Floppy Drives to display on boot menu.",NULL
g_szNfoBootSwap:		db	"Drive Number Translation (swap first drive with selected).",NULL
g_szNfoSerialDetect:	db	"Scans all standard COM ports for serial drives. This can also be invoked by holding down ALT at the end of normal drive detection.",NULL

g_szHelpBootTimeout:	incbin	"Bootmenu_Timeout.txt"
						db	NULL
g_szHelpBootDrive:		incbin	"Bootmenu_DefaultDrive.txt"
						db	NULL
g_szHelpBootFloppyDrvs:	incbin	"Bootmenu_FloppyDrives.txt"
						db	NULL
g_szHelpBootSwap:		incbin	"Bootmenu_SwapDrives.txt"
						db	NULL
g_szHelpSerialDetect:	incbin  "Bootmenu_SerialDetect.txt"
						db  NULL

g_szMultichoiceBootDispMode:
						db	"Default",LF
						db	"40x25 Black & White",LF
						db	"40x25 Color",LF
						db	"80x25 Black & White",LF
						db	"80x25 Color",LF
						db	"80x25 Monochrome",NULL

g_szMultichoiceBootFloppyDrvs:
						db	"Autodetect",LF
						db	"1",LF
						db	"2",LF
						db	"3",LF
						db	"4",NULL

g_szValueBootDispModeDefault:	db	"Default",NULL
g_szValueBootDispModeBW40:		db	"BW40",NULL
g_szValueBootDispModeCO40:		db	"CO40",NULL
g_szValueBootDispModeBW80:		db	"BW80",NULL
g_szValueBootDispModeCO80:		db	"CO80",NULL
g_szValueBootDispModeMono:		db	"Mono",NULL

g_szValueBootFloppyDrvsAuto:	db	"Auto",NULL
g_szValueBootFloppyDrvs1:		db	"1",NULL
g_szValueBootFloppyDrvs2:		db	"2",NULL
g_szValueBootFloppyDrvs3:		db	"3",NULL
g_szValueBootFloppyDrvs4:		db	"4",NULL


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

g_szHelpFlashSDP:		incbin	"Flash_SdpCommand.txt"
						db	NULL
g_szHelpFlashPageSize:	incbin	"Flash_PageSize.txt"
						db	NULL
g_szHelpFlashChecksum:	incbin	"Flash_Checksum.txt"
						db	NULL

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
g_szValueFlashNone:		db	"None",NULL
g_szValueFlashEnable:	db	"Enable",NULL

g_szMultichoicePageSize:
						db	"1 byte",LF
						db	"2 bytes",LF
						db	"4 bytes",LF
						db	"8 bytes",LF
						db	"16 bytes",LF
						db	"32 bytes",LF
g_szValueFlash64bytes:	db	"64 bytes",NULL
g_szValueFlash1byte:	db	"1 byte",NULL
g_szValueFlash2bytes:	db	"2 bytes",NULL
g_szValueFlash4bytes:	db	"4 bytes",NULL
g_szValueFlash8bytes:	db	"8 bytes",NULL
g_szValueFlash16bytes:	db	"16 bytes",NULL
g_szValueFlash32bytes:	db	"32 bytes",NULL

g_szSelectionTimeout:	db		DOUBLE_BOTTOM_LEFT_CORNER,DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL,"%ASelection in %2u s",NULL

g_szDashForZero:		db		"- ",NULL

g_szValueUnknownError:	db	"Error!",NULL

